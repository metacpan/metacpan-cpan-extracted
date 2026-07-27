######################################################################
#
# 0032-glob-paths.t  Pathname expansion in pure Perl (v0.09)
#
# BACKGROUND
#   Filename globbing used to be handed to Perl's built-in glob(), which
#   reads a BACKSLASH AS AN ESCAPE character.  For a shell whose main
#   platform is Windows that is fatal: the ordinary pattern
#
#       d="C:\dir" ; for f in $d/*.txt ; do ... done
#
#   was searched for as C:dir/*.txt, matched nothing, and -- because
#   glob() returns an unmatched pattern with those backslashes already
#   deleted -- came back as the mangled word C:dir/*.txt.  File::Glob's
#   GLOB_NOESCAPE would have avoided it, but File::Glob arrived in Perl
#   5.6 and BATsh supports 5.005_03, so v0.09 matches patterns itself
#   (BATsh::SH::_glob_paths), segment by segment, with the module's own
#   glob-to-regex translator.  The separator is "/" everywhere and "\" as
#   well on Windows; on Unix a backslash is an ordinary filename
#   character and stays one.  CMD-mode wildcards (FOR sets, DEL) use the
#   same matcher.
#
# THIS TEST
#   GP01-GP02  Patterns match in one and in several path segments.
#   GP03       A pattern that matches nothing is left exactly as written.
#   GP04-GP05  A leading "." is matched only by a pattern starting ".".
#   GP06       "[!x]" negates the class (Perl would read it as "! or x").
#   GP07       Every segment but the last has to be a directory.
#   GP08       A trailing separator is preserved.
#   GP09       Globbing works on a directory name held in a variable.
#   GP10       (not Win32) A directory whose NAME contains a backslash --
#              the Unix reading of a backslash -- globs correctly.
#   GP11       (Win32 only) Backslash separators arriving from a variable
#              are separators -- the shell-level form of C:\dir\*.txt.  A
#              backslash TYPED in an SH-mode line is an escape, as in
#              bash, so a Windows pattern is written inside quotes or
#              held in a variable; "echo C:\dir\*.txt" means C:dir*.txt.
#   GP12       CMD mode: FOR %%f IN (pattern) uses the same matcher.
#   GP13       CMD mode: DEL /Q pattern deletes only what matches (and a
#              forward-slash path is no longer mistaken for switches).
#   GP14       An unusable pattern (an empty class) is taken literally
#              and prints no Perl diagnostic.
#   GP15       (Win32 only) CMD mode takes a backslash pattern as typed,
#              cmd.exe having no escape character at all.
#   GP16       A backslash inside quotes survives the glob path, which
#              removes the quotes and dequotes the line it rebuilt.
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
use Cwd ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

my $IS_WIN = ($^O =~ /MSWin32|dos|os2/i) ? 1 : 0;
my $BASE   = '_gp_' . $$;
my $SAVED  = Cwd::cwd();

sub _touch {
    my ($path) = @_;
    local *TF;
    open(TF, "> $path") or return 0;
    close(TF);
    return 1;
}

# Build the fixture tree relative to t/, so a distribution unpacked in a
# directory whose name contains a space does not need quoting here.
chdir($FindBin::Bin) or die "cannot chdir to $FindBin::Bin: $!";
my @MADE_DIR  = ();
my @MADE_FILE = ();
sub _mkdir_tracked {
    my ($d) = @_;
    return 0 unless mkdir($d, 0755);
    unshift @MADE_DIR, $d;
    return 1;
}
sub _touch_tracked {
    my ($f) = @_;
    return 0 unless _touch($f);
    push @MADE_FILE, $f;
    return 1;
}

my $SETUP = 0;
if (_mkdir_tracked($BASE)
    && _mkdir_tracked("$BASE/sub")
    && _mkdir_tracked("$BASE/other")
    && _mkdir_tracked("$BASE/del")
    && _touch_tracked("$BASE/sub/one.txt")
    && _touch_tracked("$BASE/sub/two.log")
    && _touch_tracked("$BASE/sub/.hidden")
    && _touch_tracked("$BASE/other/three.txt")
    && _touch_tracked("$BASE/del/a.tmp")
    && _touch_tracked("$BASE/del/b.tmp")
    && _touch_tracked("$BASE/del/keep.txt")) {
    $SETUP = 1;
}

# A directory whose name contains a backslash is impossible on Windows
# and perfectly ordinary on Unix, where it is the case the CPAN Testers
# failure was really about.
my $BSDIR = 0;
if ($SETUP && !$IS_WIN) {
    if (_mkdir_tracked("$BASE/a\\b") && _touch_tracked("$BASE/a\\b/c.txt")) {
        $BSDIR = 1;
    }
}

sub _cleanup {
    for my $f (@MADE_FILE) { unlink($f) }
    for my $d (@MADE_DIR)  { rmdir($d) }
    @MADE_FILE = ();
    @MADE_DIR  = ();
    chdir($SAVED);
    return 1;
}

sub _capture {
    my ($code) = @_;
    my $out = '';
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    my $tmp = "_gp_cap_$$.tmp";
    close(STDOUT);
    open(STDOUT, "> $tmp")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    eval { $code->() };
    my $err = $@;
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    local *RF;
    if (open(RF, $tmp)) { local $/; $out = <RF>; close(RF) }
    unlink($tmp);
    $out = '' unless defined $out;
    warn $err if $err;
    $out =~ s/\r//g;
    $out =~ s/\s+\z//;
    return $out;
}

