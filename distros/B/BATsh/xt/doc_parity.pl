#!/usr/bin/perl
######################################################################
#
# xt/doc_parity.pl  --  documentation parity gate (maintainer only)
#
# Run before every release:
#
#     perl xt/doc_parity.pl            # from the distribution root
#     perl xt/doc_parity.pl --verbose
#
# Exit status is the number of failed checks, so it can be used as a
# release gate.  This script is NOT run by "make test": it needs
# Pod::Text, whose rendering differs between Perl releases, and a smoker
# must never fail on a formatting difference in the author's toolchain.
#
# ---------------------------------------------------------------------
# WHY THIS EXISTS
#
# Four pre-release reviews in a row turned up "one more thing to fix",
# and every time the finding came from a NEW axis that no earlier review
# had looked at.  The last review found two of them at once:
#
#   * README had grown feature documentation (let, type, command, umask,
#     hash, readonly, mapfile, declare -i/-r, set --, brace expansion,
#     extglob, here-strings, process substitution, select, alias, exec,
#     subshell groups, and a whole EXAMPLES section) that never reached
#     the POD -- so metacpan, which shows the POD, understated what the
#     module does.  Meanwhile the POD had corrections that never reached
#     README.  The two files had drifted in BOTH directions.
#
#   * BATsh::SH kept two hand-maintained copies of its builtin table and
#     the second copy had fallen behind.
#
# Both are the same failure: a fact written down in more than one place,
# with nothing checking that the copies agree.  The cure is not another
# careful review -- it is a check that fails.  Each block below turns one
# of those axes into an assertion.
#
# WHEN YOU ADD A FEATURE, ADD ITS AXIS HERE.  A finding that is fixed but
# not encoded in this file will come back.
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use File::Spec ();

my $VERBOSE = 0;
for my $a (@ARGV) {
    if    ($a eq '--verbose' || $a eq '-v') { $VERBOSE = 1 }
    elsif ($a eq '--help' || $a eq '-h')    { _usage(); exit 0 }
    else { print STDERR "unknown option: $a\n"; _usage(); exit 2 }
}

sub _usage {
    print <<'END_OF_USAGE';
usage: perl xt/doc_parity.pl [--verbose]

Checks that the distribution's documentation matches itself and matches
the code:

  1. README is exactly "pod2text --width=76 lib/BATsh.pm".
  2. Every builtin and keyword BATsh::SH resolves is named in the POD.
  3. Every CMD command BATsh::CMD implements is named in the POD.
  4. BATsh::SH holds only ONE table of builtin names.
  5. The version string agrees everywhere it is written.

Exit status is the number of failed checks (0 = all good).
END_OF_USAGE
    return;
}

my $ROOT = '.';
for my $cand ('.', '..') {
    if (-f File::Spec->catfile($cand, 'lib', 'BATsh.pm')) { $ROOT = $cand; last }
}

my $PM_MAIN = File::Spec->catfile($ROOT, 'lib', 'BATsh.pm');
my $PM_SH   = File::Spec->catfile($ROOT, 'lib', 'BATsh', 'SH.pm');
my $PM_CMD  = File::Spec->catfile($ROOT, 'lib', 'BATsh', 'CMD.pm');
my $README  = File::Spec->catfile($ROOT, 'README');

my $failed = 0;
my $checks = 0;

sub _slurp {
    my ($path) = @_;
    local *FH;
    open(FH, $path) or return undef;
    local $/;
    my $t = <FH>;
    close(FH);
    return $t;
}

sub _check {
    my ($ok, $name, @detail) = @_;
    $checks++;
    if ($ok) {
        print "ok   - $name\n";
    }
    else {
        $failed++;
        print "FAIL - $name\n";
        print "       $_\n" for @detail;
    }
    return $ok ? 1 : 0;
}

