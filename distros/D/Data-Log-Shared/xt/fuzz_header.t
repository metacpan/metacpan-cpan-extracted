use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Log::Shared;

my $seed = $ENV{FUZZ_SEED} || time;
srand $seed;
diag "FUZZ_SEED=$seed";

my $N = $ENV{FUZZ_N} || 500;
my ($rej, $acc) = (0, 0);

for (1..$N) {
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.fz');
    binmode $fh;
    my $size = int(rand(2048)) + 16;
    print $fh join('', map chr(int rand 256), 1..$size);
    close $fh;
    open(my $rfh, '<', $path) or die;
    my $r = eval { Data::Log::Shared->new_from_fd(fileno($rfh)) };
    if ($r) { $acc++ } else { $rej++ }
    close $rfh;
}
diag "rejected=$rej accepted=$acc of $N";
cmp_ok $rej, '>=', $N * 0.95, "95%+ rejected (no segfault)";
cmp_ok $acc, '<', 10, "near-zero false accepts";

done_testing;
