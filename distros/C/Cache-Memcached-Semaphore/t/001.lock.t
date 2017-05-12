#!/usr/bin/perl -Tw

use strict;
use Test::More;

use Cache::Memcached;
use IO::Socket::INET;

my $testaddr = "127.0.0.1:11211";
my $msock = IO::Socket::INET->new(PeerAddr => $testaddr,
                                  Timeout  => 3);
if ($msock) {
    plan tests => 18;
} else {
    plan skip_all => "No memcached instance running at $testaddr\n";
    exit 0;
}

my $memd = Cache::Memcached->new({
    servers   => [ $testaddr ],
    namespace => "Cache::Memcached::Semaphore::t/$$/" . (time() % 100) . "/",
});

BEGIN {
	use_ok('Cache::Memcached::Semaphore');
}

require_ok('Cache::Memcached::Semaphore');

my $lock = Cache::Memcached::Semaphore->new( memd => $memd, name => "semaphore" );
ok( $lock, "Semaphore object" );

my $err_lock = Cache::Memcached::Semaphore->new( memd => $memd, name => "semaphore" );
ok( !$err_lock, "Cannot lock same semaphore" );

# scoping
{
	my $c_lock = Cache::Memcached::Semaphore->new( memd => $memd, name => "c_test" );
	my $s_lock = Cache::Memcached::Semaphore::acquire( memd => $memd, name => "s_test" );
	
	ok( $c_lock, "Inner block constructor acquired" );
	ok( $s_lock, "Inner block sub acquired" );
	ok( !Cache::Memcached::Semaphore->new( memd => $memd, name => "c_test" ), "Inner block constructor locked" );
	ok( !Cache::Memcached::Semaphore::acquire( memd => $memd, name => "s_test" ), "Inner block sub locked" );
}

my $c_lock = Cache::Memcached::Semaphore->new( memd => $memd, name => "c_test" );
my $s_lock = Cache::Memcached::Semaphore::acquire( memd => $memd, name => "s_test" );
ok( $c_lock, "Outer block constructor acquired" );
ok( $s_lock, "Outer block sub acquired" );
ok( !Cache::Memcached::Semaphore->new( memd => $memd, name => "c_test" ), "Outer block constructor locked" );
ok( !Cache::Memcached::Semaphore::acquire( memd => $memd, name => "s_test" ), "Outer block sub locked" );

# timeout
ok( Cache::Memcached::Semaphore->new( memd => $memd, name => "c_timeout", timeout => 10 ), "Constructor with timeout" );
ok( !Cache::Memcached::Semaphore->new( memd => $memd, name => "c_timeout", timeout => 10 ), "Constructor with timeout locked" );
ok( Cache::Memcached::Semaphore::acquire( memd => $memd, name => "s_timeout", timeout => 10 ), "Sub with timeout" );
ok( !Cache::Memcached::Semaphore::acquire( memd => $memd, name => "s_timeout", timeout => 10 ), "Sub with timeout locked" );

ok( Cache::Memcached::Semaphore::wait_acquire( memd => $memd, name => "w_timeout", timeout => 2 ), "Wait lock. Create with timeout" );
ok( Cache::Memcached::Semaphore::wait_acquire( memd => $memd, name => "w_timeout", timeout => 10), "Wait indefinitely. Create with timeout" );
ok( !Cache::Memcached::Semaphore::wait_acquire( memd => $memd, name => "w_timeout", timeout => 10, max_wait => 1), "Wait 1 sec. No acquire" );

#require Benchmark;
#my $benchmark = Benchmark::timeit( 1000, sub { Cache::Memcached::Semaphore->new( memd => $memd, name => 'benchmark' ) || die "Couldn't lock" } );	
#diag(Benchmark::timestr($benchmark));
