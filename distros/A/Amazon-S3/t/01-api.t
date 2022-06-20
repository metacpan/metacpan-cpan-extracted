#!/usr/bin/perl -w

## no critic

use warnings;
use strict;

use lib 'lib';

use Data::Dumper;
use Digest::MD5::File qw(file_md5_hex);
use English qw{-no_match_vars};
use File::Temp qw{ tempfile };
use Test::More;

our $OWNER_ID;
our $OWNER_DISPLAYNAME;
our @REGIONS = (undef);

if ( $ENV{AMAZON_S3_REGIONS} ) {
  push @REGIONS, split /\s*,\s*/xsm, $ENV{AMAZON_S3_REGIONS};
} ## end if ( $ENV{AMAZON_S3_REGIONS...})

my $host;

my $skip_owner_id;
my $skip_permissions;
my $skip_acls;

if ( exists $ENV{AMAZON_S3_LOCALSTACK} ) {
  $host = 'localhost:4566';

  $ENV{'AWS_ACCESS_KEY_ID'}     = 'test';
  $ENV{'AWS_ACCESS_KEY_SECRET'} = 'test';

  $ENV{'AMAZON_S3_EXPENSIVE_TESTS'} = 1;

  $skip_owner_id    = 1;
  $skip_permissions = 1;
  $skip_acls        = 1;
} ## end if ( exists $ENV{AMAZON_S3_LOCALSTACK...})
else {
  $host = $ENV{AMAZON_S3_HOST};
} ## end else [ if ( exists $ENV{AMAZON_S3_LOCALSTACK...})]

my $secure = $host ? 0 : 1;

# do not use DNS bucket names for testing if a mocking service is used
# override this by setting AMAZON_S3_DNS_BUCKET_NAMES to any value
# your tests may fail unless you have DNS entry for the bucket name
# e.g 127.0.0.1 net-amazon-s3-test-test.localhost

my $dns_bucket_names;
#  = ( $host && !exists $ENV{AMAZON_S3_DNS_BUCKET_NAMES} ) ? 0 : 1;

$skip_acls //= exists $ENV{AMAZON_S3_MINIO}
  || exists $ENV{AMAZON_S3_SKIP_ACL_TESTS};

my $no_region_constraint //= exists $ENV{AMAZON_S3_MINIO}
  || exists $ENV{AMAZON_S3_SKIP_REGION_CONSTRAINT_TEST};

my $aws_access_key_id     = $ENV{'AWS_ACCESS_KEY_ID'};
my $aws_secret_access_key = $ENV{'AWS_ACCESS_KEY_SECRET'};
my $token                 = $ENV{'AWS_SESSION_TOKEN'};

if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'} ) {
  plan skip_all => 'Testing this module for real costs money.';
} ## end if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'...})
else {
  plan tests => 74 * scalar(@REGIONS) + 2;
} ## end else [ if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'...})]

########################################################################
# BEGIN TESTS
########################################################################

use_ok('Amazon::S3');
use_ok('Amazon::S3::Bucket');

my $s3;

if ( $ENV{AMAZON_S3_CREDENTIALS} ) {
  require Amazon::Credentials;

  $s3 = Amazon::S3->new(
    { credentials      => Amazon::Credentials->new,
      host             => $host,
      secure           => $secure,
      dns_bucket_names => $dns_bucket_names,
      level            => $ENV{DEBUG} ? 'trace' : 'error',
    }
  );
  ( $aws_access_key_id, $aws_secret_access_key, $token )
    = $s3->get_credentials;
} ## end if ( $ENV{AMAZON_S3_CREDENTIALS...})
else {
  $s3 = Amazon::S3->new(
    { aws_access_key_id     => $aws_access_key_id,
      aws_secret_access_key => $aws_secret_access_key,
      token                 => $token,
      host                  => $host,
      secure                => $secure,
      dns_bucket_names      => $dns_bucket_names,
      level                 => $ENV{DEBUG} ? 'trace' : 'error',
    }
  );
} ## end else [ if ( $ENV{AMAZON_S3_CREDENTIALS...})]

# list all buckets that i own
my $response = eval { return $s3->buckets; };

if ( $EVAL_ERROR || !$response ) {
  BAIL_OUT($EVAL_ERROR);
} ## end if ( $EVAL_ERROR || !$response)

$OWNER_ID          = $response->{owner_id};
$OWNER_DISPLAYNAME = $response->{owner_displayname};

