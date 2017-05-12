use Test::More;
use DataDog::DogStatsd::Helper qw(stats_inc stats_dec stats_timing stats_gauge);

pass "successfully imported functions";
stats_inc('test.stats');
pass "stats_inc";
stats_dec('test.stats');
pass "stats_dec";
stats_timing('test.timing', 1);
pass "stats_timing";
stats_gauge('test.gauge', 10);
pass "stats_gauge";

stats_inc('test.stats.tags', { tags => ['tagC', 'tagD'] });

done_testing;
