package Amazon::S3::BucketV2;

use strict;
use warnings;

use Amazon::S3::Constants qw(:all);
use Amazon::S3::Util qw(:all);

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(pairs);
use Scalar::Util qw(reftype);

use parent qw(Amazon::S3::Bucket);

our $VERSION = '2.0.2';  ## no critic (RequireInterpolation)

######################################################################
our @GET_OBJECT_METHODS = (
######################################################################
  get_object_acl                => 'acl',
  get_object_attributes         => 'attributes',
  get_object_legal_hold         => 'legal-hold',
  get_object_lock_configuration => 'object-lock',
  get_object_retention          => 'retention',
  get_object_tagging            => 'tagging',
  get_object_torrent            => 'torrent',
  get_public_access_block       => 'publicAccessBlock',
);

create_methods(
  type       => 'object',
  method     => 'GET',
  method_def => \@GET_OBJECT_METHODS
);

######################################################################
our @HEAD_OBJECT_METHODS = ( get_object_head => 'head', );
######################################################################

create_methods(
  type       => 'object',
  method     => 'HEAD',
  method_def => [ head_object => $EMPTY ]
);

create_methods(
  type       => 'bucket',
  method     => 'HEAD',
  method_def => [ head_bucket => $EMPTY ]
);

######################################################################
our @GET_BUCKET_METHODS = (
######################################################################
  get_bucket_accelerate_configuration          => 'accelerate',
  get_bucket_acl                               => 'acl',
  get_bucket_analytics                         => 'analytics',
  get_bucket_cors                              => 'cors',
  get_bucket_encryption                        => 'encryption',
  get_bucket_intelligent_tiering_configuration => 'intelligent_tiering',
  get_bucket_inventory_configuration           => 'inventory',
  get_bucket_lifecycle_configuration           => 'lifecycle',
  get_bucket_location                          => 'location',
  get_bucket_logging                           => 'logging',
  get_bucket_metrics_configuration             => 'metrics',
  get_bucket_notification_configuration        => 'notification',
  get_bucket_ownership_controls                => 'ownershipControls',
  get_bucket_policy                            => 'policy',
  get_bucket_policy_status                     => 'policyStatus',
  get_bucket_replication                       => 'replication',
  get_bucket_request_payment                   => 'requestPayment',
  get_bucket_tagging                           => 'tagging',
  get_bucket_versioning                        => 'versioning',
  get_bucket_website                           => 'website',
);

create_methods(
  type       => 'bucket',
  method     => 'GET',
  method_def => \@GET_BUCKET_METHODS,
);

#######################################################################
our @PUT_BUCKET_METHODS = (
#######################################################################
  put_bucket_intelligent_tiering_configuration => 'intelligent-tiering',
  put_bucket_cors                              => 'cors',
  put_bucket_replication_configuration         => 'replication',
  put_bucket_versioning                        => 'versioning',
  put_bucket_encryption                        => 'encryption',
  put_bucket_lifecycle_configuration           => 'lifecycle',
  put_bucket_lifecycle                         => 'lifecycle',
  put_bucket_tagging                           => 'tagging',
);

create_methods(
  type       => 'bucket',
  method     => 'PUT',
  method_def => \@PUT_BUCKET_METHODS
);

######################################################################
our @PUT_OBJECT_METHODS = (
#######################################################################
  put_object                    => $EMPTY,
  put_object_acl                => 'acl',
  put_object_tagging            => 'tagging',
  put_object_retention          => 'retention',
  put_object_legal_hold         => 'legal-hold',
  put_object_lock_configuraiton => 'lock-object',
  put_public_access_block       => 'publicAccessBlock',
  restore_object                => sub {
    return { method => 'POST', api => 'restore' };
  },
  upload_part      => $EMPTY,
  upload_part_copy => $EMPTY,
);

create_methods(
  type       => 'object',
  method     => 'PUT',
  method_def => \@PUT_OBJECT_METHODS,
);

