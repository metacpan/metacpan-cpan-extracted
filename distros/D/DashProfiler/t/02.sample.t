use strict;

use Test::More qw(no_plan);
use Config;

use DBI qw(dbi_time);
use Symbol qw(gensym);
use List::Util qw(sum min max shuffle reduce);
$|=1;

use DashProfiler::Core;

my $dp1 = DashProfiler::Core->new("dp1", {
});

pass();

# check that time always goes forwards...
my $dbi_time_samples = 1_000_000;
my ($prev, @diffs) = 0;
for (my $i=$dbi_time_samples; $i; --$i) {
    my $diff = dbi_time() - $prev;
    next if $diff >= 0;
    push @diffs, $diff;
}
if (@diffs) {
    warn sprintf "Warning: Time went backwards for %d out of %d samples (avg %fs, max %fs)!",
        scalar @diffs, $dbi_time_samples, sum(@diffs)/@diffs, max(@diffs);
}

# report version and archname for the record, also moves cursor
# to a new line for the sample overhead reports below
warn " you're using perl $] on $Config::Config{archname} $Config::Config{optimize}\n";

# prepare a new sampler
my $sampler1 = $dp1->prepare("c1");
my @sample_times;

for (my $i=1_000; $i--;) {
    my $t1 = dbi_time();
    my $ps1 = $sampler1->("spin");
    undef $ps1;
    push @sample_times, dbi_time() - $t1;
    cache_buster();
}
warn sprintf " Average 'cold' sample overhead is %.6fs (max %.6fs, min %.6fs)\n",
    sum(@sample_times)/@sample_times, max(@sample_times), min(@sample_times);
$dp1->reset_profile_data;
@sample_times = ();

for (my $i=2_000; $i--;) {
    my $t1 = dbi_time();
    my $ps1 = $sampler1->("spin");
    undef $ps1;
    push @sample_times, dbi_time() - $t1;
}
warn sprintf " Average 'hot'  sample overhead is %.6fs (max %.6fs, min %.6fs)\n",
    sum(@sample_times)/@sample_times, max(@sample_times), min(@sample_times);
$dp1->reset_profile_data;
@sample_times = ();

pass();

my $sample = $sampler1->("and warm the cache");
sleep 1;
cmp_ok $sample->current_sample_duration, '>=', 0.5,
    'current_sample_duration should be > 0.5';
cmp_ok $sample->current_sample_duration, '<', 2,
    'current_sample_duration should be < 2';
undef $sample; # end sample
sleep 1; # needed to keep output tidy, odd
$dp1->reset_profile_data;


sub cache_buster { # quick hack, could be better
    my $foo = unpack("%32b*", (rand()."foo ") x 1000);
    gensym() for 1..1000;
    my @tmp = shuffle 1..1000;
}

1;
