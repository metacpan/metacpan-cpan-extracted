# Arch Perl library, Copyright (C) 2004-2005 Mikhael Goikhman, Enno Cramer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.006;
use strict;

package Arch::Run;

use IO::Poll qw(POLLIN POLLOUT POLLERR);
use POSIX qw(waitpid WNOHANG setsid);

use constant RAW   => 0;
use constant LINES => 1;
use constant ALL   => 2;

use vars qw(@ISA @EXPORT_OK @OBSERVERS %SUBS $DETACH_CONSOLE);

use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
	run_with_pipe run_async poll wait unobserve observe
	RAW LINES ALL
);

BEGIN {
	$DETACH_CONSOLE = 0;
}

sub set_detach_console ($) {
	$DETACH_CONSOLE = shift;
}

sub run_with_pipe (@) {
	my $arg0 = shift || die "Missing command to run_with_pipe\n";
	my @args = (split(/\s+/, $arg0), @_);

	pipe TO_PARENT_RDR, TO_PARENT_WRT;
	pipe TO_CHILD_RDR,  TO_CHILD_WRT;

	my $pid = fork;
	die "Can't fork: $!\n" unless defined $pid;

	if ($pid) {
		close TO_PARENT_WRT;
		close TO_CHILD_RDR;

		return wantarray
			? (\*TO_PARENT_RDR, \*TO_CHILD_WRT, $pid)
			: \*TO_PARENT_RDR;

	} else {
		close TO_PARENT_RDR;
		close TO_CHILD_WRT;

		close STDIN;
		# my perl won't compile this if i use
		#   open STDIN, "<&", TO_CHILD_RDR
		# the same thing for STDOUT is accepted though,
		# the "<&" vs ">&" makes the difference
		open STDIN, "<&TO_CHILD_RDR";
		close TO_CHILD_RDR;

		close STDOUT;
		open STDOUT, ">&TO_PARENT_WRT";
		close TO_PARENT_WRT;

		setsid
			if $DETACH_CONSOLE;

		exec(@args);
	}
}

sub run_async (%) {
	my %args = @_;

	die "Missing command to run_async\n"
		unless exists $args{command};

	my @args = ref $args{command} ? @{$args{command}} : $args{command};
	my ($out, $in, $pid) = run_with_pipe(@args);

	_notify('cmd_start', $pid, @args);

	$SUBS{$pid} = {
		# in   => $in, # not for now
		out  => $out,
		mode => $args{mode},
		data => $args{datacb},
		exit => $args{exitcb},

		accum => '',
	};

	close($in); # no input for now

	return $pid;
}

sub get_output_handle ($) {
	my $key = shift;

	return $SUBS{$key}->{out};
}

sub handle_output ($) {
	my $key = shift;
	my $rec = $SUBS{$key};

	my $buffer;
	my $result = sysread $rec->{out}, $buffer, 4096;

	_notify('cmd_output_raw', $key, $buffer)
		if $result > 0;

	# handle output
	if ($result) {
		# raw mode
		if ($rec->{mode} eq RAW) {
			$rec->{data}->($buffer);

		# line mode
		} elsif ($rec->{mode} eq LINES) {
			$rec->{accum} .= $buffer;

			while ($rec->{accum} =~ s/^.*?(\015\012|\012|\015)//) {
				$rec->{data}->($&);
			}

		# bloody big block mode
		} else {
			$rec->{accum} .= $buffer;
			$rec->{data}->($rec->{accum})
				if $result == 0;
		}

	# error and eof
	} else {
		$rec->{data}->($rec->{accum})
			if length $rec->{accum};

		my $pid = waitpid $key, 0;
		my $exitcode = $pid == $key ? $? : undef;

		_notify('cmd_exit', $exitcode);

		$rec->{exit}->($exitcode)
			if defined $rec->{exit};

		delete $SUBS{$key};
	}
}

sub poll (;$) {
	my $count = 0;

	# check for output
	my $poll = IO::Poll->new;
	foreach my $key (keys %SUBS) {
		$poll->mask($SUBS{$key}->{out}, POLLIN | POLLERR)
			unless $SUBS{$key}->{done};
	}

	my $result = $poll->poll($_[0]);
	foreach my $key (keys %SUBS) {
		if ($poll->events($SUBS{$key}->{out})) {
			handle_output($key);
			++$count;
		}
	}

	return $count;
}

sub wait ($) {
	my $pid = shift;

	my $ret;

	# overwrite callback to capture exit code
	if (exists $SUBS{$pid}) {
		my $old_cb = $SUBS{$pid}->{exit};
		$SUBS{$pid}->{exit} = sub {
			$ret = shift;
			$old_cb->($ret)
				if defined $old_cb;
		};

		# Poll until a) our target has exited or b) there are no more
		# file handles to poll for.
		while (exists $SUBS{$pid} && poll(undef)) {}
	}

	# returns undef if childs exit has already been handled
	return $ret;
}

sub killall (;$) {
	my $signal = shift || 'INT';

	kill $signal, keys %SUBS;
	while (%SUBS && poll(undef)) {}
}

sub _notify (@) {
	die "no touching\n"
		if caller ne __PACKAGE__;

	my $method = shift;
	foreach my $observer (@OBSERVERS) {
		$observer->$method(@_) if $observer->can($method);
	}
}

