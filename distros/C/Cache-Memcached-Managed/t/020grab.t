
# Warn for possible excessive timing when on OS X
diag( <<"DIAG" ) if $^O eq 'darwin';

This test may take very long on OS X (some 10 hours) if you use an older
version of libevent and/or memcached.  Please upgrade to the latest libevent
if this test is taking more than a few minutes.
DIAG

# Make sure we have a version for the subroutine based checks
$Foo::VERSION = 'Foo::VERSION';

# Set up test and strictness
use Test::More tests => 36018;
use strict;
use warnings;

# Load modules that we need
use List::Util qw(shuffle);

# Add stopping code
my $cache;
END {
    diag( "\nStopped memcached server(s)" )
      if $cache and ok( $cache->stop, "Check if all servers have stopped" );
} #END

# Make sure we have all the support routines
require 'testlib';
my $class = 'Cache::Memcached::Managed';
use_ok( $class );

# Obtain port and create config
my $port = anyport();
ok( $port,"Check whether we have a port to work on" );
my $config = "127.0.0.1:$port";

# Create a cache object
my $memcached_class = $ENV{CACHE_MEMCACHED} || 'Cache::Memcached';
$cache = $class->new(
  data            => $config,
  memcached_class => $memcached_class,
);
isa_ok( $cache,$class,"Check whether object ok" );

# Start the server, skip further tests if failed
SKIP: {
skip( "Memcached server not started",36014 ) if !$cache->start;
sleep 2; # let the server warm up
diag("\nStarted memcached server");

# Set the number of items to check
my @item = (1,2,255,256,257,511,512,513,1023,1024,1025,4095,4096,4097);

# Set them all in random order
Foo::set($_) foreach shuffle @item;

# Check them all in random order
Foo::check($_) foreach shuffle @item;

# Obtain final stats
my $got = $cache->stats->{$config};

# Remove stuff that we cannot check reliably
delete @$got{ qw(
 bytes_read
 bytes_written
 connection_structures
 curr_connections
 limit_maxbytes
 pid
 pointer_size
 rusage_user
 rusage_system
 time
 total_connections
 uptime 
 version
) };

# Set up the expected stats for the rest
my $expected = {
 bytes       => 0,
 cmd_get     => 88764,
 cmd_set     => 35936,
 curr_items  => 0,
 get_hits    => 88722,
 get_misses  => 42,
 total_items => 35968,
};

# Check if it is what we expected
TODO: {
local $TODO = 'Need to look up changes in memcached for different versions';
diag( Data::Dumper::Dumper( $got, $expected ) ) if
  !is_deeply( $got,$expected,
    "Check if final stats with one server correct" );
} #TODO

# Stop the single memcached server setup
ok( $cache->stop, "Check if single server has stopped" );
diag("\nStopped memcached server");

# Obtain ports and create config
my @port = map { anyport() } 0 .. 1;
ok( $port[$_], "Check whether we have a port to work on for $_" )
  foreach 0 .. 1;
my @config = map { "127.0.0.1:$_" } @port;

# Create a cache object
$cache = $class->new(
  data            => $config[1],
  directory       => $config[0],
  memcached_class => $memcached_class,
);
isa_ok( $cache, $class, "Check whether object ok" );

# Start the server, give it time to warm up
diag( "\nStarted memcached servers" )
  if ok( $cache->start, "Check if memcached servers started" );
sleep 2;

# Set them all in random order
Foo::set($_) foreach shuffle @item;

# Check them all in random order
Foo::check($_) foreach shuffle @item;

# Obtain final stats for directory server
my $stats = $cache->stats;

# Remove stuff that we cannot check reliably
$got = $stats->{$config[0]};
delete @$got{ qw(
 bytes_read
 bytes_written
 connection_structures
 curr_connections
 limit_maxbytes
 pid
 pointer_size
 rusage_user
 rusage_system
 time
 total_connections
 uptime 
 version
) };

# Set up the expected stats for the rest
$expected = {
 bytes       => 0,
 cmd_get     => 53393,
 cmd_set     => 17989,
 curr_items  => 0,
 get_hits    => 53351,
 get_misses  => 42,
 total_items => 18021,
};

# Check if it is what we expected
TODO: {
local $TODO = 'Need to look up changes in memcached for different versions';
diag( Data::Dumper::Dumper( $got,$expected ) ) if
  !is_deeply( $got,$expected,
    "Check if final stats with two servers correct" );
} #TODO

# Obtain final stats for data server
$got = $stats->{ $config[1] };

# Remove stuff that we cannot check reliably
delete @$got{ qw(
 bytes_read
 bytes_written
 connection_structures
 curr_connections
 limit_maxbytes
 pid
 pointer_size
 rusage_user
 rusage_system
 time
 total_connections
 uptime 
 version
) };

# Set up the expected stats for the rest
$expected = {
 bytes       => 0,
 cmd_get     => 35371,
 cmd_set     => 17947,
 curr_items  => 0,
 get_hits    => 35371,
 get_misses  => 0,
 total_items => 17947,
};

# Check if it is what we expected
TODO: {
local $TODO = 'Need to look up changes in memcached for different versions';
diag( Data::Dumper::Dumper( $got,$expected ) ) if
  !is_deeply( $got, $expected,
  "Check if final stats with two servers correct" );
}   #TODO

} #SKIP

#---------------------------------------------------------------------
# Foo::set
#
# Set information for group setting check
#
#  IN: 1 number of items

sub Foo::set {
    my ($items) = @_;

    # Set up items and group name
    my $group = "group$items";

    # Fill the group
    foreach ( shuffle 1 .. $items ) {
        ok( $cache->set(
         key   => "::$items",
         id    => $_,
         value => $items - $_ + 1,
         group => $group ), "Check if group$_ set ok for $_" );
    }
} #Foo::set

#---------------------------------------------------------------------
# Foo::check
#
# Check group information
#
#  IN: 1 number of items

sub Foo::check {
    my ($items) = @_;

    # Set up items and group name
    my $group = "group$items";
    my $key   = "Foo::$items";

    # Obtain the group key and associated IDs
    my $got = $cache->group( group => $group );
    my $expected = { $key => [ sort 1 .. $items ] }; # need alpha sorting
    diag( Data::Dumper::Dumper( $got, $expected ) ) if
      !is_deeply( $got, $expected,
        "Check if group key and IDs correct for $_" );

    # Fetch the group and data
    $got = $cache->get_group( group => $group );
    $expected = { $key => {
      $Foo::VERSION => { map { $_ => ( $items - $_ + 1 ) } 1..$items }
    } };
    diag( Data::Dumper::Dumper( $got, $expected ) ) if
      !is_deeply( $got,$expected,
        "Check if fetch group and data structure correct for $_" );

    my $values = $expected->{$key}->{$Foo::VERSION};
    foreach ( shuffle 1 .. 20 ) {
        ok( $cache->set(
         key   => $key,
         id    => $_,
         value => ($values->{$_} = $_),
         group => $group ), "Check if group$_ override ok for $_" );
    }

    # Grab the group and data
    $got = $cache->grab_group( group => $group );
    diag( Data::Dumper::Dumper( $got, $expected ) ) if
      !is_deeply( $got,$expected,
        "Check if grab group and data structure correct for $_" );

    # Grab the now empty group and data
    $got = $cache->grab_group( group => $group );
    diag( Data::Dumper::Dumper( $got, {} ) ) if
      !is_deeply( $got, {},
        "Check if second grab group and data structure fails for $_" );
} #Foo::check
