package INA_CPAN_Check;

######################################################################
#
# INA_CPAN_Check - Shared test library for ina@CPAN distributions
#
# COMPATIBILITY: Perl 5.005_03 and later
#
# Check catalogue.  Each letter is one category, exported as a pair:
# count_X($root) returns how many assertions check_X($root) will make, so
# a test file can emit its plan before running anything.
#
#   A  MANIFEST completeness
#   B  version consistency across .pm / META.yml / META.json /
#      Makefile.PL / Changes, including the provides blocks
#   C  encoding hygiene: US-ASCII, trailing whitespace, final newline
#   D  Perl 5.005_03 compatibility of lib/*.pm
#   E  code layout style: no shebang, no '} else' on one line
#   F  eg/ examples exist
#   G  POD structure of lib/*.pm
#   H  README required sections
#   I  generated metadata is well-formed
#   J  test suite and prerequisite conventions
#   K  reference and punctuation style of lib/*.pm
#   L  Changes file format
#
# A distribution calls only the letters it does not already cover in more
# depth itself.  D, G and H in particular are baseline checks: a dist that
# ships its own perl5compat / pod / readme test file should leave them out
# rather than assert the same things twice.
#
# selfcheck_suite() is separate from the letters.  It runs the whole test
# suite in a child Perl at 'pmake dist' time and verifies the TAP each file
# emits, which is the only way to catch a plan line in the wrong place.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use vars qw($VERSION @EXPORT_OK);
use Exporter ();
use vars qw(@ISA);
@ISA = qw(Exporter);

$VERSION = '0.41';
$VERSION = $VERSION;

@EXPORT_OK = qw(
    ok plan_tests diag plan_skip end_testing
    _slurp _slurp_lines _scan_code _code_only
    _manifest_files _manifest_pm_and_t _text_files _find_pm_t
    _primary_pm _lib_pm_files _pm_version
    _yaml_str _json_str
    check_A count_A
    check_B count_B
    check_C count_C
    check_D count_D
    check_E count_E
    check_F count_F
    check_G count_G
    check_H count_H
    check_I count_I
    check_J count_J
    check_K count_K
    check_L count_L
);

use vars qw($T_PLAN $T_RUN $T_FAIL
            $T_PLANNED $T_SKIPPED $T_DOUBLE $T_FINALIZED);
