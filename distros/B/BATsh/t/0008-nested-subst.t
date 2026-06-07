######################################################################
#
# 0008-nested-subst.t  Regression: nested command substitution
#                      $( ... $( ... ) ) -- including pipelines at
#                      each level -- must capture correctly on BOTH
#                      cmd.exe (Windows) AND /bin/sh (Unix/BSD).
#
# BACKGROUND
#   BATsh::SH captures command-substitution output through a temporary
#   file and runs SH pipelines through per-stage temporary files.  Three
#   distinct defects made a nested $( ... ) collapse to an empty string
#   (Unix) or hang (Unix), while behaving differently again on Windows:
#
#   (1) CAPTURE-FILE COLLISION -- _cmd_subst() named its capture file
#       with the process id alone (batsh_cap_$$.tmp).  An inner $(...)
#       reused the very same path and unlink()'d it, so the outer level
#       captured nothing.  Fixed by tagging the file with the active
#       substitution-nesting depth.
#
#   (2) PIPELINE-SPLIT DEPTH -- _split_sh_pipe() counted the '(' of a
#       "$(" twice, so after a nested $(...) the $( nesting depth was
#       stuck at 1 and a bare '|' that followed it was not recognised as
#       a pipe.  Fixed by consuming both characters of "$(" and bumping
#       the depth exactly once.
#
#   (3) PIPE-STAGE COLLISION + UNLOCALIZED HANDLES -- _exec_sh_pipe()
#       named its stage files with the process id alone (batsh_shp_$$)
#       and left its dup STDOUT/STDIN globs un-local()ised.  A nested
#       pipeline (a segment whose $(...) body is itself a pipeline) then
#       clobbered the outer pipeline's stage file and saved handles; the
#       outer's final segment found no input file and blocked on the real
#       STDIN (a hang on Unix).  Fixed by tagging the stage files with the
#       active pipeline-nesting depth and local()ising the handle globs.
#
# THIS TEST
#   NS01/NS02  pure-builtin nesting (no external command): proves the
#              capture-file depth fix independently of any "perl" on PATH.
#   NS03       single-level $(...) that contains a pipeline (baseline).
#   NS04/NS05  nested $(...) with a pipeline at each level: the core
#              regression for defects (2) and (3).
#   NS06       two sibling $(...) pipelines on one line: no cross-collision
#              between non-overlapping substitutions/pipelines.
#   NS07       assignment from a nested pipeline substitution, then reuse.
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

# Portability: NS03..NS07 shell out to a bareword "perl".  On a CPAN
# smoker the perl under test is frequently NOT on PATH as "perl"
# (perlbrew/plenv, or perl invoked by absolute path), which would turn
# these checks into false failures.  Prepend the directory of the
# running interpreter ($^X) to PATH so "perl" resolves to it.  Done by
# environment (not by embedding $^X in the command) so a Win32 path with
# backslashes never reaches SH-mode quote/escape processing.  Must
# precede the first init(): init() snapshots %ENV into STORE and
# sync_to_env() later copies STORE back to %ENV.
{
    my ($pvol, $pdirs) = File::Spec->splitpath($^X);
    my $perldir = File::Spec->catpath($pvol, $pdirs, '');
    if (length $perldir) {
        my $sep = ($^O =~ /^(?:MSWin32|dos|os2)$/) ? ';' : ':';
        $ENV{'PATH'} = (defined($ENV{'PATH'}) && length($ENV{'PATH'}))
                     ? "$perldir$sep$ENV{'PATH'}" : $perldir;
    }
}
BATsh::Env::init();

my @tests = (

    ##################################################################
    # 1. Pure-builtin nesting (no external command required)
    ##################################################################

    # NS01: one level of nesting using only the echo builtin.
    sub {
        my $out = _capture(sub {
            BATsh->run_string('echo $(echo a-$(echo b))');
        });
        $out =~ s/[\r\n]+\z//;
        _ok($out eq 'a-b', "NS01: builtin nested subst (got [$out])");
    },

    # NS02: three levels of nesting using only the echo builtin.
    sub {
        my $out = _capture(sub {
            BATsh->run_string('echo $(echo $(echo $(echo z)))');
        });
        $out =~ s/[\r\n]+\z//;
        _ok($out eq 'z', "NS02: triple builtin nesting (got [$out])");
    },

    ##################################################################
    # 2. Substitution containing a pipeline (single level baseline)
    ##################################################################

    # NS03: $( cmd | perl ... ) captured into the surrounding word.
    sub {
        my $out = _capture(sub {
            BATsh->run_string('echo R=$(echo hi | perl -ne "print uc")');
        });
        $out =~ s/[\r\n]+\z//;
        _ok($out eq 'R=HI', "NS03: subst with pipeline (got [$out])");
    },

    ##################################################################
    # 3. Nested substitution with a pipeline at each level
    ##################################################################

    # NS04: inner $( | ) feeds an outer $( | ).
    sub {
        my $out = _capture(sub {
            BATsh->run_string(
                'echo $(echo $(echo x|perl -ne "print uc")|perl -ne "print uc")');
        });
        $out =~ s/[\r\n]+\z//;
        _ok($out eq 'X', "NS04: nested subst + pipeline (got [$out])");
    },

    # NS05: deeper nesting, literal text preserved around each level.
    sub {
        my $out = _capture(sub {
            BATsh->run_string(
                'echo outer-$(echo inner-$(echo deep|perl -ne "print uc")'
              . '|perl -ne "print uc")');
        });
        $out =~ s/[\r\n]+\z//;
        _ok($out eq 'outer-INNER-DEEP',
            "NS05: deep nested subst + pipeline (got [$out])");
    },

    ##################################################################
    # 4. Sibling substitutions must not collide
    ##################################################################

    # NS06: two independent $( | ) on one line, joined by a literal '-'.
    sub {
        my $out = _capture(sub {
            BATsh->run_string(
                'echo $(echo a|perl -ne "print uc")-$(echo b|perl -ne "print uc")');
        });
        $out =~ s/[\r\n]+\z//;
        _ok($out eq 'A-B', "NS06: sibling subst pipelines (got [$out])");
    },

    ##################################################################
    # 5. Assignment from a nested pipeline substitution, then reuse
    ##################################################################

    # NS07: VAR=$( | ) then a second $( | ) consuming $VAR.
    sub {
        my $out = _capture(sub {
            BATsh->run_string(
                'X=$(echo low|perl -ne "print uc"); '
              . 'echo v-$X-$(echo $X|perl -ne "print lc")');
        });
        $out =~ s/[\r\n]+\z//;
        _ok($out eq 'v-LOW-low',
            "NS07: assign from nested pipeline subst (got [$out])");
    },

);

######################################################################
# Helpers
######################################################################

# Capture STDOUT produced by $code into a string (Perl 5.005_03
# compatible: bareword filehandles, 2-argument open).
sub _capture {
    my ($code) = @_;
    my $tmpfile = File::Spec->catfile(
        File::Spec->tmpdir(), "batsh_cap8_$$\.tmp");
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

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    $name = '' unless defined $name;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { $? = 1 if $fail }
