use strict; use warnings;

use Test::More !$ENV{POGGY_TEST_DSN}? (skip_all => 'no POGGY_TEST_DSN set') : ();
use_ok('AnyEvent');
use Promises qw(collect deferred);

use_ok 'DBIx::Poggy';
my $pool = DBIx::Poggy->new( pool_size => 3 );
$pool->connect($ENV{POGGY_TEST_DSN}, 'postgres');
is scalar @{ $pool->{free} }, 3;

{
    my $cv = AnyEvent->condvar;
    $pool->take->do(
        'CREATE TABLE IF NOT EXISTS poggy_users (email varchar(255) primary key, password varchar(64))'
    )->then( sub {
        ok $_[0], "created table";
    })
    ->catch(sub{
        fail "error is not expected, but we got: ". $_[0]->{errstr};
    })
    ->finally($cv);
    is scalar @{ $pool->{free} }, 2;
    $cv->recv;
    is scalar @{ $pool->{free} }, 3;
}

{
    my $cv = AnyEvent->condvar;
    $pool->take->do('DELETE FROM poggy_users')->finally($cv);
    $cv->recv;
}

{
    my $cv = AnyEvent->condvar;

    my $dbh = $pool->take;
    is scalar @{ $pool->{free} }, 2;
    $dbh->begin_work->finally($cv);

    $dbh->do(
        'DELETE FROM poggy_users'
    )
    ->then(sub {
        is scalar @{ $pool->{free} }, 2;
        return $dbh->do('INSERT INTO poggy_users (email) VALUES (?)', undef, 'u@example.com');
    })
    ->then(sub {
        is scalar @{ $pool->{free} }, 2;
        return $dbh->commit;
    })
    ->catch(sub {
        fail "error is not expected";
        $dbh->rollback;
    });
    is scalar @{ $pool->{free} }, 2;
    $cv->recv;
    is scalar @{ $pool->{free} }, 3;
}

{
    my $cv = AnyEvent->condvar;

    do {
        my $dbh = $pool->take;
        $dbh->selectall_arrayref('SELECT 1')
        ->then(sub {
            pass "selected";
            my $d = deferred;
            my $w;
            $w = AnyEvent->timer(after => 0.01, cb => sub { $w = undef; $d->resolve } );
            return $d->promise;
        })
        ->then(sub{
            return $dbh->selectall_arrayref('SELECT 1');
        })
        ->catch(sub { print @_ })
        ->finally($cv);
    };
    is scalar @{ $pool->{free} }, 2;
    $cv->recv;
    warn "out of scope";
    is scalar @{ $pool->{free} }, 3;
}

done_testing;
