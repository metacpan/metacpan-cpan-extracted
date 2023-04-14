#!/usr/bin/env perl -w

use warnings;
use strict;

use lib qw( . lib);

use Data::Dumper;
use Digest::MD5::File qw(file_md5_hex);
use English           qw{-no_match_vars};
use File::Temp        qw{ tempfile };
use List::Util        qw(any);
use Test::More;

use S3TestUtils qw(:constants :subs);

our @REGIONS = (undef);

if ( $ENV{AMAZON_S3_REGIONS} ) {
  push @REGIONS, split /\s*,\s*/xsm, $ENV{AMAZON_S3_REGIONS};
}

my $host = set_s3_host();

my $bucket_name = make_bucket_name();

if ( !$ENV{AMAZON_S3_EXPENSIVE_TESTS} ) {
  plan skip_all => 'Testing this module for real costs money.';
}
else {
  plan tests => 85 * scalar(@REGIONS) + 2;
}

########################################################################
# BEGIN TESTS
########################################################################

use_ok('Amazon::S3');
use_ok('Amazon::S3::Bucket');

my $s3 = get_s3_service($host);

if ( !$s3 || $EVAL_ERROR ) {
  BAIL_OUT( 'could not initialize s3 object: ' . $EVAL_ERROR );
}

# bail if test bucket already exists
our ( $OWNER_ID, $OWNER_DISPLAYNAME ) = check_test_bucket($s3);

