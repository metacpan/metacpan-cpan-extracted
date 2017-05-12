package AnyEvent::Net::Amazon::S3::Client::Object;

# ABSTRACT: An easy-to-use Amazon S3 client object
our $VERSION = 'v0.04.0.80'; # VERSION

use strict;
use warnings;

# TODO: _content_sub might become more async manner?
# NOTE: exists and delete have HIGH risk.
use Module::AnyEvent::Helper::Filter -as => __PACKAGE__, -target => 'Net::Amazon::S3::Client::Object',
        -transformer => 'Net::Amazon::S3::Client::Object',
        -translate_func => [qw(exists _get get get_decoded get_filename _put put put_filename delete
                               initiate_multipart_upload complete_multipart_upload abort_multipart_upload put_part)],
        -replace_func => [qw(_send_request_raw _send_request _send_request_xpc)]
;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Net::Amazon::S3::Client::Object - An easy-to-use Amazon S3 client object

=head1 VERSION

version v0.04.0.80

=head1 SYNOPSIS

  # show the key
  print $object->key . "\n";

  # show the etag of an existing object (if fetched by listing
  # a bucket)
  print $object->etag . "\n";

  # show the size of an existing object (if fetched by listing
  # a bucket)
  print $object->size . "\n";

  # to create a new object
  my $object = $bucket->object( key => 'this is the key' );
  $object->put('this is the value');

  # to get the vaue of an object
  my $value = $object->get;

  # to see if an object exists
  if ($object->exists) { ... }

  # to delete an object
  $object->delete;

  # to create a new object which is publically-accessible with a
  # content-type of text/plain which expires on 2010-01-02
  my $object = $bucket->object(
    key          => 'this is the public key',
    acl_short    => 'public-read',
    content_type => 'text/plain',
    expires      => '2010-01-02',
  );
  $object->put('this is the public value');

  # return the URI of a publically-accessible object
  my $uri = $object->uri;

  # to store a new object with server-side encryption enabled
  my $object = $bucket->object(
    key        => 'my secret',
    encryption => 'AES256',
  );
  $object->put('this data will be stored using encryption.');

  # upload a file
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    content_type => 'image/jpeg',
  );
  $object->put_filename('hat.jpg');

  # upload a file if you already know its md5_hex and size
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    content_type => 'image/jpeg',
    etag         => $md5_hex,
    size         => $size,
  );
  $object->put_filename('hat.jpg');

  # download the value of the object into a file
  my $object = $bucket->object( key => 'images/my_hat.jpg' );
  $object->get_filename('hat_backup.jpg');

  # use query string authentication
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    expires      => '2009-03-01',
  );
  my $uri = $object->query_string_authentication_uri();

=head1 DESCRIPTION

This module represents objects in buckets.

This module provides the same interface as L<Net::Amazon::S3::Client::Object>.
In addition, some asynchronous methods returning AnyEvent condition variable are added.

=for test_synopsis no strict 'vars';
no warnings;

=head1 METHODS

All L<Net::Amazon::S3::Client::Bucket> methods are available.
In addition, there are the following asynchronous methods.
Arguments of the methods are identical as original but return value becomes L<AnyEvent> condition variable.
You can get actual return value by calling C<shift-E<gt>recv()>.

=over 4

=item delete_async

=item exists_async

=item get_async

=item get_decoded_async

=item get_filename_async

=item put_async

=item put_filename_async

=item complete_multipart_upload_async

=item initiate_multipart_upload_async

=item abort_multipart_upload_async

=item put_part_async

=back

=for Pod::Coverage list_parts
query_string_authentication_uri
uri
get_callback

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
