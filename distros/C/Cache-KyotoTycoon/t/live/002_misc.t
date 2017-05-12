use strict;
use warnings;
use Test::More;
use Data::Dumper;

use Cache::KyotoTycoon;

use t::Util;

test_kt(
    sub {
        my $port = shift;
        my $kt = Cache::KyotoTycoon->new(port => $port);
        subtest 'echo' => sub {
            my $input = {foo => 'bar', 'hoge' => 'fuga'};
            my $got = $kt->echo($input);
            is_deeply($got, $input);
        };
        subtest 'report' => sub {
            my $got = $kt->report();
            note Dumper($got);
            ok(keys(%$got) > 0);
        };
        subtest 'status' => sub {
            my $got = $kt->status();
            note Dumper($got);
            ok exists($got->{count});
            ok exists($got->{size});
        };
        subtest 'synchronize' => sub {
            my $got = $kt->synchronize();
            is($got, 1);
        };
        subtest 'vacuum' => sub {
            $kt->vacuum();
            $kt->vacuum(1);
            ok 1;
        };
        subtest 'clear' => sub {
            $kt->clear();
            ok 1;
        };
        done_testing;
    },
);


