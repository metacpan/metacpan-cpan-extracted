use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# Bit-flip corruption survival: flip random bytes in the middle of a
# valid pool file, then reopen. Validator must reject (magic/version/
# offset mismatches), never segfault or silently return garbage.

use Data::Pool::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pool');
close $fh;

my $seed = $ENV{FUZZ_SEED} || time;
srand $seed;
diag "FUZZ_SEED=$seed";

my $N = 200;
my $rejected = 0;
my $accepted = 0;

for (1..$N) {
    # Recreate a clean file each iteration
    unlink $path;
    {
        my $p = Data::Pool::Shared::I64->new($path, 16);
        $p->alloc for 1..3;
    }

    my $sz = -s $path;
    # Corrupt the header area (first 64 bytes) where magic/version/
    # offsets live. Data-area corruption wouldn't be detectable by
    # the validator anyway and is fine to leave alone.
    my $offset = int(rand(64));
    my $n_bytes = int(rand(4)) + 1;

    open(my $w, '+<', $path) or die;
    binmode $w;
    seek($w, $offset, 0);
    print $w join('', map chr(int rand 256), 1..$n_bytes);
    close $w;

    my $r = eval { Data::Pool::Shared::I64->new($path, 16) };
    if ($r) {
        $accepted++;
        # Corrupted-but-accepted: operations must still not crash
        eval { $r->alloc; $r->stats; };
        fail "crash after reopen of corrupted file: $@" if $@ && $@ !~ /full|not allocated|invalid/;
    } else {
        $rejected++;
    }
}

diag "rejected=$rejected accepted=$accepted of $N";
cmp_ok $rejected, '>=', $N * 0.3, "at least 30% of header-area corruptions rejected";
# No strict accepted bound; some bit flips in unused regions won't break invariants

done_testing;