for my $location (@REGIONS) {
  # this test formerly used the same bucket name for both regions,
  # however when you delete a bucket it may take up to an hour for
  # that bucket name to be available again when using AWS as the host.
  # To test the bucket constraint policy below then we need to use a
  # different bucket name. The old comment here was...
  #
  # create a bucket
  # make sure it's a valid hostname for EU testing
  # we use the same bucket name for both in order to force one or the
  # other to have stale DNS

  $s3->region($location);
  $host = $s3->host;

  my $bucketname_raw;
  my $bucketname;
  my $bucket_obj;
  my $bucket_suffix;

  while (1) {

    $bucketname_raw = sprintf 'net-amazon-s3-test-%s%s',
      lc($aws_access_key_id), $bucket_suffix // '';

    $bucketname = '/' . $bucketname_raw;

    $bucket_obj = eval {
      $s3->add_bucket(
        { bucket              => $bucketname,
          acl_short           => 'public-read',
          location_constraint => $location
        }
      );
    };

    if ( $EVAL_ERROR || !$bucket_obj ) {
      diag( $s3->err . ": " . $s3->errstr );
    } ## end if ( $EVAL_ERROR || !$bucket_obj)

    last if $bucket_obj;

    # 409 indicates bucket name not yet available...
    if ( $s3->last_response->code ne '409' ) {
      BAIL_OUT("could not create $bucketname");
    } ## end if ( $s3->last_response...)

    $bucket_suffix = '-2';
  } ## end while (1)

  is( ref $bucket_obj,
    'Amazon::S3::Bucket',
    'create bucket in ' . ( $location // 'DEFAULT_REGION' ) )
    or BAIL_OUT("could not create bucket $bucketname");

  SKIP: {
    if ($no_region_constraint) {
      skip "No region constraints", 1;
    } ## end if ($no_region_constraint)

    is( $bucket_obj->get_location_constraint, $location );
  } ## end SKIP:

  SKIP: {

    if ( $skip_acls || !$bucket_obj ) {
      skip "ACLs only for Amazon S3", 3;
    } ## end if ( $skip_acls || !$bucket_obj)

    like_acl_allusers_read($bucket_obj);

    ok( $bucket_obj->set_acl( { acl_short => 'private' } ) );
    unlike_acl_allusers_read($bucket_obj);

  } ## end SKIP:

  # another way to get a bucket object (does no network I/O,
  # assumes it already exists).  Read Amazon::S3::Bucket.
  $bucket_obj = $s3->bucket($bucketname);
  is( ref $bucket_obj, "Amazon::S3::Bucket" );

  # fetch contents of the bucket
  # note prefix, marker, max_keys options can be passed in

  $response = $bucket_obj->list
    or BAIL_OUT( $s3->err . ": " . $s3->errstr );

  SKIP: {
    skip "invalid response to 'list'"
      if !$response;

    is( $response->{bucket}, $bucketname =~ s/^\///r )
      or BAIL_OUT( Dumper [$response] );

    ok( !$response->{prefix} );
    ok( !$response->{marker}, );

    is( $response->{max_keys}, 1_000 )
      or BAIL_OUT( Dumper [$response] );

    is( $response->{is_truncated}, 0 );

    is_deeply( $response->{keys}, [] )
      or BAIL_OUT( Dumper( [$response] ) );

    is( undef, $bucket_obj->get_key("non-existing-key") );
  } ## end SKIP:

  my $keyname = 'testing.txt';

  {

    # Create a publicly readable key, then turn it private with a short acl.
    # This key will persist past the end of the block.
    my $value = 'T';
    $bucket_obj->add_key(
      $keyname, $value,
      { content_type        => 'text/plain',
        'x-amz-meta-colour' => 'orange',
        acl_short           => 'public-read',
      }
    );

    my $url
      = $s3->dns_bucket_names
      ? "http://$bucketname_raw.$host/$keyname"
      : "http://$host/$bucketname/$keyname";

    SKIP: {
      if ($skip_acls) {
        skip "ACLs only for Amazon S3", 3;
      } ## end if ($skip_acls)

      is_request_response_code( $url, 200,
        "can access the publicly readable key" );

      like_acl_allusers_read( $bucket_obj, $keyname );

      ok(
        $bucket_obj->set_acl( { key => $keyname, acl_short => 'private' } ) );
    } ## end SKIP:

    SKIP: {
      if ($skip_acls) {
        skip 'ACLs only for Amazon S3', 1;
      } ## end if ($skip_acls)

      is_request_response_code( $url, 403, "cannot access the private key" );
    } ## end SKIP:

    SKIP: {
      if ($skip_acls) {
        skip 'ACLs only for Amazon S3', 5;
      } ## end if ($skip_acls)

      unlike_acl_allusers_read( $bucket_obj, $keyname );

      ok(
        $bucket_obj->set_acl(
          { key     => $keyname,
            acl_xml => acl_xml_from_acl_short('public-read')
          }
        )
      );

      is_request_response_code( $url,
        200, "can access the publicly readable key after acl_xml set" );

      like_acl_allusers_read( $bucket_obj, $keyname );

      ok(
        $bucket_obj->set_acl(
          { key     => $keyname,
            acl_xml => acl_xml_from_acl_short('private')
          }
        )
      );
    } ## end SKIP:

    SKIP: {
      if ( $skip_acls || $ENV{LOCALSTACK} ) {
        skip 'LocalStack does not enforce ACLs', 2;
      } ## end if ( $skip_acls || $ENV...)

      is_request_response_code( $url,
        403, 'cannot access the private key after acl_xml set' );

      unlike_acl_allusers_read( $bucket_obj, $keyname );
    } ## end SKIP:
  }

  {

    # Create a private key, then make it publicly readable with a short
    # acl.  Delete it at the end so we're back to having a single key in
    # the bucket.
    my $keyname2 = 'testing2.txt';
    my $value    = 'T2';

    $bucket_obj->add_key(
      $keyname2,
      $value,
      { content_type        => 'text/plain',
        'x-amz-meta-colour' => 'blue',
        acl_short           => 'private',
      }
    );

    my $url
      = $s3->dns_bucket_names
      ? "http://$bucketname_raw.$host/$keyname2"
      : "http://$host/$bucketname/$keyname2";

    SKIP: {
      skip 'LocalStack does not enforce ACLs', 1
        if $skip_permissions || $skip_acls;

      is_request_response_code( $url, 403, "cannot access the private key" );
    } ## end SKIP:

    SKIP: {
      skip 'ACLs only for Amazon S3', 4 if $skip_acls;

      unlike_acl_allusers_read( $bucket_obj, $keyname2 );

      ok(
        $bucket_obj->set_acl(
          { key       => $keyname2,
            acl_short => 'public-read'
          }
        )
      );

      is_request_response_code( $url,
        200, "can access the publicly readable key" );

      like_acl_allusers_read( $bucket_obj, $keyname2 );

    } ## end SKIP:

    $bucket_obj->delete_key($keyname2);
  }

  # list keys in the bucket
  foreach my $v ( 1 .. 2 ) {

    if ( $v eq '2' ) {
      $response = $bucket_obj->list_v2( { 'fetch-owner' => 'true' } );
    } ## end if ( $v eq '2' )
    else {
      $response = $bucket_obj->list;
    } ## end else [ if ( $v eq '2' ) ]

    if ( !$response ) {
      BAIL_OUT( $s3->err . ": " . $s3->errstr );
    } ## end if ( !$response )

    is(
      $response->{bucket},
      $bucketname =~ s/^\///r,
      "list($v) - bucketname "
    );

    ok( !$response->{prefix}, "list($v) - prefix empty" )
      or diag( Dumper [$response] );

    ok( !$response->{marker}, "list($v) - marker empty" );

    is( $response->{max_keys}, 1_000, "list($v) - max keys 1000 " );

    is( $response->{is_truncated}, 0, "list($v) - is_truncated 0" )
      or diag( Dumper [$response] );

    my @keys = @{ $response->{keys} };
    is( @keys, 1, "list($v) - keys == 1 " )
      or diag( Dumper \@keys );

    my $key = $keys[0];
    is( $key->{key}, $keyname, "list($v) - keyname" );

    # the etag is the MD5 of the value
    is( $key->{etag}, 'b9ece18c950afbfa6b0fdbfa4ff731d3', "list($v) - etag" );
    is( $key->{size}, 1, "list($v) - size == 1" );

    SKIP: {
      skip 'LocalStack has different owner for bucket', 1 if $skip_owner_id;
      is( $key->{owner_id}, $OWNER_ID, "list($v) - owner id " )
        or diag( Dumper [$key] );
    } ## end SKIP:

    is( $key->{owner_displayname},
      $OWNER_DISPLAYNAME, "list($v) - owner display name" );
  } ## end foreach my $v ( 1 .. 2 )

  # You can't delete a bucket with things in it
  ok( !$bucket_obj->delete_bucket(), 'delete bucket' );

  $bucket_obj->delete_key($keyname);

  # now play with the file methods
  my ( $fh, $lorem_ipsum ) = tempfile();
  print {$fh} <<'EOT';
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.
EOT

  close $fh;

  my $lorem_ipsum_md5  = file_md5_hex($lorem_ipsum);
  my $lorem_ipsum_size = -s $lorem_ipsum;

  $keyname .= "2";

  $bucket_obj->add_key_filename(
    $keyname,
    $lorem_ipsum,
    { content_type        => 'text/plain',
      'x-amz-meta-colour' => 'orangy',
    }
  );

  $response = $bucket_obj->get_key($keyname);

  is( $response->{content_type}, 'text/plain', 'get_key - content_type' );
  like( $response->{value}, qr/Lorem ipsum/, 'get_key - Lorem ipsum' );

  is( $response->{etag}, $lorem_ipsum_md5, 'get_key - etag' )
    or diag( Dumper [$response] );

  is( $response->{'x-amz-meta-colour'}, 'orangy', 'get_key - metadata' );
  is( $response->{content_length},
    $lorem_ipsum_size, 'get_key - content_type' );

  eval { unlink $lorem_ipsum };

  $response = $bucket_obj->get_key_filename( $keyname, undef, $lorem_ipsum );

  is( $response->{content_type},
    'text/plain', 'get_key_filename - content_type' );

  is( $response->{value}, '', 'get_key_filename - value empty' );

  is( $response->{etag}, $lorem_ipsum_md5, 'get_key_filename - etag == md5' );

  is( file_md5_hex($lorem_ipsum),
    $lorem_ipsum_md5, 'get_key_filename - file md5' );

  is( $response->{'x-amz-meta-colour'},
    'orangy', 'get_key_filename - metadata' );

  is( $response->{content_length},
    $lorem_ipsum_size, 'get_key_filename - content_length' );

  $bucket_obj->delete_key($keyname);

  # try empty files
  $keyname .= '3';
  $bucket_obj->add_key( $keyname, '' );
  $response = $bucket_obj->get_key($keyname);

  is( $response->{value}, '', 'empty object - value empty' );

  is(
    $response->{etag},
    'd41d8cd98f00b204e9800998ecf8427e',
    'empty object - etag'
  );

  is( $response->{content_type},
    'binary/octet-stream', 'empty object - content_type' );

  is( $response->{content_length}, 0, 'empty object - content_length == 0' );

  $bucket_obj->delete_key($keyname);

  # fetch contents of the bucket
  # note prefix, marker, max_keys options can be passed in
  $response = $bucket_obj->list
    or die $s3->err . ": " . $s3->errstr;

  $bucketname =~ s/^\///;

  is( $response->{bucket}, $bucketname,
    'delete key from bucket - bucketname' );

  ok( !$response->{prefix}, 'delete key from bucket - prefix empty' );

  ok( !$response->{marker}, 'delete key from bucket - marker empty' );

  is( $response->{max_keys}, 1_000,
    'delete key from bucket - max keys 1000' );

  is( $response->{is_truncated},
    0, 'delete key from bucket - is_truncated 0' );

  is_deeply( $response->{keys}, [],
    'delete key from bucket - empty list of keys' );

  ok( $bucket_obj->delete_bucket(), 'delete bucket' );
} ## end for my $location (@REGIONS)

# see more docs in Amazon::S3::Bucket

# local test methods
sub is_request_response_code {
  my ( $url, $code, $message ) = @_;
  my $request = HTTP::Request->new( 'GET', $url );

  #warn $request->as_string();
  my $response = $s3->ua->request($request);

  is( $response->code, $code, $message )
    or diag( Dumper($response) );
} ## end sub is_request_response_code

sub like_acl_allusers_read {
  my ( $bucketobj, $keyname ) = @_;

  my $message = acl_allusers_read_message( 'like', @_ );

  my $acl = $bucketobj->get_acl($keyname);

  like( $acl, qr(AllUsers.+READ), $message )
    or diag( Dumper [$acl] );

} ## end sub like_acl_allusers_read

sub unlike_acl_allusers_read {
  my ( $bucketobj, $keyname ) = @_;
  my $message = acl_allusers_read_message( 'unlike', @_ );
  unlike( $bucketobj->get_acl($keyname), qr(AllUsers.+READ), $message );
} ## end sub unlike_acl_allusers_read

sub acl_allusers_read_message {
  my ( $like_or_unlike, $bucketobj, $keyname ) = @_;
  my $message = $like_or_unlike . "_acl_allusers_read: " . $bucketobj->bucket;
  $message .= " - $keyname" if $keyname;
  return $message;
} ## end sub acl_allusers_read_message

sub acl_xml_from_acl_short {
  my $acl_short = shift || 'private';

  my $public_read = '';
  if ( $acl_short eq 'public-read' ) {
    $public_read = qq~
            <Grant>
                <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:type="Group">
                    <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
                </Grantee>
                <Permission>READ</Permission>
            </Grant>
        ~;
  } ## end if ( $acl_short eq 'public-read')

  return qq~<?xml version="1.0" encoding="UTF-8"?>
    <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
        <Owner>
            <ID>$OWNER_ID</ID>
            <DisplayName>$OWNER_DISPLAYNAME</DisplayName>
        </Owner>
        <AccessControlList>
            <Grant>
                <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:type="CanonicalUser">
                    <ID>$OWNER_ID</ID>
                    <DisplayName>$OWNER_DISPLAYNAME</DisplayName>
                </Grantee>
                <Permission>FULL_CONTROL</Permission>
            </Grant>
            $public_read
        </AccessControlList>
    </AccessControlPolicy>~;
} ## end sub acl_xml_from_acl_short

