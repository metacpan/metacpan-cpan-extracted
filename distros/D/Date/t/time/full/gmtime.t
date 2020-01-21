use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

plan skip_all => 'set TEST_FULL=1 to enable real test coverage' unless $ENV{TEST_FULL};

subtest 'range-step' => sub {
    my @ranges;
    # check normal times
    push @ranges, [299, "2005-01-01 00:00:00", "2008-12-30 00:00:00"];
    # check QUAD YEARS threshold
    push @ranges, [1, "2004-12-31 00:00:00", "2005-01-01 10:00:00"];
    # check CENT YEARS threshold
    push @ranges, [1, "1900-12-31 00:00:00", "1901-01-01 10:00:00"];
    # check QUAD CENT YEARS threshold
    push @ranges, [1, "2000-12-31 00:00:00", "2001-01-01 10:00:00"];
    
    # negative check
    push @ranges, [86399, "-1000-01-01 12:34:56",  "2014-01-01 00:00:00"];
    
    foreach my $range (@ranges) {
        my ($step, $from, $till) = @$range;
        ok(MyTest::test_gmtime($step, epoch_from($from), epoch_from($till)));
    }
};

subtest 'random check' => sub {
    # RAND_FLAG, DIA (+- from 1970), ITERS COUNT
    ok(MyTest::test_gmtime(0, 1500000000, 1000000));
    ok(MyTest::test_gmtime(0, 20000000000, 1000000));
};
    
done_testing();
