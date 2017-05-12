package AnyEvent::Process::Job;
use strict;

sub new {
	my ($ref, $pid) = @_;
	my $self = bless {pid => $pid, cbs => [], handles => [], timers => []}, $ref;

	return $self;
}

sub kill {
	my ($self, $signal) = @_;

	return kill $signal, $self->{pid};
}

sub pid {
	return $_[0]->{pid};
}

sub _add_cb {
	my ($self, $cb) = @_;
	push @{$self->{cbs}}, $cb;
}

sub _add_handle {
	my ($self, $handle) = @_;
	push @{$self->{handles}}, $handle;
}

sub _add_timer {
	my ($self, $timer) = @_;
	push @{$self->{timers}}, $timer;
}

sub _remove_cbs {
	undef $_[0]->{cbs};
}

sub _remove_timers {
	my $self = shift;
	undef $_ foreach @{$self->{timers}};
	undef $self->{timers};
}

sub close {
	my $self = shift;
	undef $_ foreach @{$self->{handles}};
	undef $self->{handles};
}

package AnyEvent::Process;
use strict;

use AnyEvent::Handle;
use AnyEvent::Util;
use AnyEvent;
use Carp;

our @proc_args = qw(fh_table code on_completion args watchdog_interval on_watchdog kill_interval on_kill close_all_fds_except);
our $VERSION = '0.02';

my $nop = sub {};

sub _yield {
	my $cv_yield = AE::cv;
	AE::postpone { $cv_yield->send };
	$cv_yield->recv;
}

# Create a callback factory. This is needed to execute on_completion after all
# other callbacks. 
sub _create_callback_factory {
	my $on_completion = shift // $nop;
	my $counter = 0;
	my @on_completion_args;

	my $factory = sub {
		my $func = shift // $nop;

		$counter++;
		return sub {
			my ($err, $rtn);

			eval {
				$rtn = $func->(@_);
			}; $err = $@;

			if (--$counter == 0) {
				eval {
					$on_completion->(@on_completion_args);
				}; $err = $err || $@;
				$on_completion_args[0]->_remove_cbs;
			}

			if ($err) {
				croak $err;
			}

			return $rtn;
		}
	};
	my $set_on_completion_args = sub {
		@on_completion_args = @_;
	};

	return $factory, $set_on_completion_args;
}

sub new {
	my $ref = shift;
	my $self = bless {}, $ref;
	my %args = @_;

	foreach my $arg (@proc_args) {
		$self->{$arg} = delete $args{$arg} if defined $args{$arg};
	}

	if (%args) {
		croak 'Unknown arguments: ' . join ', ', keys %args;
	}

	return $self;
}

