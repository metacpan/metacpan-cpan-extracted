
# Version number initializations
$VERSION      = 'main::VERSION';
$Foo::VERSION = 'Foo::VERSION';

# Set up tests and strictness
use Test::More tests => 176;
use strict;
use warnings;

# Add the termination code
my $cache;
END {
    my $stopped_ok;
    $stopped_ok = $cache->stop if $cache;
    diag( "\nStopped memcached server" )
      if ok( $stopped_ok, "Check if all servers have stopped" );
} #END

# Make sure we have all the support routines
require 'testlib';
my $class = 'Cache::Memcached::Managed';

# For both active and inactive version
foreach ($class,$class.'::Inactive') {

    # check loading and methods
    require_ok( $_ );
    can_ok( $_,qw(
 add
 data
 dead
 decr
 delete
 delete_group
 delimiter
 directory
 errors
 expiration
 flush_all
 flush_interval
 get
 get_group
 get_multi
 grab_group
 group
 group_names
 incr
 namespace
 new
 replace
 reset
 servers
 set
 start
 stats
 stop
 version
) );
}

# Obtain port and create config
my $port = anyport();
ok( $port, "Check whether we have a port to work on" );
my $config = "127.0.0.1:$port";

# Create a cache object
my $memcached_class = $ENV{CACHE_MEMCACHED} || 'Cache::Memcached';
$cache = $class->new(
  data            => $config,
  memcached_class => $memcached_class,
);
isa_ok( $cache,$class, "Check whether object ok" );

