package App::Actions::Process;

use strict;
use warnings;
use Carp qw(croak);
use File::Spec;
use File::Temp ();
use IO::Handle ();
use POSIX ();

use App::Actions::I18N qw(i18n);

our $VERSION = '0.002.1';

# Turn Perl's $? into an exit code.  Windows reports $? in the same
# POSIX-compatible form as Unix, so no platform check is needed.
sub exit_code {
    my ($status) = @_;

    # A signal is reported as a shell reports it, 128 plus its number.
    return !$status ? 0
        : ($status & 127) ? 128 + ($status & 127)
        : ($status >> 8) & 255;
}

# How many jobs this machine can usefully run at once.  Linux reports the
# online processors in /proc/cpuinfo, Windows in NUMBER_OF_PROCESSORS, and
# POSIX systems through sysconf; where none of those answers, one at a time is
# the safe answer.  The command uses this as the default for --parallel.
sub cpu_count {
    if ($^O eq 'MSWin32') {
        my $count = $ENV{NUMBER_OF_PROCESSORS};
        return $count + 0 if defined $count && $count =~ /\A[1-9][0-9]*\z/;
    }

    if (open my $handle, '<', '/proc/cpuinfo') {
        my $count = 0;
        while (my $line = <$handle>) {
            $count++ if $line =~ /\Aprocessor\s*:/;
        }
        close $handle;

        return $count if $count > 0;
    }

    my $count = eval { POSIX::sysconf(POSIX::_SC_NPROCESSORS_ONLN()) };
    return $count + 0 if defined $count && $count =~ /\A[1-9][0-9]*\z/;

    return 1;
}

# Run $command (an array reference) and capture its standard output.
# Standard error is passed through to the caller unless quiet_stderr is true.
# Returns the output and the exit code.
sub capture {
    my ($command, %options) = @_;

    croak 'No command given' unless ref $command eq 'ARRAY' && @$command;

    my $temp = File::Temp->new(
        TEMPLATE => 'app-actions-XXXXXX',
        TMPDIR   => 1,
        UNLINK   => 1,
    );

    my $status = run(
        $command,
        stdout => $temp->filename,
        stderr => $options{quiet_stderr} ? File::Spec->devnull : undef,
        merge_stderr => $options{merge_stderr} ? 1 : 0,
    );

    seek $temp, 0, 0 or croak "Unable to rewind captured output: $!";
    local $/;
    my $output = <$temp>;
    $output = '' unless defined $output;
    $output =~ s/\r\n/\n/g;

    return ($output, $status);
}

