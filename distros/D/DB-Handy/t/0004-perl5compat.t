######################################################################
#
# 0004-perl5compat.t
#
# Verifies that all .pm files in lib/ use only Perl 5.005_03-compatible
# syntax.  This test runs BEFORE cpan_precheck.t so that source-level
# problems are caught as early as possible.
#
# Checks performed on each .pm file (code sections only; POD and
# __END__ are stripped before scanning):
#
#   P1  No `our` keyword
#   P2  No `say` / `given` / `state` keywords
#   P3  No `my (undef, ...)` list-undef (Perl 5.10+)
#   P4  No defined-or operator  //  (Perl 5.10+)
#       Note: split(//, ...) is exempt (empty regex, valid in 5.005)
#   P5  No `//=` operator (Perl 5.10+)
#   P6  No `...` (yada-yada) operator (Perl 5.12+)
#   P7  No `when` keyword (Perl 5.10+)
#   P8  No `\o{...}` octal escape (Perl 5.14+)
#   P9  No `\x{...}` wide hex escape outside of strings
#         (allowed inside strings/regex, but not as bare syntax)
#   P10 $VERSION self-assignment exists ($VERSION = $VERSION;)
#   P11 warnings stub is present and correct
#   P12 CVE-2016-1238 mitigation: pop @INC in BEGIN block
#
# Perl 5.005_03 compatible (this file itself must pass its own checks).
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

###############################################################################
# Minimal test harness (no Test::More -- must work under 5.005_03)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok {
    my($cond, $name) = @_;
    $T++;
    if ($cond) { $PASS++; print "ok $T - $name\n" }
    else       { $FAIL++; print "not ok $T - $name\n" }
}
sub diag { print "# $_[0]\n" }

###############################################################################
# Helpers
###############################################################################

sub _slurp {
    my($file) = @_;
    local *SLURP_FH;
    open(SLURP_FH, "< $file") or return '';
    local $/;
    my $c = <SLURP_FH>;
    close SLURP_FH;
    return $c;
}

# Return the code section of a .pm file:
#   - strip POD (=head1 ... =cut blocks)
#   - strip from __END__ to EOF
#   - strip single-line comments
sub _code_only {
    my($text) = @_;
    # Strip __END__ and everything after
    $text =~ s/\n__END__\b.*\z//s;
    # Strip POD blocks
    $text =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    return $text;
}

# Scan code lines for a pattern; return list of {line=>N, text=>...}.
# Strips string literals and regex patterns before matching to avoid
# false positives from pattern text appearing in strings.
sub _scan {
    my($code, $pat) = @_;
    my @hits;
    my $lineno = 0;
    for my $line (split /\n/, $code) {
        $lineno++;
        next if $line =~ /^\s*#/;   # comment line
        # Remove string literals (rough heuristic)
        my $clean = $line;
        $clean =~ s/'(?:[^'\\]|\\.)*'/''/g;
        $clean =~ s/"(?:[^"\\]|\\.)*"/""/g;
        # Remove regex literals m//, s///, qr//
        $clean =~ s{(?:s|m|qr)/[^/]*/[^/]*/[gimsex]*}{}g;
        $clean =~ s{/[^/]+/[gimsex]*}{}g;
        # Remove comment portion
        $clean =~ s/#.*$//;
        if ($clean =~ $pat) {
            push @hits, { line => $lineno, text => $line };
        }
    }
    return @hits;
}

###############################################################################
# Discover .pm files
###############################################################################
my $ROOT = "$FindBin::Bin/..";
local *LIBDH;
opendir(LIBDH, "$ROOT/lib/DB") or die "Cannot open lib/DB: $!";
my @pm_files = sort map { "lib/DB/$_" }
               grep { /\.pm$/ } readdir(LIBDH);
closedir LIBDH;

my $pm_count = scalar @pm_files;
# Each file: P1..P9 = 9 scan tests + P10 + P11 + P12 = 12 tests per file
my $TESTS_PER_FILE = 12;
print "1..", $pm_count * $TESTS_PER_FILE, "\n";

