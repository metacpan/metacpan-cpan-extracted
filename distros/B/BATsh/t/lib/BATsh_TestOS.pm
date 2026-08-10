######################################################################
#
# BATsh_TestOS.pm  Platform semantics for the BATsh test suite
#
# WHY THIS FILE EXISTS
#   BATsh is a cmd.exe emulator, so its main platform is the one the
#   author cannot smoke locally.  Every Windows FAIL this distribution
#   has received so far was a TEST defect, not a shell defect, and each
#   one was an assumption about Win32 that had been written inline in a
#   single .t file and never reviewed:
#
#     * a pathname was compared as a STRING, and Cwd::cwd(),
#       Cwd::realpath() and the string handed to chdir() do not agree on
#       Win32 about separator direction, drive-letter case or 8.3 short
#       names                       (t/0020 TE01/TE02, twice; t/0030 EL16)
#     * a POSIX-only guarantee was asserted -- open(O_CREAT|O_EXCL) does
#       not follow a symlink, and mode bits mean something -- neither of
#       which Win32 owes anybody              (t/0019 TS01-TS04)
#     * a filename was assumed to be storable, when the ANSI code page
#       decides whether it is                          (t/0015 CP12)
#     * getpwnam() was assumed to exist                (t/0020 TE03)
#
#   Written inline, each of those has to be re-derived by whoever adds
#   the next test, and gets re-derived wrongly.  They live here instead,
#   named once, so that a new case reuses a reviewed predicate rather
#   than inventing a fresh guess.
#
# RULES FOR ASSERTIONS IN THIS SUITE
#   These are the conclusions drawn from those failures.  They are not
#   style preferences; every one of them corresponds to a FAIL that was
#   shipped to CPAN Testers.
#
#   R1  Never compare pathnames as strings.  Decide "did we reach the
#       right directory?" with a MARKER and a RELATIVE file test made
#       from the directory the code under test moved to.  A relative
#       probe has no spelling, so it cannot disagree with anything.
#       Use dir_marker() / in_marked_dir() / drop_marker() below.
#
#   R2  Never assert on text produced by the operating system.  Windows
#       error strings are localised; "No such file or directory" is not
#       a promise anyone made.  Assert on exit status instead.
#
#   R3  Never write an assertion that prints nothing when it fails.  A
#       bare "not ok" cannot be diagnosed from a CPAN Testers report --
#       the 0.10 FAIL could not be resolved without shipping 0.11 for
#       that reason alone.  Print the operands with tap_diag().
#
#   R4  When the platform cannot support what the case assumes, SKIP
#       with a printed reason; do not fail.  A skip that says why is a
#       report about the platform; a fail is a false accusation about
#       the shell.  Probe first (posix_file_semantics(), have_getpwnam(),
#       fs_can_hold_name()) rather than testing $^O at the call site.
#
#   R5  A newly enabled case has never run on Windows.  t/0020 TE02 sat
#       silently passing behind a failed "require File::Temp" until 0.10
#       made it real, and it failed on the first Windows smoker that saw
#       it.  Run xt/win32_matrix.pl before releasing anything that turns
#       an assertion on.
#
#   R6  "It passed on my Windows box" is not evidence.  Every FAIL this
#       distribution has received passed a local "pmake test" first, and
#       the author's console is not the smoker's environment: a smoker
#       has no PERL5LIB, no PERL5OPT, no interactive STDIN, no console
#       code page of its own choosing, AUTOMATED_TESTING set, and a
#       $HOME the author never picked.  xt/win32_matrix.pl reproduces
#       that environment rather than the author's; run it, and do not
#       treat a bare local run as a release gate.
#
#   R7  A green report must still say what it was green ON.  When a
#       spurious-looking FAIL does arrive, the only difference between
#       an actionable report and a guess is knowing what the smoker's
#       environment was.  t/0000-environment.t prints that fingerprint
#       on every run, pass or fail; keep it passing unconditionally so
#       that it can never itself become the failure being diagnosed.
#
#       And a corollary that cost 30 matrix cells in 0.11: PROGRAM TEXT
#       must not travel through argv at all.  t/9070 ran the examples
#       with "-e 'BATsh->run($ARGV[0])'".  That operand contains '>',
#       which is a cmd.exe redirection character; once ANOTHER argument
#       on the same command line needed quoting -- which happened as soon
#       as the build path contained a space or parentheses -- Windows
#       routed the line through cmd.exe, which cut the program text at
#       the '>'.  Every example then reported a syntax error and zero
#       output, in 30 of 90 cells, with nothing wrong in lib/.  A
#       pathname in argv needs quoting and is fine; program text needs
#       shell escaping and is not.  Run bin/batsh.pl instead of -e.
#
#   R10 AN EXTERNAL COMMAND NAMED IN A CASE IS AN ASSUMPTION ABOUT THE
#       MACHINE, not about BATsh.  A pipeline case has to send its output
#       somewhere, and the obvious somewhere is a small filter -- but
#       "cat", "head", "wc", "tr", "grep" and "sed" are not present on a
#       plain Windows installation, and a case that names one reports a
#       FAIL for a program that was never there.  BATsh-0.11 shipped
#       exactly that: t/0034 TAIL10 piped a compound into "cat" and drew
#       a FAIL on MSWin32 with nothing wrong in lib/, alongside cmd.exe's
#       own "'cat' is not recognized" on the console.  Therefore: probe
#       with have_external() and skip with a reason, or -- better -- do
#       not need an external command at all.  Note that this is a
#       DIFFERENT rule from R2: R2 forbids inspecting the TEXT an OS
#       command prints; R10 forbids assuming the command EXISTS.
#
#   R8  The build directory's SPELLING belongs to the tester, not to us.
#       A case that interpolates a path derived from $FindBin::Bin into
#       shell or cmd.exe source is putting a string this distribution
#       never chose into a language that has opinions about it -- and on
#       Windows that string very often contains a space:
#       "C:\Users\John Doe\...", "C:\Documents and Settings\...",
#       "C:\Program Files (x86)\...".  Unquoted, BATsh word-splits it
#       exactly as bash would, so the case fails and accuses the shell of
#       a defect that lives in the test.  Therefore: always QUOTE such an
#       operand, as a user would have to; and where the spelling carries
#       a character that shell source cannot carry at all -- a quote, a
#       backtick, $ % & ; # | < > -- skip with a reason rather than fail.
#       Use shell_safe_path() below.  A case that needs no directory part
#       at all is better still: a bare basename has nothing to quote.
#
#   R9  A CHILD PROCESS ARGUMENT that contains a space is not carried
#       reliably by every perl.  Win32 has no argv: perl joins the LIST
#       form of system() back into one command line and the child takes
#       it apart again, so an argument containing a space depends on two
#       independent quoting implementations agreeing.  BATsh-0.11 shipped
#       a case that ran "batsh.pl -e 'echo WORD'" and it arrived at the
#       child as two arguments on a Windows smoker, which made the test
#       report a shell defect that did not exist.  Prefer a space-free
#       argument for the case that must always run, and gate the
#       space-carrying variant on argv_space_safe() below.  This says
#       nothing about BATsh: a user typing the same line at a cmd.exe
#       prompt hands the argument to the child directly, and cmd.exe
#       quotes it correctly.
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
package BATsh_TestOS;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use File::Spec ();

