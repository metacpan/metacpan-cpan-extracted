# Test of cache clear_all behaviour
use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;
use DataLoader::Test qw(await);

use AnyEvent;
use Data::Dump qw(dump);
use Mojo::Promise;
use Scalar::Util qw(weaken);

use DataLoader;

subtest 'Complex cache behaviour via clear_all()', sub {
    # The loader clears its cache as soon as the batch function is
    # dispatched.
    my @calls;
    my $loader; $loader = DataLoader->new(sub {
        $loader->clear_all;
        push @calls, \@_;
        return Mojo::Promise->resolve(@_);
    });

    my @values = await(DataLoader->all(map { $loader->load($_) } qw(A B A)));
    cmp_deeply( \@values, [qw(A B A)] );

    @values = await(DataLoader->all(map { $loader->load($_) } qw(A B A)));
    cmp_deeply( \@values, [qw(A B A)] );

    cmp_deeply( \@calls, [
        ['A', 'B'],
        ['A', 'B'],
    ] ) or diag('got: ' . dump(\@calls));
};

done_testing;
