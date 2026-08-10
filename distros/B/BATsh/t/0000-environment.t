######################################################################
#
# 0000-environment.t  Print the environment this run happened in
#
# WHY THIS FILE EXISTS
#   This distribution has now received four Windows FAILs, and every one
#   of them arrived without the one thing needed to act on it: a
#   description of the machine it failed on.  A CPAN Testers report
#   carries the perl version and the OS name and almost nothing else,
#   and each of those failures turned on something the report did not
#   say -- the spelling of $HOME, whether the working directory was on
#   the same drive as $HOME, which ANSI code page was current, whether
#   the file system could hold a particular byte sequence in a name.
#   Guessing at those cost a release each time.
#
#   So this file guesses at nothing and asks the machine instead, and
#   prints the answers as TAP comments, which every harness carries
#   through into the report.  It runs first because it is numbered 0000,
#   so the fingerprint sits at the top of the report and above whatever
#   failed below it.
#
#   It is a REPORT, not an assertion.  It has exactly one test and that
#   test always passes: a fingerprint that can itself fail is one more
#   thing to diagnose rather than the means of diagnosing.  Nothing here
#   should ever be turned into a check -- put the check in the file that
#   cares about the property, where a failure names the behaviour that
#   broke.  See rule R7 in t/lib/BATsh_TestOS.pm.
#
#   Nothing is created that is not removed again, and no value is
#   printed that a smoker report does not already carry: the names of
#   environment variables and the SHAPE of the paths, not the contents
#   of the machine.  $HOME and the working directory are printed in
#   full because they are the operands of the cases that keep failing,
#   and a smoker's are a scratch directory.
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
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use BATsh_TestOS qw(is_windows posix_file_semantics have_getpwnam
                    have_symlink writable_dir path_shape fs_can_hold_name
                    shell_safe_path argv_space_safe);

# Cwd is core everywhere this distribution runs, but a fingerprint that
# dies because a module is missing tells nobody anything.
BEGIN { eval { require Cwd } }

sub _cwd {
    return defined(&Cwd::cwd) ? Cwd::cwd() : '(Cwd unavailable)';
}

sub _say {
    my ($key, $value) = @_;
    $value = '(undef)' unless defined $value;
    $value =~ s/[\r\n]+/ | /g;
    print "# $key: $value\n";
    return 1;
}

######################################################################
# perl and platform.  %Config is core since 5.000, but a fingerprint
# that dies is worse than one that says "unknown".
######################################################################
sub _Config_archname {
    my $v = '(unknown)';
    # One line, so that the dependency scan reads the eval as the guard
    # it is and does not report Config as a test prerequisite.
    my $have = eval { require Config };
    if ($have && defined $Config::Config{'archname'}) {
        $v = $Config::Config{'archname'};
    }
    return $v;
}

######################################################################
# The environment variables that have decided a FAIL, listed so that the
# report says which of them were set.  The NAME is what matters here;
# the values are long, machine-specific and, for the ones that decide
# behaviour, boolean in practice.  $HOME is printed in full above,
# because it is the operand of the cases that keep failing.
######################################################################
my @FLAG_VARS  = qw(
    HOMEDRIVE HOMEPATH USERPROFILE
    TEMP TMP TMPDIR
    COMSPEC SHELL PATHEXT
    PERL5LIB PERL5OPT PERLIO PERL_UNICODE PERL_MM_OPT PERL_MM_USE_DEFAULT
    AUTOMATED_TESTING NONINTERACTIVE_TESTING EXTENDED_TESTING RELEASE_TESTING
    HARNESS_ACTIVE HARNESS_OPTIONS HARNESS_PERL_SWITCHES
    LANG LC_ALL LC_CTYPE
);