($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
# Regression guards for two defect classes that previously slipped through
# (a test passing when run by hand but FAILing under a real TAP harness):
#   $T_PLANNED  -- a "1..N" (or SKIP) plan line has already been emitted
#   $T_SKIPPED  -- the plan was a "1..0 # SKIP"
#   $T_DOUBLE   -- plan_tests()/plan_skip() was called after a plan existed
#   $T_FINALIZED-- _finalize() has already run (END + explicit end_testing)
($T_PLANNED, $T_SKIPPED, $T_DOUBLE, $T_FINALIZED) = (0, 0, 0, 0);

use File::Spec ();

# Export all symbols into caller's namespace by default
sub import {
    my $class = shift;
    no strict 'refs';
    my $pkg = caller(0);
    for my $sym (@EXPORT_OK) {
        *{"${pkg}::${sym}"} = \&{"INA_CPAN_Check::${sym}"};
    }
}

######################################################################
# TAP helpers
######################################################################

sub plan_tests {
    # A plan line must be emitted at most once per test file. Emitting a
    # second "1..N" corrupts the TAP stream ("More than one plan found in
    # TAP output") and makes the file FAIL under a real harness even though
    # every "ok" line passes when the script is run by hand. If a plan was
    # already emitted, do NOT print another one; record the error so that
    # _finalize() reports a clear, immediate failure instead.
    if ($T_PLANNED) {
        $T_DOUBLE++;
        diag("plan_tests($_[0]) called after a plan of $T_PLAN was already "
           . "emitted; ignoring the extra plan");
        return;
    }
    $T_PLAN    = $_[0];
    $T_PLANNED = 1;
    print "1..$T_PLAN\n";
}

sub ok ($;$) {
    my ($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN"
        . (defined($name) && $name ne '' ? " - $name" : '') . "\n";
    return $ok;
}

sub diag {
    print "# $_[0]\n";
}

sub plan_skip {
    my ($reason) = @_;
    if ($T_PLANNED) {
        $T_DOUBLE++;
        diag("plan_skip() called after a plan was already emitted; ignoring");
        return;
    }
    $T_PLANNED = 1;
    $T_SKIPPED = 1;
    print "1..0 # SKIP $reason\n";
    exit 0;
}

# Reconcile the emitted plan with the number of assertions actually run, and
# signal failure to the harness through the exit status only. This is the
# safety net that turns the two historical defects -- a duplicate plan line
# and a plan count that does not match the number of ok() calls -- into a
# loud, immediate failure on the author's own machine, with no TAP harness
# required. exit() is never called from here: doing so from an END block
# makes Perl 5.6 and earlier abort with "Callback called exit.", which is
# printed ahead of (and masks) the real "not ok" line. Assigning to $? sets
# the process exit status portably, all the way back to Perl 5.005_03.
sub _finalize {
    return if $T_FINALIZED;
    $T_FINALIZED = 1;

    if ($T_PLANNED && !$T_SKIPPED) {
        if ($T_DOUBLE) {
            diag("plan was set more than once "
               . "(" . ($T_DOUBLE + 1) . " plan calls); "
               . "only the first plan of $T_PLAN was emitted");
            $T_FAIL++;
        }
        if ($T_RUN != $T_PLAN) {
            diag("Looks like you planned $T_PLAN test(s) but ran $T_RUN.");
            $T_FAIL++;
        }
    }
}

# Kept for backward compatibility: test files call this via END{end_testing()}.
# It both reconciles the plan and (when run inside an END block, as the
# END{end_testing()} idiom does) sets the exit status.
sub end_testing {
    _finalize();
    $? = 1 if $T_FAIL;
}

# The module's own END block is the authoritative place to set the exit
# status: assigning to $? takes effect only when done inside an END block,
# and this runs for every test file whether or not it has its own END.
END {
    _finalize();
    $? = 1 if $T_FAIL;
}

######################################################################
# File utilities
######################################################################

sub _slurp {
    my ($path) = @_;
    local *_INA_FH;
    open(_INA_FH, $path) or return '';
    my $content = do { local $/; <_INA_FH> };
    close _INA_FH;
    return defined $content ? $content : '';
}

sub _slurp_lines {
    my ($path) = @_;
    local *_INA_FH;
    open(_INA_FH, $path) or return ();
    my @lines = <_INA_FH>;
    close _INA_FH;
    return @lines;
}

# Every .pm and .t under $dir, recursively, as paths relative to nothing
# (they keep the $dir prefix they were found with).
sub _find_pm_t {
    my ($dir) = @_;
    local *_INA_DIR;
    opendir(_INA_DIR, $dir) or return ();
    my @entries = grep { !/^\./ } readdir(_INA_DIR);
    closedir _INA_DIR;
    my @found;
    for my $e (sort @entries) {
        my $path = "$dir/$e";
        if (-d $path) {
            push @found, _find_pm_t($path);
        }
        elsif ($e =~ /\.(?:pm|t)$/) {
            push @found, $path;
        }
    }
    return @found;
}

sub _manifest_files {
    my ($root) = @_;
    my @lines = _slurp_lines("$root/MANIFEST");
    my @files;
    for my $line (@lines) {
        $line =~ s/\r?\n$//;
        $line =~ s/\s*#.*$//;
        $line =~ s/^\s+|\s+$//g;
        push @files, $line if length $line;
    }
    return @files;
}

# The files that carry ina@CPAN hand-written code: lib/*.pm, every *.t,
# and eg/*.pl.  Driven by MANIFEST so that generated or vendored files
# outside it are never scanned.
sub _manifest_pm_and_t {
    my ($root) = @_;
    my @all   = _manifest_files($root);
    my @found = grep {
        ((/\.pm$/ && m{^lib/}) || /\.t$/ || m{^eg/.*\.pl$}) && -f "$root/$_"
    } @all;
    return @found if @found;
    # Fallback for a dist with no usable MANIFEST.
    my @fb;
    for my $dir ('lib', 't') {
        push @fb, _find_pm_t("$root/$dir") if -d "$root/$dir";
    }
    for my $p (@fb) {
        $p =~ s{^\Q$root\E/}{};
    }
    return @fb;
}

# MANIFEST entries that are text and therefore subject to the encoding
# checks.  Anything with a known binary extension is excluded.
sub _text_files {
    my ($root) = @_;
    return grep { !/\.(?:gz|tgz|zip|tar|bz2|png|jpe?g|gif|ico|pdf)$/i }
           _manifest_files($root);
}

# Find $pattern in $path, ignoring POD, __END__, comments, string literals
# and regex literals, so that a match is real code and not prose or data.
# Returns a list of { line => N, text => "..." }.
sub _scan_code {
    my ($path, $pattern) = @_;
    my $text = _slurp($path);
    return () unless $text ne '';
    $text =~ s/\n__END__\b.*\z//s;
    $text =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    my @hits;
    my $lineno = 0;
    for my $line (split /\n/, $text) {
        $lineno++;
        next if $line =~ /^\s*#/;
        my $clean = $line;
        $clean =~ s/'(?:[^'\\]|\\.)*'/''/g;
        $clean =~ s/"(?:[^"\\]|\\.)*"/""/g;
        $clean =~ s{(?:s|m|qr|split\s*/)[^/]*/[^/]*/[gimsex]*}{}g;
        $clean =~ s{/[^/]+/[gimsex]*}{}g;
        $clean =~ s/#.*$//;
        if ($clean =~ $pattern) {
            push @hits, { line => $lineno, text => $line };
        }
    }
    return @hits;
}

# Code with POD and __END__ removed, for whole-file pattern matching.
sub _code_only {
    my ($path) = @_;
    my $text = _slurp($path);
    $text =~ s/\n__END__\b.*\z//s;
    $text =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    return $text;
}

