######################################################################
# 9040-style.t  ina@CPAN coding style checks.
# Corresponds to: cpan_precheck categories E, K
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

plan_tests(count_E($ROOT) + count_K($ROOT));

check_E($ROOT);

# DB-Handy specific K3 exempt variables: %sch %outer_row %opts %attr
check_K($ROOT, k3_exempt => 'sch\b|outer_row\b|opts\b|attr\b');

END { end_testing() }