# Quote one argument for the Win32 command line.  Perl's own quoting cannot be
# relied on: win32/win32.c:create_command_line() drops the quotes when an
# argument contains a double quote, so such an argument is split apart by the
# C runtime.  That matters here because step commands are passed to "sh -c"
# and environment values may contain both spaces and quotes.  Arguments that
# need no quoting are returned untouched; Windows is the only platform that
# uses this.
sub quote_win32 {
    my ($argument) = @_;

    $argument = '' unless defined $argument;
    # An empty argument has to be quoted, or it disappears from the command
    # line entirely.
    return '""' unless length $argument;
    return $argument unless $argument =~ /[\s"]/;

    my $quoted    = '"';
    my $backslash = 0;
    for my $character (split //, $argument) {
        if ($character eq '\\') {
            $backslash++;
            next;
        }
        if ($character eq '"') {
            # A backslash before a quote is literal, so double those that
            # precede it, then escape the quote itself.
            $quoted .= ('\\' x ($backslash * 2 + 1)) . '"';
            $backslash = 0;
            next;
        }
        $quoted .= ('\\' x $backslash) . $character;
        $backslash = 0;
    }

    # Backslashes before the closing quote must not escape it.
    $quoted .= '\\' x ($backslash * 2) . '"';

    return $quoted;
}

# The arguments to hand to system().  The program name is left alone: it cannot
# contain a quote, and Perl has to find it as a file.
sub _spawn_args {
    my ($command) = @_;

    my @args = @$command;

    # Only Windows rebuilds a command line from the arguments, so only there
    # do they need quoting.
    return $^O eq 'MSWin32' ? ($args[0], map { quote_win32($_) } @args[1 .. $#args]) : @args;
}

# Purpose:     say whether Windows would find $program to start it: as a
#              path when it names a directory, otherwise in the current
#              directory or on PATH; with a PATHEXT extension added when it
#              has none of its own.
# Entry:       $program - the program name or path.
# Exit:        1 when a file is found, 0 when not.
# Side effects: none; reads PATH and PATHEXT.
sub _windows_program_found {
    my ($program) = @_;

    return 0 unless defined $program && length $program;

    # A name with its own extension is looked for as it is; Windows adds an
    # extension only to a bare name.
    my @extensions = $program =~ /\.[^.\\\/:]+\z/
        ? ('')
        : split /;/, (defined $ENV{PATHEXT} && length $ENV{PATHEXT} ? $ENV{PATHEXT} : '.COM;.EXE;.BAT;.CMD');

    my @directories = $program =~ m{[\\/:]}
        ? ('')
        : (File::Spec->curdir, File::Spec->path);

    for my $directory (@directories) {
        my $base = length $directory ? File::Spec->catfile($directory, $program) : $program;
        for my $extension (@extensions) {
            return 1 if -f "$base$extension";
        }
    }

    return 0;
}

# Start $command and wait for it.  A list of one element is handed to the
# shell by system() when it contains a shell metacharacter, so the program
# is named separately (system PROGRAM LIST), which never uses a shell:
# whatever the arguments hold, they are arguments.  Windows keeps the plain
# list, because there the arguments are already quoted into one command line
# by _spawn_args and Perl starts the program itself.
#
# When Windows cannot start the program, Perl tries the command line again
# through cmd.exe, which would read & and | in the arguments as commands and
# report a missing program as status 1.  So a program that is not there is
# never handed to system() on Windows: the result is that of a program that
# could not start, as it is elsewhere.
sub _system {
    my ($command) = @_;

    my @args = _spawn_args($command);

    if ($^O eq 'MSWin32') {
        if (!_windows_program_found($args[0])) {
            $! = POSIX::ENOENT();
            $? = -1;
            return -1;
        }
        return system(@args);
    }

    return system { $args[0] } @args;
}

# Run $command with both streams discarded.
sub run_quiet {
    my ($command) = @_;

    my $devnull = File::Spec->devnull;
    return run($command, stdout => $devnull, stderr => $devnull);
}

# Run $command with its output going straight to the caller's streams.
sub stream {
    my ($command) = @_;

    croak 'No command given' unless ref $command eq 'ARRAY' && @$command;

    STDOUT->flush;
    STDERR->flush;

    _system($command);

    return exit_code($?);
}

# Point a child's standard streams at the files the caller chose.  This runs
# after fork() and before exec(), so a failure is reported by the child and
# ends it rather than escaping into the parent.
sub _redirect_child {
    my (%redirect) = @_;

    for my $stream (qw(stdout stderr)) {
        my $file = $redirect{$stream};
        next unless defined $file;

        my $handle = $stream eq 'stdout' ? \*STDOUT : \*STDERR;
        open $handle, $redirect{append} ? '>>' : '>', $file or do {
            print STDERR __PACKAGE__->i18n('process.redirect_failed', {
                stream => $stream, file => $file, error => "$!",
            }), "\n";
            POSIX::_exit(127);
        };

        # The child ends with POSIX::_exit, which flushes nothing, so a
        # buffered handle would lose the message that says why exec failed.
        $handle->autoflush(1);
    }

    return;
}

# Run several commands at the same time, at most $concurrency of them at once,
# with their output going straight to the caller's streams (or to the files
# named by stdout and stderr).  Returns one exit code per command, in the
# order the commands were given.
#
# Only the running is concurrent: the results are collected by index, so a
# caller reports the same failures in the same order whichever command was
# slowest.  fork() is used only where it is reliable.  On Windows the child of
# Perl's emulated fork() shares the parent's handles, so the commands are run
# one after another there instead.
sub run_parallel {
    my ($commands, %options) = @_;

    croak 'No commands given' unless ref $commands eq 'ARRAY';
    return [] unless @$commands;

    my $concurrency = $options{concurrency} || 4;
    $concurrency = @$commands if $concurrency > @$commands;

    # A caller that wants the output kept out of its own streams names where
    # it should go instead, and gets the same treatment one command at a time.
    my %redirect;
    $redirect{stdout} = $options{stdout} if defined $options{stdout};
    $redirect{stderr} = $options{stderr} if defined $options{stderr};

    # Every program's output goes to the same files.  Each program opening
    # them afresh would keep only the last one's, so they are emptied once
    # here and each program adds to them.
    if (%redirect) {
        my %seen;
        for my $file (grep { !$seen{$_}++ } values %redirect) {
            next if $file eq File::Spec->devnull;
            open my $handle, '>', $file or croak "Unable to open '$file': $!";
            close $handle or croak "Unable to open '$file': $!";
        }
        $redirect{append} = 1;
    }

    my $run_one = sub {
        my ($command) = @_;

        return %redirect ? run($command, %redirect) : stream($command);
    };

    return [ map { $run_one->($_) } @$commands ]
        if $^O eq 'MSWin32' || $concurrency < 2;

    # Buffered output belongs before the children write to the same handle.
    STDOUT->flush;
    STDERR->flush;

    my @codes = (undef) x @$commands;
    my %running;
    my $next = 0;

    my $start = sub {
        while ($next < @$commands && keys %running < $concurrency) {
            my $index = $next++;
            my $pid = fork();

            if (!defined $pid) {
                # No child could be created, so this command runs here.  Its
                # result still belongs in its own slot.
                $codes[$index] = $run_one->($commands->[$index]);
                next;
            }

            if ($pid == 0) {
                _redirect_child(%redirect);
                # exec PROGRAM LIST, so no command ever reaches a shell.  Perl's
                # own "Can't exec" warning is left out, as run() leaves it out:
                # the line below says the same.
                my @command = @{ $commands->[$index] };
                no warnings 'exec';
                exec { $command[0] } @command or do {
                    print STDERR __PACKAGE__->i18n('process.exec_failed', {
                        program => $command[0], error => "$!",
                    }), "\n";
                    POSIX::_exit(127);
                };
            }

            $running{$pid} = $index;
        }

        return;
    };

    $start->();

    my $error;
    eval {
        while (%running) {
            my $pid = waitpid(-1, 0);
            last if $pid <= 0;

            my $index = delete $running{$pid};
            next unless defined $index;

            $codes[$index] = exit_code($?);
            $start->();
        }

        1;
    } or $error = $@;

    if (defined $error) {
        # An interrupt should not leave pulls running behind the report.
        for my $pid (keys %running) {
            kill 'KILL', $pid;
            waitpid($pid, 0);
        }
        die $error;
    }

    # A command that was started but never reported has not succeeded.
    $codes[$_] = 1 for grep { !defined $codes[$_] } 0 .. $#codes;

    return \@codes;
}

# Run $command with its standard output (and optionally its standard error)
# redirected to a file.  The redirection uses dup() and system() rather than
# fork() and a piped open(), because the forking pipe open is not reliably
# available on Windows.
sub run {
    my ($command, %options) = @_;

    croak 'No command given' unless ref $command eq 'ARRAY' && @$command;

    my $stdout = defined $options{stdout} ? $options{stdout} : File::Spec->devnull;

    # Anything already buffered belongs before the child's output.
    STDOUT->flush;
    STDERR->flush;

    open my $saved_stdout, '>&', \*STDOUT
        or croak "Unable to duplicate STDOUT: $!";
    open my $saved_stderr, '>&', \*STDERR
        or croak "Unable to duplicate STDERR: $!";

    # append adds to the files rather than replacing them, which is how
    # run_parallel sends several programs to one file.
    my $mode = $options{append} ? '>>' : '>';

    my $error;
    my $redirected = open STDOUT, $mode, $stdout;
    if ($redirected && $options{merge_stderr}) {
        # The shell's 2>&1: standard error is a duplicate of the handle
        # standard output was just opened to, so the two share one offset and
        # the child's writes arrive in the order it made them.
        $redirected = open STDERR, '>&', \*STDOUT;
    } elsif ($redirected && defined $options{stderr}) {
        $redirected = open STDERR, $mode, $options{stderr};
    }
    $error = $! unless $redirected;

    my $status = 0;
    if ($redirected) {
        # Perl announces a program it cannot start; the exit status carries the
        # same information, and the caller reports it in its own words.
        local $SIG{__WARN__} = sub {
            my $warning = shift;
            warn $warning unless $warning =~ /^Can't exec /;
        };
        _system($command);
        $status = $?;
    }

    open STDOUT, '>&', $saved_stdout
        or croak "Unable to restore STDOUT: $!";
    open STDERR, '>&', $saved_stderr
        or croak "Unable to restore STDERR: $!";

    croak "Unable to redirect command output: $error" unless $redirected;

    return exit_code($status);
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Process - run other programs, the same way on Unix and Windows

=head1 SYNOPSIS

Run a program and read what it printed:

    use App::Actions::Process;

    my ($output, $status) = App::Actions::Process::capture(['git', 'rev-parse', 'HEAD']);
    die "not a git checkout\n" if $status != 0;

Run a program and show its output to the user:

    my $status = App::Actions::Process::stream(['make', 'test']);

Run a program and hide everything it prints:

    my $status = App::Actions::Process::run_quiet(['docker', 'info']);

Run several programs at the same time:

    my $statuses = App::Actions::Process::run_parallel(
        [ ['docker', 'pull', 'alpine'], ['docker', 'pull', 'perl'] ],
        concurrency => App::Actions::Process::cpu_count(),
    );

Send the output to a file:

    my $status = App::Actions::Process::run(['ls', '-l'], stdout => 'listing.txt');

=head1 DESCRIPTION

This module starts other programs and tells you how they ended.  It works on
Linux, macOS and Windows with the same code.

Every function takes the command as a reference to a list: the program
first, then each argument.  B<A shell is never used.>  Each argument reaches
the program exactly as you wrote it, even if it contains spaces, quotes,
C<$>, C<;> or C<|>.  So text from a workflow cannot run a second command.

Windows has no separate arguments: a program gets one command line and
splits it up itself.  On Windows this module quotes each argument with
L</quote_win32> so that it is split back correctly.  On other systems the
arguments are passed as they are.  When Windows cannot start a program,
Perl would retry the whole command line through F<cmd.exe>, which reads C<&>
and C<|> as commands; this module looks for the program first (in the
current directory and on C<PATH>, adding a C<PATHEXT> extension to a bare
name) and, when it is not there, never starts anything, so the result is
the status 255 of a program that could not start, as on other systems.

Every function returns an I<exit status> as a shell shows it:

=over 4

=item * 0 - the program succeeded;

=item * 1 to 125 - the program failed, and this is the number it chose;

=item * 255 - the program could not be started (for example, it does not
exist);

=item * 128 + N - the program was stopped by signal N (130 for Ctrl-C).

=back

=head1 FUNCTIONS

No function is exported.  Call them with their full names, for example
C<App::Actions::Process::capture(...)>.

=head2 exit_code

    my $status = App::Actions::Process::exit_code($?);

Turns Perl's C<$?> into an exit status, as described above.

=head3 ARGUMENTS

=over 4

=item * C<$status> - the value of C<$?> after C<system> or C<waitpid>.

=back

=head3 RETURNS

The exit status.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    system { 'true' } 'true';
    print App::Actions::Process::exit_code($?);    # 0

=head3 API SPECIFICATION

=head4 INPUT

    { status => { type => 'integer', optional => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0, max => 255 }

=head3 MESSAGES

None.

=head2 cpu_count

    my $count = App::Actions::Process::cpu_count();

Returns how many processors this computer can use now.  C<action-run> uses
it as the default for C<--parallel>.

=head3 ARGUMENTS

None.

=head3 RETURNS

A whole number, 1 or more.  If the computer does not say, 1.

=head3 SIDE EFFECTS

Reads C<NUMBER_OF_PROCESSORS> on Windows, F</proc/cpuinfo> on Linux, or asks
the system with C<sysconf>.

=head3 EXAMPLE

    my $jobs = App::Actions::Process::cpu_count();

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', min => 1 }

=head3 MESSAGES

None.

=head2 capture

    my ($output, $status) = App::Actions::Process::capture(\@command, %options);

Runs a program and returns what it printed.

=head3 ARGUMENTS

=over 4

=item * C<\@command> - the program and its arguments.  Not empty.

=item * C<quiet_stderr> - optional.  True to throw away the error output.
Otherwise it goes to your terminal.

=item * C<merge_stderr> - optional.  True to include the error output in the
returned text, in the order the program wrote it (like the shell's
C<2E<gt>&1>).

=back

=head3 RETURNS

A list of two values: the output, and the exit status.  Windows line ends
(C<\r\n>) in the output become C<\n>.

=head3 SIDE EFFECTS

Writes the output to a temporary file, which is deleted afterwards.

=head3 EXAMPLE

    my ($version) = App::Actions::Process::capture(['perl', '-e', 'print $]']);

=head3 API SPECIFICATION

=head4 INPUT

    {
        command      => { type => 'arrayref', min => 1 },
        quiet_stderr => { type => 'boolean', optional => 1 },
        merge_stderr => { type => 'boolean', optional => 1 },
    }

=head4 OUTPUT

    { type => 'array', min => 2, max => 2 }    # (string, integer)

=head3 MESSAGES

    +------------------------------------------+---------------------------------+---------------------------+
    | Exception (croak)                        | Meaning                         | What to do                |
    +------------------------------------------+---------------------------------+---------------------------+
    | No command given                         | not a non-empty array reference | pass [program, args...]   |
    | Unable to rewind captured output: ERR    | the temporary file failed       | check the temp directory  |
    | Unable to redirect command output: ERR   | the output file could not be    | check the temp directory  |
    |                                          | opened                          | and disk space            |
    | Unable to duplicate STDOUT/STDERR: ERR   | the program's own handles are   | do not close STDOUT or    |
    | Unable to restore STDOUT/STDERR: ERR     | broken                          | STDERR before calling     |
    +------------------------------------------+---------------------------------+---------------------------+

=head2 run

    my $status = App::Actions::Process::run(\@command, %options);

Runs a program and sends its output to a file.

=head3 ARGUMENTS

=over 4

=item * C<\@command> - the program and its arguments.  Not empty.

=item * C<stdout> - optional.  The file for the output.  Default: the null
device (the output is thrown away).

=item * C<stderr> - optional.  The file for the error output.  Default: your
terminal.

=item * C<merge_stderr> - optional.  True to send the error output to the
C<stdout> file too.  It wins over C<stderr>.

=item * C<append> - optional.  True to add to the C<stdout> and C<stderr>
files rather than replace what is in them.

=back

=head3 RETURNS

The exit status.

=head3 SIDE EFFECTS

Replaces the files named by C<stdout> and C<stderr>.  While the program runs,
this process's own C<STDOUT> and C<STDERR> point to those files; they are
put back afterwards.

=head3 EXAMPLE

    my $status = App::Actions::Process::run(['make'], stdout => 'build.log', merge_stderr => 1);

=head3 API SPECIFICATION

=head4 INPUT

    {
        command      => { type => 'arrayref', min => 1 },
        stdout       => { type => 'string', optional => 1 },
        stderr       => { type => 'string', optional => 1 },
        merge_stderr => { type => 'boolean', optional => 1 },
        append       => { type => 'boolean', optional => 1 },
    }

=head4 OUTPUT

    { type => 'integer', min => 0, max => 255 }

=head3 MESSAGES

As for L</capture>, except the "rewind" message.

=head2 run_quiet

    my $status = App::Actions::Process::run_quiet(\@command);

Runs a program and throws away everything it prints.

=head3 ARGUMENTS

=over 4

=item * C<\@command> - the program and its arguments.

=back

=head3 RETURNS

The exit status.

=head3 SIDE EFFECTS

None, apart from what the program does.

=head3 API SPECIFICATION

=head4 INPUT

    { command => { type => 'arrayref', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0, max => 255 }

=head3 MESSAGES

As for L</run>.

=head2 stream

    my $status = App::Actions::Process::stream(\@command);

Runs a program with its output and error output going straight to your
terminal, as it happens.

=head3 ARGUMENTS

=over 4

=item * C<\@command> - the program and its arguments.

=back

=head3 RETURNS

The exit status.

=head3 SIDE EFFECTS

Flushes C<STDOUT> and C<STDERR> first, so that what you printed before
appears before the program's output.

=head3 API SPECIFICATION

=head4 INPUT

    { command => { type => 'arrayref', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0, max => 255 }

=head3 MESSAGES

    +------------------+------------------------------------+-------------------------+
    | Exception (croak)| Meaning                            | What to do              |
    +------------------+------------------------------------+-------------------------+
    | No command given | not a non-empty array reference    | pass [program, args...] |
    +------------------+------------------------------------+-------------------------+

=head2 run_parallel

    my $statuses = App::Actions::Process::run_parallel(\@commands, %options);

Runs several programs, some at the same time.

=head3 ARGUMENTS

=over 4

=item * C<\@commands> - a list of commands, each a list reference as for
L</stream>.

=item * C<concurrency> - optional.  The most programs that run at the same
time.  Default 4.

=item * C<stdout>, C<stderr> - optional.  Files for every program's output,
as for L</run>.  Each file is emptied once, before the first program starts,
and then every program adds to it, so it holds the output of them all.
Without them, the output goes to your terminal, mixed together.

=back

=head3 RETURNS

An array reference of exit statuses, in the same order as C<\@commands>.
An empty list gives an empty array reference.

=head3 SIDE EFFECTS

On Unix, uses C<fork>.  On Windows, or with C<concurrency> below 2, the
programs run one after the other.  If this process is interrupted while
waiting, the programs still running are killed.

=head3 EXAMPLE

    my $statuses = App::Actions::Process::run_parallel(
        [ map { ['gzip', '-9', $_] } @files ],
        concurrency => 2,
    );
    my @failed = grep { $statuses->[$_] != 0 } 0 .. $#files;

=head3 API SPECIFICATION

=head4 INPUT

    {
        commands    => { type => 'arrayref' },
        concurrency => { type => 'integer', min => 1, optional => 1, default => 4 },
        stdout      => { type => 'string', optional => 1 },
        stderr      => { type => 'string', optional => 1 },
    }

=head4 OUTPUT

    { type => 'arrayref', element_type => 'integer' }

=head3 MESSAGES

    +--------------------------+----------------------------------+------------------------------+
    | Message                  | Meaning                          | What to do                   |
    +--------------------------+----------------------------------+------------------------------+
    | No commands given (croak)| \@commands is not an array ref   | pass an array reference      |
    | Unable to open 'F': ERR  | the stdout or stderr file could  | check the path               |
    | (croak)                  | not be emptied before the start  |                              |
    | Unable to run 'P': ERR   | (printed by the child) program P | install P or fix its path;   |
    |                          | could not start; status 127      | the status is 127            |
    | Unable to redirect       | (printed by the child) the file  | check the path; status 127   |
    | STREAM to 'F': ERR       | could not be opened              |                              |
    +--------------------------+----------------------------------+------------------------------+

=head2 quote_win32

    my $argument = App::Actions::Process::quote_win32($text);

Quotes one argument for a Windows command line, using the rules Windows
programs use to split it again.  The other functions call it for you on
Windows; you need it only to build a Windows command line yourself.

=head3 ARGUMENTS

=over 4

=item * C<$text> - one argument.  C<undef> is treated as the empty string.

=back

=head3 RETURNS

The argument, quoted if it needs to be.  An argument without spaces or
double quotes is returned unchanged.  An empty argument becomes C<"">.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    print App::Actions::Process::quote_win32('say "hi"');    # "say \"hi\""
    print App::Actions::Process::quote_win32('C:\dir\\');    # C:\dir\
    print App::Actions::Process::quote_win32('a b\\');       # "a b\\"

=head3 API SPECIFICATION

=head4 INPUT

    { argument => { type => 'string', optional => 1 } }

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head1 COMMON PITFALLS

=over 4

=item * B<Pass a list reference, not a string.>  C<capture('ls -l')> is an
error, and C<capture(['ls -l'])> looks for a program called "ls -l".  Write
C<capture(['ls', '-l'])>.

=item * B<There is no shell.>  Pipes (C<|>), redirection (C<E<gt>>),
wildcards (C<*.txt>) and variables (C<$HOME>) are not expanded.  If you need
them, run the shell yourself: C<['sh', '-c', 'ls *.txt']>, and never put
untrusted text inside that string.

=item * B<capture returns a list.>  C<my $text = capture(...)> gives the
status, not the text.  Write C<my ($text, $status) = capture(...)>.

=item * B<A status is not Perl's C<$?>.>  Compare it with 0, not with
C<$? E<gt>E<gt> 8>.

=item * B<A missing program is status 255, not an exception.>  Perl also
prints a "Can't exec" warning, except in L</run>, L</run_quiet> and
L</capture>, which hide it.  On Windows it is 255 too, rather than the
status 1 and "is not recognized" message of F<cmd.exe>, because the
program is looked for before anything is started.  A program Windows finds
somewhere this module does not look (such as the folder of the running
program, when it is not on C<PATH>) counts as missing.

=item * B<Output from parallel programs is mixed.>  Without C<stdout>,
L</run_parallel> lets every program write to the same terminal, so their
lines can be interleaved.

=item * B<Captured output is held in memory.>  Do not capture a program that
prints gigabytes.

=back

=head1 ENCODING

Commands, arguments and captured output are bytes.  Encode text with
non-ASCII characters or emoji (for example with
C<Encode::encode('UTF-8', $text)>) before you put it in a command, and decode
captured output if you need characters.  On Windows, the program receives the
command line through the Windows "ANSI" code page, so characters outside it
may be lost.  An argument cannot contain a NUL character.  The line a child
prints when it cannot redirect its output or start its program is in the
current language of L<App::Actions::I18N>, encoded as the standard error
handle is.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  The lines below the rule are always true
when the routine returns.  The module keeps no state of its own; C<Host> is
the computer, whose processes and files the routines change.

    [ARG, FILE]
    STATUS == 0 .. 255
    COMMAND == seq₁ ARG
    exec : COMMAND → STATUS × seq BYTE × seq BYTE    status, output, error output
    exec(c) runs program head c with arguments tail c, without a shell

=head2 exit_code

    ┌─ ExitCode ────────────────────────────────────────
    │ status? : optional ℤ
    │ r!      : STATUS
    ├───────────────────────────────────────────────────
    │ status? = 0 ∨ status? = ⊥ ⇒ r! = 0
    │ status? mod 128 ≠ 0 ⇒ r! = 128 + (status? mod 128)
    │ otherwise r! = status? div 256
    └───────────────────────────────────────────────────

=head2 cpu_count

    ┌─ CpuCount ────────────────────────────────────────
    │ ΞHost
    │ r! : ℕ₁
    ├───────────────────────────────────────────────────
    │ r! = first defined of ⟨NUMBER_OF_PROCESSORS (Windows),
    │      #processor lines in /proc/cpuinfo, sysconf(NPROCESSORS_ONLN), 1⟩
    └───────────────────────────────────────────────────

=head2 capture

    ┌─ Capture ─────────────────────────────────────────
    │ ΔHost
    │ command? : COMMAND
    │ quiet?, merge? : 𝔹
    │ r! : seq BYTE × STATUS
    ├───────────────────────────────────────────────────
    │ (s, out, err) = exec(command?)
    │ merge? ⇒ r! = (crlf_to_lf(out ⋈ err), s)     ⋈ : in time order
    │ ¬merge? ⇒ r! = (crlf_to_lf(out), s)
    │ ¬merge? ∧ ¬quiet? ⇒ err goes to the caller's STDERR
    └───────────────────────────────────────────────────

=head2 run

    ┌─ Run ─────────────────────────────────────────────
    │ ΔHost
    │ command? : COMMAND
    │ stdout?, stderr? : optional FILE
    │ merge?, append? : 𝔹
    │ r! : STATUS
    ├───────────────────────────────────────────────────
    │ (s, out, err) = exec(command?)
    │ r! = s
    │ let before(F) == (if append? then contents(F) else ⟨⟩)
    │ contents'(stdout? or null) = before(stdout?) ⁀ (out ⋈ (if merge? then err else ⟨⟩))
    │ ¬merge? ∧ stderr? ≠ ⊥ ⇒ contents'(stderr?) = before(stderr?) ⁀ err
    │ STDOUT' = STDOUT ∧ STDERR' = STDERR
    └───────────────────────────────────────────────────

=head2 run_quiet

    ┌─ RunQuiet ────────────────────────────────────────
    │ Run[stdout? := null, stderr? := null]
    └───────────────────────────────────────────────────

=head2 stream

    ┌─ Stream ──────────────────────────────────────────
    │ ΔHost
    │ command? : COMMAND
    │ r! : STATUS
    ├───────────────────────────────────────────────────
    │ (s, out, err) = exec(command?) ∧ r! = s
    │ out goes to STDOUT and err to STDERR, after what was already buffered
    └───────────────────────────────────────────────────

=head2 run_parallel

    ┌─ RunParallel ─────────────────────────────────────
    │ ΔHost
    │ commands?    : seq COMMAND
    │ concurrency? : ℕ₁
    │ r!           : seq STATUS
    ├───────────────────────────────────────────────────
    │ #r! = #commands?
    │ ∀ i ∈ dom commands? • r!(i) = first(exec(commands?(i)))
    │ at no time do more than min(concurrency?, #commands?) commands run
    │ ∀ F ∈ {stdout?, stderr?} • contents'(F) = ⋈ { i ∈ dom commands? • output_F(i) }
    │ Windows ∨ concurrency? < 2 ⇒ the commands run one after another
    └───────────────────────────────────────────────────

=head2 quote_win32

    ┌─ QuoteWin32 ──────────────────────────────────────
    │ arg? : optional seq CHAR
    │ r!   : seq₁ CHAR
    ├───────────────────────────────────────────────────
    │ arg? = ⊥ ∨ arg? = ⟨⟩ ⇒ r! = "\"\""
    │ arg? contains no white space and no '"' ⇒ r! = arg?
    │ otherwise r! = '"' ⁀ escape(arg?) ⁀ '"' where
    │     a run of n '\' before '"' becomes 2n+1 '\' then '"',
    │     a run of n '\' at the end becomes 2n '\',
    │     any other run of '\' is unchanged
    │ CommandLineToArgv(r!) = ⟨arg?⟩
    └───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The module keeps no state between calls.  Each command goes through these
states:

         capture / run / run_quiet / stream / run_parallel
                              |
                              v
                     +------------------+  not a non-empty list   +-------------+
                     | CHECK ARGUMENTS  |------------------------>| croak       |
                     +------------------+                         +-------------+
                              |
                              v
                     +------------------+  (run, capture, run_quiet)
                     | REDIRECT         |  STDOUT/STDERR -> files;  open fails
                     | (if asked)       |------------------------------+
                     +------------------+                              |
                              |                                        |
                              v                                        |
                     +------------------+  Windows: quote_win32 each   |
                     | START PROGRAM    |  argument; never a shell     |
                     +------------------+                              |
                       |            |                                  |
          cannot start |            | started                          |
                       v            v                                  |
               status 255    +------------------+                      |
                       |     |    RUNNING       |  run_parallel: up to |
                       |     +------------------+  "concurrency" here  |
                       |            |                                  |
                       |            | exits, or killed by signal N     |
                       |            v                                  |
                       |     status = code, or 128 + N                 |
                       |            |                                  |
                       +------+-----+                                  |
                              v                                        |
                     +------------------+                              |
                     | RESTORE HANDLES  |<-----------------------------+
                     +------------------+
                       |            |
                       |            +--- redirect had failed --> croak
                       v
              return status (capture: and the output)

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