use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);

$VERSION = '0.04';
$VERSION = $VERSION;

@EXPORT_OK = qw(
    is_windows
    posix_file_semantics
    have_getpwnam
    have_external
    fs_can_hold_name
    have_symlink
    writable_dir
    path_shape
    shell_safe_path
    argv_space_safe
    dir_marker
    in_marked_dir
    drop_marker
    existing_entry
    tap_diag
);

######################################################################
# is_windows -- a NATIVE Windows perl.
#
# cygwin is deliberately absent: it provides POSIX file semantics, real
# symlinks and getpwnam(), so lumping it in here would skip cases that
# it can and should run.  Where a test needs "backslash is a separator"
# rather than "POSIX guarantees do not hold" -- pathname globbing, for
# instance -- cygwin does belong, and that test says so itself; this
# predicate is about the guarantees, not about the separator.
######################################################################
sub is_windows {
    return ($^O =~ /^(?:MSWin32|dos|os2)$/) ? 1 : 0;
}

######################################################################
# posix_file_semantics -- true when the file system layer keeps the
# POSIX promises this suite relies on:
#
#   * sysopen(O_CREAT|O_EXCL) refuses to follow a symbolic link, so a
#     planted link cannot redirect a freshly created temp file;
#   * the mode argument of sysopen()/mkdir() reaches the file, so a
#     0600 check means something.
#
# Win32 keeps neither.  CreateFile(CREATE_NEW) resolves a reparse point
# and creates the target, and the mode argument is very nearly a no-op.
# On a Windows box where symlink() happens to work (Windows 10 or later
# with developer mode) a test that assumes otherwise reports a
# difference in operating system semantics as a BATsh bug.
######################################################################
sub posix_file_semantics {
    return is_windows() ? 0 : 1;
}