sub _run {
    my ($script) = @_;
    BATsh::Env::init();
    return _capture(sub { BATsh->run_string($script) });
}

my @tests = (

    sub {
        return _ok(1, 'GP01: skipped (fixture tree unavailable)') unless $SETUP;
        _ok(_run("echo $BASE/sub/*.txt") eq "$BASE/sub/one.txt",
            'GP01: a pattern in the last segment matches');
    },

    sub {
        return _ok(1, 'GP02: skipped (fixture tree unavailable)') unless $SETUP;
        _ok(_run("echo $BASE/*/*.log") eq "$BASE/sub/two.log",
            'GP02: patterns in several segments match');
    },

    sub {
        return _ok(1, 'GP03: skipped (fixture tree unavailable)') unless $SETUP;
        _ok(_run("echo $BASE/nope/*.txt") eq "$BASE/nope/*.txt",
            'GP03: an unmatched pattern is left exactly as written');
    },

    sub {
        return _ok(1, 'GP04: skipped (fixture tree unavailable)') unless $SETUP;
        my $out = _run("echo $BASE/sub/*");
        my $ok = ($out =~ /one\.txt/) && ($out =~ /two\.log/)
                 && ($out !~ /hidden/);
        _ok($ok, 'GP04: * does not match a leading dot');
    },

    sub {
        return _ok(1, 'GP05: skipped (fixture tree unavailable)') unless $SETUP;
        _ok(_run("echo $BASE/sub/.*") =~ /\.hidden/,
            'GP05: .* does match a leading dot');
    },

    sub {
        return _ok(1, 'GP06: skipped (fixture tree unavailable)') unless $SETUP;
        _ok(_run("echo $BASE/sub/*[!g]") eq "$BASE/sub/one.txt",
            'GP06: [!x] negates the character class');
    },

    sub {
        return _ok(1, 'GP07: skipped (fixture tree unavailable)') unless $SETUP;
        _ok(_run("echo $BASE/*/one.txt") eq "$BASE/sub/one.txt",
            'GP07: a middle segment has to name a directory');
    },

    sub {
        return _ok(1, 'GP08: skipped (fixture tree unavailable)') unless $SETUP;
        my $out = _run("echo $BASE/*/");
        my $ok = ($out =~ m{\Q$BASE\E/sub/(?:\s|\z)}) ? 1 : 0;
        _ok($ok, q{GP08: a trailing separator is kept});
    },

    sub {
        return _ok(1, 'GP09: skipped (fixture tree unavailable)') unless $SETUP;
        my $out = _run("D=$BASE/sub; for f in \$D/*.txt; do echo [\$f]; done");
        _ok($out eq "[$BASE/sub/one.txt]",
            'GP09: a directory held in a variable globs');
    },

    sub {
        return _ok(1, 'GP10: skipped (Win32 has no backslash in a name)')
            unless $BSDIR;
        my $out = _run("D=\"$BASE/a\\b\"; echo \$D/*.txt");
        _ok($out eq "$BASE/a\\b/c.txt",
            'GP10: a directory NAME containing a backslash globs (Unix)');
    },

    sub {
        return _ok(1, 'GP11: skipped (not Win32)') unless $IS_WIN && $SETUP;
        # A backslash typed in an SH-mode line quotes the character after
        # it, exactly as in bash, so a Windows pattern reaches the matcher
        # from a variable -- which is also where a real script keeps a
        # directory name.
        my $out = _run("D='$BASE\\sub\\'; echo \$D*.txt");
        _ok($out eq "$BASE\\sub\\one.txt",
            'GP11: backslash separators from a variable glob');
    },

    sub {
        return _ok(1, 'GP12: skipped (fixture tree unavailable)') unless $SETUP;
        my $out = _run("FOR %%f IN ($BASE/sub/*.txt) DO ECHO [%%f]\n");
        _ok($out =~ /\Q[$BASE\/sub\/one.txt]\E/,
            'GP12: CMD FOR uses the same matcher');
    },

    sub {
        return _ok(1, 'GP13: skipped (fixture tree unavailable)') unless $SETUP;
        _run("DEL /Q $BASE/del/*.tmp\n");
        my $ok = !-e "$BASE/del/a.tmp" && !-e "$BASE/del/b.tmp"
                 && -e "$BASE/del/keep.txt";
        _ok($ok, 'GP13: CMD DEL deletes only the matches');
    },

    sub {
        return _ok(1, 'GP14: skipped (fixture tree unavailable)') unless $SETUP;
        _ok(_run("echo $BASE/sub/[]") eq "$BASE/sub/[]",
            'GP14: an unusable pattern is taken literally');
    },

    sub {
        return _ok(1, 'GP15: skipped (not Win32)') unless $IS_WIN && $SETUP;
        my $out = _run("FOR %%f IN ($BASE\\sub\\*.txt) DO ECHO [%%f]\n");
        my $ok = (index($out, "[$BASE\\sub\\one.txt]") >= 0) ? 1 : 0;
        _ok($ok, 'GP15: CMD mode takes a backslash pattern as typed');
    },

    sub {
        return _ok(1, 'GP16: skipped (fixture tree unavailable)') unless $SETUP;
        # The glob path strips the quotes and then dequotes the line it
        # rebuilt, which used to eat a backslash that stood inside them.
        _ok(_run('echo "x\y"/*.zz') eq 'x\y/*.zz',
            'GP16: a backslash inside quotes survives the glob path');
    },

);

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    $name = '' unless defined $name;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
_cleanup();
END { $? = 1 if $fail }