######################################################################
our @DELETE_OBJECT_METHODS = (
######################################################################
  delete_object  => $EMPTY,
  delete_objects => sub {
    return { method => 'POST', api => 'delete' };
  },
  delete_object_tagging => 'tagging',
);

create_methods(
  type       => 'object',
  method     => 'DELETE',
  method_def => \@DELETE_OBJECT_METHODS,
);

######################################################################
our @DELETE_BUCKET_METHODS = (
######################################################################
  delete_bucket                         => $EMPTY,
  delete_bucket_analytics_configuration => 'analytics',
  delete_bucket_cors                    => 'cors',
  delete_bucket_encryption              => 'encryption',
  delete_bucket_intelligent_tiering     => 'intelligent-tiering',
  delete_bucket_inventory_configuration => 'inventory',
  delete_bucket_lifecycle               => 'lifecycle',
  delete_bucket_metrics_configuration   => 'metrics',
  delete_bucket_ownership_controls      => 'ownershipControls',
  delete_bucket_policy                  => 'policy',
  delete_bucket_replication             => 'replication',
  delete_bucket_tagging                 => 'tagging',
  delete_bucket_website                 => 'website',
  delete_public_access_block            => 'publicAccessBlock',
);

create_methods(
  type       => 'bucket',
  method     => 'DELETE',
  method_def => \@DELETE_BUCKET_METHODS
);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  return $class->SUPER::new(@args);
}

########################################################################
sub to_camel_case {
########################################################################
  my ($method) = @_;

  return join $EMPTY, map { ucfirst $_ } split /_/xsm, $method;
}

########################################################################
# send_request()
########################################################################
# This is a general purpose method to send requests that may include an
# XML payload. These requests may also accept headers or query string
# parameters.
#
# args is a hash ref or list of key/value pairs
#   api         => name of the API to invoke (example: 'versioning')
#   content_key => optional root element for XML serialzation
#   headers     => optional headers - create a Content-MD5 key in the headers
#                   object if you want to add the MD5 value
#   bucket      => optional bucket name
#   key         => optional key value for APIs that accept a key
#   data        => optional object that will be converted to an XML payload
#   method      => HTTP method
#
# NOTES:
#   1. If the 'data' object is included, the default method is 'PUT'
#   2. If no 'data' object is included, the default method is 'GET'
#   3. If 'content_key' is not provided when including a 'data' object
#      the method will attempt to guess the root element (content_key)
#      when serializing the data object to XML. If you include
#      additional elements to be used as query string parameters,
#      you should specify 'content_key'..
########################################################################
sub send_request {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my $account = $self->account;

  my $headers = delete $parameters->{headers};
  $headers //= {};

  my $bucket = delete $parameters->{bucket};

  $bucket //= $self->bucket;

  croak 'no bucket'
    if !$bucket;

  my $key = delete $parameters->{key} // $EMPTY;

  my $api = delete $parameters->{api};

  croak 'no api'
    if !defined $api;

  my $path = delete $parameters->{path};

  my $method = delete $parameters->{method};

  # see if we need to send an XML payload
  my $data = delete $parameters->{data};

  if ($data) {
    my $content_key = delete $parameters->{content_key};

    # if we are sending data, include MD5 by default
    my $md5 = delete $parameters->{md5};
    $md5 //= $TRUE;

    if ( !$content_key ) {
      ($content_key) = keys %{$parameters};
    }

    $data = create_xml_request($data);

    if ( $md5 || exists $headers->{'Content-MD5'} ) {
      set_md5_header( data => $data, headers => $headers );
    }
  }

  # create the URI from bucket, key, api and possibly additional parameters
  $path //= sprintf '%s/%s?%s', $bucket, $key, $api;

  if ( keys %{$parameters} ) {
    my $query_string = create_query_string( %{$parameters} );

    if ( $path !~ /[?]$/xsm ) {
      $query_string = "&$query_string";
    }

    $path .= $query_string;
  }

  return $account->_send_request(
    { region  => $self->region,
      method  => $method // 'GET',
      path    => $path,
      headers => $headers,
      $data ? ( data => $data ) : (),
    }
  );
}