######################################################################
# Distribution and metadata utilities
######################################################################

sub _dist_name {
    my ($root) = @_;
    my $base = $root;
    $base =~ s{.*[/\\]}{};
    $base =~ s{-[\d.]+$}{};
    return $base;
}

# The primary module is the first MANIFEST entry (ina convention, as used
# by pmake.bat).  Deriving it from MANIFEST is robust regardless of the
# directory name or a trailing "/.." that rel2abs leaves in $root.
sub _primary_pm {
    my ($root) = @_;
    if (-f "$root/MANIFEST") {
        my @manifest = _manifest_files($root);
        if (@manifest && $manifest[0] =~ /\.pm$/ && -f "$root/$manifest[0]") {
            return "$root/$manifest[0]";
        }
    }
    my $dist = _dist_name($root);
    (my $rel = $dist) =~ s{-}{/}g;
    return "$root/lib/$rel.pm";
}

sub _lib_pm_files {
    my ($root) = @_;
    # The grep must not be written directly after sort: "sort grep {...} LIST"
    # parses as "sort SUBNAME LIST" and calls grep as the comparator.
    my @pm = grep { m{^lib/.*\.pm$} && -f "$root/$_" } _manifest_files($root);
    return sort @pm;
}

sub _pm_version {
    my ($path) = @_;
    my $text = _slurp($path);
    return undef unless $text ne '';
    if ($text =~ /\$VERSION\s*=\s*['"]([^'"]+)['"]/) {
        return $1;
    }
    if ($text =~ /\$VERSION\s*=\s*([\d._]+)/) {
        return $1;
    }
    return undef;
}

sub _yaml_str {
    my ($text, $key) = @_;
    return undef unless defined $text && $text ne '';
    if ($text =~ /^${key}:\s*['"]?([^'"\n]+)['"]?\s*$/m) {
        return $1;
    }
    return undef;
}

sub _json_str {
    my ($text, $key) = @_;
    return undef unless defined $text && $text ne '';
    if ($text =~ /"${key}"\s*:\s*"([^"]+)"/) {
        return $1;
    }
    return undef;
}

# The provides block of META.yml, as { package => version }.  Parsed line
# by line: a package key is indented and ends at the colon, its version is
# indented further.  A regex over the whole block is not reliable because
# package names contain colons themselves.
sub _provides_versions_yml {
    my ($text) = @_;
    my %h;
    return { %h } unless defined $text && $text ne '';
    my $in  = 0;
    my $pkg = undef;
    for my $line (split /\n/, $text) {
        $line =~ s/\r$//;
        if ($line =~ /^provides:\s*$/) { $in = 1; next }
        next unless $in;
        last if $line =~ /^\S/;
        if ($line =~ /^\s+([\w:]+):\s*$/) { $pkg = $1; next }
        if (defined $pkg && $line =~ /^\s+version:\s*['"]?([\d._]+)/) {
            $h{$pkg} = $1;
        }
    }
    return { %h };
}

# The provides block of META.json, as { package => version }.  The block is
# isolated by counting braces first; matching "name": { ... "version" }
# against the whole document instead would let the outer "provides" key pair
# up with the first package's version.
sub _provides_versions_json {
    my ($text) = @_;
    my %h;
    return { %h } unless defined $text && $text ne '';
    return { %h } unless $text =~ /"provides"\s*:\s*\{/g;

    my $start = pos($text);
    my $len   = length($text);
    my $depth = 1;
    my $i     = $start;
    while ($i < $len && $depth > 0) {
        my $c = substr($text, $i, 1);
        if    ($c eq '{') { $depth++ }
        elsif ($c eq '}') { $depth-- }
        $i++;
    }
    my $block = substr($text, $start, $i - $start - 1);

    while ($block =~ /"([\w:]+)"\s*:\s*\{(.*?)\}/gs) {
        my $pkg  = $1;
        my $body = $2;
        if ($body =~ /"version"\s*:\s*"([^"]+)"/) {
            $h{$pkg} = $1;
        }
    }
    return { %h };
}

######################################################################
# check_A -- MANIFEST completeness
#
#   A1  every MANIFEST entry exists on disk
#   A2  the files every ina@CPAN dist must ship are listed
#   A3  at least one .pm is listed
#
# Options:
#   required => [ list ]   override the required-file list
######################################################################

sub _required_files {
    my (%opt) = @_;
    return @{ $opt{required} } if exists $opt{required};
    return qw(Changes Makefile.PL MANIFEST META.yml META.json README LICENSE);
}

sub count_A {
    my ($root, %opt) = @_;
    return 0 unless defined($root) && -f "$root/MANIFEST";
    my @manifest = _manifest_files($root);
    my @required = _required_files(%opt);
    return scalar(@manifest) + scalar(@required) + 1;
}

