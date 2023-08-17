# NAME

Amazon::S3 - A portable client library for working with and
managing Amazon S3 buckets and keys.

![Amazon::S3](https://github.com/rlauer6/perl-amazon-s3/actions/workflows/build.yml/badge.svg?event=push)

# SYNOPSIS

    use Amazon::S3;
    
    my $aws_access_key_id     = "Fill me in!";
    my $aws_secret_access_key = "Fill me in too!";
    
    my $s3 = Amazon::S3->new(
        {   aws_access_key_id     => $aws_access_key_id,
            aws_secret_access_key => $aws_secret_access_key,
            retry                 => 1
        }
    );
    
    my $response = $s3->buckets;
    
    # create a bucket
    my $bucket_name = $aws_access_key_id . '-net-amazon-s3-test';

    my $bucket = $s3->add_bucket( { bucket => $bucket_name } )
        or die $s3->err . ": " . $s3->errstr;
    
    # store a key with a content-type and some optional metadata
    my $keyname = 'testing.txt';

    my $value   = 'T';

    $bucket->add_key(
        $keyname, $value,
        {   content_type        => 'text/plain',
            'x-amz-meta-colour' => 'orange',
        }
    );

    # copy an object
    $bucket->copy_object(
      source => $source,
      key    => $new_keyname
    );

    # list keys in the bucket
    $response = $bucket->list
        or die $s3->err . ": " . $s3->errstr;

    print $response->{bucket}."\n";

    for my $key (@{ $response->{keys} }) {
          print "\t".$key->{key}."\n";  
    }

    # delete key from bucket
    $bucket->delete_key($keyname);

    # delete multiple keys from bucket
    $bucket->delete_keys([$key1, $key2, $key3]);
    
    # delete bucket
    $bucket->delete_bucket;

# DESCRIPTION

This documentation refers to version 0.64.

`Amazon::S3` provides a portable client interface to Amazon Simple
Storage System (S3).

This module is rather dated, however with some help from a few
contributors it has had some recent updates. Recent changes include
implementations of:

- ListObjectsV2
- CopyObject
- DeleteObjects

Additionally, this module now implements Signature Version 4 signing,
unit tests have been updated and more documentation has been added or
corrected. Credentials are encrypted if you have encryption modules installed.

## Comparison to Other Perl S3 Modules

Other implementations for accessing Amazon's S3 service include
`Net::Amazon::S3` and the `Paws` project. `Amazon::S3` ostensibly
was intended to be a drop-in replacement for `Net:Amazon::S3` that
"traded some performance in return for portability". That statement is
no longer accurate as `Amazon::S3` may have changed the interface in
ways that might break your applications if you are relying on
compatibility with `Net::Amazon::S3`.

However, `Net::Amazon::S3` and `Paws::S3` today, are dependent on
`Moose` which may in fact level the playing field in terms of
performance penalties that may have been introduced by recent updates
to `Amazon::S3`. Changes to `Amazon::S3` include the use of more
Perl modules in lieu of raw Perl code to increase maintainability and
stability as well as some refactoring. `Amazon::S3` also strives now
to adhere to best practices as much as possible.

`Paws::S3` may be a much more robust implementation of
a Perl S3 interface, however this module may still appeal to
those that favor simplicity of the interface and a lower number of
dependencies. Below is the original description of the module.

> Amazon S3 is storage for the Internet. It is designed to
> make web-scale computing easier for developers. Amazon S3
> provides a simple web services interface that can be used to
> store and retrieve any amount of data, at any time, from
> anywhere on the web. It gives any developer access to the
> same highly scalable, reliable, fast, inexpensive data
> storage infrastructure that Amazon uses to run its own
> global network of web sites. The service aims to maximize
> benefits of scale and to pass those benefits on to
> developers.
>
> To sign up for an Amazon Web Services account, required to
> use this library and the S3 service, please visit the Amazon
> Web Services web site at http://www.amazonaws.com/.
>
> You will be billed accordingly by Amazon when you use this
> module and must be responsible for these costs.
>
> To learn more about Amazon's S3 service, please visit:
> http://s3.amazonaws.com/.
>
> The need for this module arose from some work that needed
> to work with S3 and would be distributed, installed and used
> on many various environments where compiled dependencies may
> not be an option. [Net::Amazon::S3](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3) used [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML)
> tying it to that specific and often difficult to install
> option. In order to remove this potential barrier to entry,
> this module is forked and then modified to use [XML::SAX](https://metacpan.org/pod/XML%3A%3ASAX)
> via [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple).

# LIMITATIONS AND DIFFERENCES WITH EARLIER VERSIONS

As noted, this module is no longer a _drop-in_ replacement for
`Net::Amazon::S3` and has limitations and differences that may impact
the use of this module in your applications. Additionally, one of the
original intents of this fork of `Net::Amazon::S3` was to reduce the
number of dependencies and make it _easy to install_. Recent changes
to this module have introduced new dependencies in order to improve
the maintainability and provide additional features. Installing CPAN
modules is never easy, especially when the dependencies of the
dependencies are impossible to control and include XS modules.

- MINIMUM PERL

    Technically, this module should run on versions 5.10 and above,
    however some of the dependencies may require higher versions of
    `perl` or some lower versions of the dependencies due to conflicts
    with other versions of dependencies...it's a crapshoot when dealing
    with older `perl` versions and CPAN modules.

    You may however, be able to build this module by installing older
    versions of those dependencies and take your chances that those older
    versions provide enough working features to support `Amazon::S3`. It
    is likely they do...and this module has recently been tested on
    version 5.10.0 `perl` using some older CPAN modules to resolve
    dependency issues.

    To build this module on an earlier version of `perl` you may need to
    downgrade some modules.  In particular I have found this recipe to
    work for building and testing on 5.10.0.

    In this order install:

        HTML::HeadParser 2.14
        LWP 6.13
        Amazon::S3

    ...other versions _may_ work...YMMV.

- API Signing

    Making calls to AWS APIs requires that the calls be signed.  Amazon
    has added a new signing method (Signature Version 4) to increase
    security around their APIs. This module no longer utilizes Signature
    Version V2.

    **New regions after January 30, 2014 will only support Signature Version 4.**

    See ["Signature Version V4"](#signature-version-v4) below for important details.

    - Signature Version 4

        [https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html)

        _IMPORTANT NOTE:_

        Unlike Signature Version 2, Version 4 requires a regional
        parameter. This implies that you need to supply the bucket's region
        when signing requests for any API call that involves a specific
        bucket. Starting with version 0.55 of this module,
        `Amazon::S3::Bucket` provides a new method (`region()`) and accepts
        in the constructor a `region` parameter.  If a region is not
        supplied, the region for the bucket will be set to the region set in
        the `account` object (`Amazon::S3`) that you passed to the bucket's
        new constructor.  Alternatively, you can request that the bucket's new
        constructor determine the bucket's region for you by calling the
        `get_location_constraint()` method.

        When signing API calls, the region for the specific bucket will be
        used. For calls that are not regional (`buckets()`, e.g.) the default
        region ('us-east-1') will be used.

    - Signature Version 2

        [https://docs.aws.amazon.com/AmazonS3/latest/userguide/RESTAuthentication.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/RESTAuthentication.html)

- New APIs

    This module does not support some of the newer API method calls
    for S3 added after the initial creation of this interface.

- Multipart Upload Support

    There are some recently added unit tests for multipart uploads that
    seem to indicate this feature is working as expected.  Please report
    any deviation from expected results if you are using those methods.

    For more information regarding multipart uploads visit the link below.

    [https://docs.aws.amazon.com/AmazonS3/latest/API/API\_CreateMultipartUpload.html](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html)

# METHODS AND SUBROUTINES

## new 

Create a new S3 client object. Takes some arguments:

- credentials (optional)

    Reference to a class (like `Amazon::Credentials`) that can provide
    credentials via the methods:

        get_aws_access_key_id()
        get_aws_secret_access_key()
        get_token()

    If you do not provide a credential class you must provide the keys
    when you instantiate the object. See below.

    _You are strongly encourage to use a class that provides getters. If
    you choose to provide your credentials to this class then they will be
    stored in this object. If you dump the class you will likely expose
    those credentials._

- aws\_access\_key\_id

    Use your Access Key ID as the value of the AWSAccessKeyId parameter
    in requests you send to Amazon Web Services (when required). Your
    Access Key ID identifies you as the party responsible for the
    request.

- aws\_secret\_access\_key 

    Since your Access Key ID is not encrypted in requests to AWS, it
    could be discovered and used by anyone. Services that are not free
    require you to provide additional information, a request signature,
    to verify that a request containing your unique Access Key ID could
    only have come from you.

    **DO NOT INCLUDE THIS IN SCRIPTS OR APPLICATIONS YOU
    DISTRIBUTE. YOU'LL BE SORRY.**

    _Consider using a credential class as described above to provide
    credentials, otherwise this class will store your credentials for
    signing the requests. If you dump this object to logs your credentials
    could be discovered._

- token

    An optional temporary token that will be inserted in the request along
    with your access and secret key.  A token is used in conjunction with
    temporary credentials when your EC2 instance has
    assumed a role and you've scraped the temporary credentials from
    _http://169.254.169.254/latest/meta-data/iam/security-credentials_

- secure

    Set this to a true value if you want to use SSL-encrypted connections
    when connecting to S3. Starting in version 0.49, the default is true.

    default: true

- timeout

    Defines the time, in seconds, your script should wait or a
    response before bailing.

    default: 30s

- retry

    Enables or disables the library to retry upon errors. This
    uses exponential backoff with retries after 1, 2, 4, 8, 16,
    32 seconds, as recommended by Amazon.

    default: off

- host

    Defines the S3 host endpoint to use.

    default: s3.amazonaws.com

    Note that requests are made to domain buckets when possible.  You can
    prevent that behavior if either the bucket name does not conform to
    DNS bucket naming conventions or you preface the bucket name with '/'.

    If you set a region then the host name will be modified accordingly if
    it is an Amazon endpoint.

- region

    The AWS region you where your bucket is located.

    default: us-east-1

- buffer\_size

    The default buffer size when reading or writing files.

    default: 4096

## signer

Sets or retrieves the signer object. API calls must be signed using
your AWS credentials. By default, starting with version 0.54 the
module will use [Net::Amazon::Signature::V4](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3ASignature%3A%3AV4) as the signer and
instantiate a signer object in the constructor. Note however, that
signers need your credentials and they _will_ get stored by that
class, making them susceptible to inadvertant exfiltration. You have a
few options here:

- 1. Use your own signer.

    You may have noticed that you can also provide your own credentials
    object forcing this module to use your object for retrieving
    credentials. Likewise, you can use your own signer so that this
    module's signer never sees or stores those credentials.

- 2. Pass the credentials object and set `cache_signer` to a
false value.

    If you pass a credentials object and set `cache_signer` to a false
    value, the module will use the credentials object to retrieve
    credentials and create a new signer each time an API call is made that
    requires signing. This prevents your credentials from being stored
    inside of the signer class.

    _Note that using your own credentials object that stores your
    credentials in plaintext is also going to expose your credentials when
    someone dumps the class._

- 3. Pass credentials, set `cache_signer` to a false value.

    Unfortunately, while this will prevent [Net::Amazon::Signature::V4](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3ASignature%3A%3AV4)
    from hanging on to your credentials, you credentials will be stored in
    the `Amazon::S3` object.

    Starting with version 0.55 of this module, if you have installed
    [Crypt::CBC](https://metacpan.org/pod/Crypt%3A%3ACBC) and [Crypt::Blowfish](https://metacpan.org/pod/Crypt%3A%3ABlowfish), your credentials will be
    encrypted using a random key created when the class is
    instantiated. While this is more secure than leaving them in
    plaintext, if the key is discovered (the key however is not stored in
    the object's hash) and the object is dumped, your _encrypted_
    credentials can be exposed.

- 4. Use very granular credentials for bucket access only.

    Use credentials that only allow access to a bucket or portions of a
    bucket required for your application. This will at least limit the
    _blast radius_ of any potential security breach.

- 5. Do nothing...send the credentials, use the default signer.

    In this case, both the `Amazon::S3` class and the
    [Net::Amazon::Signature::V4](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3ASignature%3A%3AV4) have your credentials. Caveat Emptor.

    See also [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) for more information about safely
    storing your credentials and preventing exfiltration.

## region

Sets the region for the  API calls. This will also be the
default when instantiating the bucket object unless you pass the
region parameter in the `bucket` method or use the `verify_region`
flag that will _always_ verify the region of the bucket using the
`get_location_constraint` method.

default: us-east-1

## buckets

    buckets([verify-region])

- verify-region (optional)

    `verify-region` is a boolean value that indicates if the
    bucket's region should be verified when the bucket object is
    instantiated.

    If set to true, this method will call the `bucket` method with
    `verify_region` set to true causing the constructor to call the
    `get_location_constraint` for each bucket to set the bucket's
    region. This will cause a significant decrease in the peformance of
    the `buckets()` method. Setting the region for each bucket is
    necessary since API operations on buckets require the region of the
    bucket when signing API requests. If all of your buckets are in the
    same region and you have passed a region parameter to your S3 object,
    then that region will be used when calling the constructor of your
    bucket objects.

    default: false

Returns a reference to a hash containing the metadata for all of the
buckets owned by the accout or (see below) or `undef` on error.

- owner\_id

    The owner ID of the bucket's owner.

- owner\_display\_name

    The name of the owner account. 

- buckets

    An array of [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) objects for the account. Returns
    `undef` if there are not buckets or an error occurs.

## add\_bucket

    add_bucket(bucket-configuration)

`bucket-configuration` is a reference to a hash with bucket configuration
parameters.

- bucket

    The name of the bucket. See [Bucket name
    rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
    for more details on bucket naming rules.

- acl\_short (optional)

    See the set\_acl subroutine for documenation on the acl\_short options

- location\_constraint
- region

    The region the bucket is to be created in.

Returns a [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object on success or `undef` on failure.

## bucket

    bucket(bucket, [region])

    bucket({ bucket => bucket-name, verify_region => boolean, region => region });

Takes a scalar argument or refernce to a hash of arguments.

You can pass the region or set `verify_region` indicating that
you want the bucket constructor to detemine the bucket region.

If you do not pass the region or set the `verify_region` value, the
region will be set to the default region set in your `Amazon::S3`
object.

See [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) for a complete description of the `bucket`
method.

## delete\_bucket

Takes either a [Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket) object or a reference to a hash
containing:

- bucket

    The name of the bucket to remove

- region

    Region the bucket is located in. If not provided, the method will
    determine the bucket's region by calling `get_bucket_location`.

Returns a boolean indicating the success or failure of the API
call. Check `err` or `errstr` for error messages.

Note from the [Amazon's documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html)

> If a bucket is empty, you can delete it. After a bucket is deleted,
> the name becomes available for reuse. However, after you delete the
> bucket, you might not be able to reuse the name for various reasons.
>
> For example, when you delete the bucket and the name becomes available
> for reuse, another AWS account might create a bucket with that
> name. In addition, **some time might pass before you can reuse the name
> of a deleted bucket**. If you want to use the same bucket name, we
> recommend that you don't delete the bucket.

## dns\_bucket\_names

Set or get a boolean that indicates whether to use DNS bucket
names.

default: true

## list\_bucket, list\_bucket\_v2

List all keys in this bucket.

Takes a reference to a hash of arguments:

- bucket (required)

    The name of the bucket you want to list keys on.

- prefix

    Restricts the response to only contain results that begin with the
    specified prefix. If you omit this optional argument, the value of
    prefix for your query will be the empty string. In other words, the
    results will be not be restricted by prefix.

- delimiter

    If this optional, Unicode string parameter is included with your
    request, then keys that contain the same string between the prefix
    and the first occurrence of the delimiter will be rolled up into a
    single result element in the CommonPrefixes collection. These
    rolled-up keys are not returned elsewhere in the response.  For
    example, with prefix="USA/" and delimiter="/", the matching keys
    "USA/Oregon/Salem" and "USA/Oregon/Portland" would be summarized
    in the response as a single "USA/Oregon" element in the CommonPrefixes
    collection. If an otherwise matching key does not contain the
    delimiter after the prefix, it appears in the Contents collection.

    Each element in the CommonPrefixes collection counts as one against
    the MaxKeys limit. The rolled-up keys represented by each CommonPrefixes
    element do not.  If the Delimiter parameter is not present in your
    request, keys in the result set will not be rolled-up and neither
    the CommonPrefixes collection nor the NextMarker element will be
    present in the response.

    NOTE: CommonPrefixes isn't currently supported by Amazon::S3. 

- max-keys 

    This optional argument limits the number of results returned in
    response to your query. Amazon S3 will return no more than this
    number of results, but possibly less. Even if max-keys is not
    specified, Amazon S3 will limit the number of results in the response.
    Check the IsTruncated flag to see if your results are incomplete.
    If so, use the Marker parameter to request the next page of results.
    For the purpose of counting max-keys, a 'result' is either a key
    in the 'Contents' collection, or a delimited prefix in the
    'CommonPrefixes' collection. So for delimiter requests, max-keys
    limits the total number of list results, not just the number of
    keys.

- marker

    This optional parameter enables pagination of large result sets.
    `marker` specifies where in the result set to resume listing. It
    restricts the response to only contain results that occur alphabetically
    after the value of marker. To retrieve the next page of results,
    use the last key from the current page of results as the marker in
    your next request.

    See also `next_marker`, below. 

    If `marker` is omitted,the first page of results is returned. 

Returns `undef` on error and a reference to a hash of data on success:

The return value looks like this:

    {
     bucket       => $bucket_name,
     prefix       => $bucket_prefix, 
     marker       => $bucket_marker, 
     next_marker  => $bucket_next_available_marker,
     max_keys     => $bucket_max_keys,
     is_truncated => $bucket_is_truncated_boolean
     keys          => [$key1,$key2,...]
    }

- is\_truncated

    Boolean flag that indicates whether or not all results of your query were
    returned in this response. If your results were truncated, you can
    make a follow-up paginated request using the Marker parameter to
    retrieve the rest of the results.

- next\_marker 

    A convenience element, useful when paginating with delimiters. The
    value of `next_marker`, if present, is the largest (alphabetically)
    of all key names and all CommonPrefixes prefixes in the response.
    If the `is_truncated` flag is set, request the next page of results
    by setting `marker` to the value of `next_marker`. This element
    is only present in the response if the `delimiter` parameter was
    sent with the request.

Each key is a reference to a hash that looks like this:

    {
      key           => $key,
      last_modified => $last_mod_date,
      etag          => $etag, # An MD5 sum of the stored content.
      size          => $size, # Bytes
      storage_class => $storage_class # Doc?
      owner_id      => $owner_id,
      owner_displayname => $owner_name
    }

## get\_bucket\_location

    get_bucket_location(bucket-name)
    get_bucket_locaiton(bucket-obj)

This is a convenience routines for the `get_location_constraint()` of
the bucket object.  This method will return the default
region of 'us-east-1' when `get_location_constraint()` returns a null
value.

    my $region = $s3->get_bucket_location('my-bucket');

Starting with version 0.55, `Amazon::S3::Bucket` will call this
`get_location_constraint()` to determine the region for the
bucket. You can get the region for the bucket by using the `region()`
method of the bucket object.

    my $bucket = $s3->bucket('my-bucket');
    my $bucket_region = $bucket->region;

## get\_logger

Returns the logger object. If you did not set a logger when you
created the object then an instance of `Amazon::S3::Logger` is
returned. You can log to STDERR using this logger. For example:

    $s3->get_logger->debug('this is a debug message');

    $s3->get_logger->trace(sub { return Dumper([$response]) });

## list\_bucket\_all, list\_bucket\_all\_v2

List all keys in this bucket without having to worry about
'marker'. This is a convenience method, but may make multiple requests
to S3 under the hood.

Takes the same arguments as `list_bucket`.

_You are encouraged to use the newer `list_bucket_all_v2` method._

## err

The S3 error code for the last error encountered.

## errstr

A human readable error string for the last error encountered.

## error

The decoded XML string as a hash object of the last error.

## last\_response

Returns the last [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object.

## last\_request

Returns the last [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) object.

## level

Set the logging level.

default: error

## turn\_on\_special\_retry

Called to add extra retry codes if retry has been set

## turn\_off\_special\_retry

Called to turn off special retry codes when we are deliberately triggering them

# ABOUT

This module contains code modified from Amazon that contains the
following notice:

    #  This software code is made available "AS IS" without warranties of any
    #  kind.  You may copy, display, modify and redistribute the software
    #  code either by itself or as incorporated into your code; provided that
    #  you do not remove any proprietary notices.  Your use of this software
    #  code is at your own risk and you waive any claim against Amazon
    #  Digital Services, Inc. or its affiliates with respect to your use of
    #  this software code. (c) 2006 Amazon Digital Services, Inc. or its
    #  affiliates.

# TESTING

Testing S3 is a tricky thing. Amazon wants to charge you a bit of 
money each time you use their service. And yes, testing counts as using.
Because of this, the application's test suite skips anything approaching 
a real test unless you set these environment variables:

For more on testing this module see [README-TESTING.md](https://github.com/rlauer6/perl-amazon-s3/blob/master/README-TESTING.md)

- AMAZON\_S3\_EXPENSIVE\_TESTS

    Doesn't matter what you set it to. Just has to be set

- AMAZON\_S3\_HOST

    Sets the host to use for the API service.

    default: s3.amazonaws.com

    Note that if this value is set, DNS bucket name usage will be disabled
    for testing. Most likely, if you set this variable, you are using a
    mocking service and your bucket names are probably not resolvable. You
    can override this behavior by setting `AWS_S3_DNS_BUCKET_NAMES` to any
    value.

- AWS\_S3\_DSN\_BUCKET\_NAMES

    Set this to any value to override the default behavior of disabling
    DNS bucket names during testing.

- AWS\_ACCESS\_KEY\_ID 

    Your AWS access key

- AWS\_SECRET\_ACCESS\_KEY

    Your AWS sekkr1t passkey. Be forewarned that setting this environment variable
    on a shared system might leak that information to another user. Be careful.

- AMAZON\_S3\_SKIP\_ACL\_TESTS

    Doesn't matter what you set it to. Just has to be set if you want
    to skip ACLs tests.

- AMAZON\_S3\_SKIP\_PERMISSIONS

    Skip tests that check for enforcement of ACLs...as of this version,
    LocalStack for example does not support enforcement of ACLs.

- AMAZON\_S3\_SKIP\_REGION\_CONSTRAINT\_TEST

    Doesn't matter what you set it to. Just has to be set if you want
    to skip region constraint test.

- AMAZON\_S3\_MINIO

    Doesn't matter what you set it to. Just has to be set if you want
    to skip tests that would fail on minio.

- AMAZON\_S3\_LOCALSTACK

    Doesn't matter what you set it to. Just has to be set if you want
    to skip tests that would fail on LocalStack.

- AMAZON\_S3\_REGIONS

    A comma delimited list of regions to use for testing. The default will
    only test creating a bucket in the local region.

_Consider using an S3 mocking service like `minio` or `LocalStack`
if you want to create real tests for your applications or this module._

Here's bash script for testing using LocalStack

    #!/bin/bash
    # -*- mode: sh; -*-
    
    BUCKET=net-amazon-s3-test-test 
    ENDPOINT_URL=s3.localhost.localstack.cloud:4566
    
    AMAZON_S3_EXPENSIVE_TESTS=1 \
    AMAZON_S3_HOST=$ENDPOINT_URL \
    AMAZON_S3_LOCALSTACK=1 \
    AWS_ACCESS_KEY_ID=test \
    AWS_ACCESS_SECRET_KEY=test  \
    AMAZON_S3_DOMAIN_BUCKET_NAMES=1 make test 2>&1 | tee test.log

To run the tests...clone the project and build the software.

    cd src/main/perl
    ./test.localstack

# ADDITIONAL INFORMATION

## LOGGING AND DEBUGGING

Additional debugging information can be output to STDERR by setting
the `level` option when you instantiate the `Amazon::S3`
object. Levels are represented as a string.  The valid levels are:

    fatal
    error
    warn
    info
    debug
    trace

You can set an optionally pass in a logger that implements a subset of
the `Log::Log4perl` interface.  Your logger should support at least
these method calls. If you do not supply a logger the default logger
(`Amazon::S3::Logger`) will be used.

    get_logger()
    fatal()
    error()
    warn()
    info()
    debug()
    trace()
    level()

At the `trace` level, every HTTP request and response will be output
to STDERR.  At the `debug` level information regarding the higher
level methods will be output to STDERR.  There currently is no
additional information logged at lower levels.

## S3 LINKS OF INTEREST

- [Bucket restrictions and limitations](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html)
- [Bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
- [Amazon S3 REST API](https://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html)
- [Authenticating Requests (AWS Signature Version 4)](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html)
- [Authenticating Requests (AWS Signature Version 2)](https://docs.aws.amazon.com/AmazonS3/latest/userguide/RESTAuthentication.html)
- [LocalStack](https://localstack.io)

# SUPPORT

Bugs should be reported via the CPAN bug tracker at

[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amazon-S3](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amazon-S3)

For other issues, contact the author.

# REPOSITORY

[https://github.com/rlauer6/perl-amazon-s3](https://github.com/rlauer6/perl-amazon-s3)

# AUTHOR

Original author: Timothy Appnel <tima@cpan.org>

Current maintainer: Rob Lauer <bigfoot@cpan.org>

# SEE ALSO

[Amazon::S3::Bucket](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ABucket), [Net::Amazon::S3](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3)

# COPYRIGHT AND LICENCE

This module was initially based on [Net::Amazon::S3](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3AS3) 0.41, by
Leon Brocard. Net::Amazon::S3 was based on example code from
Amazon with this notice:

_This software code is made available "AS IS" without warranties of any
kind.  You may copy, display, modify and redistribute the software
code either by itself or as incorporated into your code; provided that
you do not remove any proprietary notices.  Your use of this software
code is at your own risk and you waive any claim against Amazon
Digital Services, Inc. or its affiliates with respect to your use of
this software code. (c) 2006 Amazon Digital Services, Inc. or its
affiliates._

The software is released under the Artistic License. The
terms of the Artistic License are described at
http://www.perl.com/language/misc/Artistic.html. Except
where otherwise noted, `Amazon::S3` is Copyright 2008, Timothy
Appnel, tima@cpan.org. All rights reserved.