########################################################################
sub create_methods {
########################################################################
  my (%args) = @_;

  my ( $type, $method, $method_def ) = @args{qw( type method method_def)};

  no strict 'refs';  ## no critic

  foreach my $p ( pairs @{$method_def} ) {
    my ( $sub_name, $api ) = @{$p};

    if ( ref($api) && reftype($api) eq 'CODE' ) {
      my $api_params = $api->();
      ( $method, $api ) = @{$api_params}{qw(method api)};
    }

    my $anon = sub {
      my ( $self, %args ) = @_;

      my ( $key, $body, $uri_params, $headers ) = @args{qw(key body uri_param headers)};
      $uri_params //= {};

      return $self->send_request(
        method  => $method,
        api     => $api,
        headers => $headers,
        $key  ? ( key  => $key )  : (),
        $body ? ( data => $body ) : (),
        %{$uri_params},
      );
    };

    $sub_name = sprintf 'Amazon::S3::Bucket::%s', to_camel_case($sub_name);
    *{$sub_name} = $anon;
  }

  return;
}

1;

__END__

=pod

=head1 NAME

Amazon::S3::BucketV2 - lightweight interface to various S3 methods

=head1 SYNOPSIS

  use Amazon::S3;
  use Amazon::S3::BucketV2;

  my $s3 = Amazon::S3->new(
      {   aws_access_key_id     => $aws_access_key_id,
          aws_secret_access_key => $aws_secret_access_key,
      }
  );

  my $s3 = Amazon::S3->new();

  my $bucket = Amazon::S3::BucketV2->new(account => $s3, bucket => 'foo');

  $bucket->DeleteObject($key);

  $bucket->DeleteObjects(undef,
    { Delete => { Object => [ { Key => $key, Version => $version } ] } } );

=head1 DESCRIPTION

A lightweight, generic interface to the AWS S3
API. C<Amazon::S3::BucketV2> is a subclass of L<Amazon::S3::Bucket>. In
addition to the methods described below you can still use the
convenience methods offered in the parent class.

I<Note that this is an experimental implementation and may change in
the future.>

The methods listed below should be called with a list (or hash
reference) of key/value pairs.  Depending on your needs and the API
being invoked some of these keys may not be required.

=over 5

=item key

The key in the S3 bucket.

=item body

The request body. This should be a hash ref which will be converted
to an XML payload to be sent for the request.

You need to review the required payload for the API being invoked and
provide the appropriate Perl object to be converted to XML.

To see how your Perl object will be serialized call the C<create_xml>
method.

For example the DeleteObjects API takes a payload that looks like this:

 <Delete xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Object>
       <Key>string</Key>
       <VersionId>string</VersionId>
    </Object>
    ...
    <Quiet>boolean</Quiet>
 </Delete>

The corresponding Perl object would be created like this:

 my $content = {
   Delete => {
     Object => [
       { Key       => '/foo',
         VersionId => 'OYcLXagmS.WaD..oyH4KRguB95_YhLs7'
       }
     ]
   }
 };


...and to verify how that Perl object would be serialized as XML:

 use Amazon::S3::Util qw(create_xml_request);

 my $content = {
   Delete => {
     Object => [
       { Key       => '/foo',
         VersionId => 'OYcLXagmS.WaD..oyH4KRguB95_YhLs7'
       }
     ]
   }
 };

 print create_xml_request($content);
 
=item uri_params

A hash ref of additional query string parameters.

=item headers

A hash ref of additional headers to send with the request. The API
methods will automatically add the rquired headers for most calls.
Review the API specifications to see how to send additional headers
you might require.

=back

Example:

 $bucket->DeleteObject(key => $key);
 $bucket->DeleteObject(key => $key, uri_param => { versionId => $version });

 my $content
   = { Delete => { Object => [ { Key => $key, Version => $version } ] } };

 $bucket->DeleteObject(body => $content);