sub check_A {
    my ($root, %opt) = @_;
    plan_skip('MANIFEST not found') unless -f "$root/MANIFEST";
    my @manifest = _manifest_files($root);
    plan_skip('MANIFEST is empty') unless @manifest;

    for my $f (@manifest) {
        ok(-e "$root/$f", "A1 - MANIFEST entry exists: $f");
    }
    for my $req (_required_files(%opt)) {
        ok(scalar(grep { $_ eq $req } @manifest),
           "A2 - required file listed in MANIFEST: $req");
    }
    ok(scalar(grep { /\.pm$/ } @manifest) > 0,
       'A3 - at least one .pm listed in MANIFEST');
}

######################################################################
# check_B -- version consistency
#
# Per lib/*.pm:
#   B1  $VERSION is defined
#   B2  META.yml version matches it
#   B3  META.json version matches it
#   B4  Makefile.PL VERSION matches it
#   B5  the top Changes entry matches it
#   B6  every META.yml provides version matches it
# Once per dist:
#   B7  every META.json provides version matches the primary $VERSION
######################################################################

sub count_B {
    my ($root) = @_;
    my @pm = _lib_pm_files($root);
    return scalar(@pm) * 6 + 1;
}

sub check_B {
    my ($root) = @_;
    my @pm_files  = _lib_pm_files($root);
    my $meta_yml  = _slurp("$root/META.yml");
    my $meta_json = _slurp("$root/META.json");
    my $mkf_text  = _slurp("$root/Makefile.PL");
    my $chg_text  = _slurp("$root/Changes");

    for my $pm (@pm_files) {
        my $ver = _pm_version("$root/$pm");
        ok(defined $ver, "B1 - \$VERSION defined in $pm");
        $ver = '(undef)' unless defined $ver;

        my $yml_ver = _yaml_str($meta_yml, 'version');
        ok(defined $yml_ver && $yml_ver eq $ver,
           "B2 - META.yml version (" . (defined $yml_ver ? $yml_ver : 'undef')
           . ") eq \$VERSION ($ver)");

        my $json_ver = _json_str($meta_json, 'version');
        ok(defined $json_ver && $json_ver eq $ver,
           "B3 - META.json version (" . (defined $json_ver ? $json_ver : 'undef')
           . ") eq \$VERSION ($ver)");

        my $mk_ver;
        $mk_ver = $1 if $mkf_text =~ /'VERSION'\s*=>\s*q\{([^}]+)\}/;
        $mk_ver = $1 if !defined $mk_ver
                     && $mkf_text =~ /'VERSION'\s*=>\s*['"]([^'"]+)['"]/;
        ok(defined $mk_ver && $mk_ver eq $ver,
           "B4 - Makefile.PL VERSION (" . (defined $mk_ver ? $mk_ver : 'undef')
           . ") eq \$VERSION ($ver)");

        my $chg_ver;
        for my $line (split /\n/, $chg_text) {
            if ($line =~ /^(\d+\.\d+[\w.]*)/) { $chg_ver = $1; last }
        }
        ok(defined $chg_ver && $chg_ver eq $ver,
           "B5 - Changes top version (" . (defined $chg_ver ? $chg_ver : 'undef')
           . ") eq \$VERSION ($ver)");

        my $prov_yml = _provides_versions_yml($meta_yml);
        my @yml_mm;
        for my $pkg (sort keys %$prov_yml) {
            push @yml_mm, "$pkg=$prov_yml->{$pkg}" if $prov_yml->{$pkg} ne $ver;
        }
        ok(!@yml_mm && %$prov_yml,
           "B6 - META.yml provides versions all eq \$VERSION ($ver): $pm"
           . (@yml_mm ? " (@yml_mm)" : ''));
    }

    my $primary_ver = @pm_files ? _pm_version("$root/$pm_files[0]") : undef;
    my $prov_json   = _provides_versions_json($meta_json);
    my @json_mm;
    for my $pkg (sort keys %$prov_json) {
        push @json_mm, "$pkg=$prov_json->{$pkg}"
            if defined $primary_ver && $prov_json->{$pkg} ne $primary_ver;
    }
    ok(!@json_mm && %$prov_json,
       "B7 - META.json provides versions all eq \$VERSION ("
       . (defined $primary_ver ? $primary_ver : 'undef') . ")"
       . (@json_mm ? " (@json_mm)" : ''));
}

######################################################################
# check_C -- encoding hygiene, over every text file in MANIFEST
#
#   C1  US-ASCII only
#   C2  no trailing whitespace
#   C3  file ends with a newline
#
# Perl source and metadata must be US-ASCII for 5.005_03 portability.
# Files that are intentionally not US-ASCII -- the multi-language cheat
# sheets under doc/, a multibyte transpiler core, MBCS test fixtures --
# are exempt from C1 only.  doc/*.txt is always exempt; anything else is
# named by the caller through the utf8_ok regex.
#
# Options:
#   utf8_ok => 'regex'     extra paths exempt from C1
######################################################################

sub count_C {
    my ($root) = @_;
    plan_skip('MANIFEST not found') unless -f "$root/MANIFEST";
    my @files = _text_files($root);
    return scalar(@files) * 3;
}

