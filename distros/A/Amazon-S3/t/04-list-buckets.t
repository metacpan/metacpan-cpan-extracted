#!/usr/bin/perl -w

## no critic

use warnings;
use strict;

use lib qw(. lib);

use English qw{-no_match_vars};

use S3TestUtils qw(:constants :subs);

use Test::More;
use Data::Dumper;

my $host = set_s3_host();

if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'} ) {
  plan skip_all => 'Testing this module for real costs money.';
}
else {
  plan tests => 11;
}

########################################################################
# BEGIN TESTS
########################################################################

use_ok('Amazon::S3');
use_ok('Amazon::S3::Bucket');

my $s3 = get_s3_service($host);

my $bucket_name = make_bucket_name();

my $bucket_obj = create_bucket( $s3, $bucket_name );

ok( ref $bucket_obj, 'created bucket - ' . $bucket_name );

if ( $EVAL_ERROR || !$bucket_obj ) {
  BAIL_OUT( $s3->err . ": " . $s3->errstr );
}

my $bad_bucket = $s3->bucket( { bucket => 'does-not-exists' } );

my $response = $bad_bucket->list( { bucket => $bad_bucket } );

ok( !defined $response, 'undef returned on non-existent bucket' );

like( $bad_bucket->errstr, qr/does\snot\sexist/xsm, 'errstr populated' )
  or diag(
  Dumper(
    [ response => $response,
      errstr   => $bad_bucket->errstr,
      err      => $bad_bucket->err,
    ]
  )
  );

my $max_keys = 25;

########################################################################
subtest 'list (check response elements)' => sub {
########################################################################
  my $response = $bucket_obj->list
    or BAIL_OUT( $s3->err . ": " . $s3->errstr );

  is( $response->{bucket}, $bucket_name, 'no bucket name in list response' )
    or do {
    diag( Dumper( [$response] ) );
    BAIL_OUT( Dumper [$response] );
    };

  ok( !$response->{prefix}, 'no prefix in list response' );
  ok( !$response->{marker}, 'no marker in list response' );

  is( $response->{max_keys}, 1_000, 'max keys default = 1000' )
    or BAIL_OUT( Dumper [$response] );

  is( $response->{is_truncated}, 0, 'is_truncated 0' );

  is_deeply( $response->{keys}, [], 'no keys in bucket yet' )
    or BAIL_OUT( Dumper( [$response] ) );
};

########################################################################
subtest 'list_all' => sub {
########################################################################

  add_keys( $bucket_obj, $max_keys );

  my $response = $bucket_obj->list_all;

  is( ref $response, 'HASH', 'response isa HASH' )
    or diag( Dumper( [$response] ) );

  is( ref $response->{keys}, 'ARRAY', 'keys element is an ARRAY' )
    or diag( Dumper( [$response] ) );

  is( @{ $response->{keys} }, $max_keys, $max_keys . ' keys returned' )
    or diag( Dumper( [$response] ) );

  foreach my $key ( @{ $response->{keys} } ) {
    is( ref $key, 'HASH', 'array element isa HASH' )
      or diag( Dumper( [$key] ) );

    like( $key->{key}, qr/testing-\d{2}[.]txt/xsm, 'keyname' )
      or diag( Dumper( [$key] ) );

  }
};

########################################################################
subtest 'list' => sub {
########################################################################

  my $marker = '';
  my $iter   = 0; # so we don't loop forever if this is busted

  my @key_list;
  my $page_size = int $max_keys / 2;

  while ( $marker || !$iter ) {
    last if $iter++ > $max_keys;

    my $response = $bucket_obj->list(
      { 'max-keys' => $page_size,
        marker     => $marker,
        delimiter  => '/',
      }
    );

    if ( !$response ) {
      BAIL_OUT( $s3->err . ": " . $s3->errstr );
    }

    is( $response->{bucket}, $bucket_name, 'no bucket name' );

    ok( !$response->{prefix}, 'no prefix' )
      or diag( Dumper [$response] );

    is( $response->{max_keys}, $page_size, 'max-keys ' . $page_size );

    is( ref $response->{keys}, 'ARRAY' )
      or BAIL_OUT( Dumper( [$response] ) );

    push @key_list, @{ $response->{keys} };

    $marker = $response->{next_marker};

    last if !$marker;
  }

  is( @key_list, $max_keys, $max_keys . ' returned' )
    or diag( Dumper( [ key_list => \@key_list ] ) );
};

########################################################################
subtest 'list_v2' => sub {
########################################################################

  my $marker = '';
  my $iter   = 0; # so we don't loop forever if this is busted

  my @key_list;
  my $page_size = int $max_keys / 2;

  while ( $marker || !$iter ) {
    last if $iter++ > $max_keys;

    my $response = $bucket_obj->list_v2(
      { 'max-keys' => $page_size,
        $marker ? ( 'marker' => $marker ) : (),
        delimiter => '/',
      }
    );

    if ( !$response ) {
      BAIL_OUT( $s3->err . ": " . $s3->errstr );
    }

    is( $response->{bucket}, $bucket_name, 'no bucket name' );

    ok( !$response->{prefix}, 'no prefix' )
      or diag( Dumper [$response] );

    is( $response->{max_keys}, $page_size, 'max-keys ' . $page_size );

    is( ref $response->{keys}, 'ARRAY' )
      or BAIL_OUT( Dumper( [$response] ) );

    push @key_list, @{ $response->{keys} };

    $marker = $response->{next_marker};

    last if !$marker;
  }

  is( @key_list, $max_keys, $max_keys . ' returned' )
    or diag( Dumper( \@key_list ) );
};

########################################################################
subtest 'list_bucket_all' => sub {
########################################################################

  $max_keys += add_keys( $bucket_obj, $max_keys, 'foo/' );

  my $response = $s3->list_bucket_all( { bucket => $bucket_name } );

  is( ref $response, 'HASH', 'list_bucket_all response is a HASH' );

  is( @{ $response->{keys} }, $max_keys, $max_keys . ' returned' );
};

########################################################################
subtest 'list_bucket_all_v2' => sub {
########################################################################

  my $response = $s3->list_bucket_all_v2( { bucket => $bucket_name } );

  is( ref $response, 'HASH', 'list_bucket_all_v2 response is a HASH' );

  is( @{ $response->{keys} }, $max_keys, $max_keys . ' returned' );

  foreach ( @{ $response->{keys} } ) {
    $bucket_obj->delete_key( $_->{key} );
  }
};

$bucket_obj->delete_bucket;

1;