=head1 METHODS AND SUBROUTINES

The methods below can be called in snake or CamelCase.  Consult the
official AWS S3 API guide for documentation on each method.

L<https://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html>

=head2 delete_bucket

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html>

=head2 delete_bucket_analytics_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketAnalyticsConfiguration.html>

=head2 delete_bucket_cors

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketCors.html>

=head2 delete_bucket_encryption

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketEncryption.html>

=head2 delete_bucket_intelligent_tiering

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketIntelligentTiering.html>

=head2 delete_bucket_inventory_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketInventoryConfiguration.html>

=head2 delete_bucket_lifecycle

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html>

=head2 delete_bucket_metrics_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketMetricsConfiguration.html>

=head2 delete_bucket_ownership_controls

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketOwnershipControls.html>

=head2 delete_bucket_policy

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketPolicy.html>

=head2 delete_bucket_replication

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketReplication.html>

=head2 delete_bucket_tagging

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html>

=head2 delete_bucket_website

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketWebsite.html>

=head2 delete_object

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html>

=head2 delete_objects

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjects.html>

=head2 delete_object_tagging

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjectTagging.html>

=head2 delete_public_access_block

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html>

=head2 get_bucket_accelerate_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAccelerateConfiguration.html>

=head2 get_bucket_acl

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAcl.html>

=head2 get_bucket_analytics

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAnalytics.html>

=head2 get_bucket_cors

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketCors.html>

=head2 get_bucket_encryption

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketEncryption.html>

=head2 get_bucket_intelligent_tiering_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketIntelligentTieringConfiguration.html>

=head2 get_bucket_inventory_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketInventoryConfiguration.html>

=head2 get_bucket_lifecycle_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html>

=head2 get_bucket_location

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLocation.html>

=head2 get_bucket_logging

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLogging.html>

=head2 get_bucket_metrics_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketMetricsConfiguration.html>

=head2 get_bucket_notification_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketNotificationConfiguration.html>

=head2 get_bucket_ownership_controls

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketOwnershipControls.html>

=head2 get_bucket_policy

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicy.html>

=head2 get_bucket_policy_status

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html>

=head2 get_bucket_replication

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketReplication.html>

=head2 get_bucket_request_payment

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketRequestPayment.html>

=head2 get_bucket_tagging

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketTagging.html>

=head2 get_bucket_versioning

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html>

=head2 get_bucket_website

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketWebsite.html>

=head2 get_object_acl

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html>

=head2 get_object_attributes

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html>

=head2 get_object_legal_hold

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectLegalHold.html>

=head2 get_object_lock_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectLockConfiguration.html>

=head2 get_object_retention

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectRetention.html>

=head2 get_object_tagging

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html>

=head2 get_object_torrent

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTorrent.html>

=head2 get_public_access_block

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html>

=head2 put_bucket_cors

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketCors.html>

=head2 put_bucket_encryption

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketEncryption.html>

=head2 put_bucket_intelligent_tiering_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketIntelligentTieringConfiguration.html>

=head2 put_bucket_lifecycle

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html>

=head2 put_bucket_lifecycle_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html>

=head2 put_bucket_replication_configuration

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketReplicationConfiguration.html>

=head2 put_bucket_tagging

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html>

=head2 put_bucket_versioning

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketVersioning.html>

=head2 put_object

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html>

=head2 put_object_acl

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectAcl.html>

=head2 put_object_legal_hold

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectLegalHold.html>

=head2 put_object_lock_configuraiton

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectLockConfiguraiton.html>

=head2 put_object_retention

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectRetention.html>

=head2 put_object_tagging

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectTagging.html>

=head2 put_public_access_block

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html>

=head2 restore_object

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html>

=head2 upload_part

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html>

=head2 upload_part_copy

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html>

=head1 SEE OTHER

L<Amazon::S3>, L<Amazon::S3::Bucket>

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut
