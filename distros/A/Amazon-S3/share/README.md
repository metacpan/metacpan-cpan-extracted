# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [AUTHENTICATION AND CREDENTIALS](#authentication-and-credentials)
* [CHECKSUMS](#checksums)
  * [Uploads](#uploads)
  * [Downloads](#downloads)
* [WORKING WITH BUCKETS AND OBJECTS](#working-with-buckets-and-objects)
  * [Creating and Representing Buckets](#creating-and-representing-buckets)
* [LISTING OBJECTS](#listing-objects)
  * [Choosing a Listing API](#choosing-a-listing-api)
  * [Prefixes and Delimiters](#prefixes-and-delimiters)
  * [Pagination](#pagination)
  * [Listing Results](#listing-results)
* [MULTIPART UPLOADS](#multipart-uploads)
* [DIRECTORY BUCKETS](#directory-buckets)
* [ERROR HANDLING](#error-handling)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
  * [CONSTRUCTOR](#constructor)
    * [new](#new)
  * [ACCESSORS](#accessors)
    * [buffer\_size](#buffer\size)
    * [cache\_signer](#cache\signer)
    * [checksum\_algorithm](#checksum\algorithm)
    * [checksum\_types](#checksum\types)
    * [credentials](#credentials)
    * [dns\_bucket\_names](#dns\bucket\names)
    * [err](#err)
    * [error](#error)
    * [errstr](#errstr)
    * [host](#host)
    * [last\_request](#last\request)
    * [last\_response](#last\response)
    * [logger](#logger)
    * [retry](#retry)
    * [secure](#secure)
    * [timeout](#timeout)
    * [verify\_checksums](#verify\checksums)
  * [AUTHENTICATION AND CONFIGURATION METHODS](#authentication-and-configuration-methods)
    * [get\_credentials](#get\credentials)
    * [get\_default\_region](#get\default\region)
    * [get\_logger](#get\logger)
    * [level](#level)
    * [region](#region)
    * [signer](#signer)
  * [BUCKET MANAGEMENT](#bucket-management)
    * [add\_bucket](#add\bucket)
    * [bucket](#bucket)
    * [buckets](#buckets)
    * [bucketv2](#bucketv2)
    * [delete\_bucket](#delete\bucket)
    * [delete\_public\_access\_block](#delete\public\access\block)
    * [get\_bucket\_location](#get\bucket\location)
    * [list\_directory\_buckets](#list\directory\buckets)
  * [OBJECT LISTING AND VERSIONING](#object-listing-and-versioning)
    * [list\_bucket](#list\bucket)
    * [turn\_off\_special\_retry](#turn\off\special\retry)
    * [turn\_on\_special\_retry](#turn\on\special\retry)
* [LOGGING AND DEBUGGING](#logging-and-debugging)
* [S3-COMPATIBLE SERVICES](#s3-compatible-services)
* [COMPARISON TO OTHER PERL S3 MODULES](#comparison-to-other-perl-s3-modules)
* [COMPATIBILITY AND LIMITATIONS](#compatibility-and-limitations)
  * [Minimum Perl Version](#minimum-perl-version)
  * [Signature Version 4](#signature-version-4)
  * [Directory Buckets](#directory-buckets)
* [TESTING](#testing)
* [SUPPORT](#support)
* [REPOSITORY](#repository)
* [AUTHOR](#author)
* [SEE ALSO](#see-also)
* [LICENCE](#licence)
# NAME

Amazon::S3 - A Perl client library for working with and managing
Amazon S3 buckets and objects.

# SYNOPSIS

    use Amazon::S3;

    my $s3 = Amazon::S3->new(
      { credentials => $credentials,
        region      => 'us-east-1',
      }
    );

    my $bucket = $s3->bucket('example-bucket');

    $bucket->add_key(
      'testing.txt',
      'T',
      { content_type        => 'text/plain',
        'x-amz-meta-colour' => 'orange',
      }
    );

    my $response = $bucket->list
      or die $s3->err . ': ' . $s3->errstr;

    for my $key ( @{ $response->{keys} } ) {
      print $key->{key} . "\n";
    }

    my $object = $bucket->get_key('testing.txt')
      or die $s3->err . ': ' . $s3->errstr;

    print $object->{value};

# DESCRIPTION

`Amazon::S3` provides a Perl interface to Amazon Simple Storage
Service (S3).

The distribution separates account-level S3 operations from
bucket and object operations.

`Amazon::S3` represents the S3 client and AWS account context. It
manages credentials, request signing, regions, service endpoints,
bucket creation and discovery, and account-level listing operations.

[Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) represents an individual bucket. Object
operations such as uploads, downloads, deletes, ACLs, multipart
uploads, and bucket-scoped listing operations are provided primarily
through that class.

[Amazon::S3::BucketV2](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucketV2) is a subclass of [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) that
provides a more general interface to S3 APIs. It accepts API
parameters, headers, URI parameters, and request payload structures
using a consistent calling convention.

`Amazon::S3` originated as a fork of [Net::Amazon::S3](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3), but the two
distributions have diverged substantially. Current versions should
not be considered interchangeable.

Version 2.1.0 adds modern S3 checksum support while preserving the
existing `Amazon::S3` and [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) interfaces. Managed
uploads use CRC64NVME by default, and downloads can request and verify
checksum metadata returned by S3.

# AUTHENTICATION AND CREDENTIALS

`Amazon::S3` supports either explicit AWS access keys or a credentials
object.

Explicit credentials may be supplied to the constructor:

    my $s3 = Amazon::S3->new(
      { aws_access_key_id     => $aws_access_key_id,
        aws_secret_access_key => $aws_secret_access_key,
        token                 => $session_token,
      }
    );

The `token` option is required only when temporary AWS credentials
include a session token.

For applications that obtain credentials dynamically, a credentials
object is preferred:

    my $s3 = Amazon::S3->new({ credentials => $credentials } );

The credentials object must provide:

    get_aws_access_key_id()
    get_aws_secret_access_key()
    get_token()

[Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) is one implementation of this interface.

Using a credentials object allows the credential provider to manage
credential discovery and refresh independently of `Amazon::S3`.

`Amazon::S3` uses Signature Version 4 for AWS API requests.

The signer normally uses the credentials associated with the
`Amazon::S3` object. A signer may also be supplied to the constructor
using the `signer` option.

By default, signers are not cached. Setting `cache_signer` to true
causes `Amazon::S3` to retain and reuse the signer object.

Applications should avoid dumping `Amazon::S3`, credential, or signer
objects to logs. These objects participate in request authentication
and may contain or provide access to sensitive authentication
material.

# CHECKSUMS

Version 2.1.0 adds checksum generation for uploads and checksum
verification for downloads.

The default upload checksum algorithm is `crc64nvme`.

`Amazon::S3` provides local implementations for:

    crc64nvme
    crc32
    crc32c
    md5
    sha1
    sha256
    sha512

Amazon S3 also defines XXHash checksum algorithms. They are recognized
by `Amazon::S3` but are not implemented locally in this release.

## Uploads

When an upload is performed through [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket),
`Amazon::S3` calculates the configured checksum when that operation
supports checksum submission.

The checksum algorithm is selected using `checksum_algorithm`. The
default is `crc64nvme`.

Managed multipart uploads performed by
`Amazon::S3::Bucket::upload_multipart_object()` also use the
configured checksum algorithm.

Low-level multipart methods do not implicitly enable an additional
checksum algorithm. Applications that directly manage the multipart
workflow are responsible for selecting and carrying the checksum
algorithm through that workflow.

## Downloads

Checksum verification is enabled by default.

When `verify_checksums` is true, object downloads request checksum
metadata from S3. `Amazon::S3` verifies supported `FULL_OBJECT`
checksums returned by the service.

Verification is opportunistic. If S3 does not return a checksum, or
returns a checksum for an algorithm that `Amazon::S3` cannot
calculate locally, the object can still be downloaded.

`COMPOSITE` checksums are not independently verified.

Partial and ranged downloads are not checksum verified because the
checksum returned for an object describes the complete object rather
than the requested byte range.

The `verify_checksums` setting controls download verification only.
It does not disable checksum generation for uploads.

# WORKING WITH BUCKETS AND OBJECTS

`Amazon::S3` creates bucket objects that provide the object-oriented
interface used for most S3 operations.

## Creating and Representing Buckets

`add_bucket()` creates a bucket in S3.

`bucket()` and `bucketv2()` do not create a bucket. They construct
client-side objects representing a bucket.

A bucket region can be supplied explicitly when constructing a bucket
object. Region verification can also be requested when the bucket
region is not already known; doing so requires an additional service
request.

Amazon S3 applies public-access-block settings to new buckets by
default. Applications that intentionally create public buckets or
apply public ACLs must ensure that the account and bucket public access
settings permit the requested policy.

Directory buckets have additional creation requirements. See
["DIRECTORY BUCKETS"](#directory-buckets).

    my $bucket = $s3->bucket('example-bucket');

Calling `bucket()` does not create the bucket and does not verify
that it exists. It constructs an [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object
associated with the `Amazon::S3` client.

A bucket can be assigned a region explicitly:

    my $bucket = $s3->bucket(
      { bucket => 'example-bucket',
        region => 'us-west-2',
      }
    );

The bucket interface provides operations including:

    add_key()
    add_key_filename()
    copy_object()
    delete_key()
    delete_keys()
    get_acl()
    get_key()
    get_key_filename()
    head_key()
    set_acl()

See [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) for the method reference for bucket and
object operations.

# LISTING OBJECTS

The distribution provides both the original S3 ListObjects API and
ListObjectsV2.

At the `Amazon::S3` level these are exposed as:

    list_bucket()
    list_bucket_v2()

The corresponding convenience methods:

    list_bucket_all()
    list_bucket_all_v2()

follow pagination automatically and return the combined result.

[Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) provides bucket-oriented wrappers for these
operations.

## Choosing a Listing API

ListObjectsV2 is generally preferred for new code.

`list_bucket()` uses the original marker-based pagination model.

`list_bucket_v2()` uses the continuation-token model introduced by
ListObjectsV2 and also supports `start-after`.

Applications that need control over individual result pages should
use `list_bucket()` or `list_bucket_v2()` directly.

Applications that simply need all matching objects can use the
corresponding `_all` method.

## Prefixes and Delimiters

S3 keys are not filesystem paths. However, `prefix` and `delimiter`
can be used to present a hierarchy-like view of keys.

For example, given these keys:

    bar/baz
    bar/buz
    bar/buz/biz
    bar/buz/zip

a request using:

    prefix    => 'bar/'
    delimiter => '/'

returns the keys at that level and rolls deeper keys into a common
prefix.

A typical request is:

    my $response = $s3->list_bucket_v2(
      { bucket    => 'example-bucket',
        prefix    => 'bar/',
        delimiter => '/',
      }
    );

The rolled-up prefixes are returned in `common_prefixes`.

## Pagination

`list_bucket()` resumes a truncated listing using `marker`.

When a delimiter is used, the normalized response can contain
`next_marker`. Without a delimiter, the last returned key can be
used as the marker for the next request.

`list_bucket_v2()` resumes a truncated listing using the continuation
token returned by S3. In the normalized `Amazon::S3` result,
`next_marker` contains `NextContinuationToken`.

For example:

    my $response = $s3->list_bucket_v2(
      { bucket => 'example-bucket',
      }
    );

    while ( $response->{is_truncated} ) {
      $response = $s3->list_bucket_v2(
        { bucket               => 'example-bucket',
          'continuation-token' => $response->{next_marker},
        }
      );
    }

When application code does not need to process individual pages,
`list_bucket_all()` and `list_bucket_all_v2()` perform this work
automatically.

## Listing Results

`list_bucket()` and `list_bucket_v2()` normalize their results into
the same general structure:

    {
      bucket          => $bucket_name,
      prefix          => $prefix,
      marker          => $marker,
      next_marker     => $next_marker,
      max_keys        => $max_keys,
      is_truncated    => $boolean,
      keys            => \@keys,
      common_prefixes => \@prefixes,
    }

`common_prefixes` is present when the request uses a delimiter and S3
returns rolled-up prefixes.

Each element of `keys` is a hash reference containing object metadata:

    {
      key               => $key,
      last_modified     => $last_modified,
      etag              => $etag,
      size              => $size,
      storage_class     => $storage_class,
      owner_id          => $owner_id,
      owner_displayname => $owner_displayname,
    }

The `etag` value is the ETag returned by S3. It must not be assumed
to be a checksum of the complete object.

`list_object_versions()` is different: it returns the parsed
ListObjectVersions service response rather than this normalized
listing structure and does not automatically follow pagination.

See the corresponding entries under ["METHODS AND SUBROUTINES"](#methods-and-subroutines) for
the method contracts.

# MULTIPART UPLOADS

Multipart upload operations are provided by [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket).

For normal application use,
`Amazon::S3::Bucket::upload_multipart_object()` is the preferred
interface. It manages initiation, part uploads, completion, checksum
state, and optional abort-on-error behavior.

    my $parts = $bucket->upload_multipart_object(
      { key  => 'large-object.dat',
        data => $data,
      }
    );

The method can also consume data from a file handle or callback.

The lower-level multipart methods are available for applications that
need to control the multipart lifecycle themselves:

    initiate_multipart_upload()
    upload_part_of_multipart_upload()
    complete_multipart_upload()
    abort_multipart_upload()
    list_multipart_upload_parts()
    list_multipart_uploads()

These methods should generally be considered building blocks for
specialized workflows rather than the default multipart API.

See [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) for their complete method documentation.

# DIRECTORY BUCKETS

`Amazon::S3` provides limited support for Amazon S3 directory
buckets.

Directory buckets use the S3 Express One Zone storage class.

`Amazon::S3` can currently create and list directory buckets.
Object access within directory buckets is not yet supported because
that requires creating an S3 Express session and using the resulting
temporary credentials when signing requests to the directory bucket's
Zonal endpoint.

A directory bucket can be created by supplying an availability zone
to `add_bucket()`:

    my $bucket = $s3->add_bucket(
      { bucket            => $bucket_name,
        availability_zone => 'use1-az5',
      }
    );

Directory buckets owned by the account can be listed with
`list_directory_buckets()`.

See
[https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-overview.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-overview.html).

# ERROR HANDLING

C\[Amazon::S3\](Amazon::S3) uses both return-value errors and exceptions.

For backward compatibility, many service operations return `undef` or
a false value when an S3 request fails and record information about the
most recent error on the C\[Amazon::S3\](Amazon::S3) object.

The primary error accessors are:

err()
errstr()
error()

`err()` contains the S3 error code when one is available.

`errstr()` contains the human-readable service error message.

`error()` contains the parsed structured error response when the
service returned one.

Typical error handling using the historical interface therefore looks
like:

my $response = $s3->buckets;

if (!$response) {
die $s3->err . ': ' . $s3->errstr;
}

Applications that prefer request failures to throw exceptions can
enable `raise_error` when constructing the client:

my $s3 = Amazon::S3->new(
credentials => $credentials,
raise\_error => 1,
);

With `raise_error` enabled, S3 request failures that would normally
return a failure value instead throw an exception. The error state is
still recorded in `err()`, `errstr()`, and `error()` before the
exception is raised.

When available, the exception includes the HTTP status together with
the S3 error code and message.

Some request, protocol, multipart, checksum verification, and
validation failures always throw exceptions because the operation
cannot safely continue.

The most recent HTTP request and response can be inspected using
`last_request()` and `last_response()`.

These accessors are especially useful when diagnosing signing,
endpoint, header, or protocol problems.

`raise_error` defaults to false to preserve the historical
C\[Amazon::S3\](Amazon::S3) interface. New applications may prefer to enable it when
they want request failures to be impossible to overlook.

# METHODS AND SUBROUTINES

This section documents methods provided directly by `Amazon::S3`.

Methods implemented by [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) or
[Amazon::S3::BucketV2](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucketV2) are documented by those classes and are not
duplicated here.

Unless otherwise noted, a service operation returns `undef` when an
error occurs and records error information on the `Amazon::S3`
object. Some request, protocol, and validation failures throw an
exception instead.

See ["ERROR HANDLING"](#error-handling).

## CONSTRUCTOR

### new

    my $s3 = Amazon::S3->new(%options);

    my $s3 = Amazon::S3->new(\%options);

Creates and returns a new `Amazon::S3` client object.

The constructor accepts either a list of key/value pairs or a hash
reference.

At least one of the following credential configurations is required:

- A `credentials` object that provides `get_aws_access_key_id()`,
`get_aws_secret_access_key()`, and `get_token()`.
- Both `aws_access_key_id` and `aws_secret_access_key`.

The following options are supported:

- aws\_access\_key\_id

    AWS access key ID.

    This option is required when a `credentials` object is not supplied.

    When explicit credentials are supplied, `Amazon::S3` stores them
    internally for use when signing requests. Applications should avoid
    dumping the client object to logs.

    See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

- aws\_secret\_access\_key

    AWS secret access key.

    This option is required when a `credentials` object is not supplied.

    See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

- buffer\_size

    Default buffer size, in bytes, used by operations that stream object
    data.

    The default is 4096.

- cache\_signer

    When true, retain and reuse the Signature Version 4 signer.

    When false, construct a signer when one is needed.

    The default is false.

    See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

- checksum\_algorithm

    Checksum algorithm used when `Amazon::S3` supplies a checksum with an
    upload.

    The default is `crc64nvme`.

    Recognized S3 checksum algorithm names are validated by the
    constructor. Local checksum implementations provided by this release
    are described in ["CHECKSUMS"](#checksums).

- credentials

    Credentials provider object.

    The object must provide:

        get_aws_access_key_id()
        get_aws_secret_access_key()
        get_token()

    [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) is one implementation of this interface.

    See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

- debug

    Compatibility option that sets the default logger level to `debug`.

    Applications should normally use `level` instead.

    This option affects the internally created logger only.

- dns\_bucket\_names

    Controls whether virtual-hosted-style bucket names are used when
    possible.

    The default is true.

    A bucket name that cannot be used as a DNS subdomain is placed in the
    request path instead.

- endpoint\_url

    A fully qualified HTTP or HTTPS service endpoint. The URL may include a
    port. This constructor option is a convenience for setting `host` and
    `secure` together.

    For example:

        endpoint_url => 'http://localhost:4566'

    `endpoint_url` cannot be used together with `host` or `secure` and
    must not contain a path.

- host

    S3 service endpoint.

    The default is `s3.amazonaws.com`.

    When `region()` is set and the host is a standard Amazon S3 endpoint,
    `Amazon::S3` adjusts the host for the configured region.

    This option can also be used with S3-compatible and local testing
    services.

- level

    Logging level used when `Amazon::S3` creates its default logger.

    The default is `error`.

    See ["LOGGING AND DEBUGGING"](#logging-and-debugging).

- logger

    Logger object.

    If omitted, `Amazon::S3::Logger` is used.

    A caller-supplied logger is expected to provide the logging methods
    used by `Amazon::S3`.

    See ["LOGGING AND DEBUGGING"](#logging-and-debugging).

- raise\_error

    When true, S3 request failures that would normally be reported through
    the return value and the `err()`, `errstr()`, and `error()` accessors
    instead throw an exception.

    The exception includes the HTTP status and, when available, the S3
    error code and message.

    The default is false for backward compatibility.

    See ["ERROR HANDLING"](#error-handling).

- region

    AWS region used for account-level requests and as the default region
    for newly constructed bucket objects.

    The default is `us-east-1`.

- retry

    When true, use retry-aware HTTP handling.

    Retries use exponential delays of 1, 2, 4, 8, 16, and 32 seconds.

    The default is false.

- secure

    When true, use HTTPS when communicating with the service.

    The default is true.

- signer

    Optional Signature Version 4 signer object.

    When supplied, this signer is used instead of constructing one from
    the configured credentials.

    See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

- timeout

    HTTP request timeout in seconds.

    The default is 30.

- token

    Optional AWS session token used with temporary credentials.

- verify\_checksums

    Controls checksum verification when downloading objects.

    The default is true.

    See ["CHECKSUMS"](#checksums).

If neither a credentials provider nor both explicit access key values
are supplied, the constructor throws an exception.

An invalid `checksum_algorithm` also causes the constructor to throw
an exception.

On success, returns the new `Amazon::S3` object.

## ACCESSORS

### buffer\_size

    my $buffer_size = $s3->buffer_size;

    $s3->buffer_size($bytes);

Gets or sets the default streaming buffer size in bytes.

The constructor default is 4096.

### cache\_signer

    my $cache_signer = $s3->cache_signer;

    $s3->cache_signer($boolean);

Gets or sets whether a generated request signer is retained for reuse.

The constructor default is false.

See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

### checksum\_algorithm

    my $algorithm = $s3->checksum_algorithm;

    $s3->checksum_algorithm('sha256');

Gets or sets the checksum algorithm selected for uploads.

The constructor default is `crc64nvme`.

The constructor validates the initial value. Callers that change this
accessor after construction are responsible for supplying an
algorithm supported by the operation being performed.

See ["CHECKSUMS"](#checksums).

### checksum\_types

    my $checksum_types = $s3->checksum_types;

Returns the checksum implementations initialized for this client.

The value is a hash reference keyed by algorithm name.

This accessor is intended for introspection. The internal checksum
implementation entries are not a public plugin interface in this
release.

See ["CHECKSUMS"](#checksums).

### credentials

    my $credentials = $s3->credentials;

    $s3->credentials($credentials);

Gets or sets the credentials provider object.

See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

### dns\_bucket\_names

    my $enabled = $s3->dns_bucket_names;

    $s3->dns_bucket_names($boolean);

Gets or sets whether virtual-hosted-style bucket addressing is used
when possible.

The constructor default is true.

### err

Returns the most recent S3 error code or short error identifier.

See ["ERROR HANDLING"](#error-handling).

### error

Returns the most recent parsed structured error response.

See ["ERROR HANDLING"](#error-handling).

### errstr

Returns the most recent human-readable error message.

See ["ERROR HANDLING"](#error-handling).

### host

    my $host = $s3->host;

    $s3->host($endpoint);

Gets or sets the configured S3 endpoint.

The constructor default is `s3.amazonaws.com`.

See ["S3-COMPATIBLE SERVICES"](#s3-compatible-services).

### last\_request

Returns the most recent [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) generated by `Amazon::S3`.

See ["ERROR HANDLING"](#error-handling).

### last\_response

Returns the most recent [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) received by `Amazon::S3`.

See ["ERROR HANDLING"](#error-handling).

### logger

    my $logger = $s3->logger;

    $s3->logger($logger);

Gets or sets the logger used by `Amazon::S3`.

See ["LOGGING AND DEBUGGING"](#logging-and-debugging).

### retry

    my $retry = $s3->retry;

    $s3->retry($boolean);

Gets or sets whether retry-aware HTTP handling is enabled.

The constructor default is false.

### secure

    my $secure = $s3->secure;

    $s3->secure($boolean);

Gets or sets whether HTTPS is used.

The constructor default is true.

### timeout

    my $timeout = $s3->timeout;

    $s3->timeout($seconds);

Gets or sets the HTTP request timeout in seconds.

The constructor default is 30.

### verify\_checksums

    my $verify_checksums = $s3->verify_checksums;

    $s3->verify_checksums($boolean);

Gets or sets whether supported checksums returned for downloaded
objects are verified.

The constructor default is true.

See ["CHECKSUMS"](#checksums).

## AUTHENTICATION AND CONFIGURATION METHODS

### get\_credentials

    my ( $access_key_id, $secret_access_key, $token )
      = $s3->get_credentials;

Returns the credentials used by the client.

When a `credentials` provider is configured, this method obtains the
three values from that provider.

Otherwise it returns the credentials stored by the `Amazon::S3`
object.

The return values, in order, are:

1. AWS access key ID.
2. AWS secret access key.
3. Session token, or `undef` when no token is configured.

See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

### get\_default\_region

    my $region = $s3->get_default_region;

Attempts to determine the default AWS region.

The method checks, in order:

1. `AWS_REGION`.
2. `AWS_DEFAULT_REGION`.
3. The EC2 instance metadata availability-zone endpoint.

When an availability zone is obtained from instance metadata, the
zone suffix is removed to derive the region.

If no region can be determined, `us-east-1` is returned.

### get\_logger

    my $logger = $s3->get_logger;

Returns the logger associated with the client.

If no logger was supplied to `new()`, this is the
[Amazon::S3::Logger](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ALogger) instance created by the constructor.

This method is provided for compatibility with logger interfaces that
expect `get_logger()`.

See ["LOGGING AND DEBUGGING"](#logging-and-debugging).

### level

    my $level = $s3->level;

    $s3->level('debug');

Gets or sets the logging level.

When a level is supplied, both the stored logging level and the
associated logger level are updated.

When called without an argument, returns the current logger level.

The constructor default is `error`.

See ["LOGGING AND DEBUGGING"](#logging-and-debugging).

### region

    my $region = $s3->region;

    $s3->region('us-west-2');

Gets or sets the region used by the client.

The region is used for account-level requests and as the default
region assigned to bucket objects when no bucket-specific region is
supplied.

When the configured host uses the standard `s3.amazonaws.com` form,
setting the region also adjusts the host to the regional Amazon S3
endpoint.

The constructor default is `us-east-1`.

### signer

    my $signer = $s3->signer;

Returns the Signature Version 4 signer used for requests.

If a signer was supplied to the constructor, that signer is returned.

Otherwise a signer is constructed from the current credentials,
region, and session token.

When `cache_signer` is true, a generated signer is retained and
reused. When it is false, a signer can be generated as needed.

This method does not accept a signer argument. Supply a custom signer
using the `signer` constructor option.

See ["AUTHENTICATION AND CREDENTIALS"](#authentication-and-credentials).

## BUCKET MANAGEMENT

### add\_bucket

    my $bucket = $s3->add_bucket(\%configuration);

Creates a bucket.

The argument is a hash reference containing the bucket configuration.

- bucket

    Required. Bucket name.

- acl\_short

    Optional canned ACL.

    Optional canned ACL applied when creating the bucket.

    See ["WORKING WITH BUCKETS AND OBJECTS"](#working-with-buckets-and-objects).

- location\_constraint

    Compatibility name for the region in which the bucket should be
    created.

    When both `location_constraint` and `region` are supplied,
    `location_constraint` takes precedence.

- region

    Region in which the bucket should be created.

    If neither `region` nor `location_constraint` is supplied, the
    client region is used.

    For `us-east-1`, no location constraint is sent.

- headers

    Optional hash reference containing additional request headers.

- availability\_zone

    When supplied, create an S3 directory bucket in the specified
    availability zone.

    See ["DIRECTORY BUCKETS"](#directory-buckets).

On success, returns an [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object for the newly
created bucket.

On failure, returns `undef` and records error information on the
client.

### bucket

    my $bucket = $s3->bucket($bucket_name);

    my $bucket = $s3->bucket($bucket_name, $region);

    my $bucket = $s3->bucket(
      { bucket        => $bucket_name,
        region        => $region,
        verify_region => $boolean,
      }
    );

Constructs and returns an [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object.

This method does not create an S3 bucket and does not otherwise verify
that the bucket exists.

The hash-reference form accepts:

- bucket

    Bucket name.

- region

    Region containing the bucket.

    When no region is supplied and `verify_region` is false, the client
    region is used.

- verify\_region

    When true, allow the [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) constructor to determine
    the bucket region using the bucket location API.

    This incurs an additional service request.

The returned bucket object is associated with this `Amazon::S3`
client.

See [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket).

### buckets

    my $response = $s3->buckets;

    my $response = $s3->buckets($verify_region);

Lists the general-purpose buckets owned by the account.

`verify_region` is an optional boolean. When true, each returned
[Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object is constructed with region verification
enabled.

Region verification can require an additional service request for
each bucket and can therefore significantly increase the cost and
latency of `buckets()`.

The default is false.

On success, returns a hash reference containing:

- owner\_id

    Owner ID returned by S3.

- owner\_displayname

    Owner display name returned by S3.

- buckets

    Array reference of [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) objects.

    When the account has no returned buckets, this is an empty array
    reference.

On failure, returns `undef` and records error information on the
client.

### bucketv2

    my $bucket = $s3->bucketv2(
      { bucket        => $bucket_name,
        region        => $region,
        verify_region => $boolean,
      }
    );

Constructs and returns an [Amazon::S3::BucketV2](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucketV2) object.

The accepted parameters are:

- bucket

    Bucket name.

- region

    Region containing the bucket.

    When no region is supplied and `verify_region` is false, the client
    region is used.

- verify\_region

    When true, allow the bucket object to determine its region.

Like `bucket()`, this method constructs a client-side object. It does
not create the S3 bucket.

### delete\_bucket

    my $ok = $s3->delete_bucket($bucket);

    my $ok = $s3->delete_bucket(
      { bucket  => $bucket_name,
        region  => $region,
        headers => $headers,
      }
    );

Deletes an S3 bucket.

The first form accepts an [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object and uses its
bucket name and region.

The hash-reference form accepts:

- bucket

    Required. Bucket name.

- region

    Region containing the bucket.

    If omitted, `get_bucket_location()` is called to determine the
    region.

- headers

    Optional hash reference containing additional request headers.

The bucket must be empty before Amazon S3 will delete it.

Returns a true value on success.

On failure, returns `undef` and records error information on the
client.

### delete\_public\_access\_block

    my $response = $s3->delete_public_access_block($bucket);

Removes the public access block configuration from a bucket.

The argument is expected to be an [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object.

The method performs the `DeletePublicAccessBlock` operation through
the [Amazon::S3::BucketV2](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucketV2) interface and returns that operation's
result.

This operation may be required before applying public ACLs or public
bucket policies to buckets whose public access block settings prohibit
them.

### get\_bucket\_location

    my $region = $s3->get_bucket_location($bucket_name);

    my $region = $s3->get_bucket_location($bucket);

Returns the region containing a bucket.

The argument may be a bucket name or an [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object.

For a bucket name, a temporary [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object is
constructed and its `get_location_constraint()` method is called.

Amazon S3 represents `us-east-1` with a null location constraint.
When the bucket location call returns no region,
`get_bucket_location()` returns `us-east-1`.

### list\_directory\_buckets

    my $response = $s3->list_directory_buckets;

    my $response = $s3->list_directory_buckets(
      { uri_params => \%params,
      }
    );

Lists directory buckets owned by the account.

The optional `uri_params` hash reference is passed as URI parameters
to the S3 Express control endpoint.

The method temporarily switches the client to the S3 Express control
endpoint for the request and restores the previous express-mode state
afterward.

On success, returns the parsed S3 response.

On failure, returns `undef` and records error information on the
client.

See ["DIRECTORY BUCKETS"](#directory-buckets).

## OBJECT LISTING AND VERSIONING

### list\_bucket

    my $response = $s3->list_bucket(\%parameters);

Lists objects using the original S3 ListObjects API.

The argument is a hash reference. `bucket` is required. Other defined
entries are sent as ListObjects query parameters.

Common parameters are:

- bucket

    Required. Bucket name.

- delimiter

    Optional delimiter used to group matching keys into common prefixes.

- headers

    Optional hash reference containing additional request headers.

- marker

    Optional key after which listing should resume.

- max-keys

    Optional maximum number of results returned by S3.

- prefix

    Optional prefix used to restrict returned keys.

On success, returns the normalized listing structure described in
["LISTING OBJECTS"](#listing-objects).

On failure, returns `undef` and records error information on the
client.

See ["LISTING OBJECTS"](#listing-objects).
&#x3d;head3 list\_bucket\_all

    my $response = $s3->list_bucket_all(\%parameters);

Lists all matching objects using the original ListObjects API.

The accepted parameters are the same as for `list_bucket()`.

The method follows pagination automatically and can therefore make
multiple S3 requests.

On success, returns the combined normalized listing result.

On a pagination failure, the method throws an exception.

See ["LISTING OBJECTS"](#listing-objects).
&#x3d;head3 list\_bucket\_all\_v2

    my $response = $s3->list_bucket_all_v2(\%parameters);

Lists all matching objects using ListObjectsV2.

The accepted parameters are the same as for `list_bucket_v2()`.

The method follows pagination automatically and can therefore make
multiple S3 requests.

On success, returns the combined normalized listing result.

On a pagination failure, the method throws an exception.

See ["LISTING OBJECTS"](#listing-objects).
&#x3d;head3 list\_bucket\_v2

    my $response = $s3->list_bucket_v2(\%parameters);

Lists objects using the S3 ListObjectsV2 API.

The argument is a hash reference. `bucket` is required. Other defined
entries are sent as ListObjectsV2 query parameters.

Common parameters are:

- bucket

    Required. Bucket name.

- continuation-token

    Optional continuation token returned by a previous ListObjectsV2
    request.

- delimiter

    Optional delimiter used to group matching keys into common prefixes.

- encoding-type

    Optional S3 response encoding type.

- fetch-owner

    Optional boolean controlling whether owner information is returned.

- headers

    Optional hash reference containing additional request headers.

- marker

    Compatibility alias for `continuation-token`.

- max-keys

    Optional maximum number of results returned by S3.

- prefix

    Optional prefix used to restrict returned keys.

- start-after

    Optional key after which S3 should begin the listing.

On success, returns the normalized listing structure described in
["LISTING OBJECTS"](#listing-objects).

On failure, returns `undef` and records error information on the
client.

See ["LISTING OBJECTS"](#listing-objects).
&#x3d;head3 list\_object\_versions

    my $response = $s3->list_object_versions(\%parameters);

Lists object versions in a bucket.

The argument is a hash reference.

- bucket

    Required. Bucket name.

    This operation is not available for directory buckets.

- delimiter

    Optional delimiter used to group matching keys.

- encoding-type

    Optional S3 response encoding type.

- headers

    Optional hash reference containing additional request headers.

- key-marker

    Optional key marker used when continuing a paginated listing.

- max-keys

    Optional maximum number of results returned by S3.

    The S3 default is 1000.

- prefix

    Optional prefix used to restrict returned keys.

- version-id-marker

    Optional version ID marker used with `key-marker` when continuing a
    paginated listing.

On success, returns the parsed ListObjectVersions service response.
This method does not automatically follow pagination.

On failure, returns `undef` and records error information on the
client.

See ["LISTING OBJECTS"](#listing-objects) and
[https://docs.aws.amazon.com/AmazonS3/latest/API/API\_ListObjectVersions.html](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectVersions.html).
&#x3d;head2 ADVANCED AND COMPATIBILITY METHODS

### turn\_off\_special\_retry

    $s3->turn_off_special_retry;

Removes the additional HTTP 400 retry condition installed by
`turn_on_special_retry()`.

When retry handling is disabled, this method has no effect.

This method exists primarily for internal and compatibility use.

### turn\_on\_special\_retry

    $s3->turn_on_special_retry;

When retry handling is enabled, adds HTTP 400 to the conditions
handled by the retry-aware user agent.

This behavior exists because some S3 request timeouts have historically
been returned as HTTP 400 responses.

The constructor calls this method automatically.

When retry handling is disabled, this method has no effect.

This method exists primarily for internal and compatibility use.

# LOGGING AND DEBUGGING

Logging is controlled by the configured logger and logging level.

When no logger is supplied, `Amazon::S3::Logger` is used.

Valid levels include:

    fatal
    error
    warn
    info
    debug
    trace

The default level is `error`.

At `debug` level, `Amazon::S3` records higher-level request and
configuration information.

At `trace` level, HTTP request and response information may also be
logged.

Applications should review trace output before retaining or sharing
it. Request and response data may contain sensitive application
information even when authentication values are sanitized.

# S3-COMPATIBLE SERVICES

`Amazon::S3` can be used with S3-compatible services and local S3
implementations by configuring the service endpoint and related
connection options.

The `host`, `secure`, and `dns_bucket_names` settings are commonly
relevant when using a non-AWS endpoint.

S3-compatible implementations may differ from AWS in supported APIs,
request validation, checksum behavior, or edge cases.

The integration tests used during development include LocalStack, but
applications targeting another S3-compatible implementation should
test against that implementation directly.

# COMPARISON TO OTHER PERL S3 MODULES

Perl applications have several choices for accessing Amazon S3,
including [Net::Amazon::S3](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3), [Paws::S3](https://metacpan.org/pod/Paws%3A%3AS3), [Amazon::S3::Lite](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ALite), and
[Amazon::API::S3](https://metacpan.org/pod/Amazon%3A%3AAPI%3A%3AS3). Each takes a different approach.

`Amazon::S3` provides a dedicated S3 interface with a long-established
API. The distribution combines the account-level `Amazon::S3`
interface with [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) for common object workflows and
[Amazon::S3::BucketV2](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucketV2) for broader low-level API access.

`Net::Amazon::S3` is the project from which `Amazon::S3` originally
forked. The distributions have since diverged and should not be
considered drop-in replacements for one another.

`Paws::S3` is part of the larger [Paws](https://metacpan.org/pod/Paws) AWS SDK for Perl and follows
AWS service APIs through its generated service model.

[Amazon::S3::Lite](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ALite) is a smaller client intended for applications
where dependency size and startup cost are important.

[Amazon::API::S3](https://metacpan.org/pod/Amazon%3A%3AAPI%3A%3AS3) is generated from the AWS Botocore service model
and is intended to closely reflect the current low-level S3 API.

The appropriate client depends primarily on the interface and level of
abstraction required by the application.

# COMPATIBILITY AND LIMITATIONS

## Minimum Perl Version

`Amazon::S3` declares Perl 5.10 as its minimum supported Perl
version.

Dependencies may impose additional constraints on older Perl
installations.

Applications using an older Perl should run the complete distribution
test suite after installation.

## Signature Version 4

AWS API requests are signed using Signature Version 4.

Signature Version 2 is not supported.

Because Signature Version 4 includes the AWS region in the signature,
bucket operations must use the region containing the bucket.

A bucket region can be supplied explicitly or determined using bucket
region verification.

## Directory Buckets

Directory bucket support is currently limited to account-level create
and list operations.

See ["DIRECTORY BUCKETS"](#directory-buckets).

# TESTING

The distribution includes unit tests and integration tests that
exercise behavior requiring an S3 endpoint.

Run the normal distribution test suite with:

    make test

Integration testing during development includes LocalStack.

See `README-TESTING.md` in the distribution root for test
environment setup, integration-test requirements, and additional
testing instructions.

# SUPPORT

Bug reports and feature requests should be submitted through the
project issue tracker.

When reporting a problem, include the `Amazon::S3` version, Perl
version, operating system, and enough information to reproduce the
behavior.

For request or protocol problems, debug or trace logging may also be
useful. Review logs before sharing them to ensure that they do not
contain credentials, authorization information, or sensitive object
data.

# REPOSITORY

The source repository, issue tracker, and development history are
available at:

[https://github.com/rlauer6/Amazon-S3](https://github.com/rlauer6/Amazon-S3)

# AUTHOR

Original author: Timothy Appnel <tima@cpan.org>

Current maintainer: Rob Lauer <bigfoot@cpan.org>

# SEE ALSO

[Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket)

[Amazon::S3::BucketV2](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucketV2)

[Amazon::S3::Constants](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3AConstants)

[Amazon::S3::Logger](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ALogger)

[Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials)

[Net::Amazon::S3](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3)

[Amazon S3 API Reference](https://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html)

[Amazon S3 bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)

[Amazon S3 bucket restrictions and limitations](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html)

[AWS Signature Version 4](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html)

[Amazon S3 directory buckets](https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-overview.html)

[LocalStack](https://localstack.io)

# LICENCE

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

Portions of this distribution contain code modified from Amazon. That
code is made available under the following notice:

    #  This software code is made available "AS IS" without warranties of any
    #  kind.  You may copy, display, modify and redistribute the software
    #  code either by itself or as incorporated into your code; provided that
    #  you do not remove any proprietary notices.  Your use of this software
    #  code is at your own risk and you waive any claim against Amazon
    #  Digital Services, Inc. or its affiliates with respect to your use of
    #  this software code. (c) 2006 Amazon Digital Services, Inc. or its
    #  affiliates.