######################################################################
# have_getpwnam -- true when getpwnam() is implemented.  It is not on
# native Windows perl, where calling it dies with "unimplemented".  A
# case that resolves ~user needs this; BATsh itself treats ~user as a
# no-op wherever this is false.
######################################################################
sub have_getpwnam {
    my $ok = 1;
    eval {
        local $SIG{'__DIE__'} = 'DEFAULT';
        my @pw = getpwnam('root');
        @pw = @pw;
    };
    $ok = 0 if $@;
    return $ok;
}

######################################################################
# fs_can_hold_name -- can this file system hold a file with exactly
# these bytes in its name?
#
# Asked, not assumed.  A CP932 name whose trail byte is 0x5C is legal on
# a Japanese Windows and rejected with ENOENT by a Windows perl whose
# ANSI code page is UTF-8, before any BATsh code is reached.  The probe
# is plain perl -- sysopen(), the same O_CREAT|O_EXCL claim the rest of
# the distribution uses -- so a failure here is the platform's answer
# and not a statement about the shell.
#
#   fs_can_hold_name($dir, $name) -> 1 | 0
#
# The probe file is removed again; the directory is left as it was.
######################################################################
sub fs_can_hold_name {
    my ($dir, $name) = @_;
    return 0 unless defined $dir && defined $name && $name ne '';
    my $path = File::Spec->catfile($dir, $name);
    my $made = 0;
    local *_TOS_PROBE;
    {
        # The refusal is the answer, so the platform's complaint about it
        # ("Invalid \0 character in pathname", and its Win32 equivalents)
        # must not reach the harness as a stray warning.
        local $SIG{'__WARN__'} = sub { 1 };
        if (sysopen(_TOS_PROBE, $path, O_WRONLY | O_CREAT | O_EXCL)) {
            $made = 1;
            close(_TOS_PROBE);
        }
    }
    my $ok = ($made && -f $path) ? 1 : 0;
    unlink($path) if $made;
    return $ok;
}

######################################################################
# dir_marker -- claim a uniquely named subdirectory inside $dir and
# return its BASENAME, or '' when $dir cannot be written.
#
# mkdir() is itself the atomic claim, exactly as the rest of this
# distribution uses sysopen(O_CREAT|O_EXCL) rather than a temp-file
# module (File::Temp entered core in 5.6.1 and this distribution
# supports 5.005_03, where a "require File::Temp" fails silently and
# leaves the case passing without having tested anything).
#
#   my $mark = dir_marker($dir, 'te02');
#
# The basename is what the caller wants: it is probed RELATIVELY, from
# whatever spelling of $dir the code under test arrived at.  See R1.
######################################################################
sub dir_marker {
    my ($dir, $tag) = @_;
    return '' unless defined $dir && $dir ne '' && -d $dir;
    $tag = 'mark' unless defined $tag && $tag ne '';
    for my $try (0 .. 99) {
        my $cand = "batsh_${tag}_${$}_$try";
        if (mkdir(File::Spec->catdir($dir, $cand), 0700)) {
            return $cand;
        }
    }
    return '';
}

######################################################################
# in_marked_dir -- the R1 probe.  Called AFTER the code under test has
# changed directory: true when the marker is visible relatively, which
# is true if and only if the current directory really is the marked one.
# No pathname is spelled, so no two spellings can disagree.
######################################################################
sub in_marked_dir {
    my ($mark) = @_;
    return 0 unless defined $mark && $mark ne '';
    return (-e $mark) ? 1 : 0;
}

######################################################################
# drop_marker -- remove a marker made by dir_marker().  Must not be
# called while the marker's parent is the current directory on Win32,
# which refuses to remove a directory in use.
######################################################################
sub drop_marker {
    my ($dir, $mark) = @_;
    return 0 unless defined $dir && defined $mark && $mark ne '';
    return rmdir(File::Spec->catdir($dir, $mark)) ? 1 : 0;
}

