######################################################################
# 9030-distribution.t  Distribution integrity:
#   MANIFEST, version consistency, META files, Changes, Makefile.PL,
#   test-suite consistency.
# Corresponds to: INA_CPAN_Check categories A, B, F, I, J, L
#
# Categories D, G and H are deliberately not called here: this
# distribution covers them in more depth in t/9020-perl5compat.t,
# t/9050-pod.t and t/9060-readme.t respectively.
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
         + count_I()      + count_J()      + count_L());

check_A($ROOT);
check_B($ROOT);
check_F($ROOT);
check_I($ROOT);
check_J($ROOT);
check_L($ROOT);

END { end_testing() }
