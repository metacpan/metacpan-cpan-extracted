package Command::Run;

our $VERSION = "1.00";

use v5.14;
use warnings;
use utf8;
use Carp;
use Fcntl;
use IO::File;

use parent 'Command::Run::Tmpfile';

our $debug;
sub debug {
    my $obj = shift;
    @_ ? $debug = shift : $debug;
}

sub code_name {
    my $code = shift;
    require B;
    my $cv = B::svref_2object($code);
    return if $cv->GV->isa('B::SPECIAL');
    $cv->GV->NAME;
}

my %default_option = (
    stderr => undef,  # undef: pass-through, 'redirect': merge to stdout, 'capture': separate capture
);

sub new {
    my $class = shift;
    my $obj = $class->SUPER::new;
    $obj->{OPTION} = { %default_option };
    $obj->{RESULT} = {};
    $obj->configure(@_) if @_;
    $obj;
}

sub configure {
    my $obj = shift;
    my %args = @_;
    for my $key (keys %args) {
	my $val = $args{$key};
	if ($key eq 'command') {
	    $obj->command(ref $val eq 'ARRAY' ? @$val : $val);
	} elsif ($key eq 'stdin') {
	    $obj->_set_stdin($val);
	} elsif ($key eq 'stdout') {
	    $obj->{STDOUT_REF} = $val;
	} elsif ($key eq 'stderr') {
	    if (ref $val eq 'SCALAR') {
		$obj->{STDERR_REF} = $val;
		$obj->option(stderr => 'capture');
	    } else {
		$obj->option(stderr => $val);
	    }
	} else {
	    $obj->option($key => $val);
	}
    }
    $obj;
}

