use strict; use warnings;

use Test::More !$ENV{POGGY_TEST_DSN}? (skip_all => 'no POGGY_TEST_DSN set') : ();
use_ok('AnyEvent');
use Promises qw(collect deferred);

use_ok 'DBIx::Poggy';
my $pool = DBIx::Poggy->new( pool_size => 3 );
$pool->connect($ENV{POGGY_TEST_DSN}, 'postgres');

{
my $dbh = $pool->take;

note "set timeout";
{
    my $cv = AnyEvent->condvar;
    $dbh->do(
        'set statement_timeout to 100'
    )->then( sub {
        ok $_[0], "set timeout";
    })
    ->catch(sub{
        fail "error is not expected, but we got: ". $_[0]->{errstr};
    })
    ->finally($cv);
    $cv->recv;
}

note "statement timeout";
{
    my $cv = AnyEvent->condvar;
    $dbh->do(
        'select pg_sleep(1)'
    )->then( sub {
        fail "success is not expected";
    })
    ->catch(sub{
        pass "error is expected";
    })
    ->finally($cv);
    $cv->recv;
}
}

is scalar @{ $pool->{free} }, 3, 'released back';

done_testing;