######################################################################
# existing_entry -- the name of an entry that already exists in $dir AND
# is not visible from the current directory, or '' when there is none
# (or $dir cannot be read).
#
# This is the read-only form of a marker: a case that wants to prove it
# reached $dir can probe an entry that is already there instead of
# creating one, so it keeps working where $dir is not writable.
#
# The second condition is what makes the probe mean anything.  A marker
# that is ALSO present in the directory the caller starts from would be
# found by the relative probe whether the code under test moved or not,
# so the case would pass without having tested the move -- and that is
# not hypothetical: a smoker that sets $HOME to the build directory
# makes every entry of $HOME visible from the working directory the
# harness starts in.  A vacuous pass is a worse outcome than a skip,
# because it hides the case forever instead of for one run.  Where no
# distinguishing entry exists the caller gets '' and skips with a
# reason, per rule R4.
######################################################################
sub existing_entry {
    my ($dir) = @_;
    return '' unless defined $dir && $dir ne '' && -d $dir;
    my $found = '';
    local *_TOS_DH;
    if (opendir(_TOS_DH, $dir)) {
        my @names = sort readdir(_TOS_DH);
        closedir(_TOS_DH);
        for my $nm (@names) {
            next if $nm eq '.' || $nm eq '..';
            next unless -e File::Spec->catfile($dir, $nm);
            # Already reachable from here, so finding it later would
            # prove nothing.
            next if -e $nm;
            $found = $nm;
            last;
        }
    }
    return $found;
}

######################################################################
# have_symlink -- true when symlink() is implemented AND actually works
# in $dir.  Both halves are needed: Win32 perl has had the function
# since 5.16 but it fails without the privilege, and a FAT or network
# file system refuses it everywhere.  Asked, not assumed (rule R4).
#
# The link is removed again.  Nothing is created when the probe fails.
######################################################################
sub have_symlink {
    my ($dir) = @_;
    return 0 unless defined $dir && $dir ne '' && -d $dir;
    my $link = File::Spec->catfile($dir, "batsh_tos_symlink_$$");
    my $made = 0;
    {
        local $SIG{'__WARN__'} = sub { 1 };
        $made = eval {
            local $SIG{'__DIE__'} = 'DEFAULT';
            symlink('.', $link) ? 1 : 0;
        };
        $made = 0 unless defined $made;
    }
    # symlink('.', ...) names a directory, and on Win32 that produces a
    # DIRECTORY symlink, which unlink() cannot always remove -- it needs
    # rmdir().  Try both rather than leave a link behind in t/: a probe
    # that litters the tree it is probing is its own kind of defect.
    if ($made) {
        unlink($link) or rmdir($link);
    }
    return $made ? 1 : 0;
}

######################################################################
# writable_dir -- true when a new entry can be created in $dir right
# now.  -w is not the answer on Win32, where it reports the read-only
# attribute and says nothing about the ACL that will actually decide.
######################################################################
sub writable_dir {
    my ($dir) = @_;
    return 0 unless defined $dir && $dir ne '' && -d $dir;
    my $probe = "batsh_tos_w_$$";
    my $ok = fs_can_hold_name($dir, $probe);
    return $ok;
}

######################################################################
# have_external -- true when an external command of this name can be
# found on PATH.  The rule R10 predicate.
#
# Windows needs PATHEXT: "sort" is really "sort.exe" and a bare -f test
# on the name alone answers false for every command on the system.  The
# executable bit is not tested there either -- Windows does not have one,
# and -x answers from the file extension, which is what PATHEXT already
# covered.  No child process is started: asking the file system is both
# cheaper and quiet, where running "cmd /c name" would print cmd.exe's
# own diagnostic to the console of a passing test run.
######################################################################
sub have_external {
    my ($name) = @_;
    return 0 unless defined $name && $name ne '';
    return 0 if $name =~ /[\\\/]/;   # a path, not a command name

    my $path = defined $ENV{'PATH'} ? $ENV{'PATH'} : '';
    return 0 if $path eq '';

    my $win = is_windows();
    my $sep = $win ? ';' : ':';

    my @ext = ('');
    if ($win) {
        my $pe = defined $ENV{'PATHEXT'} && $ENV{'PATHEXT'} ne ''
               ? $ENV{'PATHEXT'} : '.COM;.EXE;.BAT;.CMD';
        for my $e (split(/;/, $pe)) { push @ext, $e if defined $e && $e ne '' }
    }

    for my $dir (split(/\Q$sep\E/, $path)) {
        next if !defined $dir || $dir eq '';
        for my $e (@ext) {
            my $file = File::Spec->catfile($dir, $name . $e);
            next unless -f $file;
            return 1 if $win;
            return 1 if -x $file;
        }
    }
    return 0;
}

