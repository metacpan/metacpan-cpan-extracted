# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [CONSTRUCTOR](#constructor)
  * [new](#new)
  * [Credential resolution order](#credential-resolution-order)
* [METHODS](#methods)
  * [list\_objects\_v2](#list\objects\v2)
  * [list\_all\_objects\_v2](#list\all\objects\v2)
  * [get\_object](#get\object)
  * [head\_object](#head\object)
  * [put\_object](#put\object)
  * [copy\_object](#copy\object)
  * [delete\_object](#delete\object)
  * [list\_buckets](#list\buckets)
  * [create\_bucket](#create\bucket)
  * [put\_bucket\_notification\_configuration](#put\bucket\notification\configuration)
  * [get\_bucket\_notification\_configuration](#get\bucket\notification\configuration)
  * [remove\_bucket\_notification\_configuration](#remove\bucket\notification\configuration)
* [ERROR HANDLING](#error-handling)
* [DEPENDENCIES](#dependencies)
* [LAMBDA USAGE NOTES](#lambda-usage-notes)
* [TESTING](#testing)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

Amazon::S3::Lite - A lightweight Amazon S3 client for common
operations

# SYNOPSIS

    use Amazon::S3::Lite;

    # Credentials from environment or IAM role automatically
    my $s3 = Amazon::S3::Lite->new({ region => 'us-east-1' });

    # Explicit credentials
    my $s3 = Amazon::S3::Lite->new({
      region                => 'us-east-1',
      aws_access_key_id     => $key,
      aws_secret_access_key => $secret,
      token                 => $session_token,  # optional, for STS/Lambda roles
    });

    # Pass any credentials object with standard getters
    my $s3 = Amazon::S3::Lite->new({
      region      => 'us-east-1',
      credentials => $creds_obj,
    });

    # List objects in a bucket
    my $result = $s3->list_objects_v2('my-bucket', prefix => 'logs/');

    foreach my $obj ( @{ $result->{objects} } ) {
      printf "%s  %d bytes\n", $obj->{key}, $obj->{size};
    }

    # Paginate
    while ( $result->{is_truncated} ) {
      $result = $s3->list_objects_v2('my-bucket',
        prefix             => 'logs/',
        continuation_token => $result->{next_continuation_token},
      );
      # ... process $result->{objects}
    }

    # Get an object
    my $obj = $s3->get_object('my-bucket', 'path/to/key.json');
    print $obj->{content};

    # Head an object (existence check / metadata only)
    my $meta = $s3->head_object('my-bucket', 'path/to/key.json');
    if ($meta) {
      print $meta->{content_length};
    }

    # Put an object
    $s3->put_object('my-bucket', 'path/to/key.json', $json_string,
      content_type => 'application/json',
      metadata     => { source => 'lambda' },
    );

    # Copy an object
    $s3->copy_object(
      src_bucket => 'my-bucket', src_key => 'orig/file.json',
      dst_bucket => 'my-bucket', dst_key => 'archive/file.json',
    );

    # Delete an object
    $s3->delete_object('my-bucket', 'path/to/key.json');

    # List all buckets
    my $result = $s3->list_buckets;
    for my $bucket ( @{ $result->{buckets} } ) {
      print $bucket->{name}, "\n";
    }

    # Create a bucket
    $s3->create_bucket('my-bucket');
    $s3->create_bucket('my-bucket', region => 'eu-west-1');

    # Configure a Lambda notification trigger
    $s3->put_bucket_notification_configuration('my-bucket',
      type       => 'lambda',
      lambda_arn => $function_arn,
      events     => 's3:ObjectCreated:*',
      filters    => { prefix => 'uploads/' },
    );

    # Configure an SQS notification trigger
    $s3->put_bucket_notification_configuration('my-bucket',
      type      => 'sqs',
      queue_arn => $queue_arn,
      events    => 's3:ObjectCreated:*',
    );

    # Retrieve notification configuration
    my $configs = $s3->get_bucket_notification_configuration('my-bucket');
    for my $cfg ( @{$configs} ) {
      printf "id=%s lambda=%s queue=%s\n",
        $cfg->{id}, $cfg->{lambda_arn} // '', $cfg->{queue_arn} // '';
    }

# DESCRIPTION

`Amazon::S3::Lite` is a minimal Amazon S3 client covering the
operations most commonly needed in AWS Lambda functions and
lightweight scripts: listing buckets, listing objects, reading,
writing, copying, and deleting.

It is built on [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) (core since Perl 5.14) and
[Amazon::Signature4::Lite](https://metacpan.org/pod/Amazon%3A%3ASignature4%3A%3ALite), with no dependency on LWP or any part of
the libwww-perl ecosystem. The dependency list is intentionally small,
making it well-suited for Lambda container images where minimizing
cold-start time and image size matters.

It is not a replacement for [Amazon::S3](https://metacpan.org/pod/Amazon%3A%3AS3) or [Net::Amazon::S3](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3), which
support the full S3 API surface including multipart upload, bucket
management, ACLs, versioning, and presigned URLs. If you need those
features, use one of those distributions instead.

[Amazon::S3::Thin](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3AThin) is another excellent lightweight S3 client with a
similar philosophy and a longer track record. It is more complete than
this module - supporting presigned URLs, bulk delete, and
virtual-hosted-style requests - and returns raw [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse)
objects so callers handle status codes and errors
themselves. `Amazon::S3::Lite` differs in three ways: it has no
dependency on LWP (`Amazon::S3::Thin` defaults to [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent)),
it returns parsed hashrefs rather than raw response objects, and it
has first-class support for Lambda IAM role credential rotation. If
you need the broader feature set or prefer direct HTTP access,
`Amazon::S3::Thin` is a fine choice.

# CONSTRUCTOR

## new

    my $s3 = Amazon::S3::Lite->new(\%options);

Returns a new `Amazon::S3::Lite` object. Options:

- region (required)

    The AWS region for your bucket, e.g. `us-east-1`.

- aws\_access\_key\_id / aws\_secret\_access\_key

    Static credentials. `token` may also be supplied for STS temporary
    credentials (as used by Lambda execution roles).

    These are only consulted if no `credentials` object is provided.

- token

    Optional STS session token, used alongside static credentials for
    temporary credential sets.

- credentials

    An object providing credential getters. The object must respond to:

        $creds->aws_access_key_id
        $creds->aws_secret_access_key
        $creds->token            # may return undef

    Any object that satisfies this interface is accepted -
    [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials), [Paws::Credential::\*](https://metacpan.org/pod/Paws%3A%3ACredential%3A%3A%2A), or your own. The
    getters are called at request time, so objects that refresh expiring
    credentials transparently are supported.

- logger

    An object providing the standard log methods:

        $logger->trace(...)
        $logger->debug(...)
        $logger->info(...)
        $logger->warn(...)
        $logger->error(...)

    If not supplied, the module looks for [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl). If available,
    it calls `Log::Log4perl::easy_init` with level WARN and logs to
    STDERR.  If Log::Log4perl is not installed, a minimal internal logger
    is used that prints WARN and above to STDERR.

- host

    Override the S3 endpoint host. Defaults to `s3.amazonaws.com`.
    Useful for S3-compatible services (MinIO, Ceph, LocalStack).

- secure

    Use HTTPS. Default is 1 (true). Set to 0 only for testing against
    local S3-compatible endpoints.

- timeout

    HTTP request timeout in seconds. Default is 30.

## Credential resolution order

When no `credentials` object is passed, credentials are resolved in
this order:

1. Constructor arguments `aws_access_key_id` and `aws_secret_access_key`.
2. Environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
and optionally `AWS_SESSION_TOKEN`.
3. [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials), if installed. This covers IAM instance roles,
Lambda execution roles, ECS task roles, and `~/.aws/credentials`
profiles.
4. If none of the above yield credentials, the constructor croaks.

# METHODS

All methods croak on unrecoverable errors (network failure, HTTP 5xx).
HTTP 404 is not an exception - methods that can meaningfully return
`undef` for a missing resource do so.

## list\_objects\_v2

    my $result = $s3->list_objects_v2($bucket, %options);

Lists objects in `$bucket` using the S3 ListObjectsV2 API.

Options:

- prefix

    Limit results to keys beginning with this string.

- delimiter

    Group keys sharing a common prefix up to this delimiter. Grouped
    prefixes are returned in `common_prefixes`.

- max\_keys

    Maximum number of objects to return per call (1-1000, default 1000).

- continuation\_token

    Resume a truncated listing from a prior call's
    `next_continuation_token`.

- start\_after

    Return only keys lexicographically after this value.

Returns a hashref:

    {
      bucket                 => 'my-bucket',
      prefix                 => 'logs/',
      is_truncated           => 0,
      next_continuation_token => undef,        # set when is_truncated is true
      key_count              => 42,
      objects                => [
        {
          key           => 'logs/2024-01-01.gz',
          size          => 102400,
          last_modified => '2024-01-01T00:00:00.000Z',
          etag          => 'abc123',
          storage_class => 'STANDARD',
        },
        ...
      ],
      common_prefixes        => [],            # populated when delimiter is set
    }

## list\_all\_objects\_v2

    my @objects = $s3->list_all_objects_v2($bucket, %options);

Convenience wrapper around ["list\_objects\_v2"](#list_objects_v2) that automatically
follows continuation tokens and returns a flat list of all matching
object hashrefs in a single call.

Accepts the same options as `list_objects_v2` except
`continuation_token` (which is managed internally) and `delimiter`
(which is silently ignored - see below).

    my @logs = $s3->list_all_objects_v2('my-bucket', prefix => 'logs/');

    foreach my $obj (@logs) {
      printf "%s  %d bytes\n", $obj->{key}, $obj->{size};
    }

Be mindful of memory when listing buckets with large numbers of
objects.  For very large listings, use ["list\_objects\_v2"](#list_objects_v2) directly
and process each page as it arrives.

`delimiter` and `common_prefixes` are not supported by this method.
The purpose of `list_all_objects_v2` is a complete flat listing of
all matching keys. Hierarchical directory-style traversal using
`delimiter` is inherently page-by-page and should use
["list\_objects\_v2"](#list_objects_v2) directly.

Returns a (possibly empty) list of object hashrefs, each with the same
fields as the elements of `objects` in the `list_objects_v2`
response.

## get\_object

    my $obj = $s3->get_object($bucket, $key);
    my $obj = $s3->get_object($bucket, $key, %options);

Fetches the object at `$key` in `$bucket`.

Returns `undef` if the key does not exist (HTTP 404).

Returns a hashref on success:

    {
      content        => '...',          # raw bytes; absent when filename is used
      content_type   => 'application/json',
      content_length => 1024,
      etag           => 'abc123',
      last_modified  => 'Tue, 01 Jan 2024 00:00:00 GMT',
      metadata       => {               # x-amz-meta-* headers, lowercased
        source => 'lambda',
      },
    }

Options:

- range

    An HTTP Range header value, e.g. `bytes=0-1023`, for partial fetches.

- filename

    Path to a local file where the object body should be written. When
    supplied, the response body is streamed directly to disk via
    HTTP::Tiny's `:content_file` mechanism and `content` is omitted from
    the returned hashref. The file is created or overwritten.

        my $meta = $s3->get_object('my-bucket', 'data/dump.csv',
          filename => '/tmp/dump.csv',
        );
        # $meta->{content} is absent; file is on disk

    This is the recommended approach for large objects in Lambda where
    holding the full body in memory is undesirable.

## head\_object

    my $meta = $s3->head_object($bucket, $key);

Fetches metadata for `$key` without retrieving the object body.
Useful for existence checks and reading `x-amz-meta-*` headers
cheaply.

Returns `undef` if the key does not exist (HTTP 404).

Returns a hashref on success with the same fields as `get_object`
except `content`, which is always absent.

## put\_object

    $s3->put_object($bucket, $key, $data, %options);

Stores `$data` at `$key` in `$bucket`. `$data` may be:

- A scalar string (the object body verbatim)
- A reference to a scalar (avoids copying large strings)
- An open filehandle or [IO::File](https://metacpan.org/pod/IO%3A%3AFile) object (body is read to EOF)

When passing a filehandle, `content_length` becomes required unless
HTTP::Tiny can determine the size from the handle (i.e. the handle is
backed by a real file). For in-memory handles (`IO::Scalar`, etc.)
you must supply `content_length` explicitly, or the method will
croak.

    # Scalar
    $s3->put_object('my-bucket', 'hello.txt', 'Hello, world!',
      content_type => 'text/plain',
    );

    # Filehandle
    open my $fh, '<', '/tmp/data.csv' or die $!;
    $s3->put_object('my-bucket', 'data.csv', $fh,
      content_type => 'text/csv',
    );

Options:

- content\_type

    MIME type for the object. Defaults to `application/octet-stream`.

- content\_length

    Required when `$data` is an in-memory filehandle. Optional (and
    ignored) for scalar data, where length is computed automatically.

- metadata

    Hashref of user-defined metadata. Keys should be bare names - the
    `x-amz-meta-` prefix is added automatically.

        metadata => { source => 'lambda', job_id => '42' }

- acl

    Canned ACL string, e.g. `private` (default), `public-read`.

Returns the ETag of the stored object on success. Croaks on failure.

## copy\_object

    $s3->copy_object(
      src_bucket => 'src-bucket',
      src_key    => 'original/key.json',
      dst_bucket => 'dst-bucket',
      dst_key    => 'copy/key.json',
    );

Copies an object within or between buckets without transferring data
through the client. The copy is performed entirely server-side by S3.

Returns a hashref on success:

    {
      etag          => 'abc123',
      last_modified => '2024-01-01T00:00:00.000Z',
    }

Croaks on failure.

## delete\_object

    $s3->delete_object($bucket, $key);
    $s3->delete_object($bucket, $key, version_id => $vid);

Deletes the object at `$key` in `$bucket`.

If `version_id` is provided, that specific version is deleted.

Returns true on success. Note that S3 returns HTTP 204 for both
successful deletes _and_ deletes of non-existent keys, so this method
does not distinguish between the two - it succeeds silently in either
case.

## list\_buckets

    my $result = $s3->list_buckets;

Lists all S3 buckets owned by the authenticated account.

Returns a hashref:

    {
      owner_id   => 'abc123...',
      owner_name => 'myaccount',
      buckets    => [
        { name => 'my-bucket',    creation_date => '2024-01-01T00:00:00.000Z' },
        { name => 'other-bucket', creation_date => '2024-06-01T00:00:00.000Z' },
        ...
      ],
    }

Note that this operation is always signed against `us-east-1`
regardless of the region the object was constructed with. See
["LAMBDA USAGE NOTES"](#lambda-usage-notes).

## create\_bucket

    $s3->create_bucket($bucket);
    $s3->create_bucket($bucket, region => 'eu-west-1', acl => 'private');

Creates a new S3 bucket. Options:

- region

    The region in which to create the bucket. Defaults to the region the
    object was constructed with. **Note:** `us-east-1` is S3's implicit
    default - the `CreateBucketConfiguration` body is intentionally
    omitted for that region as including it causes a `InvalidLocationConstraint`
    error. For all other regions the `LocationConstraint` element is
    sent automatically.

- acl

    Canned ACL string, e.g. `private` (the S3 default), `public-read`.

Returns true on success. Croaks on failure.

## put\_bucket\_notification\_configuration

    # Lambda trigger
    $s3->put_bucket_notification_configuration($bucket,
      type       => 'lambda',
      lambda_arn => $function_arn,
      events     => 's3:ObjectCreated:*',
    );

    # SQS trigger
    $s3->put_bucket_notification_configuration($bucket,
      type      => 'sqs',
      queue_arn => $queue_arn,
      events    => [qw(s3:ObjectCreated:* s3:ObjectRemoved:*)],
      filters   => { prefix => 'uploads/', suffix => '.csv' },
    );

Sets the bucket notification configuration for `$bucket`, routing
S3 events to a Lambda function or SQS queue.

Options:

- type (required)

    The notification target type. Must be `lambda` or `sqs`.

- lambda\_arn (required when type is `lambda`)

    The ARN of the Lambda function to invoke.

- queue\_arn (required when type is `sqs`)

    The ARN of the SQS queue to deliver messages to.

- events (required)

    A scalar event name or an arrayref of event names.
    Common values: `s3:ObjectCreated:*`, `s3:ObjectRemoved:*`.

- filters

    A hashref of S3 key filter rules. Supported keys are `prefix`
    and `suffix`.

- id

    An identifier for the configuration entry. Defaults to `notification-1`.

Returns true on success. Croaks on failure.

## get\_bucket\_notification\_configuration

    my $configs = $s3->get_bucket_notification_configuration($bucket);

    for my $cfg ( @{$configs} ) {
      if ( $cfg->{lambda_arn} ) {
        printf "Lambda: id=%s arn=%s\n", $cfg->{id}, $cfg->{lambda_arn};
      }
      elsif ( $cfg->{queue_arn} ) {
        printf "SQS:    id=%s arn=%s\n", $cfg->{id}, $cfg->{queue_arn};
      }
      print "  events: ", join(', ', @{ $cfg->{events} }), "\n";
    }

Retrieves the current notification configuration for `$bucket`.
Handles both Lambda (`CloudFunctionConfiguration`) and SQS
(`QueueConfiguration`) entries, which are the XML element names
the S3 API returns regardless of how the configuration was created.

Returns an arrayref of configuration hashrefs, each containing:

- id

    The configuration entry identifier.

- lambda\_arn

    The Lambda function ARN. Present for Lambda notification entries;
    `undef` for SQS entries.

- queue\_arn

    The SQS queue ARN. Present for SQS notification entries;
    `undef` for Lambda entries.

- events

    Arrayref of event type strings.

- filters

    Arrayref of hashrefs, each with `name` (`prefix` or `suffix`)
    and `value`.

Returns an empty arrayref if no notification configuration is set.
Croaks on failure.

## remove\_bucket\_notification\_configuration

    $s3->remove_bucket_notification_configuration($bucket);

Removes all notification configurations from `$bucket` by sending an
empty `NotificationConfiguration` document to S3. After this call S3
will no longer deliver any events for the bucket.

Returns true on success. Croaks on failure.

# ERROR HANDLING

Methods croak on:

- Network-level failures (connection refused, timeout, DNS failure)
- HTTP 5xx responses from S3
- Unexpected HTTP 3xx responses that could not be resolved

Methods return `undef` on:

- HTTP 404 (key or bucket not found), where the return type allows it

All other HTTP error codes (400, 403, 409, etc.) cause a croak with a
message containing the HTTP status line and the S3 error body where
available.

# DEPENDENCIES

- [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) (core since Perl 5.14)
- [Amazon::Signature4::Lite](https://metacpan.org/pod/Amazon%3A%3ASignature4%3A%3ALite)
- [XML::Twig](https://metacpan.org/pod/XML%3A%3ATwig) (for parsing list and copy responses)
- [Digest::MD5](https://metacpan.org/pod/Digest%3A%3AMD5) (core, for Content-MD5 headers)
- [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64) (core)
- [URI::Escape](https://metacpan.org/pod/URI%3A%3AEscape)
- [Carp](https://metacpan.org/pod/Carp) (core)

Optional:

- [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) - automatic credential discovery from IAM
roles, ECS task roles, ~/.aws/credentials, and environment.
- [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) - structured logging; if present, used in
preference to the built-in minimal logger.

# LAMBDA USAGE NOTES

In a Lambda container, credentials come from the execution role via
the ECS credential provider endpoint (indicated by
`AWS_CONTAINER_CREDENTIALS_RELATIVE_URI` in the environment).
[Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) handles this automatically when installed and
is the recommended approach. If you prefer not to take that
dependency, the Lambda runtime also populates `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` directly, which
this module picks up automatically from the environment.

**Region note:** The `list_buckets` method is a global S3 operation
and is always signed against `us-east-1`, regardless of the region
supplied to the constructor. This is an S3 requirement, not a
limitation of this module, and is handled transparently - your
object's region is not changed.

**Cold start:** Because this module depends only on [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) (Perl
core), [XML::Twig](https://metacpan.org/pod/XML%3A%3ATwig), [AWS::Signature4](https://metacpan.org/pod/AWS%3A%3ASignature4), and [URI::Escape](https://metacpan.org/pod/URI%3A%3AEscape), it adds
minimal overhead to Lambda container image builds compared to
LWP-based S3 clients.

# TESTING

When testing against LocalStack, be aware that LocalStack is more
lenient than real S3 regarding SigV4 requirements. In particular,
LocalStack may accept requests where the `x-amz-content-sha256`
header is missing or where session token handling is incorrect. Tests
that pass against LocalStack should always be verified against real S3
before release.

# SEE ALSO

[Amazon::S3](https://metacpan.org/pod/Amazon%3A%3AS3) - the full-featured S3 client this module draws from

[Amazon::S3::Thin](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3AThin) - another excellent lightweight S3 client with a
similar philosophy, broader feature coverage, and a longer track
record. Uses LWP by default and returns raw [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse)
objects. See ["DESCRIPTION"](#description) for a detailed comparison.

[Net::Amazon::S3](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3) - a Moose-based full-featured alternative

[Amazon::Signature4::Lite](https://metacpan.org/pod/Amazon%3A%3ASignature4%3A%3ALite) - the signing module used internally

[Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) - credential provider with IAM role and profile
support

# AUTHOR

Rob Lauer <rlauer@treasurersbriefcase.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
