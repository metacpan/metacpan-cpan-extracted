# Test of complex job queue ordering
use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;
use DataLoader::Test qw(await id_loader);

use AnyEvent;
use Data::Dump qw(dump);
use Mojo::Promise;
use Scalar::Util qw(weaken);

use DataLoader;

# The JS version manages to do this in one batch call, because next_tick jobs
# come after all Promise job. For Mojo/AnyEvent, next_tick is too fast (happens
# before the promise) but an idle watcher works well.
subtest 'batches loads occuring within promises', sub {
    my ($loader, $load_calls) = id_loader();

    await(Mojo::Promise->all(
        $loader->load(1),
        Mojo::Promise->resolve->then(sub { Mojo::Promise->resolve })->then(sub {
            $loader->load(2);
            Mojo::Promise->resolve->then(sub { Mojo::Promise->resolve })->then(sub {
                $loader->load(3);
                Mojo::Promise->resolve->then(sub { Mojo::Promise->resolve })->then(sub {
                    $loader->load(4);
                });
            });
        })
    ));

    cmp_deeply($load_calls, [[1,2,3,4]])
        or diag("actual calls: " . dump($load_calls));
};

use Data::Dump qw(dd);
subtest 'can call a loader from a loader', sub {
    my ($deep_loader, $deep_calls) = id_loader();

    # The JS test passes the keys arrayref directly to $deep_loader->load()
    # which resolves to an arrayref of values, as expected. The Perl interface
    # should resolves to a list of values, so we need to wrap it.
    my (@a_calls, @b_calls);
    my $a_loader = DataLoader->new(sub {
        push @a_calls, \@_;
        return $deep_loader->load(\@_)->then(sub {
            my $arr = shift;
            return Mojo::Promise->resolve(@$arr);
        });
    });
    my $b_loader = DataLoader->new(sub {
        push @b_calls, \@_;
        return $deep_loader->load(\@_)->then(sub {
            my $arr = shift;
            return Mojo::Promise->resolve(@$arr);
        });
    });

    my @values = await(DataLoader->all(
        $a_loader->load('A1'),
        $b_loader->load('B1'),
        $a_loader->load('A2'),
        $b_loader->load('B2'),
    ));
    cmp_deeply( \@values, [qw(A1 B1 A2 B2)] );
    cmp_deeply( \@a_calls, [['A1', 'A2']] );
    cmp_deeply( \@b_calls, [['B1', 'B2']] );
    is( @$deep_calls, 1 );
    cmp_bag( $deep_calls->[0], [['A1', 'A2'], ['B1', 'B2']] )
        or diag("actual calls: " . dump($deep_calls));
};

done_testing;
