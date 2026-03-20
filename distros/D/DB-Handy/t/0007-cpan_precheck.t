######################################################################
#
# SYNOPSIS
#   prove -l t/0007-cpan_precheck.t        # from the distribution root
#   perl t/0007-cpan_precheck.t            # same
#
# DESCRIPTION
#   Systematically verifies that a distribution directory is ready
#   to upload to CPAN.  Checks are grouped into lettered categories:
#
#     A  File structure      (MANIFEST completeness)
#     B  Version consistency ($VERSION vs META.yml/json/Changes/Makefile.PL)
#     C  Encoding hygiene    (US-ASCII only, no trailing whitespace)
#     D  Perl 5.005_03 compat (warnings stub, forbidden keywords, CVE fix)
#     E  ina@CPAN code style (} else { on same line is a violation)
#     F  META file integrity (YAML/JSON validity, minimum_perl_version)
#     G  POD completeness    (NAME / SYNOPSIS / DESCRIPTION / balanced =cut)
#     H  Changes format      (version+date header, non-empty entry body)
#     I  Makefile.PL         (WriteMakefile present, NAME/VERSION/AUTHOR)
#
# EXIT CODE
#   0 = all tests passed
#   1 = one or more tests failed
#
# COMPATIBILITY
#   Perl 5.005_03 and later.  No non-core dependencies.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec;
use FindBin;

# This file lives in  t/  so the distribution root is one level up.
my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir)
);

######################################################################
# Minimal TAP harness (no Test::More required)
######################################################################

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);

sub plan_tests {
    $T_PLAN = $_[0];
    print "1..$T_PLAN\n";
}

sub plan_skip {
    print "1..0 # SKIP $_[0]\n";
    exit 0;
}

sub ok {
    my($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}

sub diag {
    for my $line (@_) {
#       print "# $line\n";
    }
}

END { exit 1 if $T_PLAN && $T_FAIL }

######################################################################
# Utility helpers
######################################################################

# Slurp a text file, returning lines as a list (undef on failure).
sub _slurp_lines {
    my($path) = @_;
    local *FH;
    open FH, "< $path" or return undef;
    my @lines = <FH>;
    close FH;
    return @lines;
}

# Read a file as a single string (binary-safe).
sub _slurp {
    my($path) = @_;
    local *FH;
    open FH, "< $path" or return undef;
    binmode FH;
    local $/;
    my $content = <FH>;
    close FH;
    return $content;
}

# Parse MANIFEST: return list of (non-blank, non-comment) filenames.
# Returns bare filenames exactly as written in MANIFEST (no $ROOT prefix).
# Callers must prepend $ROOT themselves when accessing files on disk.
sub _manifest_files {
    my @lines = _slurp_lines("$ROOT/MANIFEST");
    return () unless @lines;
    my @files;
    for my $line (@lines) {
        chomp $line;
        $line =~ s/\s.*$//;     # strip optional inline comment
        push @files, $line if length $line;
    }
    return @files;
}

# Collect .pm files from lib/ subtree.
sub _find_pm {
    my($dir, $out) = @_;
    $out ||= [];
    local *DH;
    opendir DH, $dir or return $out;
    my @entries = sort readdir DH;
    closedir DH;
    for my $e (@entries) {
        next if $e eq '.' || $e eq '..';
        my $path = "$dir/$e";
        if (-d $path) {
            _find_pm($path, $out);
        }
        elsif ($e =~ /\.pm$/ && -f $path) {
            push @$out, $path;
        }
    }
    return $out;
}

# Collect .pm and .t files from MANIFEST (or fallback to lib/+t/).
sub _manifest_pm_and_t {
    my @all   = _manifest_files();
    my @found = grep { /\.(pm|t)$/ && -f "$ROOT/$_" } @all;
    return @found if @found;
    # Fallback: scan lib/ and t/ under $ROOT
    my @fb;
    for my $dir ('lib', 't') {
        _find_pm("$ROOT/$dir", \@fb) if -d "$ROOT/$dir";
    }
    # Convert absolute paths back to root-relative for display consistency
    for my $p (@fb) {
        $p =~ s{^\Q$ROOT\E[/\\]}{};
    }
    return @fb;
}

# Extract the $VERSION string from a .pm file.
sub _pm_version {
    my($path) = @_;
    my @lines = _slurp_lines($path);
    return undef unless @lines;
    for my $line (@lines) {
        # Match:  $VERSION = '1.23';   or  $VERSION = "1.23";
        if ($line =~ /^\$VERSION\s*=\s*['"]([^'"]+)['"]/) {
            return $1;
        }
    }
    return undef;
}

# Tiny JSON string extractor: return value for a top-level key.
# Handles  "key": "value"  patterns only (sufficient for META.json).
sub _json_str {
    my($json, $key) = @_;
    if ($json =~ /"$key"\s*:\s*"([^"]+)"/) {
        return $1;
    }
    return undef;
}