sub check_C {
    my ($root, %opt) = @_;
    return unless -f "$root/MANIFEST";
    my $utf8_ok = exists $opt{utf8_ok} ? $opt{utf8_ok} : undef;

    for my $rel (_text_files($root)) {
        my $path = "$root/$rel";
        unless (-f $path) {
            ok(0, "C1 - US-ASCII only: $rel (file missing)");
            ok(0, "C2 - no trailing whitespace: $rel (file missing)");
            ok(0, "C3 - ends with newline: $rel (file missing)");
            next;
        }
        my $src = _slurp($path);
        my $ascii_exempt = ($rel =~ m{^doc/.*\.txt$}i)
                        || (defined $utf8_ok && $rel =~ /$utf8_ok/);
        ok($ascii_exempt || $src !~ /[^\x00-\x7F]/,
           "C1 - US-ASCII only: $rel"
           . ($ascii_exempt ? ' (exempt)' : ''));
        ok($src !~ /[ \t]+\r?\n/,      "C2 - no trailing whitespace: $rel");
        ok($src eq '' || $src =~ /\n\z/, "C3 - ends with newline: $rel");
    }
}

######################################################################
# check_D -- Perl 5.005_03 compatibility, per lib/*.pm
#
#   D1  the warnings stub defines import()
#   D2  no 'our'                        (5.6+)
#   D3  no say / given / state          (5.10+)
#   D4  no my (undef, ...)              (5.10+)
#   D5  $VERSION self-assignment present
#   D6  CVE-2016-1238 mitigation: pop @INC
#
# A dist whose own test suite checks these in more depth (a t/9020 style
# perl5compat file) should not also call check_D.
######################################################################

sub count_D {
    my ($root) = @_;
    my @pm = _lib_pm_files($root);
    return scalar(@pm) * 6;
}