for my $location (@REGIONS) {
  # this test formerly used the same bucket name for both regions,
  # however when you delete a bucket it may take up to an hour for
  # that bucket name to be available again when using AWS as the host.
  # To test the bucket constraint policy below then we need to use a
  # different bucket name. The old comment here was...
  #
  #   > create a bucket
  #   > make sure it's a valid hostname for EU testing
  #   > we use the same bucket name for both in order to force one or the
  #   > other to have stale DNS

  $s3->region($location);
  $host = $s3->host;

  my $bucket_name_raw;
  my $bucket_name;
  my $bucket_obj;
  my $bucket_suffix;

  while ($TRUE) {

    $bucket_name_raw = make_bucket_name();
    $bucket_name     = $SLASH . $bucket_name_raw;

    $bucket_obj = eval {
      $s3->add_bucket(
        { bucket              => $bucket_name,
          acl_short           => 'public-read',
          location_constraint => $location
        }
      );
    };

    if ( $EVAL_ERROR || !$bucket_obj ) {
      diag( Dumper( [ $EVAL_ERROR, $s3->err, $s3->errstr, $s3->error ] ) );
    }

    last if $bucket_obj;

    # 409 indicates bucket name not yet available...
    if ( $s3->last_response->code ne $HTTP_CONFLICT ) {
      BAIL_OUT("could not create $bucket_name");
    }

    $bucket_suffix = '-2';
  }

  is(
    ref $bucket_obj,
    'Amazon::S3::Bucket', sprintf 'create bucket (%s) in %s ',
    $bucket_name,         $location // 'DEFAULT_REGION'
  ) or BAIL_OUT("could not create bucket $bucket_name");

  SKIP: {
    if ( $ENV{AMAZON_S3_SKIP_REGION_CONSTRAINT_TEST} ) {
      skip 'No region constraints', 1;
    }

    is( $bucket_obj->get_location_constraint, $location );
  }

  SKIP: {

    if ( $ENV{AMAZON_S3_SKIP_ACLS} || !$bucket_obj ) {
      skip 'ACLs only for Amazon S3', 3;
    }

    like_acl_allusers_read($bucket_obj);

    my $rsp = $bucket_obj->set_acl( { acl_short => 'private' } );

    ok( $rsp, 'set_acl - private' )
      or diag(
      Dumper( [ response => $rsp, $s3->err, $s3->errstr, $s3->error ] ) );

    unlike_acl_allusers_read($bucket_obj);
  }

  # another way to get a bucket object (does no network I/O,
  # assumes it already exists).  Read Amazon::S3::Bucket.
  $bucket_obj = $s3->bucket($bucket_name);
  is( ref $bucket_obj, 'Amazon::S3::Bucket' );

  # fetch contents of the bucket
  # note prefix, marker, max_keys options can be passed in

  my $response = $bucket_obj->list();

  if ( !$response ) {
    BAIL_OUT( sprintf 'could not list bucket: %s', $bucket_name );
  }

  SKIP: {
    if ( !$response ) {
      skip 'invalid response to "list"';
    }

    is( $response->{bucket}, $bucket_name_raw )
      or BAIL_OUT( Dumper [$response] );

    ok( !$response->{prefix} );
    ok( !$response->{marker}, );

    is( $response->{max_keys}, 1_000 )
      or BAIL_OUT( Dumper [$response] );

    is( $response->{is_truncated}, 0 );

    is_deeply( $response->{keys}, [] )
      or diag( Dumper( [$response] ) );

    is( undef, $bucket_obj->get_key('non-existing-key') );
  }

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
      ? "http://$bucket_name_raw.$host/$keyname"
      : "http://$host/$bucket_name/$keyname";

    SKIP: {
      if ( $ENV{AMAZON_S3_SKIP_ACLS} ) {
        skip 'ACLs only for Amazon S3', 3;
      }

      is_request_response_code( $url, $HTTP_OK,
        'can access the publicly readable key' );

      like_acl_allusers_read( $bucket_obj, $keyname );

      ok(
        $bucket_obj->set_acl(
          { key       => $keyname,
            acl_short => 'private'
          }
        )
      );
    }

    SKIP: {
      if ( $ENV{AMAZON_S3_SKIP_PERMISSIONS} ) {
        skip 'Mocking service does not enforce ACLs', 1;
      }

      is_request_response_code( $url, $HTTP_FORBIDDEN,
        'cannot access the private key' );
    }

    SKIP: {
      if ( $ENV{AMAZON_S3_SKIP_ACLS} ) {
        skip 'ACLs only for Amazon S3', 5;
      }

      unlike_acl_allusers_read( $bucket_obj, $keyname );

      ok(
        $bucket_obj->set_acl(
          { key     => $keyname,
            acl_xml => acl_xml_from_acl_short('public-read')
          }
        )
      );

      is_request_response_code( $url,
        $HTTP_OK, 'can access the publicly readable key after acl_xml set' );

      like_acl_allusers_read( $bucket_obj, $keyname );

      ok(
        $bucket_obj->set_acl(
          { key     => $keyname,
            acl_xml => acl_xml_from_acl_short('private')
          }
        )
      );
    }

    SKIP: {
      if ( $ENV{AMAZON_S3_SKIP_PERMISSIONS} ) {
        skip 'Mocking service does not enforce ACLs', 2;
      }

      is_request_response_code( $url,
        $HTTP_FORBIDDEN, 'cannot access the private key after acl_xml set' );

      unlike_acl_allusers_read( $bucket_obj, $keyname );
    }
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
      ? "http://$bucket_name_raw.$host/$keyname2"
      : "http://$host/$bucket_name/$keyname2";

    SKIP: {
      if ( $ENV{AMAZON_S3_SKIP_PERMISSIONS} ) {
        skip 'Mocking service does not enforce ACLs', 1;
      }

      is_request_response_code( $url, $HTTP_FORBIDDEN,
        'cannot access the private key' );
    }

    SKIP: {
      if ( $ENV{AMAZON_S3_SKIP_ACLS} ) {
        skip 'ACLs only for Amazon S3', 4;
      }

      unlike_acl_allusers_read( $bucket_obj, $keyname2 );

      ok(
        $bucket_obj->set_acl(
          { key       => $keyname2,
            acl_short => 'public-read'
          }
        )
      );

      is_request_response_code( $url,
        $HTTP_OK, 'can access the publicly readable key' );

      like_acl_allusers_read( $bucket_obj, $keyname2 );

    }

    $bucket_obj->delete_key($keyname2);
  }

  # list keys in the bucket
  foreach my $v ( 1 .. 2 ) {

    if ( $v eq '2' ) {
      $response = $bucket_obj->list_v2( { 'fetch-owner' => 'true' } );
    }
    else {
      $response = $bucket_obj->list;
    }

    if ( !$response ) {
      BAIL_OUT( $s3->err . ': ' . $s3->errstr );
    }

    is( $response->{bucket}, $bucket_name_raw, sprintf 'list(%s) - %s',
      $v, $bucket_name );

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
      if ( $ENV{AMAZON_S3_SKIP_OWNER_ID_TEST} ) {
        skip 'mocking service has different owner for bucket', 1;
      }

      is( $key->{owner_id}, $OWNER_ID, "list($v) - owner id " )
        or diag( Dumper [$key] );
    }

    is( $key->{owner_displayname},
      $OWNER_DISPLAYNAME, "list($v) - owner display name" );
  }

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

  $keyname .= '2';

  $bucket_obj->add_key_filename(
    $keyname,
    $lorem_ipsum,
    { content_type        => 'text/plain',
      'x-amz-meta-colour' => 'orangy',
    }
  );

  $response = $bucket_obj->get_key($keyname);

  is( $response->{content_type}, 'text/plain', 'get_key - content_type' );
  like( $response->{value}, qr/Lorem\sipsum/xsm, 'get_key - Lorem ipsum' );

  is( $response->{etag}, $lorem_ipsum_md5, 'get_key - etag' )
    or diag( Dumper [$response] );

  is( $response->{'x-amz-meta-colour'}, 'orangy', 'get_key - metadata' );
  is( $response->{content_length},
    $lorem_ipsum_size, 'get_key - content_type' );

  eval { unlink $lorem_ipsum };

  $response = $bucket_obj->get_key_filename( $keyname, undef, $lorem_ipsum );

  is( $response->{content_type},
    'text/plain', 'get_key_filename - content_type' );

  is( $response->{value}, $EMPTY, 'get_key_filename - value empty' );

  is( $response->{etag}, $lorem_ipsum_md5, 'get_key_filename - etag == md5' );

  is( file_md5_hex($lorem_ipsum),
    $lorem_ipsum_md5, 'get_key_filename - file md5' );

  is( $response->{'x-amz-meta-colour'},
    'orangy', 'get_key_filename - metadata' );

  is( $response->{content_length},
    $lorem_ipsum_size, 'get_key_filename - content_length' );

  # before we delete this key...

  my $copy_result = $bucket_obj->copy_object(
    key    => "$keyname.bak",
    source => "$keyname",
  );

  isa_ok( $copy_result, 'HASH', 'copy_object returns a hash reference' );

  $response = $bucket_obj->list;

  ok( ( grep {"$keyname.bak"} @{ $response->{keys} } ), 'found the copy' );

  if ( !$ENV{AMAZON_S3_KEEP_BUCKET} ) {
    $bucket_obj->delete_key($keyname);
    $bucket_obj->delete_key("$keyname.bak");
  }

  # try empty files
  $keyname .= '3';
  $bucket_obj->add_key( $keyname, $EMPTY );
  $response = $bucket_obj->get_key($keyname);

  is( $response->{value}, $EMPTY, 'empty object - value empty' );

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
    or die $s3->err . ': ' . $s3->errstr;

  $bucket_name =~ s/^\///xsm;

  is( $response->{bucket}, $bucket_name,
    'delete key from bucket - ' . $bucket_name );

  ok( !$response->{prefix}, 'delete key from bucket - prefix empty' );

  ok( !$response->{marker}, 'delete key from bucket - marker empty' );

  is( $response->{max_keys}, 1_000,
    'delete key from bucket - max keys 1000' );

  is( $response->{is_truncated},
    0, 'delete key from bucket - is_truncated 0' );

  is_deeply( $response->{keys}, [],
    'delete key from bucket - empty list of keys' );

  ######################################################################
  # delete multiple keys from bucket
  # TODO: test deleting specific versions
  #

  SKIP: {
    if ( $ENV{AMAZON_S3_KEEP_BUCKET} ) {
      skip 'keeping bucket', 9;
    }

    $keyname = 'foo-';

    for ( 1 .. 8 ) {
      $bucket_obj->add_key( "$keyname$_", $EMPTY );
    }

    $response = $bucket_obj->list
      or die $s3->err . ': ' . $s3->errstr;

    my @key_list = @{ $response->{keys} };

    is( 8, scalar @key_list, 'wrote 8 keys for delete_keys() test' );

    ######################################################################
    # quietly delete version keys - first two
    ######################################################################
    my $delete_rsp = $bucket_obj->delete_keys(
      { quiet => 1,
        keys  => [ map { $_->{key} } @key_list[ ( 0, 1 ) ] ]
      }
    );

    ok( !$delete_rsp, 'delete_keys() quiet response - empty' )
      or BAIL_OUT(
      'could not delete quietly '
        . Dumper(
        [ response      => $delete_rsp,
          last_request  => $s3->get_last_request,
          last_response => $s3->get_last_response,
        ]
        )
      );

    $response = $bucket_obj->list
      or die $s3->err . ': ' . $s3->errstr;

    is(
      scalar @{ $response->{keys} },
      -2 + scalar(@key_list),
      'delete versioned keys'
    );

    shift @key_list;
    shift @key_list;

    ######################################################################
    # delete list of keys - next two keys
    ######################################################################
    $delete_rsp
      = $bucket_obj->delete_keys( map { $_->{key} } @key_list[ ( 0, 1 ) ] );

    ok( $delete_rsp, 'delete_keys() response' );

    $response = $bucket_obj->list
      or die $s3->err . ': ' . $s3->errstr;

    is(
      scalar @{ $response->{keys} },
      -2 + scalar(@key_list),
      'delete list of keys'
    );

    shift @key_list;
    shift @key_list;

    ######################################################################
    # delete array of keys - next two keys
    #####################################################################
    $delete_rsp
      = $bucket_obj->delete_keys( map { $_->{key} } @key_list[ ( 0, 1 ) ] );

    ok( $delete_rsp, 'delete_keys() response' );

    $response = $bucket_obj->list
      or die $s3->err . ': ' . $s3->errstr;

    is(
      scalar @{ $response->{keys} },
      -2 + scalar(@key_list),
      'delete array of keys'
    );

    shift @key_list;
    shift @key_list;

    ######################################################################
    # callback - last two keys
    ######################################################################
    $delete_rsp = $bucket_obj->delete_keys(
      sub {
        my $key = shift @key_list;
        return ( $key->{key} );
      }
    );

    ok( $delete_rsp, 'delete_keys() response' );

    $response = $bucket_obj->list
      or die $s3->err . ': ' . $s3->errstr;

    is( scalar @{ $response->{keys} }, 0, 'delete keys from callback' )
      or diag( Dumper( [ response => $response, key_list => \@key_list ] ) );

    #
    # delete multiple keys from bucket
    ######################################################################
  }

  SKIP: {
    if ( $ENV{AMAZON_S3_KEEP_BUCKET} ) {
      skip 'keeping bucket', 1;
    }

    ok( $bucket_obj->delete_bucket(), 'delete bucket' );
  }
}

