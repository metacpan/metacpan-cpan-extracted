#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Cassandra::Client::Util qw/parallel series/;

use if $ENV{BENCHMARK}, 'Benchmark', qw/timethese/;

my $run_test_parallel= sub {
    my $success= 1;
    my $ran;
    parallel([
        sub { $_[0]->(undef, "abc") },
        sub { $_[0]->(undef, "abc") },
        sub { $_[0]->(undef, "abc") },
    ], sub {
        $success &&= (!$_[0] && $_[1] eq 'abc' && $_[2] eq 'abc' && $_[3] eq 'abc');
        $ran= 1;
    });

    return ($success && $ran);
};

my $run_test_series= sub {
    my $success= 1;
    my $ran;
    my $str= 'abc';

    series([
        sub { $_[0]->(undef, "abc") },
        sub { $_[0]->(undef, $_[1]) },
        sub { $_[0]->(undef, $_[1]) },
    ], sub {
        $success &&= (!$_[0] && $_[1] eq 'abc');
        $ran= 1;
    });

    return ($success && $ran);
};

ok($run_test_parallel->());
ok($run_test_series->());

if ($ENV{BENCHMARK}) {
    timethese(-3, {
        parallel => $run_test_parallel,
        series => $run_test_series,
    });
}

done_testing;
