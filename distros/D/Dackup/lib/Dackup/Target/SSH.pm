package Dackup::Target::SSH;
use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Path::Class;
use Data::Dumper;
use Digest::MD5::File qw(file_md5_hex);
use File::Copy;
use Path::Class;

extends 'Dackup::Target';

has 'ssh' => (
    is       => 'ro',
    isa      => 'Net::OpenSSH',
    required => 1,
);

has 'prefix' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
);

has 'directories' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    default  => sub { {} },
);

__PACKAGE__->meta->make_immutable;

sub entries {
    my $self        = shift;
    my $ssh         = $self->ssh;
    my $dackup      = $self->dackup;
    my $prefix      = $self->prefix;
    my $cache       = $dackup->cache;
    my $directories = $self->directories;

    my ( $type, $type_err )
        = $ssh->capture2(qq{perl -e 'print "directory\\n" if -d "$prefix"'});
    chomp $type;
    return [] if $type ne 'directory';

    my $code = <<'EOF';
#!perl
use strict;
use warnings;
use File::Find;

my $root = 'XXX';
find( \&wanted, $root );

sub wanted {
    my $filename = $File::Find::name;
    my ($dev,  $ino,   $mode,  $nlink, $uid,     $gid, $rdev,
        $size, $atime, $mtime, $ctime, $blksize, $blocks
    ) = stat($filename);
    my $type;
    if ( -f _ ) {
        $type = 'file';
    } elsif ( -d _ ) {
        $type = 'directory';
    } else {
        $type = 'other';
    }
    print "$type:$ctime:$mtime:$size:$ino:$filename\n";
}
EOF
    $code =~ s/XXX/$prefix/;

    my ($tmpnam)
        = $ssh->capture(
        q{perl -e 'use File::Temp qw/:POSIX/; print scalar tmpnam() . "\n"'})
        || die "ssh failed: " . $ssh->error;
    chomp $tmpnam;

    my ( $rin, $in_pid ) = $ssh->pipe_in("cat > $tmpnam")
        or die "pipe_in method failed: " . $ssh->error;
    $rin->print("$code") || die $ssh->error;
    $rin->close || die $ssh->error;
    waitpid( $in_pid, 0 );

    my ($output) = $ssh->capture2("perl $tmpnam")
        || die "ssh failed: " . $ssh->error;
    $ssh->system("rm $tmpnam")
        or die "remote command failed: " . $ssh->error;
    return [] unless $output;

    my @entries;
    my @not_in_cache;
    foreach my $line ( split "\n", $output ) {
        my ( $type, $ctime, $mtime, $size, $inodenum, $filename ) = split ':',
            $line, 6;
        next if $type eq 'other';
        confess "Error with stat: $line"
            unless $type
                && defined($filename)
                && $ctime
                && $mtime
                && defined($size)
                && defined($inodenum);

        if ( $type eq 'directory' ) {
            $directories->{$filename} = 1;
            next;
        }

        my $key = file($filename)->relative($prefix)->stringify;
        my $cachekey
            = 'ssh:' . $ssh->{_user} . ':' . $ssh->{_host} . ':' . $line;

        my $md5_hex = $cache->get($cachekey);
        if ($md5_hex) {
            push @entries,
                Dackup::Entry->new(
                {   key     => $key,
                    md5_hex => $md5_hex,
                    size    => $size,
                }
                );
        } else {
            push @not_in_cache,
                {
                key      => $key,
                cachekey => $cachekey,
                filename => $filename,
                size     => $size,
                };
        }
    }
    if (@not_in_cache) {

        my $code = <<'EOF';
#!perl
use strict;
use warnings;
use Digest::MD5;
use IO::File;

my XXX
foreach my $filename (@$filenames) {
    my $fh = IO::File->new($filename) || die $!;
    my $md5 = Digest::MD5->new;
    $md5->addfile($fh);
    print $md5->hexdigest . ' ' . $filename . "\n";
    $fh->close;
}
EOF

        my $files
            = Data::Dumper->Dump(
            [ [ map { $_->{filename} } @not_in_cache ] ],
            ['filenames'] );
        $code =~ s/XXX/$files/;

        my ( $rin, $in_pid ) = $ssh->pipe_in("cat > $tmpnam")
            or die "pipe_in method failed: " . $ssh->error;
        $rin->print($code) || die $!;
        $rin->close || die $ssh->error;
        waitpid( $in_pid, 0 );

        my %filename_to_d;
        foreach my $d (@not_in_cache) {
            my $filename = $d->{filename};
            $filename_to_d{$filename} = $d;
        }

        my ($lines) = $ssh->capture2("perl $tmpnam")
            || die "ssh failed: " . $ssh->error;

        foreach my $line ( split "\n", $lines ) {

            # chomp $line;
            #warn "[$line]";
            my ( $md5_hex, $filename ) = split / +/, $line, 2;

            #warn "[$md5_hex, $filename]";
            confess "Error with $line"
                unless defined $md5_hex && defined $filename;
            my $d = $filename_to_d{$filename};
            confess "Missing d for $filename" unless $d;
            push @entries,
                Dackup::Entry->new(
                {   key     => $d->{key},
                    md5_hex => $md5_hex,
                    size    => $d->{size},
                }
                );
            $cache->set( $d->{cachekey}, $md5_hex );
        }
        $ssh->system("rm $tmpnam")
            or die "remote command failed: " . $ssh->error;
    }
    return \@entries;
}

