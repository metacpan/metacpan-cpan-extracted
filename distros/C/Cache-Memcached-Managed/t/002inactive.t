
# Set up tests and strictness
use Test::More tests => 68;
use strict;
use warnings;

# Make sure we have all the support routines
require 'testlib';
my $class    = 'Cache::Memcached::Managed';
my $inactive = $class.'::Inactive';

# Make sure we can load the module, both active and inactive
require_ok( $_ ) foreach 'Cache::Memcached',$class,$inactive;

# Create inactive cache object indirectly
my $cache = $class->new( inactive => 1 );
isa_ok( $cache,$inactive,"Check whether object #1 ok" );
check_methods($cache);

# Create inactive cache object directly
$cache = $inactive->new;
isa_ok( $cache,$inactive,"Check whether object #2 ok" );
check_methods( $cache );

# Create a cache object with default memcached servers
$cache = $class->new;
isa_ok( $cache, $class, "Check whether object #3 ok" );
#check_methods( $cache );

#-------------------------------------------------------------------------
# check_methods
#
# Check whether all the methods are indeed inactive.  Good for 32 tests.
#
#  IN: 1 instantiated object

sub check_methods {
    my ($cache) = @_;

    # Check methods returning undef always
    ok( !defined( $cache->$_ ), "Check result of inactive method $_" )
     foreach qw(
 add
 data
 decr
 delete
 delete_group
 delimiter
 directory
 expiration
 flush_all
 flush_interval
 get
 incr
 namespace
 replace
 reset
 set
 start
 stop
    );

    # Check all methods that always return a hash ref
    is_deeply( $cache->$_, {}, "Check result of inactive method $_" )
     foreach qw(
 errors
 get_group
 get_multi
 grab_group
 group
 stats
 version
    );

    # Check all methods returning a list in array context
    is_deeply( [$cache->$_], [], "Check result of list inactive method $_" )
     foreach qw(
 dead
 group_names
 servers
    );

    # Check all methods returning a hash ref in scalar context
    is_deeply( scalar $cache->$_, {},
      "Check result of scalar inactive method $_")
        foreach qw(
 dead
 group_names
 servers
    );
} #check_methods
