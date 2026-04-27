use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# Header fuzzing: feed random bytes to new_from_fd. Validator must never
# segfault — only reject. Uses a fixed seed for reproducibility.

use Data::Pool::Shared;

my $seed = $ENV{FUZZ_SEED} || time;
srand $seed;
diag "FUZZ_SEED=$seed";

my $N = $ENV{FUZZ_N} || 5000;

my $accepted = 0;
my $rejected = 0;
my $errors   = 0;

for my $i (1..$N) {
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.fz');
    binmode $fh;

    # Random size between 0 and 8KB
    my $size = int(rand(8192));
    print $fh join('', map chr(int rand 256), 1..$size);
    close $fh;

    open(my $rfh, '<', $path) or die;
    my $fd = fileno($rfh);
    my $p = eval { Data::Pool::Shared::I64->new_from_fd($fd) };
    if ($p) {
        $accepted++;   # extremely unlikely but not impossible (20-byte collision)
    } elsif ($@) {
        $rejected++;
    } else {
        $errors++;
    }
    close $rfh;
    last if $i % 500 == 0 && !($accepted + $rejected);   # early-abort on no progress
}

diag "accepted=$accepted rejected=$rejected errors=$errors of $N";

cmp_ok $rejected, '>=', $N * 0.99,
    "at least 99% of random bytes cleanly rejected (no segfault)";
is $errors, 0, "no eval-less errors (all via controlled croak)";
ok $accepted < 5,
    "virtually no random bytes pass validation (accidental-valid < 5)";

done_testing;