sub filename {
    my ( $self, $entry ) = @_;
    return file( $self->prefix, $entry->key );
}

sub name {
    my ( $self, $entry ) = @_;
    my $ssh = $self->ssh;
    return
          'ssh://'
        . $ssh->{_user} . '@'
        . $ssh->{_host}
        . file( $self->prefix, $entry->key );
}

sub update {
    my ( $self, $source, $entry ) = @_;
    my $ssh                   = $self->ssh;
    my $source_type           = ref($source);
    my $destination_filename  = $self->filename($entry);
    my $destination_directory = $destination_filename->parent;
    my $directories           = $self->directories;

    if ( $source_type eq 'Dackup::Target::Filesystem' ) {
        my $source_filename = $source->filename($entry);

        unless ( $directories->{$destination_directory} ) {

            my $quoted_destination_directory
                = $ssh->shell_quote("$destination_directory");

            # warn "mkdir -p $quoted_destination_directory";
            $ssh->system("mkdir -p $quoted_destination_directory")
                || die "mkdir -p $quoted_destination_directory failed: "
                . $ssh->error;
            $directories->{$destination_directory} = 1;
        }

        #warn "$source_filename -> $destination_filename";

        my $scp_options = {};
        my $throttle    = $self->dackup->throttle;
        if ($throttle) {
            my $data_rate       = Number::DataRate->new;
            my $bits_per_second = $data_rate->to_bits_per_second($throttle);
            $scp_options->{bwlimit} = $bits_per_second / 1000;    # in Kbit/s
        }

        $ssh->scp_put( $scp_options, "$source_filename",
            "$destination_filename" )
            || die "scp failed: " . $ssh->error;
    } else {
        confess "Do not know how to update from $source_type";
    }
}

sub delete {
    my ( $self, $entry ) = @_;
    my $ssh      = $self->ssh;
    my $filename = $self->filename($entry);

    $ssh->system("rm -f $filename")
        || die "rm -f $filename failed: " . $ssh->error;
}

1;

__END__

=head1 NAME

Dackup::Target::SSH - Flexible file backup remote hosts via SSH

=head1 SYNOPSIS

  use Dackup;
  use Net::OpenSSH;

  my $ssh = Net::OpenSSH->new('acme:password@backuphost');
  $ssh->error
      and die "Couldn't establish SSH connection: " . $ssh->error;

  my $source = Dackup::Target::Filesystem->new(
      prefix => '/home/acme/important/' );

  my $destination = Dackup::Target::SSH->new(
      ssh    => $ssh,
      prefix => '/home/acme/important_backup/'
  );

  my $dackup = Dackup->new(
      source      => $source,
      destination => $destination,
      delete      => 0,
  );
  $dackup->backup;

=head1 DESCRIPTION

This is a Dackup target for a remote host via SSH.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.
