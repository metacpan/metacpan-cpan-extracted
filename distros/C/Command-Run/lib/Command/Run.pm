package Command::Run;

our $VERSION = "0.9901";

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
    if (@_ == 1 or @_ > 1 && $_[0] !~ /^(command|stdin|stderr)$/) {
	# Command::new(@command) style
	$obj->command(@_);
    } else {
	# Command::new(command => [...]) style
	$obj->configure(@_);
    }
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
	    my $data = $opt{stdin};
	    open my $fh, '<', \$data or die "open: $!\n";
	    open STDIN, '<&', $fh or die "dup: $!\n";
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
    my $input = $obj->{INPUT} //= do {
	my $fh = new_tmpfile IO::File or die "new_tmpfile: $!\n";
	$fh->fcntl(F_SETFD, 0) or die "fcntl F_SETFD: $!\n";
	binmode $fh, ':encoding(utf8)';
	$fh;
    };
    $input->seek(0, 0)  or die "seek: $!\n";
    $input->truncate(0) or die "truncate: $!\n";
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
    my $cmd = Command::Run->new('date');
    $cmd->update;
    system("cat", $cmd->path);  # /dev/fd/N

    # Code reference execution
    my $result = Command::Run->new(
        command => [\&some_function, @args],
        stdin   => $input_data,
    )->run;

    # Using with() method
    my ($out, $err);
    Command::Run->new("command", @args)
        ->with(stdin => $input, stdout => \$out, stderr => \$err)
        ->run;

=head1 VERSION

Version 0.9901

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

=item B<new>(@command)

Create a new Command::Run object.  Parameters can be passed as
key-value pairs (see L</PARAMETERS>), or a command can be passed
directly:

    # Parameters style
    my $runner = Command::Run->new(
        command => \@command,
        stdin   => $input_data,
        stderr  => 'redirect',
    );

    # Direct command style
    my $runner = Command::Run->new('ls', '-l');

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
