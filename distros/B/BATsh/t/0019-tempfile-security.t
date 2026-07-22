######################################################################
#
# 0019-tempfile-security.t  Regression: command-substitution and SH
#                            pipeline temp files must resist symlink
#                            races and must not be group/world readable.
#
# BACKGROUND
#   Before 0.07, BATsh::SH::_cmd_subst() ($( ... ) / `...` output
#   capture) and BATsh::SH::_exec_sh_pipe() (per-stage stdout->stdin
#   bridge files) opened a PREDICTABLE path in the shared temp
#   directory with a plain open(FH, "> $path"):
#     - no O_EXCL, so a pre-existing symlink at that path was silently
#       followed and written through (classic /tmp symlink race);
#     - the file mode was whatever umask left of the default open()
#       mode (typically 0644, i.e. world-readable), unlike the
#       O_CREAT|O_EXCL, 0600 discipline already used by the
#       background-job pidfile helper (_bg_tempfile) and the
#       here-document helper (_hd_tempfile).
#   0.07 adds BATsh::SH::_subst_tempfile() and _shp_tempfile(), which
#   mirror the existing sysopen(O_CREAT|O_EXCL, 0600) + retry-on-EEXIST
#   pattern.
#
# THIS TEST
#   TS01  command substitution: pre-planting a symlink at the exact
#         first-candidate capture-file path does not corrupt the
#         result and does not write through the symlink.
#   TS02  command substitution: the actual capture file BATsh created
#         is mode 0600 (owner read/write only).
#   TS03  SH pipeline: pre-planting a symlink at the exact
#         first-candidate stage-file path does not corrupt the
#         pipeline's output and does not write through the symlink.
#   TS04  SH pipeline: the actual stage file BATsh created is mode
#         0600.
#   TS05  No stray temp files are left behind after a normal run.
#
#   Symlink checks are skipped (with a documented reason, not silently)
#   on platforms where symlink() is unavailable (e.g. many Windows
#   configurations without developer mode / admin privilege).
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
use File::Spec ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

BATsh::Env::init();

my $TMPDIR = File::Spec->tmpdir();
my $CANARY = File::Spec->catfile($TMPDIR, "batsh_canary_$$.tmp");

# Detect symlink() support without dying (Win32 without privilege, or a
# filesystem that refuses symlinks, returns 0 or dies).
my $HAVE_SYMLINK = eval {
    my $target = File::Spec->catfile($TMPDIR, "batsh_symtest_${$}_t.tmp");
    my $link   = File::Spec->catfile($TMPDIR, "batsh_symtest_${$}_l.tmp");
    open(_TS_T, "> $target") or die; close(_TS_T);
    my $ok = symlink($target, $link) ? 1 : 0;
    unlink $target; unlink $link;
    $ok;
} ? 1 : 0;

# Capture STDOUT produced by $code into a string (Perl 5.005_03
# compatible: bareword filehandles, 2-argument open).
sub _capture {
    my ($code) = @_;
    my $tmpfile = File::Spec->catfile($TMPDIR, "batsh_cap19_$$\.tmp");
    open(_CAP_OLD, '>&STDOUT') or return '';
    open(_CAP_FH,  ">$tmpfile") or do { open(STDOUT, '>&_CAP_OLD'); return '' };
    open(STDOUT, '>&_CAP_FH');
    close(_CAP_FH);
    eval { $code->() };
    open(STDOUT, '>&_CAP_OLD');
    close(_CAP_OLD);
    my $buf = '';
    if (open(_CAP_RFH, "< $tmpfile")) {
        local $/;
        $buf = <_CAP_RFH>;
        close(_CAP_RFH);
    }
    unlink $tmpfile;
    $buf = '' unless defined $buf;
    return $buf;
}

