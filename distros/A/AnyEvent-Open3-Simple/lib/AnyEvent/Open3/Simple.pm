package AnyEvent::Open3::Simple;

use strict;
use warnings;
use 5.006;
use warnings::register;
use IPC::Open3 qw( open3 );
use Scalar::Util qw( reftype );
use Symbol qw( gensym );
use AnyEvent::Open3::Simple::Process;
use Carp qw( croak );
use File::Temp ();
use constant _is_native_win32 => $^O eq 'MSWin32';
use constant _detect => _is_native_win32() ? 'idle' : 'child';

# ABSTRACT: Interface to open3 under AnyEvent
our $VERSION = '0.86'; # VERSION

 
sub new
{
  my $default_handler = sub { };
  my $class = shift;
  my $args = (reftype($_[0]) || '') eq 'HASH' ? shift : { @_ };
  my %self;
  croak "stdin passed into AnyEvent::Open3::Simple->new no longer supported" if $args->{stdin};
  croak "raw passed into AnyEvent::Open::Simple->new no longer supported" if $args->{raw};
  $self{$_} = $args->{$_} || $default_handler for qw( on_stdout on_stderr on_start on_exit on_signal on_fail on_error on_success );
  $self{impl} = $args->{implementation} 
             || $ENV{ANYEVENT_OPEN3_SIMPLE}
             || _detect();
  croak "unknown implementation $self{impl}" unless $self{impl} =~ /^(idle|child|mojo)$/;
  $self{impl} = _detect() 
    if $self{impl} eq 'mojo' && do { require Mojo::Reactor; Mojo::Reactor->detect eq 'Mojo::Reactor::EV' };
  bless \%self, $class;
}


