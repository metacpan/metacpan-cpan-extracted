# Test of error handling
use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;
use Test::Exception;
use DataLoader::Test qw(await make_test_loader id_loader);

use AnyEvent;
use Data::Dump qw(dump);
use Mojo::Promise;

use DataLoader;

# Show stack trace for timeouts
$Carp::Verbose = 1;

sub even_loader {
    return make_test_loader { $_ % 2 == 0 ? $_ : DataLoader->error("Odd: $_") };
}

sub error_loader {
    return make_test_loader { DataLoader->error("Error: $_") };
}

subtest 'Resolves to error to indicate failure', sub {
    my ($even_loader, $load_calls) = even_loader();

    throws_ok { await($even_loader->load(1)) } qr/Odd: 1/;
    is( await($even_loader->load(2)), 2 );
    cmp_deeply( $load_calls, [ [1], [2] ] );
};

subtest 'Can represent failures and successes simultaneously', sub {
    my ($even_loader, $load_calls) = even_loader();

    my $promise1 = $even_loader->load(1);
    my $promise2 = $even_loader->load(2);

    throws_ok { await($promise1) } qr/Odd: 1/;
    is( await($promise2), 2 );
    cmp_deeply( $load_calls, [ [1, 2] ] );
};

subtest 'Caches failed fetches', sub {
    my ($loader, $load_calls) = error_loader(); 
    throws_ok { await($loader->load(1)) } qr/Error: 1/;
    throws_ok { await($loader->load(1)) } qr/Error: 1/, 'cached version';

    cmp_deeply( $load_calls, [[1]], 'loader fn only called once' );
};

subtest 'Handles priming the cache with an error', sub {
    my ($loader, $load_calls) = id_loader();

    $loader->prime(1, DataLoader->error("Error: 1"));
    throws_ok { await($loader->load(1)) } qr/Error: 1/;
    cmp_deeply( $load_calls, [] );

    $loader->prime(1, DataLoader->error("Error: 2"));
    throws_ok { await($loader->load(1)) } qr/Error: 1/, 'does not replace old value';
    cmp_deeply( $load_calls, [] );
};

subtest 'Can clear values from the cache after errors', sub {
    my ($loader, $load_calls) = error_loader();

    for my $try (1..2) {
        throws_ok {
            await($loader->load(1)->catch(sub {
                my $error = shift;
                # e.g. we decided the error is transient, so we clear it to allow the
                # data to be queried again.
                $loader->clear(1);
                # XXX are we sure it's a DataError object?
                $error->throw;
            }));
        } qr/Error: 1/, "try $try";
    }
    cmp_deeply( $load_calls, [[1], [1]] );
};

subtest 'Propagates error to all loads', sub {
    my @load_calls;
    my $loader = DataLoader->new(sub {
        push @load_calls, \@_;
        return Mojo::Promise->reject("I am a terrible loader");
    });

    my $promise1 = $loader->load(1);
    my $promise2 = $loader->load(2);

    throws_ok { await($promise1) } qr/I am a terrible loader/;
    throws_ok { await($promise2) } qr/I am a terrible loader/;

    cmp_deeply( \@load_calls, [[1,2]] );
};

subtest 'Batch loader exceptions are not cached', sub {
    my ($loader, $load_calls) = make_test_loader {
        state $called = 0;
        $called++ ? 100 : die "temporary failure"
    };

    throws_ok { await($loader->load(1)) } qr/temporary failure/, 'error passed through';
    is( await($loader->load(1)), 100, 'worked second time' );
    is( await($loader->load(1)), 100, 'cache successful result' );

    cmp_deeply( $load_calls, [ [1], [1] ] );
};

subtest 'Batch loader rejected promises are not cached', sub {
    my @load_calls;
    my $loader = DataLoader->new(sub {
        state $called = 0;
        push @load_calls, \@_;
        $called++ ? Mojo::Promise->resolve(@_) : Mojo::Promise->reject("I suck!")
    });

    throws_ok { await($loader->load(1)) } qr/I suck!/, 'error passed through';
    is( await($loader->load(1)), 1, 'worked second time' );
    is( await($loader->load(1)), 1, 'cache successful result' );

    cmp_deeply( \@load_calls, [ [1], [1] ] );
};

done_testing;
