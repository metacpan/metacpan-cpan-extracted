######################################################################
#
# 9010-encoding.t  US-ASCII source encoding check
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

my @pm_files = grep { -f "$ROOT/$_" } map { "lib/$_" }
    qw(BATsh.pm BATsh/Env.pm BATsh/CMD.pm BATsh/SH.pm);

plan_skip('no .pm files found') unless @pm_files;
plan_tests(scalar(@pm_files));

for my $rel (@pm_files) {
    my $path = "$ROOT/$rel";
    my @lines = _slurp_lines($path);
    my ($bad, $lineno) = (0, 0);
    for my $line (@lines) {
        $lineno++;
        if ($line =~ /[^\x0A\x0D\x20-\x7E]/) {
            $bad++;
            diag("non-US-ASCII at $rel line $lineno");
            last;
        }
    }
    ok($bad == 0, "$rel: US-ASCII only");
}

END { end_testing() }
