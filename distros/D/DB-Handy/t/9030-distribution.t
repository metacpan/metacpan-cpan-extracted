######################################################################
# 9030-distribution.t  Distribution integrity:
#   MANIFEST, version consistency, META files, Changes, Makefile.PL,
#   test-suite consistency.
# Corresponds to: cpan_precheck categories A, B, F, H, I, J
######################################################################
use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

plan_skip('MANIFEST not found') unless -f "$ROOT/MANIFEST";

plan_tests(count_A($ROOT) + count_B($ROOT) + count_F()
         + count_H()      + count_I()      + count_J($ROOT));

check_A($ROOT);
check_B($ROOT);
check_F($ROOT);
check_H($ROOT);
check_I($ROOT);

# DB-Handy specific J2 stale entries
check_J($ROOT,
    j2_stale => [
        'No INTERSECT or EXCEPT set operations',
        'Range scans do not use indexes',
        'CHECK.*evaluated on INSERT only',
    ]
);

END { end_testing() }