sub unobserve ($) {
	my $observer = shift;
	@OBSERVERS = grep { $_ ne $observer } @OBSERVERS;
}   

sub observe ($) {
   my $observer = shift;
	unobserve($observer);
	push @OBSERVERS, $observer;
}

1;

__END__


=head1 NAME

Arch::Run - run subprocesses and capture output

=head1 SYNOPSIS

    use Gtk2 -init;
    use Arch::Run qw(poll run_async LINES);

    my $window = Gtk2::Window->new;
    my $label = Gtk2::Label->new;
    my $pbar = Gtk2::ProgressBar->new;
    my $vbox = Gtk2::VBox->new;
    $vbox->add($label); $vbox->add($pbar); $window->add($vbox);
    $window->signal_connect(destroy => sub { Gtk2->main_quit; });
    $window->set_default_size(200, 48); $window->show_all;
    sub set_str { $label->set_text($_[0]); }

    my $go = 1;  # keep progress bar pulsing
    Glib::Timeout->add(100, sub { $pbar->pulse; poll(0); $go; });

    run_async(   
        command => [ 'du', '-hs', glob('/usr/share/*') ],
        mode    => LINES,
        datacb  => sub { chomp(my $str = $_[0]); set_str($str); },
        exitcb  => sub { $go = 0; set_str("exit code: $_[0]"); },
    );

    Gtk2->main;

=head1 DESCRIPTION

Arch::Run allows the user to run run subprocesses and capture their
output in a single threaded environment without blocking the whole
application.

You can use either B<poll> to wait for and handle process output, or
use B<handle_output> and B<handle_exits> to integrate
B<Arch::Run> with your applications main loop.


=head1 METHODS

The following functions are available:
B<run_with_pipe>,
B<run_async>,
B<get_output_handle>,
B<handle_output>,
B<poll>,
B<wait>,
B<killall>,
B<observe>,
B<unobserve>.


=over 4

=item B<run_with_pipe> I<$command>

=item B<run_with_pipe> I<$executable> I<$argument> ...

Fork and exec a program with STDIN and STDOUT connected to pipes. In
scalar context returns the output handle, STDIN will be connected to
/dev/null. In list context, returns the output and input handle.

The programs standard error handle (STDERR) is left unchanged.


=item B<run_async> I<%args>

Run a command asyncronously in the background.  Returns the
subprocesses pid.

Valid keys for I<%args> are:

=over 4

=item B<command> => I<$command>

=item B<command> => [ I<$executable> I<$argument> ... ]

Program and parameters.


=item B<mode> => I<$accum_mode>

Control how output data is accumulated and passed to B<data> and
B<finish> callbacks.

I<$accum_mode> can be one of

=over 4

=item B<RAW>

No accumulation.  Pass output to B<data> callback as it is received.


=item B<LINES>

Accumulate output in lines.  Pass every line separately to B<data>
callback.


=item B<ALL>

Accumulate all data.  Pass complete command output as one block to
B<data> callback.

=back


=item B<datacb> => I<$data_callback>

Codeblock or subroutine to be called when new output is available.
Receives one parameter, the accumulated command output.


=item B<exitcb> => I<$exit_callback>

Codeblock or subroutine to be called when subprocess exits.  Receives
a single parameter, the commands exit code. (Or maybe not. We have to
handle SIG{CHLD} then. But maybe we have to do so anyway.)

=back


=item B<get_output_handle> I<$pid>

Returns the STDOUT handle of process $pid.  You should never directly
read from the returned handle.  Use L<IO::Select> or L<IO::Poll> to
wait for output and call B<handle_output> to process the output.


=item B<handle_output> I<$pid>

Handle available output from process I<$pid>.

B<ATTENTION:> Call this method only if there really is output to be
read.  It will block otherwise.


=item B<poll> I<$timeout>

Check running subprocesses for available output and run callbacks as
appropriate.  Wait at most I<$timeout> seconds when no output is
available.

Returns the number of processes that had output available.


=item B<wait> I<$pid>

Wait for subprocess I<$pid> to terminate, repeatedly calling B<poll>.
Returns the processes exit status or C<undef> if B<poll> has already been
called after the processes exit.


=item B<killall> [I<$signal>]

Send signal I<$signal> (B<SIGINT> if omitted) to all managed
subprocesses, and wait until every subprocess to terminate.


=item B<observe> I<$observer>

Register an observer object that wishes to be notified of running
subprocesses.  I<$observer> should implement one or more of the
following methods, depending on which event it wishes to receive.

=over 4

=item B<-E<gt>cmd_start> I<$pid> I<$executable> I<$argument> ...

Called whenever a new subprocess has been started.  Receives the
subprocesses PID and the executed command line.


=item B<-E<gt>cmd_output_raw> I<$pid> I<$data>

Called whenever a subprocess has generated output.  Receives the
subprocesses PID and a block of output data.

B<NOTE:> I<$data> is not preprocesses (e.g. split into lines).
B<cmd_output_raw> receives data block as if B<RAW> mode was used.


=item B<-E<gt>cmd_exit> I<$pid> I<$exitcode>

Called whenever a subprocess exits.  Receives the subprocesses PID and
exit code.

=back


=item B<unobserve> I<$observer>

Remove I<$observer> from observer list.

=back

=cut