sub check_D {
    my ($root) = @_;
    for my $pm (_lib_pm_files($root)) {
        my $text = _slurp("$root/$pm");
        my $code = _code_only("$root/$pm");

        ok($code =~ /\$INC\{'warnings\.pm'\}\s*=.*?eval\s*['"]package warnings;\s*sub import/s,
           "D1 - warnings stub defines import(): $pm");

        my @our_hits = _scan_code("$root/$pm", qr/\bour\b/);
        ok(!@our_hits, "D2 - no 'our' keyword: $pm");

        my @syn = _scan_code("$root/$pm", qr/\b(?:say|given|state)\s*[\(\{]/);
        ok(!@syn, "D3 - no say/given/state: $pm");

        my @und = _scan_code("$root/$pm", qr/\bmy\s*\(\s*undef/);
        ok(!@und, "D4 - no 'my (undef, ...)': $pm");

        ok($text =~ /\$VERSION\s*=\s*\$VERSION/,
           "D5 - \$VERSION self-assignment present: $pm");

        ok($code =~ /BEGIN\s*\{[^}]*pop\s+\@INC[^}]*\}/s
        || $code =~ /pop \@INC if \$INC\[-1\] eq '\.'/,
           "D6 - CVE-2016-1238 pop \@INC: $pm");
    }
}

######################################################################
# check_E -- code layout style
#
#   E1  no shebang in lib/*.pm                          (once)
#   E2  no '} else' / '} elsif' on one line             (per file)
######################################################################

sub count_E {
    my ($root) = @_;
    my @files = _manifest_pm_and_t($root);
    return 1 + scalar(@files);
}

sub check_E {
    my ($root) = @_;

    my $no_shebang = 1;
    for my $f (_find_pm_t("$root/lib")) {
        if (_slurp($f) =~ /^#!/) {
            $no_shebang = 0;
            diag("E1: shebang found in $f");
        }
    }
    ok($no_shebang, 'E1 - no shebang in lib/*.pm');

    for my $f (_manifest_pm_and_t($root)) {
        next unless -f "$root/$f";
        my @hits = _scan_code("$root/$f", qr/^\s*\}\s*els(?:e|if)\b/);
        ok(!@hits, "E2 - no '} else/elsif' on same line: $f");
        for my $h (@hits) { diag("  line $h->{line}: $h->{text}") }
    }
}

######################################################################
# check_F -- eg/ examples exist
#
#   F1  at least one eg/*.pl is shipped
######################################################################

sub count_F { return 1 }

sub check_F {
    my ($root) = @_;
    my @eg;
    if (-d "$root/eg") {
        local *_INA_EG;
        if (opendir(_INA_EG, "$root/eg")) {
            @eg = grep { /\.pl$/ } readdir(_INA_EG);
            closedir _INA_EG;
        }
    }
    ok(scalar(@eg) > 0, 'F1 - at least one eg/*.pl example exists');
}

######################################################################
# check_G -- POD structure, per lib/*.pm
#
#   G1  =head1 NAME          G4  =head1 DESCRIPTION
#   G2  =head1 VERSION       G5  =head1 AUTHOR
#   G3  =head1 SYNOPSIS      G6  a =head1 naming LICENSE
#   G7  every POD block is closed by =cut
#
# G6 accepts any heading that contains the word LICENSE, so both
# "=head1 LICENSE" and "=head1 COPYRIGHT AND LICENSE" pass.
#
# A dist whose own test suite checks POD in more depth (a t/9050 style
# pod file) should not also call check_G.
######################################################################

sub count_G {
    my ($root) = @_;
    my @pm = _lib_pm_files($root);
    return scalar(@pm) * 7;
}

sub check_G {
    my ($root) = @_;
    for my $pm (_lib_pm_files($root)) {
        my $text = _slurp("$root/$pm");
        ok($text =~ /^=head1\s+NAME\b/m,        "G1 - =head1 NAME: $pm");
        ok($text =~ /^=head1\s+VERSION\b/m,     "G2 - =head1 VERSION: $pm");
        ok($text =~ /^=head1\s+SYNOPSIS\b/m,    "G3 - =head1 SYNOPSIS: $pm");
        ok($text =~ /^=head1\s+DESCRIPTION\b/m, "G4 - =head1 DESCRIPTION: $pm");
        ok($text =~ /^=head1\s+AUTHOR\b/m,      "G5 - =head1 AUTHOR: $pm");
        ok($text =~ /^=head1\s+.*\bLICENSE\b/m, "G6 - =head1 ... LICENSE: $pm");
        my $opens = () = $text =~ /^=[a-zA-Z]/mg;
        my $cuts  = () = $text =~ /^=cut\b/mg;
        ok($cuts >= 1 && $cuts <= $opens, "G7 - POD blocks closed by =cut: $pm");
    }
}

######################################################################
# check_H -- README required sections
#
#   H1 NAME   H2 SYNOPSIS   H3 DESCRIPTION   H4 INSTALL
#
# A dist whose own test suite checks README in more depth (a t/9060 style
# readme file) should not also call check_H.
######################################################################

sub count_H { return 4 }

sub check_H {
    my ($root) = @_;
    my $readme = _slurp("$root/README");
    ok($readme =~ /\bNAME\b/,        'H1 - README has NAME');
    ok($readme =~ /\bSYNOPSIS\b/,    'H2 - README has SYNOPSIS');
    ok($readme =~ /\bDESCRIPTION\b/, 'H3 - README has DESCRIPTION');
    ok($readme =~ /\bINSTALL/i,      'H4 - README has INSTALL');
}

######################################################################
# check_I -- generated metadata is well-formed
#
# META.yml:   I1 name  I2 version  I3 license
#             I4 minimum_perl_version  I5 author  I6 provides non-empty
# META.json:  I7 name  I8 version  I9 parses as an object
# Makefile.PL I10 WriteMakefile()  I11 NAME and VERSION  I12 AUTHOR
#
# Options:
#   min_perl  => '5.00503'                 expected minimum_perl_version
#   author_re => 'ina\.cpan\@gmail\.com'   expected author / AUTHOR
######################################################################

sub count_I { return 12 }

sub check_I {
    my ($root, %opt) = @_;
    my $min_perl  = exists $opt{min_perl}  ? $opt{min_perl}  : '5.00503';
    my $author_re = exists $opt{author_re} ? $opt{author_re}
                                           : 'ina\.cpan\@gmail\.com';

    my $yml  = _slurp("$root/META.yml");
    my $jsn  = _slurp("$root/META.json");
    my $mkpl = _slurp("$root/Makefile.PL");

    ok($yml =~ /^name\s*:/m,    'I1 - META.yml has name');
    ok($yml =~ /^version\s*:/m, 'I2 - META.yml has version');
    ok($yml =~ /^license\s*:/m, 'I3 - META.yml has license');

    my $got_perl = _yaml_str($yml, 'minimum_perl_version');
    ok(defined $got_perl && $got_perl eq $min_perl,
       "I4 - META.yml minimum_perl_version is $min_perl (got: "
       . (defined $got_perl ? $got_perl : 'undef') . ")");

    my $author = _yaml_str($yml, 'author');
    $author = '' unless defined $author;
    if ($yml =~ /^author:\s*\n(\s+-[^\n]+)/m) { $author = $1 }
    ok($author =~ /$author_re/i, 'I5 - META.yml author matches expected address');

    my $prov = _provides_versions_yml($yml);
    ok(scalar(keys %$prov) > 0, 'I6 - META.yml provides is non-empty');

    ok($jsn =~ /"name"\s*:/,    'I7 - META.json has name');
    ok($jsn =~ /"version"\s*:/, 'I8 - META.json has version');
    ok($jsn =~ /^\s*\{/,        'I9 - META.json is a JSON object');

    ok($mkpl =~ /WriteMakefile\s*\(/, 'I10 - Makefile.PL calls WriteMakefile()');
    ok($mkpl =~ /'NAME'/ && $mkpl =~ /'VERSION'/,
       'I11 - Makefile.PL has NAME and VERSION');
    ok($mkpl =~ /$author_re/i, 'I12 - Makefile.PL AUTHOR matches expected address');
}

######################################################################
# check_J -- test suite and prerequisite conventions
#
#   J1  9NNN test files are named 9NNN-name.t
#   J2  no declared prerequisite carries the module's own $VERSION
#
# J2 catches the copy-paste slip of pasting the dist version into a core
# module's minimum version in META.yml requires.
######################################################################

sub count_J { return 2 }

sub check_J {
    my ($root) = @_;

    my @t_files;
    local *_INA_T;
    if (opendir(_INA_T, "$root/t")) {
        @t_files = grep { /\.t$/ } readdir(_INA_T);
        closedir _INA_T;
    }
    my @bad = sort grep { /^9\d{3}/ && !/^9\d{3}[-_][a-z]/ } @t_files;
    ok(!@bad, 'J1 - 9NNN test files follow 9NNN-name.t'
            . (@bad ? " (@bad)" : ''));

    my @pm_files = _lib_pm_files($root);
    my $pm_ver   = @pm_files ? _pm_version("$root/$pm_files[0]") : undef;
    my $meta_yml = _slurp("$root/META.yml");
    my $clash    = 0;
    if (defined $pm_ver && $meta_yml =~ /^requires:(.*?)(?=^\S)/ms) {
        my $block = $1;
        while ($block =~ /:\s*([\d._]+)/g) {
            if ($1 eq $pm_ver) { $clash = 1; last }
        }
    }
    ok(!$clash, 'J2 - no prerequisite version equals the module $VERSION');
}

######################################################################
# check_K -- reference and punctuation style, per lib/*.pm
#
#   K1  a comma is followed by whitespace
#   K2  [ @array ] rather than \@array
#   K3  { %hash }  rather than \%hash
#
# Options:
#   k3_exempt => 'regex'   hash names allowed to keep the \%name form
#                          (default: env, opts, args)
######################################################################

sub count_K {
    my ($root) = @_;
    my @pm = _lib_pm_files($root);
    return scalar(@pm) * 3;
}

sub check_K {
    my ($root, %opt) = @_;
    my $k3_exempt = exists $opt{k3_exempt} ? $opt{k3_exempt}
                                           : 'env\b|opts\b|args\b';

    for my $pm (_lib_pm_files($root)) {
        my $text  = _code_only("$root/$pm");
        my @lines = split /\n/, $text;

        my @k1_bad;
        my $n = 0;
        for my $line (@lines) {
            $n++;
            my $s = $line;
            $s =~ s/^\s*#.*$//;
            next unless $s =~ /\S/;
            $s =~ s/'(?:[^'\\]|\\.)*'/''/g;
            $s =~ s/"(?:[^"\\]|\\.)*"/""/g;
            $s =~ s{(?:s|m|qr|split\s*/)[^/]*/[^/]*/[gimsex]*}{}g;
            $s =~ s{/[^/]+/[gimsex]*}{}g;
            $s =~ s/#.*$//;
            push @k1_bad, $n if $s =~ /,(?=[^\s\n\)\]\}\/])/;
        }
        ok(!@k1_bad, "K1 - comma followed by whitespace: $pm"
                   . _first_lines(\@k1_bad));

        my @k2_bad;
        $n = 0;
        for my $line (@lines) {
            $n++;
            next if $line =~ /^\s*#/;
            my $cl = $line;
            $cl =~ s/'[^']*'//g;
            $cl =~ s/"[^"]*"//g;
            $cl =~ s/#.*$//;
            push @k2_bad, $n if $cl =~ /(?:push|unshift|return|=)\s*\\\@\w/;
        }
        ok(!@k2_bad, "K2 - use [ \@array ] instead of \\\@array: $pm"
                   . _first_lines(\@k2_bad));

        my @k3_bad;
        $n = 0;
        for my $line (@lines) {
            $n++;
            next if $line =~ /^\s*#/;
            my $cl = $line;
            $cl =~ s/'[^']*'//g;
            $cl =~ s/"[^"]*"//g;
            $cl =~ s/#.*$//;
            push @k3_bad, $n if $cl =~ /\\\%(?!$k3_exempt)\w+/;
        }
        ok(!@k3_bad, "K3 - use { \%hash } instead of \\\%hash: $pm"
                   . _first_lines(\@k3_bad));
    }
}