# ---------------------------------------------------------------- 1
# README must be the rendered POD, byte for byte.  README is the file a
# PAUSE/metacpan visitor reads first and the POD is what "perldoc BATsh"
# shows; keeping them mechanically identical is the only way they stay
# in step, and it makes the POD the single place to edit.
my $have_podtext = eval { require Pod::Text; 1 } ? 1 : 0;
if (!$have_podtext) {
    print "skip - README/POD parity (Pod::Text not available)\n";
}
else {
    my $rendered = '';
    eval {
        my $parser = Pod::Text->new(width => 76, sentence => 0);
        $parser->output_string(\$rendered);
        $parser->parse_file($PM_MAIN);
        1;
    };
    my $readme = _slurp($README);
    $readme = '' unless defined $readme;
    if (!defined $rendered || $rendered eq '') {
        _check(0, 'README is pod2text --width=76 lib/BATsh.pm',
               'Pod::Text produced no output');
    }
    else {
        my @r = split(/\n/, $rendered, -1);
        my @f = split(/\n/, $readme,   -1);
        my $first;
        for my $k (0 .. ($#r > $#f ? $#r : $#f)) {
            my $a = defined $r[$k] ? $r[$k] : '(missing)';
            my $b = defined $f[$k] ? $f[$k] : '(missing)';
            if ($a ne $b) { $first = $k + 1; last }
        }
        _check(!defined $first,
               'README is pod2text --width=76 lib/BATsh.pm',
               defined $first ? "first difference at README line $first" : (),
               defined $first ? "POD:    " . (defined $r[$first-1] ? $r[$first-1] : '(missing)') : (),
               defined $first ? "README: " . (defined $f[$first-1] ? $f[$first-1] : '(missing)') : (),
               defined $first ? 'regenerate: pod2text --width=76 lib/BATsh.pm > README' : ());
    }
}

# ---------------------------------------------------------------- 2
# Every name BATsh::SH resolves as a builtin or keyword must appear in
# the top-level POD.  This is the check that would have caught "umask",
# "let", "mapfile" and friends living only in README.
my $sh_src = _slurp($PM_SH);
$sh_src = '' unless defined $sh_src;
my $pod_main = _slurp($PM_MAIN);
$pod_main = '' unless defined $pod_main;
my ($pod_body) = ($pod_main =~ /(=head1 NAME.*)/s);
$pod_body = '' unless defined $pod_body;

my @sh_names;
{
    my ($kind_sub) = ($sh_src =~ /sub\s+_sh_name_kind\b(.*?)\n\}/s);
    $kind_sub = '' unless defined $kind_sub;
    while ($kind_sub =~ /qw\(([^)]*)\)/gs) {
        push @sh_names, split(' ', $1);
    }
}
_check(scalar(@sh_names) > 0,
       'builtin/keyword table found in _sh_name_kind()',
       'the parser below depends on its qw() lists');

my @undocumented = ();
for my $n (@sh_names) {
    my $q = quotemeta($n);
    push @undocumented, $n unless $pod_body =~ /(?:\A|[^A-Za-z0-9_])$q(?:[^A-Za-z0-9_]|\z)/;
}
_check(scalar(@undocumented) == 0,
       'every SH builtin/keyword is named in lib/BATsh.pm POD',
       scalar(@undocumented) ? 'missing: ' . join(' ', @undocumented) : ());

# ---------------------------------------------------------------- 3
# Every CMD command BATsh::CMD dispatches must appear in the POD too.
# This is what would have caught REM, CHDIR, MD, RD, ERASE and RENAME.
my $cmd_src = _slurp($PM_CMD);
$cmd_src = '' unless defined $cmd_src;
my %cmd_seen;
while ($cmd_src =~ /eq\s+'([A-Z][A-Z0-9]+)'/g) { $cmd_seen{$1} = 1 }
delete $cmd_seen{'EOF'};   # part of "GOTO :EOF", not a command
my @cmd_names = sort keys %cmd_seen;
my @cmd_missing = ();
for my $c (@cmd_names) {
    push @cmd_missing, $c unless $pod_body =~ /(?:\A|[^A-Za-z0-9_])\Q$c\E(?:[^A-Za-z0-9_]|\z)/;
}
_check(scalar(@cmd_missing) == 0,
       'every CMD command is named in lib/BATsh.pm POD',
       scalar(@cmd_missing) ? 'missing: ' . join(' ', @cmd_missing) : ());

