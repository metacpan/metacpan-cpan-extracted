#!/usr/bin/env perl
# PDL interop: Data::NDArray::Shared <-> PDL.  Shows the copy round-trip, the
# zero-copy alias (PDL ops writing straight through to the shared mapping), and a
# cross-process PDL transform on one shared array.
#
# Requires: PDL
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);

unless (eval { require PDL; PDL->import; 1 }) {
    warn "PDL not installed; skipping the PDL interop demo (cpanm PDL to run it)\n";
    exit 0;
}

use Data::NDArray::Shared;
$| = 1;

# Axis order: this array is row-major (C-order); PDL's first dim is the
# fastest-varying axis, so shapes are reversed across the boundary -- an (r, c)
# array becomes PDL dims (c, r).  to_pdl/from_pdl handle that for you.

# 1) copy round-trip: NDArray -> PDL -> compute -> a new shared array
print "=== 1. copy round-trip (to_pdl / from_pdl) ===\n";
my $a = Data::NDArray::Shared->new(undef, "f64", 3, 4);   # 3x4 matrix
$a->set_flat($_, $_) for 0 .. 11;                          # 0..11 row-major
my $p = $a->to_pdl;
printf "  NDArray shape (%s) -> PDL dims (%s)\n", join(",", $a->shape), join(",", $p->dims);
my $b = Data::NDArray::Shared->from_pdl($p * 10 + 1);      # PDL expression -> new array
printf "  PDL (x*10+1) -> NDArray row 0: %s\n", join(" ", map { $b->get(0, $_) } 0 .. 3);

# 2) zero-copy alias: a PDL view of the same mmap; in-place ops write through
print "\n=== 2. zero-copy alias (as_pdl_alias) ===\n";
my $img = Data::NDArray::Shared->new(undef, "f32", 4, 4);
$img->set_flat($_, $_) for 0 .. 15;
my $view = $img->as_pdl_alias;                            # aliases img's shared buffer
$view .= sqrt($view);                                     # PDL in-place -> no copy
printf "  after PDL in-place sqrt, NDArray get_flat(9)=%.4f (sqrt(9)=3)\n", $img->get_flat(9);

# 3) cross-process: a worker runs a PDL transform on the shared array in place.
#    The alias bypasses the rwlock, so coordinate access -- here the parent simply
#    waits for the child, so nothing touches the array concurrently.
print "\n=== 3. cross-process PDL transform on one shared array ===\n";
my $shared = Data::NDArray::Shared->new_memfd('ndpdl-demo', "f64", 1000);
$shared->set_flat($_, $_ - 500) for 0 .. 999;            # -500 .. 499
my $fd = $shared->memfd;
printf "  parent: filled 1000 cells, min=%.0f sum=%.0f\n", $shared->min, $shared->sum;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: reopen the same mapping, alias it, apply a ReLU (max(x,0)) in PDL,
    # writing straight back into the shared memory the parent will read.
    my $c = Data::NDArray::Shared->new_from_fd($fd);
    my $v = $c->as_pdl_alias;
    $v .= ($v > 0) * $v;                                  # ReLU, in place
    _exit(0);
}
waitpid($pid, 0);
printf "  parent: after child's PDL ReLU, min=%.0f sum=%.0f (negatives zeroed)\n",
    $shared->min, $shared->sum;
