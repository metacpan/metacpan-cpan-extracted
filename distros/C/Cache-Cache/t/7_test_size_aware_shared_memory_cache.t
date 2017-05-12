#!/usr/bin/perl -w


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..48\n"; }
END {print "not ok 1\n" unless $loaded;}

use Cache::Cache qw( $EXPIRES_NOW
                     $EXPIRES_NEVER );

use Cache::CacheTester;
use Cache::SizeAwareCacheTester;
use Cache::SizeAwareSharedMemoryCache;


$loaded = 1;
print "ok 1\n";


######################### End of black magic.

use vars qw( $TEST_COUNT );

$TEST_COUNT = 2;

my $cache = new Cache::SizeAwareSharedMemoryCache( ) or
  not_ok( "Couldn't create new SizeAwareSharedMemoryCache" );

ok( );

my $cache_tester = new Cache::CacheTester( $TEST_COUNT ) or
  not_ok( "Couldn't create new CacheTester" );

$cache_tester->test( $cache );

$TEST_COUNT = $cache_tester->_get_test_count( );

my $size_aware_cache_tester = new Cache::SizeAwareCacheTester( $TEST_COUNT ) or
  not_ok( "Couldn't create new CacheTester" );

$size_aware_cache_tester->test( $cache );

sub ok
{
  print "ok $TEST_COUNT\n";

  $TEST_COUNT++;
}


sub not_ok
{
  my ( $message ) = @_;

  print "not ok $TEST_COUNT #  $message\n";

  $TEST_COUNT++;
}


sub skip
{
  my ( $message ) = @_;

  print "ok $TEST_COUNT # skipped: $message\n";

  $TEST_COUNT++;
}

