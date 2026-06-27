######################################################################
#
# 0014-sh-trap.t  SH trap / signal handling (pure-Perl %SIG bridge)
#
# Covers the EXIT pseudo-signal (on normal end and on exit, with deferred
# expansion and cancellation), the %SIG bridge for real signals (install,
# ignore, default, handler execution, real delivery), trap listing, and
# signal-name normalization.
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

# Reset trap state between tests so nothing leaks across cases.  Some of
# these signals are absent on Windows; assigning to them there warns "No such
# signal", so that one warning is filtered out (all others pass through).
sub _reset_traps {
    %BATsh::SH::_SH_TRAP = ();
    local $SIG{__WARN__} = sub {
        my $w = defined $_[0] ? $_[0] : '';
        warn $w unless $w =~ /No such signal/;
    };
    for my $s (qw(INT TERM HUP USR1 USR2 QUIT)) {
        eval { $SIG{$s} = 'DEFAULT' };
    }
}

# Run SH source via BATsh->run_string, capturing STDOUT (including any output
# produced by trap handlers that fire during the run).  $extra is an optional
# coderef run while STDOUT is still redirected (e.g. to deliver a signal).
sub _run_cap {
    my ($source, $extra) = @_;
    _reset_traps();
    BATsh::Env::init();
    my $cap = "$FindBin::Bin/_trap_cap_$$.tmp";
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    close(STDOUT);
    open(STDOUT, "> $cap")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    eval { BATsh->run_string($source) };
    $extra->() if $extra;
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    my $out = '';
    local *RF;
    if (open(RF, $cap)) { local $/; $out = <RF>; close(RF) }
    unlink($cap);
    $out = '' unless defined $out;
    return $out;
}

my @tests = (

    # TR1: EXIT trap runs when the script ends normally
    sub {
        my $o = _run_cap("trap 'echo bye' EXIT\necho working\n");
        _ok($o eq "working\nbye\n", 'TR1: EXIT trap on normal end');
    },

    # TR2: EXIT trap runs on explicit exit
    sub {
        my $o = _run_cap("trap 'echo cleanup' EXIT\necho before\nexit 0\necho after\n");
        _ok($o eq "before\ncleanup\n", 'TR2: EXIT trap on exit (and exit stops the run)');
    },

    # TR3: the handler command is expanded when it fires, not when registered
    sub {
        my $o = _run_cap("trap 'echo removing \$tmp' EXIT\ntmp=/tmp/xyz\necho done\n");
        _ok($o eq "done\nremoving /tmp/xyz\n", 'TR3: EXIT handler deferred expansion');
    },

    # TR4: trap - EXIT cancels a pending EXIT trap
    sub {
        my $o = _run_cap("trap 'echo nope' EXIT\ntrap - EXIT\necho ok\n");
        _ok($o eq "ok\n", 'TR4: trap - EXIT cancels the handler');
    },

    # TR5: EXIT trap fires exactly once (not twice on exit + end)
    sub {
        my $o = _run_cap("trap 'echo once' EXIT\nexit 0\n");
        _ok($o eq "once\n", 'TR5: EXIT trap fires exactly once');
    },

    # TR6: trap 'cmd' INT installs a %SIG handler (CODE ref)
    sub {
        _reset_traps();
        BATsh->run_string("trap 'echo caught' INT");
        my $ok = (ref $SIG{INT} eq 'CODE') ? 1 : 0;
        _reset_traps();
        _ok($ok, 'TR6: trap cmd INT installs a %SIG CODE handler');
    },

    # TR7: invoking the installed handler runs the registered command
    sub {
        my $o = _run_cap("trap 'echo handler-ran' INT", sub {
            $SIG{INT}->('INT') if ref $SIG{INT} eq 'CODE';
        });
        _ok($o eq "handler-ran\n", 'TR7: installed handler runs the command');
    },

    # TR8: trap '' INT sets the signal to IGNORE
    sub {
        _reset_traps();
        BATsh->run_string("trap '' INT");
        my $ok = (defined $SIG{INT} && $SIG{INT} eq 'IGNORE') ? 1 : 0;
        _reset_traps();
        _ok($ok, "TR8: trap '' INT -> IGNORE");
    },

    # TR9: trap - INT restores the default and clears the registry
    sub {
        _reset_traps();
        BATsh->run_string("trap 'echo x' INT");
        BATsh->run_string("trap - INT");
        my $ok = (defined $SIG{INT} && $SIG{INT} eq 'DEFAULT'
                  && !exists $BATsh::SH::_SH_TRAP{'INT'}) ? 1 : 0;
        _reset_traps();
        _ok($ok, 'TR9: trap - INT -> DEFAULT and cleared');
    },

    # TR10: a real signal is delivered to the handler (or, where signals are
    # unavailable, the installed handler is invoked directly -- both paths
    # assert the handler produced its output)
    sub {
        my $o = _run_cap("trap 'echo got-signal' USR2", sub {
            my $sent = 0;
            eval { $sent = kill('USR2', $$) };
            # give safe-signal delivery a chance to run the handler
            eval { select(undef, undef, undef, 0.05) } if $sent;
            if (!$sent && ref $SIG{USR2} eq 'CODE') { $SIG{USR2}->('USR2') }
        });
        _ok($o eq "got-signal\n", 'TR10: signal delivery runs the handler');
    },

    # TR11: trap with no args lists the current traps
    sub {
        my $o = _run_cap("trap 'echo hi' INT\ntrap\n");
        _ok($o eq "trap -- 'echo hi' INT\n", 'TR11: trap lists current traps');
    },

    # TR12: multiple signals registered in one command
    sub {
        _reset_traps();
        BATsh->run_string("trap 'echo m' INT TERM");
        my $ok = (ref $SIG{INT} eq 'CODE' && ref $SIG{TERM} eq 'CODE') ? 1 : 0;
        _reset_traps();
        _ok($ok, 'TR12: one trap command registers multiple signals');
    },

    # TR13: a SIG-prefixed name normalizes to the bare name
    sub {
        _reset_traps();
        BATsh->run_string("trap 'echo x' SIGINT");
        my $ok = (exists $BATsh::SH::_SH_TRAP{'INT'}
                  && ref $SIG{INT} eq 'CODE') ? 1 : 0;
        _reset_traps();
        _ok($ok, 'TR13: SIGINT normalizes to INT');
    },

    # TR14: signal number 0 is the EXIT pseudo-signal
    sub {
        my $o = _run_cap("trap 'echo zero' 0\necho body\n");
        _ok($o eq "body\nzero\n", 'TR14: numeric 0 is the EXIT trap');
    },

);

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { exit 1 if $fail }
