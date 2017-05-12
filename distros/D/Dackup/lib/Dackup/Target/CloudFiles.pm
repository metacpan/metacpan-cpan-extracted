package Dackup::Target::CloudFiles;
use Moose;
use MooseX::StrictConstructor;
use File::Temp qw/tmpnam/;

extends 'Dackup::Target';

has 'container' => (
    is       => 'ro',
    isa      => 'Net::Mosso::CloudFiles::Container',
    required => 1,
);

has 'prefix' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => '',
);

__PACKAGE__->meta->make_immutable;

sub entries {
    my $self      = shift;
    my $dackup    = $self->dackup;
    my $container = $self->container;
    my $prefix    = $self->prefix;

    my @entries;
    my $stream = $container->objects( prefix => $prefix );
    until ( $stream->is_done ) {
        foreach my $object ( $stream->items ) {
            my $key = $object->name;
            $key =~ s/^$prefix//;
            my $entry = Dackup::Entry->new(
                {   key     => $key,
                    md5_hex => $object->etag,
                    size    => $object->size,
                }
            );
            push @entries, $entry;
        }
    }
    return \@entries;
}

sub object {
    my ( $self, $entry ) = @_;
    return $self->container->object(
        name => $self->prefix . $entry->key,
        etag => $entry->md5_hex,
        size => $entry->size,
    );
}

sub name {
    my ( $self, $entry ) = @_;
    return
          'cloudfiles://'
        . $self->container->name . '/'
        . $self->prefix
        . $entry->key;
}

sub update {
    my ( $self, $source, $entry ) = @_;
    my $container   = $self->container;
    my $prefix      = $self->prefix;
    my $source_type = ref($source);
    my $object      = $self->object($entry);

    if ( $source_type eq 'Dackup::Target::Filesystem' ) {
        $object->put_filename( $source->filename($entry) );
    } elsif ( $source_type eq 'Dackup::Target::S3' ) {
        my $filename      = tmpnam();
        my $source_object = $source->object($entry);
        $source_object->get_filename($filename);
        $object->put_filename( $filename );
        unlink($filename) || die "Error deleting $filename: $!";
    } else {
        confess "Do not know how to update from $source_type";
    }
}

sub delete {
    my ( $self, $entry ) = @_;
    my $object = $self->object($entry);
    $object->delete;
}

1;

__END__

=head1 NAME

Dackup::Target::CloudFiles - Flexible file backup to/from CloudFiles

=head1 SYNOPSIS

  use Dackup;
  use Net::Amazon::S3;
  use Net::Mosso::CloudFiles;

  my $s3 = Net::Amazon::S3->new(
      aws_access_key_id     => 'XXX',
      aws_secret_access_key => 'YYY,
      retry                 => 1,
  );
  my $client = Net::Amazon::S3::Client->new( s3 => $s3 );
  my $bucket = $client->bucket( name => 'important' );

  my $cloudfiles = Net::Mosso::CloudFiles->new(
      user => 'myuser',
      key  => 'ZZZ',
  );
  my $container = $cloudfiles->container('backup');

  my $source = Dackup::Target::S3->new( bucket => $bucket );

  my $destination = Dackup::Target::CloudFiles->new(
      container => $container,
      prefix    => 'important_backup/', # optional
  );

  my $dackup = Dackup->new(
      directory   => '/home/acme/dackup',
      source      => $source,
      destination => $destination,
      delete      => 1,
  );
  $dackup->backup;

=head1 DESCRIPTION

This is a Dackup target for the Mosso CloudFile's service.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.