my @tests = (

    ##################################################################
    # 1. Command substitution: symlink race
    ##################################################################

    # TS01: plant a symlink at the exact path _subst_tempfile() will
    # try first in a fresh process ('batsh_cap_<pid>_1_1.tmp': depth
    # and sequence both start at 1 for the first substitution), then
    # confirm BATsh's own output is still correct AND the canary file
    # the symlink points at was never created/written by BATsh (i.e.
    # BATsh did not follow the symlink; it must have skipped past it
    # via O_EXCL retry and used a different file instead).
    sub {
        if (!$HAVE_SYMLINK) {
            _ok(1, 'TS01: skipped (symlink() unsupported here)');
            return;
        }
        unlink $CANARY;
        my $trap = File::Spec->catfile($TMPDIR, "batsh_cap_${$}_1_1.tmp");
        unlink $trap;
        symlink($CANARY, $trap);
        my $out = _capture(sub {
            BATsh->run_string('echo $(echo hello)');
        });
        $out =~ s/[\r\n]+\z//;
        my $canary_written = (-e $CANARY) ? 1 : 0;
        unlink $trap unless -e $CANARY; # remove dangling symlink, keep canary if written (for diagnosis)
        _ok($out eq 'hello' && !$canary_written,
            "TS01: subst does not follow pre-planted symlink (out=[$out] canary_written=$canary_written)");
    },

    ##################################################################
    # 2. Command substitution: file mode
    ##################################################################

    # TS02: the capture file must be 0600 while it exists. We can't
    # observe it mid-flight from outside the process, so we call the
    # internal helper directly and check the mode of what it created.
    sub {
        if ($^O =~ /^(?:MSWin32|dos|os2)$/) {
            _ok(1, "TS02: skipped (POSIX mode bits not meaningful on $^O)");
            return;
        }
        no strict 'refs';
        my $path = &{"BATsh::SH::_subst_tempfile"}();
        my $ok = 0;
        if (defined $path && -f $path) {
            my @st = stat($path);
            $ok = (($st[2] & 07777) == 0600) ? 1 : 0;
        }
        close(*BATsh::SH::_SUBST_CAPFH) if defined fileno(*BATsh::SH::_SUBST_CAPFH);
        unlink $path if defined $path;
        _ok($ok, 'TS02: subst capture file created with mode 0600');
    },

    ##################################################################
    # 3. SH pipeline: symlink race
    ##################################################################

    # TS03: plant a symlink at the exact path _shp_tempfile() will try
    # first for the first stage of a fresh process's first pipeline
    # ('batsh_shp_<pid>_1_0_1.tmp': pipe-depth 1, segment idx 0,
    # sequence 1), then confirm the pipeline's output is still correct
    # and the canary was never created.
    sub {
        if (!$HAVE_SYMLINK) {
            _ok(1, 'TS03: skipped (symlink() unsupported here)');
            return;
        }
        unlink $CANARY;
        my $trap = File::Spec->catfile($TMPDIR, "batsh_shp_${$}_1_0_1.tmp");
        unlink $trap;
        symlink($CANARY, $trap);
        my $out = _capture(sub {
            BATsh->run_string('echo hello | perl -ne "print uc"');
        });
        $out =~ s/[\r\n]+\z//;
        my $canary_written = (-e $CANARY) ? 1 : 0;
        unlink $trap unless -e $CANARY;
        _ok($out eq 'HELLO' && !$canary_written,
            "TS03: pipe stage does not follow pre-planted symlink (out=[$out] canary_written=$canary_written)");
    },

    ##################################################################
    # 4. SH pipeline: file mode
    ##################################################################

    sub {
        if ($^O =~ /^(?:MSWin32|dos|os2)$/) {
            _ok(1, "TS04: skipped (POSIX mode bits not meaningful on $^O)");
            return;
        }
        no strict 'refs';
        my $stub = File::Spec->catfile($TMPDIR, "batsh_shp19_$$");
        my $path = &{"BATsh::SH::_shp_tempfile"}($stub);
        my $ok = 0;
        if (defined $path && -f $path) {
            my @st = stat($path);
            $ok = (($st[2] & 07777) == 0600) ? 1 : 0;
        }
        close(*BATsh::SH::_SH_PIPE_WFH) if defined fileno(*BATsh::SH::_SH_PIPE_WFH);
        unlink $path if defined $path;
        _ok($ok, 'TS04: pipe stage file created with mode 0600');
    },

    ##################################################################
    # 5. No leftover temp files after a normal run
    ##################################################################

    sub {
        my @before = glob(File::Spec->catfile($TMPDIR, 'batsh_cap_*'));
        push @before, glob(File::Spec->catfile($TMPDIR, 'batsh_shp_*'));
        _capture(sub {
            BATsh->run_string(
                'echo $(echo a|perl -ne "print uc"); '
              . 'echo b | perl -ne "print uc" | perl -ne "print lc"');
        });
        my @after = glob(File::Spec->catfile($TMPDIR, 'batsh_cap_*'));
        push @after, glob(File::Spec->catfile($TMPDIR, 'batsh_shp_*'));
        _ok(scalar(@after) <= scalar(@before),
            'TS05: no stray capture/pipe temp files left after a normal run');
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
unlink $CANARY;
END { $? = 1 if $fail }
