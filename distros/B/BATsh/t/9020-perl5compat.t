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
plan_tests(scalar(@pm_files) * 12);

for my $rel (@pm_files) {
    my $path  = "$ROOT/$rel";
    my @lines = _slurp_lines($path);
    my $code  = join('', @lines);
    my $guarded = ($code =~ /if\s*\(\s*\$\]\s*>=\s*5\./);

    ok($code !~ /^\s*use\s+5\.0*[6-9][0-9]*\b/m,
       "$rel P1: no bare use 5.006+");
    # P2: 3-argument open -- both lexical ($fh) and bareword (FH) forms.
    # Detects: open($fh, '<', ...), open(my $fh, '<', ...),
    #          open(FH, '<', ...), open(STDIN, '<', ...)
    # Does NOT flag: open(FH, "<$file"), open(FH, '<&STDIN') (2-arg forms).
    # Key insight: in 3-arg open, the mode is a standalone quoted string
    # ('>' '<' '>>' etc.) followed by another comma. In 2-arg open the mode
    # and filename are combined in one string ("<$file") or use & for dup.
    my $has_3arg =
        ($code =~ /\bopen\s*\(\s*(?:(?:my\s+)?\$\w+|[A-Z_][A-Z0-9_]*)\s*,\s*['"](?:>>?|<<?|\+>|\+<)['"]\s*,/);
    ok(!$has_3arg || $guarded,
       "$rel P2: 3-arg open (lexical or bareword) guarded or absent");
    # P3: lexical filehandle -- open my $fh or open(my $fh, ...)
    # Detects both: open my $fh, ... and open(my $fh, ...)
    my $has_lex = ($code =~ /\bopen\s*[\(\s]\s*my\s+\$\w+/);
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

    # P8: //= (defined-or-assign) operator -- Perl 5.10+
    # Strip comment-only lines before checking to avoid false positives.
    do {
        my $p8_code = join "\n",
            grep { !/^\s*#/ } split /\n/, $code;
        $p8_code =~ s/#[^\n]*//g;   # strip inline comments
        ok($p8_code !~ m{//=},
           "$rel P8: no //= operator (Perl 5.10+)");
    };

    # P9: opendir(my $fh ...) -- Perl 5.6+ lexical dir handle
    my $has_od_lex = ($code =~ /\bopendir\s*[\(\s]+my\s+\$/);
    ok(!$has_od_lex || $guarded,
       "$rel P9: opendir(my \$dh...) guarded or absent");

    # P10: say built-in -- Perl 5.10+
    ok($code !~ /^\s*say\s/m && $code !~ /[;{(]\s*say\s/m,
       "$rel P10: no bare say (Perl 5.10+)");

    # P11: state variables -- Perl 5.10+
    ok($code !~ /\bstate\s+[\$\@\%]/m,
       "$rel P11: no state variable (Perl 5.10+)");

    # P12: // defined-or operator -- Perl 5.10+
    # Genuine defined-or: VAR // EXPR where // is surrounded by spaces.
    # Excludes: split //, m//, s///, =~ //, URLs (://), comments.
    do {
        my $p12_fail = 0;
        for my $p12_line (split /\n/, $code) {
            next if $p12_line =~ /^\s*#/;         # skip full-line comments
            $p12_line =~ s/#[^'"'"'"]*$//;         # strip inline comments
            next if $p12_line =~ /=~\s*[sm]?\//; # skip =~ m// s//
            next if $p12_line =~ /\bsplit\s*\/\//; # skip split //
            next if $p12_line =~ m{:\//};          # skip URLs ://
            # Flag: whitespace // whitespace (not ///  not //=)
            if ($p12_line =~ m{\s//[^/=]}) { $p12_fail = 1; last }
        }
        ok(!$p12_fail || $guarded,
           "$rel P12: // defined-or guarded or absent");
    };

}

END { end_testing() }