sub _first_lines {
    my ($bad) = @_;
    return '' unless @$bad;
    my $last = @$bad > 3 ? 2 : $#$bad;
    return ' (lines: ' . join(', ', @{$bad}[0 .. $last]) . ')';
}

######################################################################
# check_L -- Changes file format
#
#   L1  Changes is non-empty
#   L2  the newest entry starts with VERSION and a date
#   L3  the newest entry has an indented description body
######################################################################

sub count_L { return 3 }

sub check_L {
    my ($root) = @_;
    my @lines = _slurp_lines("$root/Changes");
    ok(scalar(@lines) > 0, 'L1 - Changes is non-empty');

    my $top = '';
    for my $line (@lines) {
        $line =~ s/\r?\n$//;
        next unless $line =~ /^\d/;
        $top = $line;
        last;
    }
    ok($top =~ /^\d+\.\d+\S*\s+\S+/,
       "L2 - newest Changes entry has VERSION and date: '$top'");

    my $has_body = 0;
    my $in_entry = 0;
    for my $line (@lines) {
        $line =~ s/\r?\n$//;
        if ($line =~ /^\d+\.\d+/) {
            last if $in_entry;
            $in_entry = 1;
            next;
        }
        if ($in_entry && $line =~ /^\s+\S/) { $has_body = 1; last }
    }
    ok($has_body, 'L3 - newest Changes entry has an indented body');
}

