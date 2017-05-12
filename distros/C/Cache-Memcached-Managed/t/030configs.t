
# Setup test and strictness
use Test::More tests => 1 + ( 4 * 5 ) + 1 + 5;
use strict;
use warnings;

# initializations
my $class= 'Cache::Memcached::Managed';
my $memcached_class= $ENV{CACHE_MEMCACHED} || 'Cache::Memcached';
my $base_config= "127.0.0.1";

# Make sure we have all the support routines
require 'testlib';

# Make sure class is loaded
use_ok($class);

# simple string config
my $port= anyport();
check_config( $port, "$base_config:$port",
  'simple string config' );

# simple listref config
$port= anyport();
check_config( $port, [ "$base_config:$port" ],
  'simple listref config' );

# hashref/string config
$port= anyport();
check_config( $port, { servers => "$base_config:$port" },
  'hashref/string config' );

# hashref/listref config
$port= anyport();
check_config( $port, { servers => [ "$base_config:$port" ] },
  'hashref/listref config' );

# object config
$port= anyport();
my $memcached= $memcached_class->new(
  servers => [ "$base_config:$port" ],
);
isa_ok( $memcached, $memcached_class, "Check whether memcached object ok" );
check_config( $port, $memcached,
  'object config' );

#-------------------------------------------------------------------------------
# check_config
#
# Check given port / config.  Good for 5 tests.
#
#  IN: 1 port
#      2 config
#      3 test message

sub check_config {
    my ( $port, $config, $message )= @_;

    ok( $port, "Check whether we have a port to work on for $message" );

    # Create a cache object
    my $cache= $class->new(
      data            => $config,
      memcached_class => $memcached_class,
    );
    isa_ok( $cache, $class, "Check whether object ok for $message" );

    # Start the server, skip further tests if failed
    SKIP: {
        skip( "Memcached server not started", 3 ) if !$cache->start;
        sleep 2; # let the server warm up
        diag("\nStarted memcached server for $message");

        # Set/Get simple value here
        my $value= 'value';
        ok( $cache->set($value), "Check if simple set is ok for $message" );
        is( $cache->get,$value,  "Check if simple get is ok for $message" );

        # Stop the server
        ok( $cache->stop, "Check if all servers have stopped for $message" );
        diag("\nStopped memcached server for $message");
    } #SKIP
} #check_config
#-------------------------------------------------------------------------------