my @tests = (

    sub {
        print "# ------------------------------------------------------------\n";
        print "# BATsh environment fingerprint (report only; always passes)\n";
        print "# ------------------------------------------------------------\n";

        _say('perl', $]);
        _say('executable', $^X);
        _say('osname', $^O);
        _say('archname', _Config_archname());
        _say('is_windows', is_windows() ? 'yes' : 'no');
        _say('posix_file_semantics', posix_file_semantics() ? 'yes' : 'no');
        # Which File::Spec subclass is in force decides what catdir()
        # and splitpath() do with a volume and a separator.
        {
            no strict 'refs';
            my @isa = @{'File::Spec::ISA'};
            _say('File::Spec class', @isa ? $isa[0] : '(none)');
        }

        # Where the harness started us, and how it is spelled.  A case
        # that probes relatively (rule R1) probes from HERE, so this is
        # half of every such probe.
        my $cwd = _cwd();
        _say('cwd', $cwd);
        _say('cwd shape', path_shape($cwd));

        # Rule R8: several cases interpolate the build directory into
        # shell or cmd.exe source.  They quote it, which handles the
        # common Windows case of a space; a spelling that quoting cannot
        # survive makes those cases skip, and a report that does not say
        # so looks like unexplained missing coverage.
        _say('build path usable in shell source',
             shell_safe_path($FindBin::Bin) ? 'yes' : 'no (cases will skip)');

        # Win32 has no argv: perl rebuilds a command line and the child
        # takes it apart again, so an argument containing a space depends
        # on two quoting implementations agreeing.  Where they do not,
        # cases that hand inline source to a child skip (rule R9), and a
        # report that does not say so looks like missing coverage.
        _say('system(LIST) keeps a space inside one argument',
             argv_space_safe() ? 'yes' : 'no (cases will skip)');

        my $home = exists $ENV{'HOME'} ? $ENV{'HOME'} : undef;
        _say('HOME', $home);
        _say('HOME shape', path_shape($home));
        if (defined $home && $home ne '') {
            _say('HOME is a directory', (-d $home) ? 'yes' : 'no');
            _say('HOME readable', (-r $home) ? 'yes' : 'no');
            _say('HOME writable (probed)', writable_dir($home) ? 'yes' : 'no');
        }

        # Windows keeps a current directory per drive, so "the same
        # relative path" means different things depending on whether
        # $HOME and the working directory share a volume.
        if (defined $home && $home ne '' && $cwd ne '') {
            my ($hv) = File::Spec->splitpath($home);
            my ($cv) = File::Spec->splitpath($cwd);
            $hv = '' unless defined $hv;
            $cv = '' unless defined $cv;
            _say('same volume as cwd',
                 (lc($hv) eq lc($cv)) ? 'yes' : "no (HOME=$hv cwd=$cv)");
        }

        for my $var (@FLAG_VARS) {
            next unless exists $ENV{$var};
            my $v = $ENV{$var};
            $v = '' unless defined $v;
            # Length rather than content: PATHEXT and PERL5LIB are long
            # and are only ever interesting for being set at all.
            _say("env $var", (length($v) > 60)
                 ? '(set, ' . length($v) . " chars)" : "'$v'");
        }
        my @unset = grep { !exists $ENV{$_} } @FLAG_VARS;
        _say('env unset', @unset ? join(' ', @unset) : '(none)');

        # A console is not a pipe.  The author runs the suite on a
        # terminal and the smokers do not, and code that asks whether it
        # is talking to one behaves differently in the two.
        _say('STDIN is a tty', (-t STDIN) ? 'yes' : 'no');
        _say('STDOUT is a tty', (-t STDOUT) ? 'yes' : 'no');

        # Capabilities the suite skips on rather than fails on.  Printing
        # them makes a report say which cases actually ran.
        _say('getpwnam', have_getpwnam() ? 'available' : 'unimplemented');

        my $tdir = $FindBin::Bin;
        _say('symlink in t/', have_symlink($tdir) ? 'works' : 'unavailable');
        _say('t/ writable (probed)', writable_dir($tdir) ? 'yes' : 'no');

        # The t/0015 CP12 question: can a name carrying a CP932 trail
        # byte of 0x5C exist here at all?  "\x{83}\x{5C}" is the CP932
        # encoding of a single character whose second byte is the
        # backslash; whether the file system accepts it is decided by
        # the ANSI code page, not by BATsh.
        my $cp932 = "batsh_cp932_\x83\x5C_$$";
        _say('CP932 trail-byte name',
             fs_can_hold_name($tdir, $cp932) ? 'accepted' : 'rejected');

        # Case folding decides whether two spellings of one name are the
        # same file, which is the whole subject of rules R1 and R2.
        my $lower = "batsh_case_probe_$$";
        my $upper = uc($lower);
        my $folds = 'unknown';
        if (fs_can_hold_name($tdir, $lower)) {
            local *T0000_FH;
            my $path = File::Spec->catfile($tdir, $lower);
            if (open(T0000_FH, "> $path")) {
                close(T0000_FH);
                $folds = (-e File::Spec->catfile($tdir, $upper))
                       ? 'case-insensitive' : 'case-sensitive';
                unlink($path);
            }
        }
        _say('file name case', $folds);

        # Rule R10: which external filters exist decides whether the
        # pipeline cases in t/0034 run or skip.  A green report has to
        # say which -- otherwise "45 files OK" on a machine with no
        # filters looks the same as one where those cases really ran.
        my @filters = ();
        for my $c (qw(sort cat find more)) {
            push @filters, $c if BATsh_TestOS::have_external($c);
        }
        _say('external filters', scalar(@filters) ? join(' ', @filters) : 'none');

        print "# ------------------------------------------------------------\n";
        _ok(1, 'ENV01: environment reported (this case never fails)');
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
END { $? = 1 if $fail }
