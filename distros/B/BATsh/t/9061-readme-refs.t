######################################################################
#
# 9061-readme-refs.t  README -> disk reference existence checks
#
# Complements 9060-readme.t (MANIFEST -> README direction) and
# 9070-examples.t (runs MANIFEST .batsh files).  Neither verifies that
# a file *named by the README* actually exists on disk, which is how a
# ghost reference (a sample advertised in the README but absent from the
# distribution) previously slipped through.  This test walks the other
# direction: every in-distribution path the README mentions must exist.
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

my $readme = "$ROOT/README";
my $text   = (-f $readme) ? _slurp($readme) : '';

# Collect every in-distribution file path the README references.  Only the
# project subdirectories are considered; external URLs and ordinary words
# are ignored.  Trailing sentence punctuation is trimmed, and bare
# directory mentions (ending in "/") are skipped.
my %ref;
while ($text =~ m{\b((?:eg|doc|bin|lib|t)/[A-Za-z0-9_][A-Za-z0-9_./-]*)}g) {
    my $p = $1;
    $p =~ s{[.:;)\],]+$}{};
    next if $p =~ m{/$};
    $ref{$p} = 1;
}
my @refs = sort keys %ref;

# Dynamic plan via a closure array (no hardcoded count).  The first check is
# unconditional so the file always emits at least one assertion, even if the
# README happens to reference nothing.
my @tests;
push @tests, sub {
    ok(-f $readme, 'RR0: README exists on disk');
};
for my $rel (@refs) {
    my $path = "$ROOT/$rel";
    push @tests, sub {
        ok(-e $path, "RR: README-referenced $rel exists on disk");
    };
}

plan_tests(scalar(@tests));
$_->() for @tests;

END { end_testing() }
