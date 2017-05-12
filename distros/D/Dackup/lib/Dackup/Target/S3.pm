package Dackup::Target::S3;
use Moose;
use MooseX::StrictConstructor;

extends 'Dackup::Target';

has 'bucket' => (
    is       => 'ro',
    isa      => 'Net::Amazon::S3::Client::Bucket',
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
    my $self   = shift;
    my $bucket = $self->bucket;
    my $prefix = $self->prefix;

    my @entries;
    my $object_stream = $bucket->list( { prefix => $prefix } );
    until ( $object_stream->is_done ) {
        foreach my $object ( $object_stream->items ) {
            my $key = $object->key;
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
    return $self->bucket->object(
        key  => $self->prefix . $entry->key,
        etag => $entry->md5_hex,
        size => $entry->size,
    );
}

sub name {
    my ( $self, $entry ) = @_;
    return 's3://' . $self->bucket->name . '/' . $self->prefix . $entry->key;
}

sub update {
    my ( $self, $source, $entry ) = @_;
    my $source_type = ref($source);
    my $object      = $self->object($entry);
    if ( $source_type eq 'Dackup::Target::Filesystem' ) {
        $object->put_filename( $source->filename($entry) );
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

Dackup::Target::S3 - Flexible file backup to/from Amazon S3

=head1 SYNOPSIS

  use Dackup;
  use Net::Amazon::S3;

  my $s3 = Net::Amazon::S3->new(
      aws_access_key_id     => 'XXX',
      aws_secret_access_key => 'YYY',
      retry                 => 1,
  );

  my $client = Net::Amazon::S3::Client->new( s3 => $s3 );
  
  # You must have already created this bucket
  # see Net::Amazon::S3::Client
  my $bucket = $client->bucket( name => 'mybackups' );

  my $source = Dackup::Target::Filesystem->new(
      prefix => '/home/acme/important/' );

  my $destination = Dackup::Target::S3->new( 
      bucket => $bucket,
      prefix => 'important_backup/', # optional
  );

  my $dackup = Dackup->new(
      source      => $source,
      destination => $destination,
      delete      => 1,
  );
  $dackup->backup;

=head1 DESCRIPTION

This is a Dackup target for Amazon's Simple Storage Service.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.
