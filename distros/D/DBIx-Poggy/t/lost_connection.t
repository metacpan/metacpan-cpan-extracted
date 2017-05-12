use strict; use warnings;

use Test::More !$ENV{POGGY_TEST_DSN}? (skip_all => 'no POGGY_TEST_DSN set') : ();
use_ok('AnyEvent');
use Promises qw(collect deferred);

use_ok 'DBIx::Poggy';
my $pool = DBIx::Poggy->new( pool_size => 3, ping_on_take => 1 );
$pool->connect($ENV{POGGY_TEST_DSN}, 'postgres', undef, {PrintError => 0});

note "server closed connection during query";
{
    my $cv = AnyEvent->condvar;
    $cv->begin;
    $cv->begin;
    {
        my $dbh1 = $pool->take;
        $dbh1->do(
            'select pg_sleep(10)'
        )->then( sub {
            fail "success is not expected";
        })
        ->catch(sub{
            pass "error is expected"
        })
        ->finally(sub{ $cv->end });

        $pool->take->do(
            'select pg_terminate_backend(?)', undef, $dbh1->{pg_pid},
        )
        ->then( sub {
            pass "terminated";
        })
        ->catch(sub{
            fail "error is not expected" or "error: ". $_[0]->{errstr};
        })
        ->finally(sub{ $cv->end });
    }

    $cv->recv;

    is scalar @{ $pool->{free} }, 2;
}

note "server closed connection in the pool";
{
    {
        my $cv = AnyEvent->condvar;
        my $dbh = $pool->take;
        $dbh->do(
            'select pg_terminate_backend(?)', undef, $pool->{free}[0]{pg_pid},
        )
        ->then( sub {
            pass "terminated";
        })
        ->catch(sub{
            fail "error is not expected" or "error: ". $_[0]->{errstr};
        })
        ->finally($cv);
        $cv->recv;
    }

    my $cv = AnyEvent->condvar;
    my $w;
    $w = AnyEvent->timer( after => 2, cb => sub {
        $w = undef;
        $pool->take->selectrow_array(
            'select 123'
        )->then( sub {
            is shift, 123, "successful query";
        })
        ->catch(sub{
            fail "error is not expected" or "error: ". $_[0]->{errstr};
        })
        ->finally($cv);
    });
    $cv->recv;

    is scalar @{ $pool->{free} }, 1, "we lost another one connection";
}

done_testing;