sub run {
	my $self = shift;
	my %args = @_;
	my %proc_args;
	my @fh_table;
	my @handles;

	# Process arguments
	foreach my $arg (@proc_args) {
		$proc_args{$arg} = $args{$arg} // $self->{$arg};
		delete $args{$arg} if defined $args{$arg};
	}

	if (%args) {
		croak 'Unknown arguments: ' . join ', ', keys %args;
	}

	my ($callback_factory, $set_on_completion_args) = 
			_create_callback_factory($proc_args{on_completion});

	# Handle fh_table
	for (my $i = 0; $i < $#{$proc_args{fh_table}}; $i += 2) {
		my ($handle, $args) = @{$proc_args{fh_table}}[$i, $i + 1];

		unless (ref $handle eq 'GLOB' or $handle =~ /^\d{1,4}$/) {
			croak "Every second element in 'fh_table' must be " . 
					"GLOB reference or file descriptor number";
		} elsif ($args->[0] eq 'pipe') {
			my ($my_fh, $child_fh);

			# Create pipe or socketpair
			if ($args->[1] eq '>') {
				($my_fh, $child_fh) = portable_pipe;
			} elsif ($args->[1] eq '<') {
				($child_fh, $my_fh) = portable_pipe;
			} elsif ($args->[1] eq '+>' or $args->[1] eq '+<') {
				($child_fh, $my_fh) = portable_socketpair;
			} else {
				croak "Invalid mode '$args->[1]'";
			}

			unless (defined $my_fh && defined $child_fh) {
				croak "Creating pipe failed: $!";
			}

			push @fh_table, [$handle, $child_fh];
			if (ref $args->[2] eq 'GLOB') {
				open $args->[2], '+>&', $my_fh;
				close $my_fh;
			} elsif ($args->[2] eq 'handle') {
				push @handles, [$my_fh, $args->[3]];
			}
		} elsif ($args->[0] eq 'open') {
			open my $fh, $args->[1], $args->[2];
			unless (defined $fh) {
				croak "Opening file failed: $!";
			}
			push @fh_table, [$handle, $fh];
		} elsif ($args->[0] eq 'decorate') {
			my $out = $args->[3];
			unless (defined $out or ref $out eq 'GLOB') {
				croak "Third argument of decorate must be a glob reference";
			}

			my ($my_fh, $child_fh) = portable_pipe;
			unless (defined $my_fh && defined $child_fh) {
				croak "Creating pipe failed: $!";
			}

			my $on_read;
			my $decorator = $args->[2];
			if (defined $decorator and ref $decorator eq '') {
				$on_read = sub {
					while ($_[0]->rbuf() =~ s/^(.*\n)//) {
						print $out $decorator, $1;
					}
				};
			} elsif (defined $decorator and ref $decorator eq 'CODE') {
				$on_read = sub {
					while ($_[0]->rbuf() =~ s/^(.*\n)//) {
						print $out $decorator->($1);
					}
				};
			} else {
				croak "Second argument of decorate must be a string or code reference";
			}

			push @fh_table, [$handle, $child_fh];
			push @handles,  [$my_fh, [on_read => $on_read, on_eof => $callback_factory->()]];
		} else {
			croak "Unknown redirect type '$args->[0]'";
		}
	}

	# Start child
	my $pid = fork;
	my $job;
	unless (defined $pid) {
		croak "Fork failed: $!";
	} elsif ($pid == 0) {
		# Duplicate FDs
		foreach my $dup (@fh_table) {
			open $dup->[0], '+>&', $dup->[1];
			close $dup->[1];
		}

		# Close handles
		foreach my $dup (@handles) {
			close $dup->[0];
		}

		# Close other filedescriptors
		if (defined $proc_args{close_all_fds_except}) {
			my @not_close = map fileno($_), @{$proc_args{close_all_fds_except}};
			AE::log trace => "Closing all other fds except: " . join ', ', @not_close;
			push @not_close, fileno $_->[0] foreach @fh_table;

			AE::log trace => "Closing all other fds except: " . join ', ', @not_close;
			AnyEvent::Util::close_all_fds_except @not_close;
		}

		# Run the code
		my $rtn = $proc_args{code}->(@{$proc_args{args} // []});
		exit ($rtn eq int($rtn) ? $rtn : 1);
	} else {
		AE::log info => "Forked new process $pid.";

		$job = new AnyEvent::Process::Job($pid);

		# Close FDs
		foreach my $dup (@fh_table) {
			AE::log trace => "Closing $dup->[1].";
			close $dup->[1];
		}

		# Create handles
		foreach my $handle (@handles) {
			my (@hdl_args, @hdl_calls);
			for (my $i = 0; $i < $#{$handle->[1]}; $i += 2) {
				if (AnyEvent::Handle->can($handle->[1][$i]) and 'ARRAY' eq ref $handle->[1][$i+1]) {
					if ($handle->[1][$i] eq 'on_eof') {
						push @hdl_calls, [$handle->[1][$i], $callback_factory->($handle->[1][$i+1][0])];
					} else {
						push @hdl_calls, [$handle->[1][$i], $handle->[1][$i+1]];
					}
				} else {
					push @hdl_args, $handle->[1][$i] => $handle->[1][$i+1];
				}
			}
			AE::log trace => "Creating handle " . join ' ', @hdl_args;
			my $hdl = AnyEvent::Handle->new(fh => $handle->[0], @hdl_args);
			foreach my $call (@hdl_calls) {
				no strict 'refs';
				my $method = $call->[0];
				AE::log trace => "Calling handle method $method(" . join(', ', @{$call->[1]}) . ')';
				$hdl->$method(@{$call->[1]});
			}
			$job->_add_handle($hdl);
		}

		# Create callbacks
		my $completion_cb = sub {
			$job->_remove_timers();
			AE::log info => "Process $job->{pid} finished with code $_[1].";
			$set_on_completion_args->($job, $_[1]);
		};
		$job->_add_cb(AE::child $pid, $callback_factory->($completion_cb));

		$self->{job} = $job;

		# Create watchdog and kill timers
		my $on_kill = $proc_args{on_kill} // sub { $_[0]->kill(9) };
		if (defined $proc_args{kill_interval}) {
			my $kill_cb = sub { 
				$job->_remove_timers();
				AE::log warn => "Process $job->{pid} is running too long, killing it.";
				$on_kill->($job);
			};
			$job->_add_timer(AE::timer $proc_args{kill_interval}, 0, $kill_cb);
		}
		if (defined $proc_args{watchdog_interval} or defined $proc_args{on_watchdog}) {
			unless (defined $proc_args{watchdog_interval} &&
				defined $proc_args{on_watchdog}) {
				croak "Both or none of watchdog_interval and on_watchdog must be defined";
			}

			my $watchdog_cb = sub {
				AE::log info => "Executing watchdog for process $job->{pid}.";
				unless ($proc_args{on_watchdog}->($job)) {
					$job->_remove_timers();
					AE::log warn => "Watchdog for process $job->{pid} failed, killing it.";
					$on_kill->($job);
				}
			};
			$job->_add_timer(AE::timer $proc_args{watchdog_interval}, $proc_args{watchdog_interval}, $watchdog_cb);
		}
	}
	
	# We need this to allow AE collecting pending signals and prevent accumulation of zombies
	$self->_yield;

	return $job;
}

sub kill {
	my ($self, $signal) = @_;

	croak 'No process was started' unless defined $self->{job};
	return $self->{job}->kill($signal // 15);
}

sub pid {
	my $self = shift;

	croak 'No process was started' unless defined $self->{job};
	return $self->{job}->pid();
}

sub close {
	my $self = shift;

	croak 'No process was started' unless defined $self->{job};
	return $self->{job}->close();
}

1;

__END__

=head1 NAME

AnyEvent::Process - Start a process and watch for events 

=head1 SYNOPSIS

  use AnyEvent::Process;

  my $proc = new AnyEvent::Process(
    fh_table => [
      # Connect OUTPIPE file handle to STDIN of a new process
      \*STDIN  => ['pipe', '<', \*OUTPIPE],
      # Connect INPIPE file handle to STDOUT of a new process
      \*STDOUT => ['pipe', '>', \*INPIPE],
      # Print everything written to STDERR by a new process to STDERR of current
      # process, but prefix every line with 'bc ERROR: '
      \*STDERR => ['decorate', '>', 'bc ERROR: ', \*STDERR]
    ],
    # We don't want to wait longer than 10 seconds, so kill bc after that time
    kill_interval => 10,
    # Execute bc in a new process
    code => sub {
      exec 'bc', '-q';
    });
  
  # Start bc in a new process
  $proc->run();
  
  # Send data to bc standart input
  print OUTPIPE "123^456\n";
  close OUTPIPE;
  
  # Read from bc standart output
  my $result = <INPIPE>;
  print "BC computed $result";

=head1 DESCRIPTION

This module starts a new process. It allows connecting file descriptor in the 
new process to files or handles (both to perl handles or to 
L<AnyEvent:Handle|AnyEvent:Handle>).

It is possible to monitor the process execution using a watchdog callback or 
kill the process after a defined time.

=head1 METHODS

=head2 new

Creates new AnyEvent::Process instance. 

Arguments:

=over 4

=item fh_table (optional)

Can be used to define opened files in a created process. Syntax of this option
is the following:

  [
    HANDLE => [TYPE, DIRECTION, ARGS...],
    HANDLE => [TYPE, DIRECTION, ARGS...],
    ...
  ]

where

=over 4

=item HANDLE

is a handle reference or a filedescriptor number, which will be opened in the 
new process.

=item DIRECTION

can be C<E<gt>> if the HANDLE in the new process shall be opened for writting, 
C<E<lt>> if it shall be opened for reading or C<+E<lt>> if it shall be opened
in the read-write mode.

=item TYPE

Following types are supported:

=over 4

=item pipe

Opens an unidirectional pipe or a bidirectional socket (depends on the DIRECTION) 
between the current and the new process. ARGS can be a glob reference, then the 
second end of the pipe or socket pair is connected to it, or C<handle =E<gt> 
[handle_args...]>, where handle_args are an argument passed to the 
L<AnyEvent::Handle|AnyEvent::Handle> constructor, which will be connected to the
second end of the pipe or socket. In the a case handle_args is in the form of 
C<method =E<gt> [method_args...]> and method is AnyEvent::Handle method, then 
this method is called with method_args, after the handle is instantiated.

Example:
  \*STDOUT => ['pipe', '>', handle => [push_read  => [line => \&reader]]]

=item open

Opens the specified HANDLE using open with DIRECTION and ARGS as its arguments.

Example:
  0 => ['open', '<', '/dev/null']

=item decorate

Decorate every line written to the HANDLE by the child. The DIRECTION must be 
C<E<gt>>. ARGS are in the form C<DECORATOR, OUTPUT>. OUTPUT is a glob reference
and specifies a file handle, into which decorated lines are written. Decorator is
a string or a code reference. If the decorator is a string, it is prepended to 
every line written by the started process. If the DECORATOR is a code reference, 
it is called for each line written to the HANDLE with that line as its argument 
and its return value is written to the OUTPUT.

Example:
  \*STDERR => ['decorate', '>', 'Child STDERR: ', \*STDERR]

=back

=back

=item code (optional, but must be specified either in new or run) 

A code reference, which is executed in the newly started process.

=item args (optional)

Arguments past to a code reference specified as code argument when it is called.

=item on_completion (optional)

Callback, which is executed when the process finishes. It receives 
AnyEvent::Process::Job instance as the first argument and exit code as the 
second argument.

It is called after all AnyEvent::Handle callbacks specified in the fh_table.

=item watchdog_interval (in seconds, optional)

How often a watchdog shall be called. If undefined or set to 0, the watchdog
functionality is disabled. 

=item on_watchdog (optional)

Watchdog callback, receives AnyEvent::Process::Job instance as its argument.
If it returns false value, the watched process is killed (see on_kill). 

=item kill_interval (in seconds, optional)

Maximum time the process can run. After this time expires, the process is 
killed.

=item on_kill (optional, sends SIGKILL by default)

Called, when the process shall be killed. Receives AnyEvent::Process::Job 
instance as its argument.

=back

=head2 run

Run a process. Any argument specified to the constructor can be overridden here.
Returns AnyEvent::Process::Job, which represents the new process, or undef on an
error.

=over 4

=item Returned AnyEvent::Process::Job instance has following methods:

=over 4

=item pid

Returns PID of the process.

=item kill

Send signal specified as the argument to the process.

=item close

Close all pipes and socketpairs between this process and the child.

=back

=back

=head2 kill

Run the kill method of the latest created AnyEvent::Process::Job - sends signal
specified as its argument to the process.

=head2 pid

Run the pid method of the latest created AnyEvent::Process::Job - returns PID of
the process.

=head2 close

Run the close method of the latest created AnyEvent::Process::Job.

=head1 SEE ALSO

L<AnyEvent> - Event framework for PERL.

L<AnyEvent::Subprocess> - Similar module, but with more dependencies and a little
more complicated usage.

=head1 AUTHOR

Petr Malat E<lt>oss@malat.bizE<gt> L<http://malat.biz/>

=head1 COPYRIGHT

Copyright (c) 2012 by Petr Malat E<lt>oss@malat.bizE<gt>

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.
See F<http://www.perl.com/perl/misc/Artistic.html>.
