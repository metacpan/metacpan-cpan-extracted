######################################################################
#
# 9020-perl5compat.t  Perl 5.005_03 compatibility checks
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
plan_tests(scalar(@pm_files) * 7);

for my $rel (@pm_files) {
    my $path  = "$ROOT/$rel";
    my @lines = _slurp_lines($path);
    my $code  = join('', @lines);
    my $guarded = ($code =~ /if\s*\(\s*\$\]\s*>=\s*5\./);

    ok($code !~ /^\s*use\s+5\.0*[6-9][0-9]*\b/m,
       "$rel P1: no bare use 5.006+");
    my $has_3arg = ($code =~ /\bopen\s*\(\s*\$\w+\s*,\s*['"][<>]/);
    ok(!$has_3arg || $guarded,
       "$rel P2: 3-arg open guarded or absent");
    my $has_lex = ($code =~ /\bopen\s+my\s+\$\w+/);
    ok(!$has_lex || $guarded,
       "$rel P3: open(my \$fh...) guarded or absent");
    ok($code !~ /^\s*use\s+warnings\s*;/m
       || $code =~ /BEGIN\s*\{[^}]*warnings/,
       "$rel P4: use warnings guarded");
    ok(1, "$rel P5: qr// informational (always pass)");
    ok($code !~ /^\s*use\s+(?:parent|base)\b/m || $guarded,
       "$rel P6: use parent/base guarded or absent");
    ok($code !~ /^\s*our\s+[\$\@\%][A-Za-z]/m,
       "$rel P7: no bare 'our' declaration");
}

END { end_testing() }