# Naive YAML scalar extractor: return value for a top-level key.
sub _yaml_str {
    my($yaml, $key) = @_;
    if ($yaml =~ /^$key\s*:\s*['"]?([^\n'"]+?)['"]?\s*$/m) {
        return $1;
    }
    return undef;
}

# Parse "provides" version from META.yml or META.json.
#   returns hashref  { 'Package::Name' => '1.23', ... }
sub _provides_versions_yml {
    my($yaml) = @_;
    my %prov;
    # Match blocks like:  PackageName:\n    file: ...\n    version: 1.23
    while ($yaml =~ /^  ([A-Za-z][A-Za-z0-9:_]*):\s*\n(?:[ \t]+\S[^\n]*\n)*?[ \t]+version:\s*['"]?(\S+?)['"]?\s*$/mg) {
        $prov{$1} = $2;
    }
    return \%prov;
}

sub _provides_versions_json {
    my($json) = @_;
    my %prov;
    # Match: "Package::Name": { ... "version": "1.23" ... }
    while ($json =~ /"([A-Za-z][A-Za-z0-9:_]*)"\s*:\s*\{[^}]*?"version"\s*:\s*"([^"]+)"[^}]*?\}/sg) {
        $prov{$1} = $2;
    }
    return \%prov;
}

# Check a single file for code-level patterns (skips POD and heredocs).
# Returns list of { line => N, text => '...' } hashrefs for each match.
sub _scan_code {
    my($path, $pattern) = @_;
    my @hits;
    local *FH;
    open FH, "< $path" or return ();
    my ($in_pod, $in_heredoc, $lineno) = (0, 0, 0);
    while (my $line = <FH>) {
        $lineno++;
        if ($in_heredoc) {
            $in_heredoc = 0 if $line =~ /^\Q$in_heredoc\E\s*$/;
            next;
        }
        if ($line =~ /<<['"]?(\w+)['"]?/) { $in_heredoc = $1 }
        $in_pod = 1 if $line =~ /^=[a-zA-Z]/;
        if ($line =~ /^=cut/) { $in_pod = 0; next }
        next if $in_pod;
        next if $line =~ /^\s*#/;
        if ($line =~ $pattern) {
            push @hits, { line => $lineno, text => $line };
        }
    }
    close FH;
    return @hits;
}

######################################################################
# Main: discover the distribution
######################################################################

# This file lives in t/; the distribution root is $ROOT (one level up).
plan_skip("MANIFEST not found under $ROOT")
    unless -f "$ROOT/MANIFEST";

my @manifest_files = _manifest_files();
plan_skip('MANIFEST is empty') unless @manifest_files;

# Find the primary .pm file(s): MANIFEST entries that are .pm files.
# @manifest_files contains root-relative paths (e.g. "lib/Foo/Bar.pm").
my @pm_files = grep { /\.pm$/ && -f "$ROOT/$_" } @manifest_files;
unless (@pm_files) {
    # Fallback: scan $ROOT/lib/
    my @abs = @{ _find_pm("$ROOT/lib") };
    for my $p (@abs) { $p =~ s{^\Q$ROOT\E[/\\]}{} }
    @pm_files = @abs;
}
plan_skip('No .pm files found') unless @pm_files;

# Sort lib/Foo/Bar.pm before others so it becomes the "primary" module.
my @sorted_pm = sort { length($a) <=> length($b) || $a cmp $b } @pm_files;
my $primary_pm = $sorted_pm[0];

# Read primary module version now (used in multiple categories).
my $pm_version = _pm_version("$ROOT/$sorted_pm[0]");

# Build test count dynamically:
# We count all planned tests below.

# --- Count tests per category ---
# A: 1 (MANIFEST exists, already passed) + scalar(@manifest_files) + 7 + 1
my @required_files = qw(Changes Makefile.PL MANIFEST META.yml META.json README LICENSE);
my $count_A = scalar(@manifest_files) + scalar(@required_files) + 1;

# B: 1 per pm * 6 checks + 1 (Changes)
my $count_B = scalar(@sorted_pm) * 6 + 1;

# C: MANIFEST files (ASCII) + pm+t (trailing ws) + pm+t (final newline)
my @pm_and_t = _manifest_pm_and_t();
my $count_C  = scalar(@manifest_files) + 2 * scalar(@pm_and_t);

# D: per pm: D1 D2 D3 D4 D5 D6 = 6 checks each
my $count_D = scalar(@sorted_pm) * 6;

# E: per pm+t file
my $count_E = scalar(@pm_and_t);

# F: 5 checks
my $count_F = 5;

# G: per pm: G1 G2 G3 G4 = 4 checks
my $count_G = scalar(@sorted_pm) * 4;

# H: 3 checks
my $count_H = 3;

# I: 3 checks
my $count_I = 3;

my $total = $count_A + $count_B + $count_C + $count_D
          + $count_E + $count_F + $count_G + $count_H + $count_I;

plan_tests($total);

######################################################################
# Category A: File Structure
######################################################################

diag('');
diag('=== Category A: File Structure ===');

# A: All MANIFEST files exist on disk
for my $f (@manifest_files) {
    ok(-e "$ROOT/$f", "A - MANIFEST file exists: $f");
}

# A: Required files are in MANIFEST
my %in_manifest = map { $_ => 1 } @manifest_files;
for my $req (@required_files) {
    ok($in_manifest{$req}, "A - required file in MANIFEST: $req");
}

# A: At least one .pm is in MANIFEST
ok(scalar(grep { /\.pm$/ } @manifest_files) > 0, 'A - at least one .pm in MANIFEST');

######################################################################
# Category B: Version Consistency
######################################################################

diag('');
diag('=== Category B: Version Consistency ===');

# Load META files once
my $meta_yml_text  = _slurp("$ROOT/META.yml")    || '';
my $meta_json_text = _slurp("$ROOT/META.json")   || '';
my $makefile_text  = _slurp("$ROOT/Makefile.PL") || '';

for my $pm (@sorted_pm) {
    my $ver = _pm_version("$ROOT/$pm");

    # B1: $VERSION is defined
    ok(defined $ver, "B - \$VERSION defined in $pm");
    $ver = '(undef)' unless defined $ver;

    # B2: META.yml version matches
    my $yml_ver = _yaml_str($meta_yml_text, 'version');
    my $b2 = defined $yml_ver && $yml_ver eq $ver;
    ok($b2, "B - META.yml version (${\($yml_ver||'undef')}) eq \$VERSION ($ver)");
    diag("  META.yml=${\($yml_ver||'undef')}  pm=$ver") unless $b2;

    # B3: META.json version matches
    my $json_ver = _json_str($meta_json_text, 'version');
    my $b3 = defined $json_ver && $json_ver eq $ver;
    ok($b3, "B - META.json version (${\($json_ver||'undef')}) eq \$VERSION ($ver)");
    diag("  META.json=${\($json_ver||'undef')}  pm=$ver") unless $b3;

    # B4: Makefile.PL VERSION matches
    my $mk_ver;
    if ($makefile_text =~ /'VERSION'\s*=>\s*q\{([^}]+)\}/) {
        $mk_ver = $1;
    }
    elsif ($makefile_text =~ /'VERSION'\s*=>\s*['"]([^'"]+)['"]/) {
        $mk_ver = $1;
    }
    my $b4 = defined $mk_ver && $mk_ver eq $ver;
    ok($b4, "B - Makefile.PL VERSION (${\($mk_ver||'undef')}) eq \$VERSION ($ver)");
    diag("  Makefile.PL=${\($mk_ver||'undef')}  pm=$ver") unless $b4;

    # B5: Changes top version entry matches
    my @changes_lines = _slurp_lines("$ROOT/Changes");
    my $changes_ver;
    for my $line (@changes_lines) {
        if ($line =~ /^(\d+\.\d+[\w.]*)/) {
            $changes_ver = $1;
            last;
        }
    }
    my $b5 = defined $changes_ver && $changes_ver eq $ver;
    ok($b5, "B - Changes top version (${\($changes_ver||'undef')}) eq \$VERSION ($ver)");
    diag("  Changes=${\($changes_ver||'undef')}  pm=$ver") unless $b5;

    # B6: META.yml provides versions all match
    my $prov_yml = _provides_versions_yml($meta_yml_text);
    my @yml_mismatch;
    for my $pkg (sort keys %$prov_yml) {
        if ($prov_yml->{$pkg} ne $ver) {
            push @yml_mismatch, "$pkg=$prov_yml->{$pkg}";
        }
    }
    my $b6 = @yml_mismatch == 0 && %$prov_yml;
    ok($b6, "B - META.yml provides versions all eq \$VERSION ($ver) in $pm");
    diag("  mismatch: @yml_mismatch") if @yml_mismatch;
    diag('  (no provides entries found in META.yml)') unless %$prov_yml;
}

# B7: META.json provides versions all match
my $prov_json = _provides_versions_json($meta_json_text);
my @json_mismatch;
for my $pkg (sort keys %$prov_json) {
    if (defined $pm_version && $prov_json->{$pkg} ne $pm_version) {
        push @json_mismatch, "$pkg=$prov_json->{$pkg}";
    }
}
my $b7 = @json_mismatch == 0 && %$prov_json;
ok($b7, "B - META.json provides versions all eq \$VERSION (${\($pm_version||'undef')})");
diag("  mismatch: @json_mismatch") if @json_mismatch;
diag('  (no provides entries found in META.json)') unless %$prov_json;

######################################################################
# Category C: Encoding Hygiene
######################################################################

diag('');
diag('=== Category C: Encoding Hygiene ===');

# C1: All MANIFEST files are US-ASCII only
for my $f (@manifest_files) {
    my $abs = "$ROOT/$f";
    unless (-f $abs) {
        ok(0, "C - US-ASCII: $f (file missing)");
        next;
    }
    local *FH;
    open FH, "< $abs" or do { ok(0, "C - US-ASCII: $f (cannot open)"); next };
    binmode FH;
    my ($bad, $lineno) = (0, 0);
    while (<FH>) {
        $lineno++;
        if (/[^\x00-\x7F]/) { $bad = $lineno; last }
    }
    close FH;
    ok(!$bad, "C - US-ASCII only: $f");
    diag("  first non-ASCII at line $bad") if $bad;
}

# C2: No trailing whitespace in .pm / .t files
for my $f (@pm_and_t) {
    my @lines = _slurp_lines("$ROOT/$f");
    my @bad;
    my $n = 0;
    for my $line (@lines) {
        $n++;
        push @bad, $n if $line =~ /[ \t]+\n$/ || ($line =~ /[ \t]+$/ && $line !~ /\n$/);
    }
    ok(@bad == 0, "C - no trailing whitespace: $f");
    if (@bad) {
        my $show = join ', ', @bad[0 .. ($#bad < 4 ? $#bad : 4)];
        diag("  trailing whitespace at lines: $show" . (@bad > 5 ? ' ...' : ''));
    }
}

# C3: Files end with a newline
for my $f (@pm_and_t) {
    my $content = _slurp("$ROOT/$f");
    if (defined $content && length $content) {
        ok(substr($content, -1) eq "\n", "C - ends with newline: $f");
    }
    else {
        ok(1, "C - ends with newline: $f (empty file, skipped)");
    }
}

######################################################################
# Category D: Perl 5.005_03 Compatibility
######################################################################

diag('');
diag('=== Category D: Perl 5.005_03 Compatibility ===');

for my $pm (@sorted_pm) {
    my @lines = _slurp_lines("$ROOT/$pm");
    my $code = join('', @lines);

    # D1: warnings stub has correct form: includes import() method
    my $d1 = $code =~ /\$INC\{'warnings\.pm'\}\s*=.*?eval\s*['"]package warnings;\s*sub import/s;
    ok($d1, "D - warnings stub includes import() sub: $pm");
    diag("  expected: \$INC{'warnings.pm'} = ...; eval 'package warnings; sub import {}'") unless $d1;

    # D2: no `our` keyword in code (POD-exempt via _scan_code)
    my @our_hits = _scan_code("$ROOT/$pm", qr/\bour\b/);
    ok(@our_hits == 0, "D - no 'our' keyword in code: $pm");
    for my $h (@our_hits) {
        diag("  line $h->{line}: $h->{text}");
    }

    # D3: no 5.6+ exclusive syntax: say / given / state
    my @syn_hits = _scan_code("$ROOT/$pm", qr/\b(?:say|given|state)\s*[\(\{]/);
    ok(@syn_hits == 0, "D - no 5.6+ syntax (say/given/state): $pm");
    for my $h (@syn_hits) {
        diag("  line $h->{line}: $h->{text}");
    }

    # D4: no my (undef, ...) list undef (5.10+)
    my @undef_hits = _scan_code("$ROOT/$pm", qr/\bmy\s*\(\s*undef\b/);
    ok(@undef_hits == 0, "D - no 'my (undef, ...)' (5.10+ only): $pm");
    for my $h (@undef_hits) {
        diag("  line $h->{line}: $h->{text}");
    }

    # D5: $VERSION self-assignment exists  ($VERSION = $VERSION;)
    my $d5 = $code =~ /\$VERSION\s*=\s*\$VERSION/;
    ok($d5, "D - \$VERSION self-assignment present: $pm");
    diag("  missing: \$VERSION = \$VERSION; (suppresses 'used only once' warning)") unless $d5;

    # D6: CVE-2016-1238 mitigation in BEGIN block
    my $d6 = $code =~ /BEGIN\s*\{[^}]*pop\s+\@INC[^}]*\}/s
          || $code =~ /pop \@INC if \$INC\[-1\] eq '\.'/ ;
    ok($d6, "D - CVE-2016-1238 mitigation (pop \@INC): $pm");
    diag("  missing: BEGIN { pop \@INC if \$INC[-1] eq '.' }") unless $d6;
}

######################################################################
# Category E: ina@CPAN Coding Style
######################################################################

diag('');
diag('=== Category E: ina@CPAN Coding Style ===');

# E1: No '} else {' or '} elsif ... {' on the same line as '}'
for my $f (@pm_and_t) {
    my @hits = _scan_code("$ROOT/$f", qr/^\s*\}\s*els(?:e|if)\b/);
    ok(@hits == 0, "E - no '} else/elsif' on same line: $f");
    for my $h (@hits) {
        diag("  line $h->{line}: $h->{text}");
    }
}

######################################################################
# Category F: META File Integrity
######################################################################

diag('');
diag('=== Category F: META File Integrity ===');

# F1: META.yml basic YAML sanity (key: value pairs reachable)
my $f1 = $meta_yml_text =~ /^name\s*:/m
      && $meta_yml_text =~ /^version\s*:/m
      && $meta_yml_text =~ /^license\s*:/m;
ok($f1, 'F - META.yml contains name/version/license keys');

# F2: META.json is valid JSON (minimal: outer braces, version key)
my $f2 = $meta_json_text =~ /^\s*\{/s
      && $meta_json_text =~ /\}\s*$/s
      && $meta_json_text =~ /"version"\s*:/;
ok($f2, 'F - META.json appears to be valid JSON');

# F3: META.yml minimum_perl_version is 5.00503
my $min_perl = _yaml_str($meta_yml_text, 'minimum_perl_version');
my $f3 = defined $min_perl && $min_perl eq '5.00503';
ok($f3, "F - META.yml minimum_perl_version is 5.00503 (got: ${\($min_perl||'undef')})");

# F4: META.yml author contains ina@cpan.org
my $f4 = $meta_yml_text =~ /ina\@cpan\.org/;
ok($f4, 'F - META.yml author contains ina@cpan.org');

# F5: META.yml provides section exists and is non-empty
my $prov_yml_chk = _provides_versions_yml($meta_yml_text);
my $f5 = %$prov_yml_chk;
ok($f5, 'F - META.yml provides section is non-empty');
if (!$f5) {
    diag('  No provides entries found. Add provides: to META.yml');
}

######################################################################
# Category G: POD Completeness
######################################################################

diag('');
diag('=== Category G: POD Completeness ===');

for my $pm (@sorted_pm) {
    my $text = _slurp("$ROOT/$pm") || '';

    # G1: =head1 NAME
    ok($text =~ /^=head1\s+NAME\b/m, "G - =head1 NAME present: $pm");

    # G2: =head1 SYNOPSIS
    ok($text =~ /^=head1\s+SYNOPSIS\b/m, "G - =head1 SYNOPSIS present: $pm");

    # G3: =head1 DESCRIPTION
    ok($text =~ /^=head1\s+DESCRIPTION\b/m, "G - =head1 DESCRIPTION present: $pm");

    # G4: every =pod / =head is eventually closed by =cut
    my @pod_opens = ($text =~ /^=(?:pod|head\d|over|begin|for)\b/mg);
    my @pod_cuts  = ($text =~ /^=cut\b/mg);
    # Heuristic: number of =cut must be >= 1 if any pod markers exist
    my $g4 = !@pod_opens || @pod_cuts >= 1;
    ok($g4, "G - POD sections closed by =cut: $pm");
    unless ($g4) {
        diag("  ${\scalar @pod_opens} opening POD directives, ${\scalar @pod_cuts} =cut found");
    }
}

######################################################################
# Category H: Changes File Format
######################################################################

diag('');
diag('=== Category H: Changes File Format ===');

my @changes_lines = _slurp_lines("$ROOT/Changes");

# H1: Changes file is non-empty
ok(@changes_lines > 0, 'H - Changes file is non-empty');

# H2: First version-like entry has proper format: VERSION  DATE
my $top_entry = '';
for my $line (@changes_lines) {
    if ($line =~ /^\d+\.\d+/) {
        $top_entry = $line;
        last;
    }
}
chomp $top_entry;
# Accept: "1.05  2026-02-23" or "1.05  2026-02-23 JST (...)"
my $h2 = $top_entry =~ /^\d+\.\d+[\w.]*\s+\d{4}-\d{2}-\d{2}/;
ok($h2, "H - latest Changes entry has VERSION + DATE format: '$top_entry'");

# H3: Entry body (indented lines after version header) is non-empty
my $found_header = 0;
my $found_body   = 0;
for my $line (@changes_lines) {
    if (!$found_header && $line =~ /^\d+\.\d+/) {
        $found_header = 1;
        next;
    }
    if ($found_header) {
        last if $line =~ /^\d+\.\d+/;  # next entry starts
        if ($line =~ /^\s+\S/) { $found_body = 1; last }
    }
}
ok($found_body, 'H - latest Changes entry has indented description body');

######################################################################
# Category I: Makefile.PL
######################################################################

diag('');
diag('=== Category I: Makefile.PL ===');

# I1: WriteMakefile is called
my $i1 = $makefile_text =~ /WriteMakefile\s*\(/;
ok($i1, 'I - Makefile.PL calls WriteMakefile()');

# I2: NAME and VERSION keys are present
my $i2 = $makefile_text =~ /'NAME'\s*=>/ && $makefile_text =~ /'VERSION'\s*=>/;
ok($i2, "I - Makefile.PL contains NAME and VERSION keys");

# I3: AUTHOR contains ina@cpan.org
my $i3 = $makefile_text =~ /ina\@cpan\.org/;
ok($i3, 'I - Makefile.PL AUTHOR contains ina@cpan.org');

__END__

=head1 NAME

07-cpan_precheck.t - ina@CPAN pre-publication release check suite

=head1 SYNOPSIS

  prove -l t/07-cpan_precheck.t        # from the distribution root
  perl t/07-cpan_precheck.t            # same

=head1 DESCRIPTION

Runs a comprehensive set of TAP-compatible checks against the
distribution whose C<t/> directory contains this file.  The distribution
root is located automatically as the parent directory of C<t/> via
C<FindBin>; there is no need to C<cd> first or pass any arguments.

=head2 Check Categories

=over 4

=item B<A - File Structure>

Verifies that every file listed in MANIFEST exists on disk, and that
the seven required distribution files are all present in MANIFEST:
C<Changes>, C<Makefile.PL>, C<MANIFEST>, C<META.yml>, C<META.json>,
C<README>, C<LICENSE>.

=item B<B - Version Consistency>

Extracts C<$VERSION> from each C<.pm> file and confirms that the same
string appears in C<META.yml>, C<META.json>, C<Makefile.PL>, the top
entry of C<Changes>, and every C<provides:> block in both META files.

=item B<C - Encoding Hygiene>

Confirms that every file in MANIFEST contains only US-ASCII bytes
(0x00-0x7F), that no C<.pm> or C<.t> file has trailing whitespace on
any line, and that each such file ends with a newline character.

=item B<D - Perl 5.005_03 Compatibility>

For each C<.pm> file, checks:

=over 4

=item D1 warnings stub includes C<sub import {}>

The correct idiom is:

  BEGIN { if ($] < 5.006) {
      $INC{'warnings.pm'} = 'stub';
      eval 'package warnings; sub import {}'
  } } use warnings;

A stub that only sets C<$INC{'warnings.pm'}> without providing
C<import()> causes C<Can't locate object method 'import'> on 5.005_03.

=item D2 No C<our> keyword

C<our> was introduced in Perl 5.6.  Use bare package variables instead.

=item D3 No 5.6+ exclusive syntax

C<say>, C<given>, and C<state> are not available in 5.005_03.

=item D4 No C<my (undef, ...)>

Discarding list elements with C<undef> in a C<my()> declaration
requires Perl 5.10.

=item D5 C<$VERSION> self-assignment

C<$VERSION = $VERSION;> suppresses the I<"used only once"> warning
under C<use strict> without requiring C<our>.

=item D6 CVE-2016-1238 mitigation

  BEGIN { pop @INC if $INC[-1] eq '.' }

removes the current directory from the module search path, preventing
injection of malicious modules placed in C<.>.

=back

=item B<E - ina@CPAN Coding Style>

Detects the pattern C<} else {> or C<} elsif ... {> on the same line
as the closing brace of the previous block.  In ina@CPAN style,
C<else>/C<elsif> must always appear on a new line.  POD sections and
heredocs are excluded from the scan.

=item B<F - META File Integrity>

Checks that C<META.yml> contains the mandatory C<name>, C<version>,
and C<license> keys; that C<META.json> is structurally valid JSON; that
C<minimum_perl_version> is C<5.00503>; that C<ina@cpan.org> appears in
the author field; and that the C<provides:> section is non-empty.

=item B<G - POD Completeness>

Confirms that each C<.pm> contains C<=head1 NAME>, C<=head1 SYNOPSIS>,
and C<=head1 DESCRIPTION>, and that every POD opening directive is
matched by at least one C<=cut>.

=item B<H - Changes File Format>

Verifies that C<Changes> is non-empty, that the topmost version entry
follows the C<VERSION  YYYY-MM-DD> convention, and that the entry body
contains at least one indented description line.

=item B<I - Makefile.PL>

Confirms that C<WriteMakefile()> is called, that C<NAME> and
C<VERSION> keys are present, and that C<ina@cpan.org> appears in
the C<AUTHOR> field.

=back

=head1 EXIT CODE

Returns 0 when all tests pass, 1 otherwise.

=head1 COMPATIBILITY

Perl 5.005_03 and later.  Uses no modules beyond C<strict>, C<warnings>,
and C<File::Spec> (all core since 5.005_03).

=cut