######################################################################
# shell_safe_path -- true when $path may be interpolated into shell or
# cmd.exe source INSIDE DOUBLE QUOTES and come out the other side as the
# same pathname.  The rule R8 predicate.
#
# The rejected characters are the ones that survive double quoting and
# still mean something: the quotes themselves (which would close the
# quoting), the backtick and $ (command and parameter substitution in
# sh), % (parameter substitution in cmd.exe), and & ; # | < > (command
# separators and redirections that BATsh re-reads after expansion, as
# cmd.exe and bash both do).  Each of those was reached by trying it:
# unpacking this distribution into a directory so named makes a case
# fail with nothing wrong in lib/.
#
# A space is NOT rejected, and must not be: it is the common Windows
# case, and double quoting is exactly the answer to it.  Nor are ( )
# rejected -- "C:\Program Files (x86)" has to keep working.
######################################################################
sub shell_safe_path {
    my ($path) = @_;
    return 0 unless defined $path && $path ne '';
    return 0 if $path =~ /["'`\$%&;\#|<>\r\n]/;
    return 1;
}

######################################################################
# path_shape -- a one-line, printable description of how a pathname is
# SPELLED, for the environment fingerprint.  The pathname itself is
# printed alongside it; this names the properties that have actually
# changed behaviour, so that a report can be read without having to
# count characters in it.
######################################################################
sub path_shape {
    my ($path) = @_;
    return 'undef' unless defined $path;
    return 'empty'  if $path eq '';
    my @f;
    push @f, 'backslash'    if $path =~ /\\/;
    push @f, 'forward-slash' if $path =~ m{/};
    push @f, 'trailing-sep' if $path =~ m{[\\/]\z};
    push @f, 'space'        if $path =~ /\s/;
    push @f, 'drive'        if $path =~ /\A[A-Za-z]:/;
    push @f, 'unc'          if $path =~ m{\A[\\/][\\/]};
    push @f, 'non-ascii'    if $path =~ /[^\x20-\x7E]/;
    push @f, 'plain' unless @f;
    push @f, 'len=' . length($path);
    return join(',', @f);
}

######################################################################
# argv_space_safe -- does system(LIST) hand a space-carrying argument
# to the child as ONE argument?
#
# Unix passes argv as a vector, so the answer there is always yes.  Win32
# has no argv at the system-call level: perl joins the list back into a
# single command line, quoting what it thinks needs quoting, and the
# child's C runtime splits it again.  The two do not always agree, and
# when they disagree a test that runs "prog -e 'echo WORD'" sees the
# child receive "echo" and "WORD" separately -- which looks exactly like
# the program under test mis-parsing its own options (rule R9).
#
# This asks the question directly rather than guessing from $^O: it runs
# a child perl whose only job is to report how many arguments it got,
# through its exit status, so no output has to be captured.  The answer
# costs one process and is cached.
######################################################################
use vars qw($ARGV_SPACE_SAFE);
sub argv_space_safe {
    return $ARGV_SPACE_SAFE if defined $ARGV_SPACE_SAFE;
    # The -e source is itself space-free, so the probe survives even on
    # a perl that would split it -- otherwise it could not run on the
    # very platform it exists to detect.
    my $rc = system($^X, '-e', 'exit(0+@ARGV)', 'one two');
    $ARGV_SPACE_SAFE = ($rc >= 0 && ($rc >> 8) == 1) ? 1 : 0;
    return $ARGV_SPACE_SAFE;
}

######################################################################
# tap_diag -- the R3 printer.  Emits TAP comments, which every harness
# carries through to the CPAN Testers report:
#
#   tap_diag('TE02', "HOME=$home", "want=$want", "got=$got");
#
#     # TE02 HOME=C:\home\flower
#     # TE02 want=C:/home/flower/batsh_te02_1_0
#     # TE02 got=C:/cpan/build/BATsh-0.11/t
#
# Embedded newlines are folded so that one call cannot be mistaken for
# several TAP lines, and an undefined operand prints as (undef) rather
# than vanishing -- "got=" with nothing after it is exactly the kind of
# report that cannot be acted on.
######################################################################
sub tap_diag {
    my ($tag, @msg) = @_;
    $tag = '?' unless defined $tag && $tag ne '';
    for my $m (@msg) {
        my $line = defined($m) ? $m : '(undef)';
        $line =~ s/\s+\z//;
        $line =~ s/[\r\n]+/ | /g;
        next if $line eq '';
        print "# $tag $line\n";
    }
    return 1;
}

1;