sub command {
    my $obj = shift;
    if (@_) {
	$obj->{COMMAND} = [ @_ ];
	$obj;
    } else {
	@{$obj->{COMMAND} // []};
    }
}

sub option {
    my $obj = shift;
    if (@_ == 1) {
	return $obj->{OPTION}->{+shift};
    } else {
	while (my($k, $v) = splice @_, 0, 2) {
	    $obj->{OPTION}->{$k} = $v;
	}
	return $obj;
    }
}

sub run {
    my $obj = shift;
    $obj->update(@_);
    if (my $ref = $obj->{STDOUT_REF}) {
	$$ref = $obj->data;
    }
    if (my $ref = $obj->{STDERR_REF}) {
	$$ref = $obj->error;
    }
    return $obj->result;
}

sub update {
    use Time::localtime;
    my $obj = shift;
    my @command = $obj->command;
    if (@command) {
	$obj->{RESULT} = $obj->execute(\@command, @_);
	# Store stdout in temp file for path access
	my $fh = $obj->fh;
	$fh->seek(0, 0)  or die "seek: $!\n";
	$fh->truncate(0) or die "truncate: $!\n";
	$fh->print($obj->{RESULT}->{data} // '');
	$fh->flush;
	$fh->seek(0, 0)  or die "seek: $!\n";
    }
    $obj->date(ctime());
    $obj;
}

sub result {
    my $obj = shift;
    $obj->{RESULT};
}

sub execute {
    my $obj = shift;
    my $command = shift;
    my %opt = (%{$obj->{OPTION}}, @_);
    my @command = ref $command eq 'ARRAY' ? @$command : ($command);

    # Use nofork path for code references when requested
    if ($opt{nofork} and ref $command[0] eq 'CODE') {
	return $obj->_execute_nofork(\@command, %opt);
    }

    my $stderr = $opt{stderr} // '';

    # Create pipes for stdout and stderr
    pipe(my $stdout_r, my $stdout_w) or die "pipe: $!\n";
    pipe(my $stderr_r, my $stderr_w) or die "pipe: $!\n" if $stderr eq 'capture';

    my $pid = fork // die "fork: $!\n";
    if ($pid == 0) {
	# Child process
	close $stdout_r;
	close $stderr_r if $stderr eq 'capture';

	if (exists $opt{stdin}) {
	    my $tmp = new_tmpfile IO::File or die "tmpfile: $!\n";
	    binmode $tmp, ':encoding(utf8)';
	    $tmp->print($opt{stdin});
	    $tmp->seek(0, 0) or die "seek: $!\n";
	    open STDIN, '<&', $tmp or die "dup: $!\n";
	    binmode STDIN, ':encoding(utf8)';
	} elsif (my $input = $obj->{INPUT}) {
	    open STDIN, "<&=", $input->fileno or die "open: $!\n";
	    binmode STDIN, ':encoding(utf8)';
	}

	open STDOUT, ">&=", $stdout_w->fileno or die "open stdout: $!\n";
	if ($stderr eq 'redirect') {
	    open STDERR, ">&STDOUT" or die "open stderr: $!\n";
	} elsif ($stderr eq 'capture') {
	    open STDERR, ">&=", $stderr_w->fileno or die "open stderr: $!\n";
	}
	# else: stderr passes through to terminal

	if (ref $command[0] eq 'CODE') {
	    my $code = shift @command;
	    @ARGV = @command;
	    if (my $name = code_name($code)) {
		$0 = $name;
	    }
	    $code->(@command);
	    exit 0;
	}
	exec @command;
	die "exec: $@\n";
    }

    # Parent process
    close $stdout_w;
    close $stderr_w if $stderr eq 'capture';

    binmode $stdout_r, ':encoding(utf8)';
    binmode $stderr_r, ':encoding(utf8)' if $stderr eq 'capture';

    my $stdout = do { local $/; <$stdout_r> };
    my $stderr_out = $stderr eq 'capture' ? do { local $/; <$stderr_r> } : '';

    close $stdout_r;
    close $stderr_r if $stderr eq 'capture';

    waitpid $pid, 0;
    my $result = $?;

    return {
	result => $result,
	data   => $stdout,
	error  => $stderr_out,
	pid    => $pid,
    };
}

sub _tmpfile {
    my ($obj, $key, %opt) = @_;
    $key .= '_RAW' if $opt{raw};
    my $fh = $obj->{$key} //= do {
	my $f = new_tmpfile IO::File or die "tmpfile: $!\n";
	binmode $f, $opt{raw} ? ':utf8' : ':encoding(utf8)';
	$f;
    };
    $fh->seek(0, 0)  or die "seek: $!\n";
    $fh->truncate(0) or die "truncate: $!\n";
    $fh;
}

sub _execute_nofork {
    my $obj = shift;
    my $command = shift;
    my %opt = @_;
    my @command = @$command;
    my $stderr_mode = $opt{stderr} // '';
    my $raw = $opt{raw};

    my $code = shift @command;

    my $tmp_stdout = $obj->_tmpfile('NOFORK_STDOUT', raw => $raw);

    # Save and redirect STDOUT (always needed)
    open my $save_stdout, '>&', \*STDOUT or die "dup STDOUT: $!\n";
    open STDOUT, '>&', $tmp_stdout or die "redirect STDOUT: $!\n";
    binmode STDOUT, $raw ? ':utf8' : ':encoding(utf8)';

    # Handle STDERR — only save/redirect when needed
    my ($save_stderr, $tmp_stderr);
    if ($stderr_mode eq 'redirect') {
	open $save_stderr, '>&', \*STDERR or die "dup STDERR: $!\n";
	open STDERR, '>&', \*STDOUT or die "redirect STDERR: $!\n";
    } elsif ($stderr_mode eq 'capture') {
	$tmp_stderr = $obj->_tmpfile('NOFORK_STDERR', raw => $raw);
	open $save_stderr, '>&', \*STDERR or die "dup STDERR: $!\n";
	open STDERR, '>&', $tmp_stderr or die "redirect STDERR: $!\n";
    }

    # Handle STDIN — only save/redirect when needed
    my $save_stdin;
    if (exists $opt{stdin}) {
	my $tmp_stdin = $obj->_tmpfile('NOFORK_STDIN', raw => $raw);
	$tmp_stdin->print($opt{stdin});
	$tmp_stdin->seek(0, 0) or die "seek: $!\n";
	open $save_stdin, '<&', \*STDIN or die "dup STDIN: $!\n";
	open STDIN, '<&', $tmp_stdin or die "redirect STDIN: $!\n";
	binmode STDIN, $raw ? ':utf8' : ':encoding(utf8)';
    } elsif (my $input = $obj->{INPUT}) {
	$input->seek(0, 0) or die "seek: $!\n";
	open $save_stdin, '<&', \*STDIN or die "dup STDIN: $!\n";
	open STDIN, '<&', $input->fileno or die "redirect STDIN: $!\n";
	binmode STDIN, $raw ? ':utf8' : ':encoding(utf8)';
    }

    # Set global state
    local $_;
    local @ARGV = @command;
    my $orig_0;
    if (my $name = code_name($code)) {
	$orig_0 = $0;
	$0 = $name;
    }

    # Execute
    my $result = 0;
    eval { $code->(@command) };
    if ($@) {
	$result = -1;
    }

    # Flush and restore — only what was redirected
    STDOUT->flush;
    open STDOUT, '>&', $save_stdout or die "restore STDOUT: $!\n";
    if ($save_stderr) {
	STDERR->flush;
	open STDERR, '>&', $save_stderr or die "restore STDERR: $!\n";
    }
    if ($save_stdin) {
	open STDIN, '<&', $save_stdin or die "restore STDIN: $!\n";
    }
    if (defined $orig_0) {
	$0 = $orig_0;
    }

    # Read captured output from tmpfiles
    $tmp_stdout->seek(0, 0) or die "seek: $!\n";
    my $stdout_data = do { local $/; <$tmp_stdout> };

    my $stderr_data = '';
    if ($tmp_stderr) {
	$tmp_stderr->seek(0, 0) or die "seek: $!\n";
	$stderr_data = do { local $/; <$tmp_stderr> };
    }

    return {
	result => $result,
	data   => $stdout_data,
	error  => $stderr_data,
    };
}

sub data {
    my $obj = shift;
    if (@_) {
	my $data = shift;
	$obj->{RESULT}->{data} = $data;
	my $fh = $obj->fh;
	$fh->seek(0, 0)  or die "seek: $!\n";
	$fh->truncate(0) or die "truncate: $!\n";
	$fh->print($data);
	$fh->flush;
	$fh->seek(0, 0)  or die "seek: $!\n";
	return $obj;
    }
    $obj->{RESULT}->{data};
}

sub error {
    my $obj = shift;
    $obj->{RESULT}->{error};
}

sub date {
    my $obj = shift;
    @_ ? $obj->{DATE} = shift : $obj->{DATE};
}

sub _set_stdin {
    my $obj = shift;
    my $data = shift;
    my $input = $obj->_tmpfile('INPUT');
    $input->fcntl(F_SETFD, 0) or die "fcntl F_SETFD: $!\n";
    $input->print($data);
    $input->seek(0, 0)  or die "seek: $!\n";
    $obj;
}

sub with {
    my $obj = shift;
    $obj->configure(@_);
}

1;

__END__

=encoding utf-8

=head1 NAME

Command::Run - Execute external command or code reference

=head1 SYNOPSIS

    use Command::Run;

    # Simple usage
    my $result = Command::Run->new(
        command => ['ls', '-l'],
        stderr  => 'redirect',  # merge stderr to stdout
    )->run;
    print $result->{data};

    # Method chaining style
    my $runner = Command::Run->new;
    $runner->command('cat', '-n')->with(stdin => $data)->run;
    print $runner->data;

    # Separate stdout/stderr capture
    my $result = Command::Run->new(
        command => ['some_command'],
        stderr  => 'capture',
    )->run;
    print "data: ", $result->{data};
    print "error: ", $result->{error};

    # Access output via file descriptor path
    my $cmd = Command::Run->new(command => ['date']);
    $cmd->update;
    system("cat", $cmd->path);  # /dev/fd/N

    # Code reference execution
    my $result = Command::Run->new(
        command => [\&some_function, @args],
        stdin   => $input_data,
    )->run;

    # Using with() method
    my ($out, $err);
    Command::Run->new->command("command", @args)
        ->with(stdin => $input, stdout => \$out, stderr => \$err)
        ->run;

=head1 VERSION

Version 1.00

=head1 DESCRIPTION

This module provides a simple interface to execute external commands
or code references and capture their output.

When a code reference is passed as the first element of the command
array, it is called in a forked child process instead of executing an
external command.  This avoids the overhead of loading Perl and
modules for each invocation.

This module inherits from L<Command::Run::Tmpfile>, which provides
temporary file functionality.  The captured output is stored in this
temporary file, accessible via the C<path> method as C</dev/fd/N>,
which can be used as a file argument to external commands.

=head1 CONSTRUCTOR

=over 4

=item B<new>(%parameters)

Create a new Command::Run object.  Parameters are passed as
key-value pairs (see L</PARAMETERS>):

    my $runner = Command::Run->new(
        command => \@command,
        stdin   => $input_data,
        stderr  => 'redirect',
    );

    # Or use method chaining
    my $runner = Command::Run->new->command('ls', '-l');

=back

=head1 PARAMETERS

The following parameters can be used with C<new>, C<with>, and C<run>.
With C<new> and C<with>, parameters are stored in the object.
With C<run>, parameters are temporary and do not modify the object.

=over 4

=item B<command> => I<\@command>

The command to execute.  Can be an array reference of command and
arguments, or a code reference with arguments.

=item B<stdin> => I<data>

Input data to be fed to the command's STDIN.

=item B<stdout> => I<\$scalar>

Scalar reference to capture STDOUT.

=item B<stderr> => I<\$scalar> | C<'redirect'> | C<'capture'>

Controls STDERR handling:

=over 4

=item * I<\$scalar> - Capture STDERR into the referenced variable

=item * C<'redirect'> - Merge STDERR into STDOUT

=item * C<'capture'> - Capture STDERR separately (accessible via C<error> method)

=item * C<undef> (default) - STDERR passes through to terminal

=back

=item B<nofork> => I<bool>

When true and the command is a code reference, execute the code in
the current process without forking.  Ignored for external commands.
See L</NOFORK AND RAW MODE> for details.

=item B<raw> => I<bool>

When true (with C<nofork>), use C<:utf8> instead of
C<:encoding(utf8)> on I/O temporary files, avoiding encode/decode
overhead and PerlIO layer leak.  See L</NOFORK AND RAW MODE> for
details.

    my $result = Command::Run->new(
        command => [\&process, @args],
        nofork  => 1,
        raw     => 1,
    )->run;

=back

=head1 METHODS

=over 4

=item B<command>(I<@command>)

Set the command to execute.  The argument can be:

=over 4

=item * External command and arguments: C<'ls', '-l'>

=item * Code reference and arguments: C<\&func, @args>

=back

Returns the object for method chaining.

=item B<with>(I<%parameters>)

Set parameters (see L</PARAMETERS>).  Settings are stored in the
object and persist across multiple C<run> calls.  Returns the object
for method chaining.

    my ($out, $err);
    Command::Run->new("command")
        ->with(stdin => $data, stdout => \$out, stderr => \$err)
        ->run;

=item B<run>(I<%parameters>)

Execute the command and return the result hash reference.
Accepts the same parameters as C<with>, but parameters are
temporary and do not modify the object state.

    # All-in-one style
    my $result = Command::Run->new->run(
        command => ['cat', '-n'],
        stdin   => $data,
        stderr  => 'redirect',
    );

    # Reuse runner with different input
    my $runner = Command::Run->new('cat');
    $runner->run(stdin => $input1);
    $runner->run(stdin => $input2);  # object state unchanged

=item B<update>()

Execute the command and store the output.
Returns the object for method chaining.

=item B<result>()

Return the result hash reference from the last execution.

=item B<data>()

Return the captured output (stdout) from the last execution.

=item B<error>()

Return the captured error output (stderr) from the last execution.

=item B<path>()

Return the file descriptor path (e.g., C</dev/fd/3>) for the
captured output.  This can be passed to external commands.

=item B<rewind>()

Seek to the beginning of the output temp file.

=item B<date>()

Return the timestamp of the last execution.

=back

=head1 RETURN VALUE

The C<run> method returns a hash reference containing:

=over 4

=item B<result>

The exit status of the command (C<$?>).

=item B<data>

The captured output (stdout).

=item B<error>

The captured error output (stderr, empty string unless C<stderr> is C<'capture'>).

=item B<pid>

The process ID of the executed command.

=back

=head1 NOFORK AND RAW MODE

=head2 Overview

When executing Perl code references, the default fork-based execution
has two significant costs:

=over 4

=item 1. Fork overhead

C<fork()> duplicates the entire process, including all loaded modules
and data structures.

=item 2. Encoding overhead

I/O between parent and child processes goes through pipes, requiring
C<:encoding(utf8)> layers that encode and decode UTF-8 on every read
and write.

=back

The C<nofork> option eliminates the fork cost by executing the code
reference in the current process.  The C<raw> option eliminates the
encoding cost by using the C<:utf8> PerlIO pseudo-layer instead of
C<:encoding(utf8)>.

Combined, these options can achieve B<over 30x speedup> compared to
fork-based execution for lightweight functions with small I/O.

=head2 How Nofork Works

In nofork mode, C<_execute_nofork> temporarily redirects the real
STDOUT, STDERR, and STDIN file descriptors to temporary files using
C<dup>, executes the code reference, then restores them:

    # Simplified flow:
    open $save, '>&', \*STDOUT;           # save original
    open STDOUT, '>&', $tmpfile;          # redirect to tmpfile
    $code->(@args);                       # execute code ref
    open STDOUT, '>&', $save;             # restore original
    $tmpfile->seek(0, 0);
    $output = do { local $/; <$tmpfile> }; # read captured output

The code reference sees real STDOUT/STDIN file descriptors (not tied
handles), so it behaves identically to the fork path from the
callee's perspective.  C<@ARGV>, C<$0>, and C<$_> are protected with
C<local> to prevent side effects.

=head2 How Raw Mode Works

The C<raw> option controls which PerlIO layer is applied to the
temporary files used for I/O redirection:

    # Normal mode (raw => 0):
    binmode $tmpfile, ':encoding(utf8)';  # full encode/decode

    # Raw mode (raw => 1):
    binmode $tmpfile, ':utf8';            # flag only, no conversion

In the normal fork path, C<:encoding(utf8)> is necessary because data
crosses process boundaries through pipes as byte streams.  But in
nofork mode, caller and callee share the same Perl interpreter, so
Perl's internal string format (which is already UTF-8 internally) can
be passed directly.  The C<:utf8> layer simply sets Perl's UTF-8 flag
on strings read from the file without performing actual byte-level
conversion.

=head3 PerlIO Encoding Leak

There is an additional reason to prefer C<:utf8> over
C<:encoding(utf8)> in long-running processes.  Repeatedly pushing and
popping the C<:encoding(utf8)> layer (which happens on each nofork
execution when opening and closing temporary files) causes a
cumulative performance degradation in Perl's PerlIO subsystem.  This
affects B<all> PerlIO operations in the process, not just the ones
using the encoding layer.

In benchmarks, nofork with C<:encoding(utf8)> is actually B<slower>
than fork after many iterations, due to this leak.  Raw mode avoids
the issue entirely.

    # Benchmark: code ref with stdin (100-byte input, 1000 iterations)
    fork:                  399/s (baseline)
    nofork + :encoding:    316/s (0.8x — slower than fork!)
    nofork + :utf8 (raw): 13,433/s (34x faster)

=head2 Zero-Modification Callee Integration

A key advantage of this mechanism is that B<callee modules typically
require no modification> to work with nofork+raw mode.

Many Perl modules use C<use open> pragma or equivalent to set up
encoding layers on standard I/O:

    package App::ansicolumn;
    use open IO => ':utf8', ':std';    # sets :encoding(utf8) on STDIO

This works transparently because of execution order.  When using
nofork mode with method chaining:

    require App::ansicolumn;           # (1) module loaded here
    Command::Run->new
        ->command(\&ansicolumn, @args)
        ->with(stdin => $text, nofork => 1, raw => 1)
        ->update                       # (2) STDOUT redirected here
        ->data;

At step (1), C<require> loads the module and C<use open ':std'>
applies C<:encoding(utf8)> to the B<original> STDOUT.  At step (2),
C<_execute_nofork> redirects STDOUT to a fresh temporary file with
C<:utf8> layer.  The callee's encoding setup has already fired on the
original STDOUT and does not affect the redirected one.

This means existing modules like L<App::ansicolumn> and
L<App::ansifold> work unchanged with nofork+raw mode, achieving
significant speedups with zero code changes on the callee side.

=head2 Caller Protection

Nofork mode executes the code reference in the same process, so care
is needed to prevent the callee from corrupting the caller's state.
The following protections are applied:

=over 4

=item C<local $_;>

Prevents the callee from modifying the caller's C<$_>.  This is
critical when the caller aliases C<$_> to important data (e.g.,
greple's C<local *_ = shift> to alias C<$_> to the content buffer).
Without this protection, a callee's C<< while (E<lt>E<gt>) >> loop
would set C<$_> to C<undef> at EOF, destroying the caller's data.

=item C<local @ARGV>

Prevents the callee from modifying the caller's C<@ARGV>.

=item C<$0> save/restore

Prevents the callee from permanently changing the program name.

=back

=head1 COMPARISON WITH SIMILAR MODULES

There are many modules on CPAN for executing external commands.
This module is designed to be simple and lightweight, with minimal
dependencies.

This module was originally developed as L<App::cdif::Command> and
has been used in production as part of the L<App::cdif> distribution
since 2014.  It has also been adopted by several unrelated modules,
which motivated its release as an independent distribution.

=over 4

=item L<IPC::Run>

Full-featured module for running processes with support for
pipelines, pseudo-ttys, and timeouts.  Very powerful but large
(135KB+) with non-core dependencies (L<IO::Pty>).  Overkill for
simple command execution.

=item L<Capture::Tiny>

Excellent for capturing STDOUT/STDERR from Perl code or external
commands.  Does not provide stdin input functionality.

=item L<IPC::Run3>

Simpler than L<IPC::Run>, handles stdin/stdout/stderr.  Good
alternative but does not support code reference execution.

=item L<Command::Runner>

Modern interface with timeout support and code reference execution.
Has non-core dependencies.

=item L<Proc::Simple>

Simple process management with background execution support.
Focused on process control rather than I/O capture.

=back

B<Command::Run> differs from these modules in several ways:

=over 4

=item * B<Core modules only> - No non-core dependencies

=item * B<Code reference support> - Execute Perl code with $0 and @ARGV setup

=item * B<File descriptor path> - Output accessible via C</dev/fd/N>

=item * B<Minimal footprint> - About 200 lines of code

=item * B<Method chaining> - Fluent interface for readability

=back

=head1 SEE ALSO

L<Command::Run::Tmpfile>, L<IPC::Run>, L<Capture::Tiny>, L<IPC::Run3>, L<Command::Runner>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