###############################################################################
# Run checks on each .pm file
###############################################################################
for my $pm (sort @pm_files) {
    my $text = _slurp("$ROOT/$pm");
    my $code = _code_only($text);

    # ------------------------------------------------------------------
    # P1: no `our` keyword
    # ------------------------------------------------------------------
    my @p1 = _scan($code, qr/\bour\b/);
    ok(!@p1, "P1 - no 'our' keyword: $pm");
    for my $h (@p1) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P2: no say / given / state / when
    # ------------------------------------------------------------------
    my @p2 = _scan($code, qr/\b(?:say|given|state|when)\s*[\(\{]/);
    ok(!@p2, "P2 - no say/given/state/when: $pm");
    for my $h (@p2) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P3: no my(undef,...) list-undef (Perl 5.10+)
    # ------------------------------------------------------------------
    my @p3 = _scan($code, qr/\bmy\s*\(\s*undef/);
    ok(!@p3, "P3 - no my(undef,...): $pm");
    for my $h (@p3) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P4: no defined-or // operator (Perl 5.10+)
    #     Exempt: split(//, ...) which uses an empty regex, not defined-or.
    #     Uses a dedicated scan that does NOT strip // before checking,
    #     so $x // $y is correctly flagged even after string removal.
    # ------------------------------------------------------------------
    my @p4;
    {
        my $lineno = 0;
        for my $raw_line (split /\n/, $code) {
            $lineno++;
            next if $raw_line =~ /^\s*#/;
            my $cl = $raw_line;
            # Remove string literals
            $cl =~ s/'(?:[^'\\]|\\.)*'/'_STR_'/g;
            $cl =~ s/"(?:[^"\\]|\\.)*"/"_STR_"/g;
            # Remove s///, qr//path/flags  (3-part delimited)
            $cl =~ s{\bs/[^/]*/[^/]*/[gimsex]*}{}g;
            $cl =~ s{\bqr/[^/]*/[gimsex]*}{}g;
            # Remove split // (empty regex -- exempt)
            $cl =~ s{\bsplit\s*/[^/]*/[gimsex]*}{}g;
            # Remove m/non-empty-pattern/ (single-slash regex, non-empty)
            $cl =~ s{(?<![/])/(?!/)([^/\n]+)/[gimsex]*}{}g;
            # Remove comment
            $cl =~ s/#.*$//;
            # Detect remaining //  (defined-or operator)
            if ($cl =~ /(?:[\w\$\)\}\]])\s*\/\//) {
                push @p4, { line => $lineno, text => $raw_line };
            }
        }
    }
    ok(!@p4, "P4 - no defined-or // operator: $pm");
    for my $h (@p4) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P5: no //= operator (Perl 5.10+)
    # ------------------------------------------------------------------
    my @p5 = _scan($code, qr/\/\/=/);
    ok(!@p5, "P5 - no //= operator: $pm");
    for my $h (@p5) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P6: no ... (yada-yada) operator (Perl 5.12+)
    # ------------------------------------------------------------------
    my @p6 = _scan($code, qr/(?<![\.])\.\.\.(?![\.])/);
    ok(!@p6, "P6 - no yada-yada ...: $pm");
    for my $h (@p6) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P7: no `when` as statement keyword (Perl 5.10+ given/when)
    # ------------------------------------------------------------------
    my @p7 = _scan($code, qr/\bwhen\s*\(/);
    ok(!@p7, "P7 - no 'when' keyword: $pm");
    for my $h (@p7) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P8: no \o{...} octal escape (Perl 5.14+)
    # ------------------------------------------------------------------
    my @p8 = _scan($code, qr/\\o\{/);
    ok(!@p8, "P8 - no \\o{} octal escape: $pm");
    for my $h (@p8) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P9: no \x{NN} wide-character hex escape outside string context
    #     (bare \x{} in code suggests non-ASCII intent)
    # ------------------------------------------------------------------
    my @p9 = _scan($code, qr/\\x\{[0-9a-fA-F]{3,}\}/);
    ok(!@p9, "P9 - no wide \\x{} hex escape: $pm");
    for my $h (@p9) { diag("  line $h->{line}: $h->{text}") }

    # ------------------------------------------------------------------
    # P10: $VERSION self-assignment present
    # ------------------------------------------------------------------
    my $p10 = ($text =~ /\$VERSION\s*=\s*\$VERSION/);
    ok($p10, "P10 - \$VERSION self-assignment present: $pm");

    # ------------------------------------------------------------------
    # P11: warnings compatibility stub
    # ------------------------------------------------------------------
    my $p11 = ($text =~ /\$INC\{'warnings\.pm'\}\s*=.*?eval\s*['"]package warnings;\s*sub import/s);
    ok($p11, "P11 - warnings compat stub present: $pm");

    # ------------------------------------------------------------------
    # P12: CVE-2016-1238 mitigation (pop @INC in BEGIN)
    # ------------------------------------------------------------------
    my $p12 = ($text =~ /BEGIN\s*\{[^}]*pop\s+\@INC[^}]*\}/s);
    ok($p12, "P12 - CVE-2016-1238 pop \@INC in BEGIN: $pm");
}

exit($FAIL ? 1 : 0);
