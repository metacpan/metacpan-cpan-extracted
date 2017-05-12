use strict; use warnings;

use Test::More !$ENV{POGGY_TEST_DSN}? (skip_all => 'no POGGY_TEST_DSN set') : ();
use_ok('AnyEvent');
use Promises qw(collect deferred);

use_ok 'DBIx::Poggy';
my $pool = DBIx::Poggy->new( pool_size => 3, ping_on_take => 1 );
$pool->connect($ENV{POGGY_TEST_DSN}, 'postgres', undef, {PrintError => 0});

note "can not bind a reference";
{
    my $cv = AnyEvent->condvar;
    $pool->take->do(
        'select pg_sleep(?)', undef, \1
    )->then( sub {
        fail "success is not expected";
    })
    ->catch(sub{
        pass "error is expected";
    })
    ->finally($cv);

    $cv->recv;

    is scalar @{ $pool->{free} }, 3;
}

done_testing;