# Start the server, skip further tests if failed
SKIP: {
skip( "Memcached server not started", 169 ) if !$cache->start;
sleep 2; # let the server warm up
diag("\nStarted memcached server");

# Check version info
my $versions = $cache->version;
my $version  = $versions->{$config};
ok( $version, "Check whether version information available" );

# Show warning if memcached version questionable
my $pid = $cache->stats->{$config}->{pid};
diag( <<DIAG ) if $version lt '1.1.12';

\b\b******************** please UPGRADE memcached server software ******************
\b\b* Please note that some tests have been known to fail on memcached server      *
\b\b* versions below 1.1.12, most notable 1.1.11.                                  *
\b\b*                                                                              *
\b\b* Please upgrade your memcached server software to at least version 1.1.12!    *
\b\b********************************************************************************
DIAG

# Do this before and after a reset
TEST:
foreach my $reset ( 0 .. 1 ) {

    # Check the backend servers
    my @server = $cache->servers;
    is_deeply( \@server, [$config],
      "Check if all memcached backend servers accounted for from a list" );
    my $servers = $cache->servers;
    is_deeply( $servers, { $config => undef },
      "Check if all memcached backend servers accounted for from a hash ref" );

    # Check whether backend servers all alive
    my @dead = $cache->dead;
    is( scalar @dead, 0, "Check that all servers are alive from a list" );
    my $dead = $cache->dead;
    is_deeply( $dead, {}, "Check that all servers are alive from a hash ref" );

    # Check group names
    my @group_name = $cache->group_names;
    is_deeply( \@group_name, ['group'],
      "Check that all group names accounted for from a list" );
    my $group_names = $cache->group_names;
    is_deeply( $group_names, { group => undef },
      "Check that all group names accounted for from a hash ref" );

    # No key, no ID
    my $value = 'value';
    ok( $cache->set($value), "Check if simple setting works" );
    is( $cache->get,$value, "Check if simple getting works" );
    ok( $cache->delete, "Check if simple delete works" );
    ok( !defined $cache->get, "Check if simple getting fails" );

    # No key, but ID given
    foreach my $param (
      [ [ qw(foo foo) ], [qw(bar bar) ] ],
      [ [ qw(id foo value foo) ], [ qw(id bar value bar) ] ],
      ) {
        ok( $cache->set( @{ $param->[0] } ), "Check if setting with ID works" );
        ok( $cache->set( @{ $param->[1] } ), "Check if setting with ID works" );

        my $got = $cache->get_multi( [ qw(foo bar) ] );
        diag( Data::Dumper::Dumper($got) ) if
          !is_deeply( $got,{ foo => 'foo', bar => 'bar' },
            "Check whether get_multi with ID's works" );

        is( $cache->flush_all, 1, "Check if flushing works" );
        sleep 1; # give flush time to work through

        $got = $cache->get_multi( qw(foo bar) );
        diag( Data::Dumper::Dumper($got) ) if
          !is_deeply( $got,{},
            "Check whether get_multi with ID's fails" );

        # Remove flushed elements anyway for final stats
        $cache->delete($_) foreach qw(foo bar);
    }

    # Check version dependency
    my $version = do { no strict; $VERSION };
    ok( $version, "Check whether there was a version for the module itself" );
    ok( $cache->set($value), "Simple value for version / namespace check" );
    is( $cache->get( version => $version ), $value,
      "Check if simple getting with version works" );
    ok( !defined $cache->get( version => 'foo' ),
      "Check if simple getting with version fails" );

    # Check namespace dependency
    my $namespace = $cache->namespace;
    is( $namespace, $>, "Check whether there was a default namespace" );
    is( $cache->get( namespace => $namespace ), $value,
      "Check if simple getting with namespace works" );
    ok( !defined $cache->get( namespace => 'foo' ),
      "Check if simple getting with namespace fails" );

    # Check expiration
    ok( $cache->set( value => $value, expiration => '3' ),
      "Simple value for expiration check" );
    is( $cache->get, $value,
      "Check if simple getting before expiration works" );
    sleep 5;
    ok( !defined $cache->get,
      "Check if simple getting after expiration fails" );

    # Check (magical) in/decrement
    is( $cache->incr, 1, "Check initial simple increment" );
    is( $cache->incr, 2, "Check additional simple increment" );
    is( $cache->incr(7), 9, "Check additional increment with specific value" );
    is( $cache->decr, 8, "Check additional simple decrement" );
    is( $cache->decr(6),2, "Check additional decrement with specific value" );
    ok( $cache->delete, "Check whether deletion successful" );
    ok( !defined $cache->get,
      "Check if simple getting after increment + deletion fails" );
    ok( !$cache->decr( 1, 1 ), "Check if simple decrement fails" );

    # Check add/replace
    ok( $cache->add($value), "Check if simple add works" );
    is( $cache->get, $value, "Check if get after add works" );
    ok( !$cache->add($value), "Check if additional add fails" );
    is( $cache->get,$value, "Check if get after add still works" );
    ok( $cache->replace(22), "Check if simple replace works" );
    is( $cache->get, 22, "Check if get after replace works" );
    ok( $cache->replace(33), "Check if additional replace works" );
    is( $cache->get, 33, "Check if get after additional replace works" );
    ok( $cache->delete, "Check whether deletion successful" );
    ok( !$cache->replace($value), "Check if replace after delete fails" );

    # determine unique key
    my $key = $0 =~ m#^/#
      ? $0
      : do { my $pwd = `pwd`; chomp $pwd; $pwd } . "/$0";

    # Check simple group management
    ok( $cache->set( value => $value, group => 'group' ),
      "Simple value with group" );
    is( $cache->get, $value, "Check if simple get with group works" );
    my $expected = { $key => { $version => { '' => $value } } };
    my $got = $cache->get_group( group => 'group' );
    diag( Data::Dumper::Dumper($got) ) if
      !is_deeply( $got,$expected,
        "Check if simple get_group with group works" );
    is( $cache->get, $value, "Check if simple get with group works" );

    # Repeat simple group management, now with grab_group
    $got = $cache->get_group( group => 'group' );
    diag( Data::Dumper::Dumper($got) ) if
      !is_deeply( $got,$expected,
        "Check if simple get_group with group works still" );
    is( $cache->get, $value, "Check if simple get with group works" );
    $got = $cache->grab_group( group => 'group' );
    diag( Data::Dumper::Dumper($got) ) if
      !is_deeply( $got,$expected,
        "Check if simple grab_group with group works" );
    ok( !defined $cache->get,
      "Check if simple getting with grabbed group fails" );

    # Check simple group deletion
    ok( $cache->set( value => $value, group => 'group' ),
      "Simple value with group" );
    is( $cache->get, $value, "Check if simple get with group works" );
    ok( $cache->delete_group( group => 'group' ), "Delete group" );
    ok( !defined $cache->get,
      "Check if simple getting with deleted group fails" );

    # Check stats fetching
    $got = $cache->stats;
    foreach ( values %{$got} ) {
         $_ = undef foreach values %{$_};
    }
    $expected = { $config => { map { $_ => undef } qw(
     bytes
     bytes_read
     bytes_written
     cmd_get
     cmd_set
     connection_structures
     curr_items
     curr_connections
     get_hits
     get_misses
     limit_maxbytes
     pid
     rusage_system
     rusage_user
     time
     total_connections
     total_items
     uptime
     version
    ) } };

    # pointer_size introduced in memcached 1.2.1
    $expected->{$config}->{pointer_size} = undef if $version ge "1.2.1";

TODO: {
local $TODO = 'Need to look up changes in memcached for different versions';
    diag( Data::Dumper::Dumper($got) ) if
      !is_deeply( $got,$expected, "Check if simple stats works" );
} #TODO

    # Check inside subroutine
    Foo::bar();

    # Done now if we did a reset already
    last TEST if $reset;

    # Reset so we can do it again with a clean slate
    ok( $cache->reset, "Check if client side reset ok" );
}

# Obtain final stats
my $got = $cache->stats->{$config};

# Remove stuff that we cannot check reliably
delete @$got{qw(
 bytes_read
 bytes_written
 connection_structures
 curr_connections
 limit_maxbytes
 rusage_user
 rusage_system
 time
 total_connections
 uptime 
)};

# Set up the expected stats for the rest
my $expected = {
 bytes        => 0,
 cmd_get      => 108,
 cmd_set      => 56,
 curr_items   => 0,
 get_hits     => 74,
 get_misses   => 34,
 pid          => $pid,
 pointer_size => 32,
 total_items  => 52,
 version      => $version,
};

# Check if it is what we expected
TODO: {
local $TODO = 'Need to look up changes in memcached for different versions';
diag( Data::Dumper::Dumper( $got, $expected ) ) if
  !is_deeply( $got, $expected, "Check if final stats correct" );
}    #TODO

} #SKIP

