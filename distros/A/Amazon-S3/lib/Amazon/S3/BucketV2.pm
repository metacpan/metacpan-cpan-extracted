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

our $VERSION = '2.1.0'; ## no critic (RequireInterpolation)

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

  return $account->send_request(
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

  no strict 'refs'; ## no critic

  foreach my $p ( pairs @{$method_def} ) {
    my ( $sub_name, $api ) = @{$p};

    my $api_method = $method;

    if ( ref($api) && reftype($api) eq 'CODE' ) {
      my $api_params = $api->();
      ( $api_method, $api ) = @{$api_params}{qw(method api)};
    }

    my $anon = sub {
      my ( $self, %args ) = @_;

      my ( $key, $body, $uri_params, $headers ) = @args{qw(key body uri_param headers)};
      $uri_params //= {};

      return $self->send_request(
        method  => $api_method,
        api     => $api,
        headers => $headers,
        $key  ? ( key  => $key )  : (),
        $body ? ( data => $body ) : (),
        %{$uri_params},
      );
    };

    $sub_name = sprintf 'Amazon::S3::BucketV2::%s', to_camel_case($sub_name);
    *{$sub_name} = $anon;
  }

  return;
}

1;

__END__

=pod

=head1 NAME

=head1 NAME

Amazon::S3::BucketV2 - Interface to additional Amazon S3 bucket operations

=head1 SYNOPSIS

  use Amazon::S3;

  my $s3 = Amazon::S3->new(
    { credentials => $credentials,
      region      => 'us-east-1',
    }
  );

  my $bucket = $s3->bucketv2(
    { bucket => 'example-bucket',
    }
  );

  my $result = $bucket->GetBucketVersioning();

  $bucket->DeleteObject(
    key => 'obsolete.txt',
  );

  $bucket->DeleteObjects(
    body => {
      Delete => {
        Object => [
          { Key => 'one.txt' },
          { Key => 'two.txt' },
        ],
      },
    },
  );

=head1 DESCRIPTION

C<Amazon::S3::BucketV2> provides access to S3 API operations that are
not exposed as dedicated methods by L<Amazon::S3::Bucket>.

These additional methods are available only on
C<Amazon::S3::BucketV2> objects. Applications that need this API
surface should construct the bucket with L<Amazon::S3/bucketv2> rather
than L<Amazon::S3/bucket>.

Its method names and request structure are intended to closely follow
the corresponding operations documented by Amazon S3, making it easier
to move from the AWS API documentation to this interface.

C<Amazon::S3::BucketV2> is a subclass of L<Amazon::S3::Bucket>.
All methods documented by L<Amazon::S3::Bucket> remain available.

Instances are normally created with L<Amazon::S3/bucketv2>.

The methods provided by this class are thin wrappers around S3 REST
operations. They construct the request path, serialize an optional
request body as XML, send the request through the associated
L<Amazon::S3> object, and return the decoded response.

This document is primarily a method reference. The AWS S3 API
documentation linked from each method remains the authoritative
reference for operation-specific headers, query parameters, request
bodies, and service behavior.

=head1 GENERATED METHOD CALLING CONVENTION

The S3 operation methods documented below are generated by
C<Amazon::S3::BucketV2> and are called using their CamelCase names.

Each generated method accepts a list of key/value pairs:

  my $result = $bucket->OperationName(
    key       => $key,
    body      => \%body,
    uri_param => \%uri_params,
    headers   => \%headers,
  );

Only the parameters required by the S3 operation need to be supplied.

=head2 body

  body => \%body

Optional hash reference representing the XML request body.

The hash is serialized with
L<Amazon::S3::Util/create_xml_request> before the request is sent.

For example:

  $bucket->DeleteObjects(
    body => {
      Delete => {
        Object => [
          { Key => 'one.txt' },
          { Key => 'two.txt' },
        ],
        Quiet => 1,
      },
    },
  );