sub run
{
  croak "run method requires at least one argument"
    unless @_ >= 2;

  my $proc_user = (ref $_[-1] eq 'CODE' ? pop : sub {});

  my $stdin;
  $stdin = pop if ref $_[-1];

  my($self, $program, @arguments) = @_;
  
  my($child_stdin, $child_stdout, $child_stderr);
  $child_stderr = gensym;

  local *TEMP;
  if(defined $stdin)
  {
    my $file = File::Temp->new;
    $file->autoflush(1);
    $file->print(
      ref($stdin) eq 'ARRAY'
      ? join("\n", @{ $stdin })
      : $$stdin
    );
    $file->seek(0,0);
    open TEMP, '<&=', $file;
    $child_stdin = '<&TEMP';
  }

  if($self->{impl} =~ /^(child|idle)$/)
  {
    require AnyEvent;
    AnyEvent::detect();
    require AnyEvent::Open3::Simple::Idle if $self->{impl} eq 'idle';
  }
  elsif($self->{impl} eq 'mojo')
  {
    require Mojo::Reactor;
    require Mojo::IOLoop;
    require AnyEvent::Open3::Simple::Mojo;
  }
  
  my $pid = eval { open3 $child_stdin, $child_stdout, $child_stderr, $program, @arguments };
  
  if(my $error = $@)
  {
    $self->{on_error}->($error, $program, @arguments);
    return;
  }
  
  my $proc = AnyEvent::Open3::Simple::Process->new($pid, $child_stdin);
  $proc_user->($proc);

  $self->{on_start}->($proc, $program, @arguments);

  my $watcher_stdout;
  my $watcher_stderr;
  
  my $stdout_callback = sub {
    my $input = <$child_stdout>;
    return unless defined $input;
    $input =~ s/(\015?\012|\015)$//;
    my $ref = $self->{on_stdout};
    ref($ref) eq 'ARRAY' ? push @$ref, $input : $ref->($proc, $input);
  };

  my $stderr_callback = sub {
    my $input = <$child_stderr>;
    return unless defined $input;
    $input =~ s/(\015?\012|\015)$//;
    my $ref = $self->{on_stderr};
    ref($ref) eq 'ARRAY' ? push @$ref, $input : $ref->($proc, $input);
  };

  if(!_is_native_win32() && $self->{impl} =~ /^(idle|child)$/)
  {
    $watcher_stdout = AnyEvent->io(
      fh   => $child_stdout,
      poll => 'r',
      cb   => $stdout_callback,
    ) unless _is_native_win32();
  
    $watcher_stderr = AnyEvent->io(
      fh   => $child_stderr,
      poll => 'r',
      cb   => $stderr_callback,
    ) unless _is_native_win32();
  }

  my $watcher_child;

  my $end_cb = sub {
    #my($pid, $status) = @_;
    my $status = $_[1];
    my($exit_value, $signal) = ($status >> 8, $status & 127);
      
    $proc->close;
      
    # make sure we consume any stdout and stderr which hasn't
    # been consumed yet.  This seems to make on_out.t work on
    # cygwin
    if($self->{raw})
    {
      local $/;
      $self->{on_stdout}->($proc, scalar <$child_stdout>);
      $self->{on_stderr}->($proc, scalar <$child_stderr>);
    }
    else
    {
      while(!eof $child_stdout)
      {
        my $input = <$child_stdout>;
        last unless defined $input;
        $input =~ s/(\015?\012|\015)$//;
        my $ref = $self->{on_stdout};
        ref($ref) eq 'ARRAY' ? push @$ref, $input : $ref->($proc, $input);
      }
      
      while(!eof $child_stderr)
      {
        my $input = <$child_stderr>;
        last unless defined $input;
        $input =~ s/(\015?\012|\015)$//;
        my $ref = $self->{on_stderr};
        ref($ref) eq 'ARRAY' ? push @$ref, $input : $ref->($proc, $input);
      }
    }
      
    $self->{on_exit}->($proc, $exit_value, $signal);
    $self->{on_signal}->($proc, $signal) if $signal > 0;
    $self->{on_fail}->($proc, $exit_value) if $exit_value > 0;
    $self->{on_success}->($proc) if $signal == 0 && $exit_value == 0;
    undef $watcher_stdout;
    undef $watcher_stderr;
    undef $watcher_child;
    undef $proc;
  };

  if($self->{impl} eq 'mojo')
  {
    my($selout, $selerr);
    
    if(_is_native_win32())
    {
      require IO::Select;
      $selout = IO::Select->new($child_stdout);
      $selerr = IO::Select->new($child_stderr);
    }

    my $reactor = Mojo::IOLoop->singleton->reactor;
    my $id;
    $id = Mojo::IOLoop->recurring(0.25 => sub {
      AnyEvent::Open3::Simple::Mojo::_watcher($pid, sub {
        $end_cb->(@_);
        Mojo::IOLoop->remove($id);
        if(_is_native_win32())
        {
          $stdout_callback->() if $selout->can_read(0);
          $stderr_callback->() if $selerr->can_read(0);
        }
        else
        {
          $reactor->remove($child_stdout);
          $reactor->remove($child_stderr);
        }
      });
    });
   
  }
  elsif($self->{impl} eq 'idle')
  {
    my($selout, $selerr);
    
    if(_is_native_win32())
    {
      require IO::Select;
      $selout = IO::Select->new($child_stdout);
      $selerr = IO::Select->new($child_stderr);
    }

    $watcher_child = AnyEvent->idle(cb => sub {
      if(_is_native_win32())
      {
        $stdout_callback->() if $selout->can_read(0);
        $stderr_callback->() if $selerr->can_read(0);
      }
      AnyEvent::Open3::Simple::Idle::_watcher($pid, $end_cb);
    });
  }
  else
  {
    $watcher_child = AnyEvent->child(
      pid => $pid,
      cb  => $end_cb,
    );
  }
  
  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Open3::Simple - Interface to open3 under AnyEvent

=head1 VERSION

version 0.86

=head1 SYNOPSIS

 use 5.010;
 use AnyEvent;
 use AnyEvent::Open3::Simple;
 
 my $done = AnyEvent->condvar;
 
 my $ipc = AnyEvent::Open3::Simple->new(
   on_start => sub {
     my $proc = shift;       # isa AnyEvent::Open3::Simple::Process
     my $program = shift;    # string
     my @args = @_;          # list of arguments
     say 'child PID: ', $proc->pid;
   },
   on_stdout => sub { 
     my $proc = shift;       # isa AnyEvent::Open3::Simple::Process
     my $line = shift;       # string
     say 'out: ', $string;
   },
   on_stderr => sub {
     my $proc = shift;       # isa AnyEvent::Open3::Simple::Process
     my $line = shift;       # string
     say 'err: ', $line;
   },
   on_exit   => sub {
     my $proc = shift;       # isa AnyEvent::Open3::Simple::Process
     my $exit_value = shift; # integer
     my $signal = shift;     # integer
     say 'exit value: ', $exit_value;
     say 'signal:     ', $signal;
     $done->send;
   },
   on_error => sub {
     my $error = shift;      # the exception thrown by IPC::Open3::open3
     my $program = shift;    # string
     my @args = @_;          # list of arguments
     warn "error: $error";
     $done->send;
   },
 );
 
 $ipc->run('echo', 'hello there');
 $done->recv;

=head1 DESCRIPTION

This module provides an interface to open3 while running under AnyEvent
that delivers data from stdout and stderr as lines are written by the
subprocess.  The interface is reminiscent of L<IPC::Open3::Simple>, 
although this module does provides a somewhat different API, so it
cannot be used a drop in replacement for that module.

There are already a number of interfaces for interacting with subprocesses
in the context of L<AnyEvent>, but this one is the most convenient for my
usage.  Note the modules listed in the SEE ALSO section below for other 
interfaces that may be more or less appropriate.

=head1 CONSTRUCTOR

Constructor takes a hash or hashref of event callbacks and attributes.
Event callbacks have an C<on_> prefix, attributes do not.

=head2 ATTRIBUTES

=over 4

=item * implementation

The implementation to use for detecting process termination.  This should
be one of C<child>, C<idle> or C<mojo>.  On all platforms except for Microsoft
Windows (but not Cygwin) the default is C<child>.

You can change the default by setting the C<ANYEVENT_OPEN3_SIMPLE>
environment variable, like this:

 % export ANYEVENT_OPEN3_SIMPLE=idle

The C<mojo> implementation is experimental and allows you to use
L<AnyEvent::Open3::Simple> with L<Mojolicious> but without L<EV>
(which is usually required for L<AnyEvent>, L<Mojolicious> interaction).

=back

=head2 EVENTS

These events will be triggered by the subprocess when the run method is 
called. Each event callback (except C<on_error>) gets passed in an 
instance of L<AnyEvent::Open3::Simple::Process> as its first argument 
which can be used to get the PID of the subprocess, or to write to it.  
C<on_error> does not get a process object because it indicates an error in 
the creation of the process.

Not all of these events will fire depending on the execution of the 
child process.  In the very least exactly one of C<on_start> or C<on_error>
will be called.

=over 4

=item * C<on_start> ($proc, $program, @arguments)

Called after the process is created, but before the run method returns
(that is, it does not wait to re-enter the event loop first).

In versions 0.78 and better, this event also gets the program name
and arguments passed into the L<run|AnyEvent::Open3::Simple#run>
method.

=item * C<on_error> ($error, $program, @arguments)

Called when there is an execution error, for example, if you ask
to run a program that does not exist.  No process is passed in
because the process failed to create.  The error passed in is 
the error thrown by L<IPC::Open3> (typically a string which begins
with "open3: ...").

In some environments open3 is unable to detect exec errors in the
child, so you may not be able to rely on this event.  It does 
seem to work consistently on Perl 5.14 or better though.

Different environments have different ways of handling it when
you ask to run a program that doesn't exist.  On Linux and Cygwin,
this will raise an C<on_error> event, on C<MSWin32> it will
not trigger a C<on_error> and instead cause a normal exit
with a exit value of 1.

In versions 0.77 and better, this event also gets the program name
and arguments passed into the L<run|AnyEvent::Open3::Simple#run>
method.

=item * C<on_stdout> ($proc, $line)

Called on every line printed to stdout by the child process.

=item * C<on_stderr> ($proc, $line)

Called on every line printed to stderr by the child process.

=item * C<on_exit> ($proc, $exit_value, $signal)

Called when the processes completes, either because it called exit,
or if it was killed by a signal.  

=item * C<on_success> ($proc)

Called when the process returns zero exit value and is not terminated by a signal.

=item * C<on_signal> ($proc, $signal)

Called when the processes is terminated by a signal.

=item * C<on_fail> ($proc, $exit_value)

Called when the process returns a non-zero exit value.

=back

=head1 METHODS

=head2 run

 $ipc->run($program, @arguments);
 $ipc->run($program, @arguments, \$stdin);             # (version 0.76)
 $ipc->run($program, @arguments, \@stdin);             # (version 0.76)
 $ipc->run($program, @arguments, sub {...});           # (version 0.80)
 $ipc->run($program, @arguments, \$stdin, sub {...});  # (version 0.80)
 $ipc->run($program, @arguments, \@stdin, sub {...});  # (version 0.80)

Start the given program with the given arguments.  Returns
immediately.  Any events that have been specified in the
constructor (except for C<on_start>) will not be called until
the process re-enters the event loop.

You may optionally provide the full content of standard input
as a string reference or list reference as the last argument
(or second to last if you are providing a callback below).
If provided as a list reference, it will be joined by new lines
in whatever format is native to your Perl.  Currently on 
(non cygwin) Windows (Strawberry, ActiveState) this is the only
way to provide standard input to the subprocess.

Do not mix the use of passing standard input to L<run|AnyEvent::Open3::Simple#run>
and L<AnyEvent::Open3::Simple::Process#print> or L<AnyEvent::Open3::Simple::Process#say>,
otherwise bad things may happen.

In version 0.80 or better, you may provide a callback as the last argument
which is called before C<on_start>, and takes the process object as its only 
argument.  For example:

 foreach my $i (1..10)
 {
   $ipc->run($prog, @args, \$stdin, sub {
     my($proc) = @_;
     $proc->user({ iteration => $i });
   });
 }

This is useful for making data accessible to C<$ipc> object's callbacks that may
be out of scope otherwise.

=head1 CAVEATS

Some AnyEvent implementations may not work properly with the method
used by AnyEvent::Open3::Simple to wait for the child process to 
terminate.  See L<AnyEvent/"CHILD-PROCESS-WATCHERS"> for details.

This module uses an idle watcher instead of a child watcher to detect
program termination on Microsoft Windows (but not Cygwin).  This is
because the child watchers are unsupported by AnyEvent on Windows.
The idle watcher implementation seems to pass the test suite, but there
may be some traps for the unwary.  There may be other platforms or
event loops where this is the appropriate choice, and you can use the
C<ANYEVENT_OPEN3_SIMPLE> environment variable or the C<implementation>
attribute to force it use an idle watcher instead.  Patches for detecting
environments where idle watchers should be used are welcome and
encouraged.

As of version 0.85, this module works on Windows with L<AnyEvent::Impl::EV>,
L<AnyEvent::Impl::Event> and L<AnyEvent::Impl::Perl> (possibly others),
although in the past they have either not worked or had limitations placed
on them.  Because the author of L<AnyEvent> does not hold the native Windows
port of Perl in high regard problems such as this may pop up again
in the future and may not be addressed, and may be out of the control of the
author of this module.

Performance for the idle watcher implementation on native Windows (non-Cygwin)
is almost certainly suboptimal, but the author of this module uses it
and finds it useful despite this.

Writing to a subprocesses stdin with L<AnyEvent::Open3::Simple::Process#print>
or L<AnyEvent::Open3::Simple::Process#say> is unsupported on Microsoft 
Windows (it does work under Cygwin though).

There are some traps for the unwary relating to buffers and deadlocks,
L<IPC::Open3> is recommended reading.

If you register a call back for C<on_exit>, but not C<on_error> then
use a condition variable to wait for the process to complete as in
this:

 my $cv = AnyEvent->condvar;
 my $ipc = AnyEvent::Open3::Simple->new(
   on_exit => sub { $cv->send },
 );
 $ipc->run('command_not_found');
 $cv->recv;

You might be waiting forever if there is an error starting the
process (if for example you give it a bad command).  To handle
this situation you might use croak on the condition variable
in the event of error:

 my $cv = AnyEvent->condvar;
 my $ipc = AnyEvent::Open3::Simple->new(
   on_exit => sub { $cv->send },
   on_error => sub {
     my $error = shift;
     $cv->croak($error);
   },
 );
 $ipc->run('command_not_found');
 $cv->recv;

This will cause the C<recv> to die, printing a useful diagnostic
if the exception isn't caught somewhere else.

=head1 SEE ALSO

L<AnyEvent::Subprocess>, L<AnyEvent::Util>, L<AnyEvent::Run>.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Stephen R. Scaffidi

Scott Wiersdorf

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
