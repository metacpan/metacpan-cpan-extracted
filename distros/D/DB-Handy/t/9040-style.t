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

# The default K3 exemption (env, opts, args) is sufficient: lib/DB/Handy.pm
# no longer takes a reference to a named hash anywhere in its code.
check_K($ROOT);

END { end_testing() }
