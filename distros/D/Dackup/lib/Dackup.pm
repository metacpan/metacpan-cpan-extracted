package Dackup;
use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Path::Class;
use Dackup::Cache;
use Dackup::Entry;
use Dackup::Target::CloudFiles;
use Dackup::Target::Filesystem;
use Dackup::Target::S3;
use Dackup::Target::SSH;
use Data::Stream::Bulk::Path::Class;
use DBI;
use Devel::CheckOS qw(os_is);
use File::HomeDir;
use List::Util qw(sum);
use Number::DataRate;
use Path::Class;
use Term::ProgressBar::Simple;

our $VERSION = '0.44';

has 'directory' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 0,
    coerce   => 1,
    default  => sub {
        my $self = shift;
        return dir( File::HomeDir->my_data,
            ( os_is('MicrosoftWindows') ? 'Perl' : '.perl' ), 'Dackup' );
    },
);
has 'source' => (
    is       => 'ro',
    isa      => 'Dackup::Target',
    required => 1,
);
has 'destination' => (
    is       => 'ro',
    isa      => 'Dackup::Target',
    required => 1,
);
has 'delete' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
);
has 'dry_run' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has 'verbose' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has 'cache' => (
    is  => 'rw',
    isa => 'Dackup::Cache',
);
has 'throttle' => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

sub BUILD {
    my $self      = shift;
    my $directory = $self->directory;

    unless ( -d $directory ) {
        $directory->mkpath
            || confess "Unable to create directory $directory: $!";
    }

    my $filename = file( $directory, 'dackup.db' );
    my $cache = Dackup::Cache->new( filename => $filename );
    $self->cache($cache);
    $self->source->dackup($self);
    $self->destination->dackup($self);
}

sub backup {
    my $self        = shift;
    my $source      = $self->source;
    my $destination = $self->destination;
    my $delete      = $self->delete;
    my $dry_run     = $self->dry_run;
    my $verbose     = $self->verbose;

    my $source_entries      = $source->entries;
    my $destination_entries = $destination->entries;

    my ( $entries_to_update, $entries_to_delete )
        = $self->_calc( $source_entries, $destination_entries );

    my $total = sum map { $_->size } @$entries_to_update;
    $total += scalar(@$entries_to_delete) if $delete;
    $total = 0 unless defined $total;

    my $progress = Term::ProgressBar::Simple->new($total);
    $progress->message(
        'Updating ' . scalar(@$entries_to_update) . ' files' );
    $progress->message( 'Deleting ' . scalar(@$entries_to_delete) . ' files' )
        if $delete;

    foreach my $entry (@$entries_to_update) {
        if ($verbose) {
            my $source_name      = $source->name($entry);
            my $destination_name = $destination->name($entry);
            $progress->message("$source_name -> $destination_name");
        }
        $destination->update( $source, $entry ) unless $dry_run;
        $progress += $entry->size;
    }

    if ($delete) {
        foreach my $entry (@$entries_to_delete) {
            if ($verbose) {
                my $name = $destination->name($entry);
                $progress->message("Deleting $name");
            }
            $destination->delete($entry) unless $dry_run;
            $progress++;
        }
    }

    $progress->message( 'Updated ' . scalar(@$entries_to_update) . ' files' );
    $progress->message( 'Deleted ' . scalar(@$entries_to_delete) . ' files' )
        if $delete;

    return scalar(@$entries_to_update);
}

sub _calc {
    my ( $self, $source_entries, $destination_entries ) = @_;
    my %source_entries;
    my %destination_entries;

    $source_entries{ $_->key }      = $_ foreach @$source_entries;
    $destination_entries{ $_->key } = $_ foreach @$destination_entries;

    my @entries_to_update;
    my @entries_to_delete;

    foreach my $key ( sort keys %source_entries ) {
        my $source_entry      = $source_entries{$key};
        my $destination_entry = $destination_entries{$key};
        if ($destination_entry) {
            if ( $source_entry->md5_hex eq $destination_entry->md5_hex ) {

                # warn "$key same";
            } else {

                # warn "$key different";
                push @entries_to_update, $source_entry;
            }
        } else {

            # warn "$key missing";
            push @entries_to_update, $source_entry;
        }
    }

    foreach my $key ( sort keys %destination_entries ) {
        my $source_entry      = $source_entries{$key};
        my $destination_entry = $destination_entries{$key};
        unless ($source_entry) {

            # warn "$key to delete";
            push @entries_to_delete, $destination_entry;
        }
    }

    return \@entries_to_update, \@entries_to_delete;
}

1;

__END__

=head1 NAME

Dackup - Flexible file backup

=head1 SYNOPSIS

  use Dackup;

  my $source = Dackup::Target::Filesystem->new(
      prefix => '/home/acme/important/' );

  my $destination = Dackup::Target::Filesystem->new(
      prefix => '/home/acme/backup/' );

  my $dackup = Dackup->new(
      source      => $source,
      destination => $destination,
      delete      => 0,
      dry_run     => 0,
      verbose     => 1,
      throttle    => '1Mbps',
  );
  $dackup->backup;

=head1 DESCRIPTION

This module is an attempt at a flexible file backup. It supports
copying to and from filesystems, remote hosts via SSH, Amazon's
Simple Storage Service and Mosso's CloudFiles. At all stages,
it checks the MD5 hash of the source and destination files.

It uses an MD5 cache to speed up operations, which it stores by
default in your home directory (you can pass it as a directory
parameter). It's just a cache, so you can delete it, but the next
time you sync it might be a little slower.

It will update new and changed files. If you pass in 
delete => 1 then it will also delete removed files.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.