#--------------------------------------------------------------------------
# Foo::bar
#
# A subroutine for checking subroutine relative keys

sub Foo::bar {

    # One set, many different gets
    ok( $cache->set('foo1'), "Check simple set inside a subroutine" );
    is( $cache->get, 'foo1', "Check simple get inside a subroutine" );
    is( $cache->get( key => '::bar' ), 'foo1',
      "Check simple get with relative key inside a subroutine" );
    is( $cache->get( key => 'Foo::bar' ), 'foo1',
      "Check simple get with absolute key inside a subroutine" );

    # Simple delete, many gets
    ok( $cache->delete, "Check simple delete inside a subroutine" );
    ok( !$cache->get, "Check whether simple get inside a subroutinei fails" );
    ok( !$cache->get( key => '::bar' ),
      "Check whether get with relative key inside a subroutine fails" );
    ok( !$cache->get( key => 'Foo::bar' ),
      "Check whether get with absolute key inside a subroutine fails" );

    # Relative key set and delete
    ok( $cache->set( key => '::bar', value => 'foo2' ),
      "Check simple set with relative key inside a subroutine" );
    is( $cache->get, 'foo2',
      "Check simple get inside a subroutine after set with relative key" );
    ok( $cache->delete( key => '::bar' ),
      "Check delete with relative key inside a subroutine" );
    ok( !$cache->get( key => '::bar' ),
      "Check whether get with relative key inside a subroutine fails" );

    # Absolute key set and delete
    ok( $cache->set( key => 'Foo::bar', value => 'foo3' ),
      "Check simple set with absolute key inside a subroutine" );
    is( $cache->get, 'foo3',
      "Check simple get inside a subroutine after set with absolute key" );
    ok( $cache->delete( key => 'Foo::bar' ),
      "Check delete with absolute key inside a subroutine" );
    ok( !$cache->get( key => 'Foo::bar' ),
      "Check whether get with absolute key inside a subroutine fails" );

    # Check version support
    ok( $cache->set('foo4'),
      "Check simple set for version info" );
    is( $cache->get( version => $Foo::VERSION ), 'foo4',
      "Check if get with version info ok" );
    ok( $cache->delete( version => $Foo::VERSION ),
      "Check if delete with version info ok" );
    ok( !$cache->get( version => $Foo::VERSION ),
      "Check whether get with version inside a subroutine fails" );
    ok( !$cache->get( version => $main::VERSION ),
      "Check whether get with main version inside a subroutine fails" );
    ok( !$cache->get( version => $Cache::Memcached::Managed::VERSION ),
      "Check whether get with module version inside a subroutine fails" );
} #Foo::bar