When a body is supplied, C<Content-MD5> is calculated and added by
default.

The structure required by C<body> is defined by the corresponding AWS
S3 API operation.

=head2 headers

  headers => \%headers

Optional hash reference containing additional HTTP request headers.

Operation-specific headers are not inferred by this interface unless
the underlying wrapper explicitly provides them. Supply any headers
required by the corresponding S3 API operation.

=head2 key

  key => $key

Optional object key.

Object-level operations normally require this parameter. Bucket-level
operations normally do not.

=head2 uri_param

  uri_param => \%uri_params

Optional hash reference containing query-string parameters required by
the operation.

For example:

  $bucket->DeleteObject(
    key       => 'example.txt',
    uri_param => {
      versionId => $version_id,
    },
  );

The parameter name is C<uri_param>, singular.

=head2 Return Value and Errors

On a successful request with an XML response body, the generated
method returns the decoded S3 response.

A successful request with no XML response body returns C<undef>.

When S3 returns a non-2xx response, the method returns C<undef> and
records the parsed service error on the associated L<Amazon::S3>
object.

The complete HTTP response is available through
L<Amazon::S3::Bucket/last_response>.

See L<Amazon::S3/ERROR HANDLING>.

=head1 METHODS AND SUBROUTINES

=head2 CONSTRUCTOR

=head3 new

  my $bucket = Amazon::S3::BucketV2->new(%options);

  my $bucket = Amazon::S3::BucketV2->new(\%options);

Creates and returns a C<Amazon::S3::BucketV2> object.

The constructor is inherited from L<Amazon::S3::Bucket> and accepts
the same options, including C<account>, C<bucket>, C<region>,
C<logger>, C<buffer_size>, and C<verify_region>.

Applications should normally construct this object using
L<Amazon::S3/bucketv2>.

=head2 GENERAL REQUEST METHOD

=head3 send_request

  my $result = $bucket->send_request(%parameters);

  my $result = $bucket->send_request(\%parameters);

Sends a bucket-scoped S3 request.

This is the common request implementation used by the generated
operation methods.

The following parameters are supported:

=over 4

=item api

Required.

API query component appended to the request path.

An empty string is valid for operations that do not use a named query
component.

=item bucket

Optional bucket name.

The default is the bucket represented by this object.

=item content_key

Optional XML root element hint when C<data> is supplied.

=item data

Optional Perl data structure serialized as XML using
C<create_xml_request()>.

=item headers

Optional request headers.

=item key

Optional object key.

=item md5

Controls automatic C<Content-MD5> generation when C<data> is supplied.

The default is true.

=item method

HTTP method.

The default is C<GET>.

=item path

Optional complete request path.

When supplied, it replaces the path normally constructed from the
bucket, key, and API name.

=back

Any remaining parameters are encoded as query-string parameters.

Returns the decoded response using the same rules described under
L</Return Value and Errors>.

=head2 HEAD OPERATIONS

=head3 HeadBucket

  my $result = $bucket->HeadBucket();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadBucket.html>.