######################################################################
# selfcheck_suite -- dist-time TAP plan-sanity check of the test suite
#
# Runs every t/*.t (and, by default, xt/*.t) in a child Perl and verifies
# the TAP each one emits, catching the two defect classes that a plain
# "perl t/foo.t" by hand does NOT reveal but a real harness (and therefore
# CPAN Testers) does:
#
#   1. more than one "1..N" plan line in a single file
#      ("More than one plan found in TAP output")
#   2. a plan count that does not match the number of ok/not-ok lines
#      ("planned X but ran Y")
#
# It also fails on any "not ok" line. A "1..0 # SKIP" file is accepted.
#
# Intended to be invoked from pmake.bat at "pmake dist" time:
#   perl -Ilib -It/lib -MINA_CPAN_Check \
#        -e "exit(INA_CPAN_Check::selfcheck_suite())"
#
# Options (name => value):
#   dir   => 't'                test directory (default 't')
#   xt    => 1                  also run xt/*.t if present (default 1)
#   inc   => ['lib','t/lib']    -I paths for the child Perl
#   quiet => 0                  suppress the per-file PASS lines
#
# Returns the number of test files that failed the check (0 == all good),
# suitable for exit().
######################################################################
sub selfcheck_suite {
    my %opt = @_;
    my $dir   = defined($opt{dir})   ? $opt{dir}   : 't';
    my $do_xt = exists($opt{xt})     ? $opt{xt}    : 1;
    my $quiet = $opt{quiet} ? 1 : 0;
    my @inc   = (defined($opt{inc}) && ref($opt{inc}) eq 'ARRAY')
                ? @{$opt{inc}} : ('lib', "$dir/lib");

    my @files = _suite_files($dir);
    if ($do_xt) {
        push @files, _suite_files('xt');
    }

    unless (@files) {
        print "selfcheck_suite: no test files found under $dir/\n" unless $quiet;
        return 0;
    }

    # Quote the Perl interpreter path for the piped command (it may contain
    # spaces, e.g. C:\Program Files\...). Inc args and file names in an ina
    # distribution never contain spaces.
    my $perl = $^X;
    $perl = qq{"$perl"} if $perl =~ /\s/;
    my $incstr = join(' ', map { "-I$_" } @inc);

    my $errors = 0;
    for my $file (@files) {
        my $cmd = "$perl $incstr $file";
        my @out;
        # open(FH, "CMD |") is portable to Perl 5.005_03 on both Windows
        # (via cmd.exe) and Unix. TAP (plan + ok/not-ok lines) is on STDOUT,
        # so capturing STDOUT alone is sufficient; no shell redirection.
        if (open(_SC_RUN, "$cmd |")) {
            @out = <_SC_RUN>;
            close _SC_RUN;
        }
        else {
            print "FAIL $file: cannot execute ($!)\n";
            $errors++;
            next;
        }

        my @plans = grep { /^1\.\.\d+/ } @out;
        my $skip  = grep { /^1\.\.0\b.*#\s*SKIP/i } @out;
        my $nok   = grep { /^ok\b/ }     @out;
        my $nnok  = grep { /^not ok\b/ } @out;

        if ($skip && @plans == 1) {
            print "skip $file (SKIP)\n" unless $quiet;
            next;
        }
        if (@plans == 0) {
            print "FAIL $file: no TAP plan emitted\n";
            $errors++;
            next;
        }
        if (@plans > 1) {
            print "FAIL $file: more than one plan line ("
                . scalar(@plans) . ")\n";
            $errors++;
            next;
        }
        my ($planned) = $plans[0] =~ /^1\.\.(\d+)/;
        my $ran = $nok + $nnok;
        if ($ran != $planned) {
            print "FAIL $file: planned $planned but ran $ran\n";
            $errors++;
            next;
        }
        if ($nnok) {
            print "FAIL $file: $nnok failing test(s)\n";
            $errors++;
            next;
        }
        print "ok   $file ($planned)\n" unless $quiet;
    }

    if ($errors) {
        print "selfcheck_suite: FAIL -- $errors of "
            . scalar(@files) . " test file(s) failed.\n";
    }
    else {
        print "selfcheck_suite: PASS -- "
            . scalar(@files) . " test file(s) OK.\n";
    }
    return $errors;
}

sub _suite_files {
    my ($dir) = @_;
    return () unless -d $dir;
    local *_SC_DIR;
    opendir(_SC_DIR, $dir) or return ();
    my @t = grep { /\.t$/ } readdir(_SC_DIR);
    closedir _SC_DIR;
    return map { "$dir/$_" } sort @t;
}

1;