# ---------------------------------------------------------------- 4
# One table, not two.  _sh_word_is_foreground() used to keep a private
# copy of the builtin list; it now asks _sh_name_kind().  Any new hash
# that looks like a builtin table is flagged here so the duplicate
# cannot come back unnoticed.
my $dup = 0;
my @dup_at = ();
{
    my @lines = split(/\n/, $sh_src, -1);
    for my $k (0 .. $#lines) {
        next unless $lines[$k] =~ /(?:export|umask|readonly|mapfile)\s*=>\s*1/;
        $dup++;
        push @dup_at, 'line ' . ($k + 1);
    }
}
_check($dup == 0,
       'BATsh::SH holds only one builtin table',
       scalar(@dup_at) ? 'builtin-table-shaped hash at ' . join(', ', @dup_at) : (),
       $dup ? 'ask _sh_name_kind() instead of writing a second copy' : ());

# ---------------------------------------------------------------- 5
# Version agreement across every file that carries it.
my %ver;
for my $f ('lib/BATsh.pm', 'lib/BATsh/CMD.pm', 'lib/BATsh/SH.pm',
           'lib/BATsh/Env.pm', 'lib/BATsh/MB.pm') {
    my $t = _slurp(File::Spec->catfile($ROOT, split(m{/}, $f)));
    next unless defined $t;
    if ($t =~ /\$VERSION\s*=\s*'([^']+)'/) { $ver{"$f \$VERSION"} = $1 }
    if ($t =~ /=head1 VERSION\s+Version\s+(\S+)/s) { $ver{"$f POD"} = $1 }
}
{
    my $t = _slurp(File::Spec->catfile($ROOT, 'bin', 'batsh.pl'));
    if (defined $t && $t =~ /=head1 VERSION\s+Version\s+(\S+)/s) {
        $ver{'bin/batsh.pl POD'} = $1;
    }
    my $r = _slurp($README);
    if (defined $r && $r =~ /Version\s+(\d+\.\d+)/) { $ver{'README'} = $1 }
    my $c = _slurp(File::Spec->catfile($ROOT, 'Changes'));
    if (defined $c && $c =~ /^(\d+\.\d+)\s/m) { $ver{'Changes'} = $1 }
}
my %distinct = map { ($_ => 1) } values %ver;
_check(scalar(keys %distinct) == 1,
       'the version string agrees in all ' . scalar(keys %ver) . ' places',
       (scalar(keys %distinct) == 1)
           ? ()
           : map { "$_ = $ver{$_}" } sort keys %ver);

# ---------------------------------------------------------------- 6
# No test file may hand PROGRAM TEXT to a child process through argv.
# Rule R9: a "-e" operand carrying '>' (or another cmd.exe metacharacter)
# is cut in half by Windows the moment some other argument on the line
# needs quoting, which a build path with a space in it guarantees.  This
# is the check that would have caught t/9070 before the matrix did -- it
# cost 30 of 90 cells and looked exactly like an interpreter defect.
{
    my @offenders = ();
    local *DIR;
    if (opendir(DIR, File::Spec->catdir($ROOT, 't'))) {
        my @t = sort grep { /\.t\z/ } readdir(DIR);
        closedir(DIR);
        for my $f (@t) {
            my $src = _slurp(File::Spec->catfile($ROOT, 't', $f));
            next unless defined $src;
            my @l = split(/\n/, $src, -1);
            for my $k (0 .. $#l) {
                next unless $l[$k] =~ /system\s*\(/;
                next unless $l[$k] =~ /'-e'|"-e"/;
                push @offenders, "$f line " . ($k + 1);
            }
        }
    }
    _check(scalar(@offenders) == 0,
           'no test hands program text to a child through argv (rule R9)',
           scalar(@offenders) ? 'at: ' . join(', ', @offenders) : (),
           scalar(@offenders) ? 'run bin/batsh.pl instead of perl -e' : ());
}

if ($VERBOSE) {
    print "\n# SH builtins/keywords seen: " . scalar(@sh_names) . "\n";
    print "# CMD commands seen:         " . scalar(@cmd_names) . "\n";
    print '# version:                   '
        . join(', ', sort keys %distinct) . "\n";
}

print "\n$checks check(s), $failed failed.\n";
exit($failed);