=head3 HeadObject

  my $result = $bucket->HeadObject(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html>.

=head2 GET BUCKET OPERATIONS

=head3 GetBucketAccelerateConfiguration

  my $result = $bucket->GetBucketAccelerateConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAccelerateConfiguration.html>.

=head3 GetBucketAcl

  my $result = $bucket->GetBucketAcl();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAcl.html>.

=head3 GetBucketAnalytics

  my $result = $bucket->GetBucketAnalytics();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAnalyticsConfiguration.html>.

=head3 GetBucketCors

  my $result = $bucket->GetBucketCors();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketCors.html>.

=head3 GetBucketEncryption

  my $result = $bucket->GetBucketEncryption();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketEncryption.html>.

=head3 GetBucketIntelligentTieringConfiguration

  my $result = $bucket->GetBucketIntelligentTieringConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketIntelligentTieringConfiguration.html>.

=head3 GetBucketInventoryConfiguration

  my $result = $bucket->GetBucketInventoryConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketInventoryConfiguration.html>.

=head3 GetBucketLifecycleConfiguration

  my $result = $bucket->GetBucketLifecycleConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html>.

=head3 GetBucketLocation

  my $result = $bucket->GetBucketLocation();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLocation.html>.

=head3 GetBucketLogging

  my $result = $bucket->GetBucketLogging();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLogging.html>.

=head3 GetBucketMetricsConfiguration

  my $result = $bucket->GetBucketMetricsConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketMetricsConfiguration.html>.

=head3 GetBucketNotificationConfiguration

  my $result = $bucket->GetBucketNotificationConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketNotificationConfiguration.html>.

=head3 GetBucketOwnershipControls

  my $result = $bucket->GetBucketOwnershipControls();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketOwnershipControls.html>.

=head3 GetBucketPolicy

  my $result = $bucket->GetBucketPolicy();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicy.html>.

=head3 GetBucketPolicyStatus

  my $result = $bucket->GetBucketPolicyStatus();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html>.

=head3 GetBucketReplication

  my $result = $bucket->GetBucketReplication();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketReplication.html>.

=head3 GetBucketRequestPayment

  my $result = $bucket->GetBucketRequestPayment();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketRequestPayment.html>.

=head3 GetBucketTagging

  my $result = $bucket->GetBucketTagging();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketTagging.html>.

=head3 GetBucketVersioning

  my $result = $bucket->GetBucketVersioning();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html>.

=head3 GetBucketWebsite

  my $result = $bucket->GetBucketWebsite();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketWebsite.html>.

=head2 GET OBJECT OPERATIONS

=head3 GetObjectAcl

  my $result = $bucket->GetObjectAcl(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html>.

=head3 GetObjectAttributes

  my $result = $bucket->GetObjectAttributes(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html>.

=head3 GetObjectLegalHold

  my $result = $bucket->GetObjectLegalHold(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectLegalHold.html>.

=head3 GetObjectLockConfiguration

  my $result = $bucket->GetObjectLockConfiguration(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectLockConfiguration.html>.

=head3 GetObjectRetention

  my $result = $bucket->GetObjectRetention(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectRetention.html>.

=head3 GetObjectTagging

  my $result = $bucket->GetObjectTagging(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html>.

=head3 GetObjectTorrent

  my $result = $bucket->GetObjectTorrent(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTorrent.html>.

=head3 GetPublicAccessBlock

  my $result = $bucket->GetPublicAccessBlock(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html>.

=head2 PUT BUCKET OPERATIONS

=head3 PutBucketCors

  my $result = $bucket->PutBucketCors();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketCors.html>.

=head3 PutBucketEncryption

  my $result = $bucket->PutBucketEncryption();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketEncryption.html>.

=head3 PutBucketIntelligentTieringConfiguration

  my $result = $bucket->PutBucketIntelligentTieringConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketIntelligentTieringConfiguration.html>.

=head3 PutBucketLifecycle

  my $result = $bucket->PutBucketLifecycle();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html>.

=head3 PutBucketLifecycleConfiguration

  my $result = $bucket->PutBucketLifecycleConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html>.

=head3 PutBucketReplicationConfiguration

  my $result = $bucket->PutBucketReplicationConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketReplication.html>.

=head3 PutBucketTagging

  my $result = $bucket->PutBucketTagging();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html>.

=head3 PutBucketVersioning

  my $result = $bucket->PutBucketVersioning();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketVersioning.html>.

=head2 PUT OBJECT OPERATIONS

=head3 PutObject

  my $result = $bucket->PutObject(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html>.

=head3 PutObjectAcl

  my $result = $bucket->PutObjectAcl(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectAcl.html>.

=head3 PutObjectLegalHold

  my $result = $bucket->PutObjectLegalHold(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectLegalHold.html>.

=head3 PutObjectLockConfiguraiton

  my $result = $bucket->PutObjectLockConfiguraiton(
    key => $key,
  );

Object-level S3 operation.

The method name is spelled C<PutObjectLockConfiguraiton> in this
release. It invokes the S3 PutObjectLockConfiguration operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectLockConfiguration.html>.

=head3 PutObjectRetention

  my $result = $bucket->PutObjectRetention(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectRetention.html>.

=head3 PutObjectTagging

  my $result = $bucket->PutObjectTagging(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectTagging.html>.

=head3 PutPublicAccessBlock

  my $result = $bucket->PutPublicAccessBlock(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html>.

=head3 RestoreObject

  my $result = $bucket->RestoreObject(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html>.

=head3 UploadPart

  my $result = $bucket->UploadPart(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html>.

=head3 UploadPartCopy

  my $result = $bucket->UploadPartCopy(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html>.

=head2 DELETE BUCKET OPERATIONS

=head3 DeleteBucket

  my $result = $bucket->DeleteBucket();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html>.

=head3 DeleteBucketAnalyticsConfiguration

  my $result = $bucket->DeleteBucketAnalyticsConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketAnalyticsConfiguration.html>.

=head3 DeleteBucketCors

  my $result = $bucket->DeleteBucketCors();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketCors.html>.

=head3 DeleteBucketEncryption

  my $result = $bucket->DeleteBucketEncryption();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketEncryption.html>.

=head3 DeleteBucketIntelligentTiering

  my $result = $bucket->DeleteBucketIntelligentTiering();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketIntelligentTieringConfiguration.html>.

=head3 DeleteBucketInventoryConfiguration

  my $result = $bucket->DeleteBucketInventoryConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketInventoryConfiguration.html>.

=head3 DeleteBucketLifecycle

  my $result = $bucket->DeleteBucketLifecycle();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html>.

=head3 DeleteBucketMetricsConfiguration

  my $result = $bucket->DeleteBucketMetricsConfiguration();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketMetricsConfiguration.html>.

=head3 DeleteBucketOwnershipControls

  my $result = $bucket->DeleteBucketOwnershipControls();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketOwnershipControls.html>.

=head3 DeleteBucketPolicy

  my $result = $bucket->DeleteBucketPolicy();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketPolicy.html>.

=head3 DeleteBucketReplication

  my $result = $bucket->DeleteBucketReplication();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketReplication.html>.

=head3 DeleteBucketTagging

  my $result = $bucket->DeleteBucketTagging();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html>.

=head3 DeleteBucketWebsite

  my $result = $bucket->DeleteBucketWebsite();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketWebsite.html>.

=head3 DeletePublicAccessBlock

  my $result = $bucket->DeletePublicAccessBlock();

Bucket-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html>.

=head2 DELETE OBJECT OPERATIONS

=head3 DeleteObject

  my $result = $bucket->DeleteObject(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html>.

=head3 DeleteObjects

  my $result = $bucket->DeleteObjects(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjects.html>.

=head3 DeleteObjectTagging

  my $result = $bucket->DeleteObjectTagging(
    key => $key,
  );

Object-level S3 operation.

Accepts the generated-method parameters described in
L</GENERATED METHOD CALLING CONVENTION>.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjectTagging.html>.

=head1 INHERITED METHODS

C<Amazon::S3::BucketV2> inherits the complete
L<Amazon::S3::Bucket> interface.

Use the parent-class convenience methods for common object operations,
listing, ACL handling, multipart uploads, and bucket metadata when
those interfaces are more convenient than the generic API wrappers
documented here.

=head1 SEE ALSO

L<Amazon::S3>

L<Amazon::S3::Bucket>

L<Amazon::S3::Util>

L<https://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html>

=head1 AUTHOR

Rob Lauer - E<lt>bigfoot@cpan.orgE<gt>

=cut