# see more docs in Amazon::S3::Bucket

# local test methods
########################################################################
sub is_request_response_code {
########################################################################
  my ( $url, $code, $message ) = @_;

  my $request = HTTP::Request->new( 'GET', $url );

  my $response = $s3->ua->request($request);

  is( $response->code, $code, $message )
    or diag( Dumper( [ response_code => $response ] ) );

  return;
}

########################################################################
sub like_acl_allusers_read {
########################################################################
  my ( $bucket_obj, $keyname ) = @_;

  my $message = acl_allusers_read_message( 'like', $bucket_obj, $keyname );

  my $acl = $bucket_obj->get_acl($keyname);

  like( $acl, qr/AllUsers.+READ/xsm, $message )
    or diag( Dumper( [ acl => $acl ] ) );

  return;
}

########################################################################
sub unlike_acl_allusers_read {
########################################################################
  my ( $bucket_obj, $keyname ) = @_;

  my $message = acl_allusers_read_message( 'unlike', $bucket_obj, $keyname );

  my $acl = $bucket_obj->get_acl($keyname);

  unlike( $bucket_obj->get_acl($keyname), qr/AllUsers.+READ/xsm, $message )
    or diag( Dumper( [ acl => $acl ] ) );

  return;
}

########################################################################
sub acl_allusers_read_message {
########################################################################
  my ( $like_or_unlike, $bucket_obj, $keyname ) = @_;

  my $message = sprintf '%s_acl_allusers_read: %s', $like_or_unlike,
    $bucket_obj->bucket;

  if ($keyname) {
    $message .= " - $keyname";
  }

  return $message;
}

########################################################################
sub acl_xml_from_acl_short {
########################################################################
  my ($acl_short) = @_;

  $acl_short //= 'private';

  my $public_read
    = $acl_short eq 'public-read' ? $PUBLIC_READ_POLICY : $EMPTY;

  my $policy = <<"END_OF_POLICY";
<?xml version="1.0" encoding="UTF-8"?>
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
</AccessControlPolicy>
END_OF_POLICY

  return $policy;
}

1;
