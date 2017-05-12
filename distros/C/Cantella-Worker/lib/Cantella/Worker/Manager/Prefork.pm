package Cantella::Worker::Manager::Prefork;

use Moose;
use POE qw( Wheel::Run );
use Data::GUID;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Types::Log::Dispatch qw(Logger);
use Cantella::Worker::Types qw/WorkerClassName/;

our $VERSION = '0.002002';
$VERSION = eval $VERSION;

has logger => (
  is => 'ro',
  isa => Logger,
  coerce => 1,
  required => 1,
  default => sub {
    Log::Dispatch->new(outputs => [ ['Null', min_level => 'debug' ] ]);
  }
);

has program_name => (
  is => 'ro',
  isa => NonEmptySimpleStr,
  predicate => 'has_program_name',
);

has worker_class => (
  is => 'ro',
  isa => WorkerClassName,
  required => 1,
);

has worker_args => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
  default => sub { {} },
);

has workers => (
  is => 'rw',
  isa => 'Int',
  required => 1,
  default => sub { 5 },
);

has max_worker_age => (
  is => 'rw',
  isa => 'Int',
  predicate => 'has_max_worker_age',
  clearer => 'clear_max_worker_age',
);

has alias => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  default => sub{ Data::GUID->new->as_string }
);

has close_on_call => (
  is => 'rw',
  isa => 'Bool',
  required => 1,
  default => sub { 1 },
);

has worker_detaches => (
  is => 'rw',
  isa => 'Bool',
  required => 1,
  default => sub { 1 },
);

has worker_sets_process_group => (
  is => 'rw',
  isa => 'Bool',
  required => 1,
  default => sub { 0 },
);

has worker_priority => (
  is => 'rw',
  isa => 'Int',
  required => 1,
  default => sub { 0 },
);

has pid_to_wheel_map => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
  default => sub { {} }
);

has wid_to_wheel_map => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
  default => sub { {} }
);

has worker_stdout_log_level => (
  is => 'rw',
  isa => 'Str',
  required => 1,
  default => sub { 'info' },
);

has worker_stderr_log_level => (
  is => 'rw',
  isa => 'Str',
  required => 1,
  default => sub { 'info' },
);


sub BUILD {
  my ($self, $args) = @_;
  POE::Session->create(
    object_states => [
      $self, {
        _start   => '_start',
        _pause   => '_pause',
        _resume  => '_resume',
        shutdown => '_shutdown',
        spawn_workers => '_spawn_workers',
        retire_worker => '_retire_worker',
        worker_process_error => '_worker_process_error',
        worker_process_close => '_worker_process_close',
        worker_process_stdout => '_worker_process_stdout',
        worker_process_stderr => '_worker_process_stderr',
        worker_process_sig_chld => '_worker_process_sig_chld',
      } ],
    inline_states => {
      _keep_alive => sub {
        $_[KERNEL]->delay(_keep_alive => 1000);
      },
      sig_term => sub {
        my ($kernel) = $_[KERNEL];
        $kernel->yield('shutdown');
        $kernel->sig_handled;
      },
      sig_int => sub {
        my ($kernel) = $_[KERNEL];
        $kernel->yield('shutdown');
        $kernel->sig_handled;
      },
      sig_usr1 => sub {
        my ($kernel) = $_[KERNEL];
        $kernel->yield('_pause');
        $kernel->sig_handled;
      },
      sig_usr2 => sub {
        my ($kernel) = $_[KERNEL];
        $kernel->yield('_resume');
        $kernel->sig_handled;
      },
    }
  );
}

sub current_worker_count{
  my $self = shift;
  scalar keys %{ $self->pid_to_wheel_map };
}

sub worker_wheels {
  my $self = shift;
  return values %{ $self->pid_to_wheel_map }
}

sub signal_workers {
  my ($self, $signal) = @_;
  for my $worker ( $self->worker_wheels ){
    unless ( $worker->kill($signal) ){
      $self->logger->warning("Failed to signal process ".$worker->PID);
    }
  }
}

sub start {
  my $self = shift;
  if( $self->has_program_name ){
    my $name = join('-', $self->program_name, 'pm');
    $0 = $name;
  }
  $poe_kernel->run;
}

sub pause {
  my ($self) = @_;
  $poe_kernel->call($self->alias, '_pause');
}

sub resume {
  my ($self) = @_;
  $poe_kernel->call($self->alias, '_resume');
}

sub shutdown {
  my ($self) = @_;
  $poe_kernel->post($self->alias, 'shutdown');
}

#--------#---------#---------#---------#---------#---------#---------#--------#

sub _spawn_workers {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  return unless exists($heap->{spawn_workers}) && $heap->{spawn_workers};

  while ( $self->current_worker_count < $self->workers ) {
    my $class = $self->worker_class;
    my $child = POE::Wheel::Run->new(
      Program => sub {
        $poe_kernel->stop();

        my $instance = $class->new( @_ );
        if( $self->has_program_name ){
          my $name = $self->program_name;
          $0 = $name;
        }
        POE::Session->create(
          inline_states => {
            _start => sub {
              $poe_kernel->select_read(\*STDIN, 'stdin_ready');
              $poe_kernel->sig('TERM', 'stop_polling');
              $poe_kernel->sig('INT', 'stop_polling');
            },
            stop_polling => sub { $poe_kernel->select_read(\*STDIN); },
            stdin_ready => sub {
              my $buffer;
              my $status = sysread(\*STDIN, $buffer, 1);
              if( not defined($status) ){
                $instance->logger->error("Error reading STDIN: $!");
              } elsif($status == 0){
                $instance->logger->error("Manager process unexpectedly died. Shutting down worker.");
                $poe_kernel->select_read(\*STDIN);
                $poe_kernel->signal($poe_kernel, 'TERM');
              }
            },
          }
        );

        $instance->start;
      },
      Priority => $self->worker_priority,
      NoSetSid => !$self->worker_detaches,
      NoSetPgrp => !$self->worker_sets_process_group,
      ProgramArgs => [ $self->worker_args ],
      CloseOnCall => $self->close_on_call,
      StdoutEvent => 'worker_process_stdout',
      StderrEvent => 'worker_process_stderr',
      CloseEvent  => 'worker_process_close',
    );
    $kernel->sig_child($child->PID, 'worker_process_sig_chld');
    $self->wid_to_wheel_map->{ $child->ID } = $child;
    $self->pid_to_wheel_map->{ $child->PID } = $child;
    if( $self->has_max_worker_age ){
      $kernel->delay_set('retire_worker' => $self->max_worker_age, $child->ID);
    }
    $self->logger->debug("spawning wheel ".$child->ID." as pid: ".$child->PID);
  }
}

sub _retire_worker {
  my ($self, $wheel_id) = @_[OBJECT, ARG0];
  if( exists $self->wid_to_wheel_map->{$wheel_id} ){
    $self->logger->debug("retiring wheel ${wheel_id} due to old age");
    $self->wid_to_wheel_map->{$wheel_id}->kill('TERM');
  }
}

# Wheel event, including the wheel's ID.
sub _worker_process_close {
  my ($self,$wheel_id) = @_[OBJECT, ARG0];
  $self->logger->debug("close for wheel ".$wheel_id);
  if (defined(my $child = delete $self->wid_to_wheel_map->{$wheel_id})) {
    delete $self->pid_to_wheel_map->{$child->PID};
  }
  return;
}

sub _worker_process_sig_chld {
  my ($self, $kernel, $heap, $pid, $status_code) = @_[OBJECT, KERNEL, HEAP, ARG1, ARG2];
  $self->logger->debug("SIGCHLD for pid ${pid} with exit code: ${status_code}");
  if (defined(my $child = delete $self->pid_to_wheel_map->{$pid})) {
    delete $self->wid_to_wheel_map->{$child->ID};
  }
  if( exists($heap->{spawn_workers}) && $heap->{spawn_workers} ){
    $kernel->yield('spawn_workers');
  }
  return;
}

sub _worker_process_error {
  my ($self, $operation, $errnum, $errstr, $wid) = @_[OBJECT, ARG0, ARG1, ARG2, ARG3];
  $errstr = "remote end closed" if $operation eq "read" and !$errnum;
  $self->logger->error("wheel $wid generated $operation error $errnum: '$errstr'");
}

sub _worker_process_stderr {
  my($self, $line, $wid) = @_[OBJECT, ARG0, ARG1];
  my $pid = $self->wid_to_wheel_map->{$wid}->PID;
  my $message =  "worker $pid STDERR: '${line}'";
  $self->logger->log(level => $self->worker_stderr_log_level, message => $message);
}

sub _worker_process_stdout {
  my($self, $line, $wid) = @_[OBJECT, ARG0, ARG1];
  my $pid = $self->wid_to_wheel_map->{$wid}->PID;
  my $message =  "worker $pid STDOUT: '${line}'";
  $self->logger->log(level => $self->worker_stdout_log_level, message => $message);
}

#--------#---------#---------#---------#---------#---------#---------#--------#

sub _start {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $self->logger->info("starting worker manager");
  $kernel->alias_set($self->alias);
  $kernel->sig(INT => 'sig_int');
  $kernel->sig(TERM => 'sig_term');
  $kernel->sig(USR1 => 'sig_usr1');
  $kernel->sig(USR2 => 'sig_usr2');
  $heap->{spawn_workers} = 1;

  $kernel->delay(_keep_alive => 1000);
  $kernel->yield('spawn_workers');
}

sub _pause {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $self->logger->info("pausing worker manager");
  $heap->{spawn_workers} = 0;
  $self->signal_workers('USR1');
}

sub _resume {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $self->logger->info("resuming worker manager");
  $kernel->yield('spawn_workers');
  $heap->{spawn_workers} = 1;
  $self->signal_workers('USR2');
}

sub _shutdown {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $self->logger->info("shutting down worker manager");
  $self->workers(0);
  $self->signal_workers('TERM');
  $kernel->alarm_remove_all();
  #cleaup heap, alias, alarms (no lingering refs n ish)
  %$heap = ();
  $kernel->alias_remove($self->alias);
}

#--------#---------#---------#---------#---------#---------#---------#--------#

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Cantella::Worker::Manager::Prefork - Preforking POE worker-pool manager

=head1 SYNOPSIS

    my $manager = Cantella::Worker::Manager::Prefork->new(
      logger => $logger,
      workers => 5,
      worker_class => 'TestWorkerClass',
      max_worker_age => 3600,
      worker_args => {
        interval => 5,
        logger => $logger,
      }
    );

    $manager->start;

=head1 MANAGER-WORKER COMMUNICATION

=head2 Signals

Great care has been taken to provide with basic means of communication
between a manager and its workers. The manager process will pass-on C<INT>,
C<TERM>, C<USR1> and C<USR2> signals to it's workers, which means that you only
need to worry about interacting with one process.

=head2 IO Handles

To communicate with the manager, workers can write to C<STDOUT> and C<STDERR>,
which the manager will log at the levels of C<worker_stderr_log_level> and
C<worker_stdout_log_level>. Currently the worker process' C<STDIN> is reserved
for internal communications, but this may change in the future.

=head2 Process Management

At start and resume time, as well as when a C<CHLD> signal is received,
the manager process will check the number of workers and spawn new ones,
if appropriate. This way, even if a worker unexpectedly dies, it will be
promptly replaced. If workers have detached themselves from the manager
session, they will outlive their manager, so if they detect the manager has
unexpectedly exited, they will signal themselves with a C<TERM> signal and
shut down gracefully to avoid unsupervised processes.

=head1 ATTRIBUTES

=head2 logger

=over 4

=item B<logger> - reader

=back

Read-only L<Log::Dispatch> instance. Defaults to a device that logs
to Null. This attribute can coerce from a hash or array reference, see
L<MooseX::Types::Log::Dispatch> for details.

=head2 program_name

=over 4

=item B<program_name> - reader

=item B<has_program_name> - predicate

=back

Read-only non-blank string. If C<program_name> set, the manager process will
be renamed to "${program_name}-pm" and the children to "${program_name}".
Please see C<$0> in L<perlvar> for more information.

=head2 worker_class

=over 4

=item B<worker_class> - reader

=back

Required read-only class name of the worker class, which must consume the role
L<Cantella::Worker::Manager::Prefork>.

=head2 worker_args

=over 4

=item B<worker_args> - reader

=back

A read-only hash ref of arguments to be passed to instantiate the worker class.
Defaults to an empty hash ref.

=head2 workers

=over 4

=item B<workers> - accessor

=back

Read-write integer. The maximum number of subprocesses to have alive at any one
time. Defaults to 5.

=head2 max_worker_age

=over 4

=item B<max_worker_age> - accessor

=item B<has_max_worker_age> - predicate

=item B<clear_max_worker_age> - clearer

=back

Optional read-write integer. if this value is set, the manager will retire
workers when they reach a certain age and spawn a new worker. You may have seen
this behavior in mailscanner. It is useful for times when children may, in
rare cases, require large amounts of memory and you want to periodically
replace them to free it again.

=head2 alias

=over 4

=item B<alias> - accessor

=back

Read-only string. This is the alias of the session managing the workers and will
default to a UUID string by default.

=head2 close_on_call

=over 4

=item B<close_on_call> - accessor

=back

Read-write boolean value option for declaring whether file descriptors should
be closed in the forked process. Defaults to true.

=head2 worker_detaches

=over 4

=item B<worker_detches> - accessor

=back

Read-write boolean value option for declaring whether worker processes should
C<setsid()> to detach themselves from the manager's session. Defaults to true.

=head2 worker_sets_process_group

=over 4

=item B<worker_sets_process_group> - accessor

=back

Read-write boolean value option for declaring whether worker processes should
C<setpgrp()> to match the process group of the parent process. Defaults to true.

=head2 worker_priority

=over 4

=item B<worker_priority> - accessor

=back

Read-write integer. The priority or niceness that should be given to children
processes expressed as a I<delta> of the parent's. For example, to give a
worker process a lesser priority, use C<1>. To escalate the priority use a
negative number. UNIX operating systems require elevated privileges to do this.
Defaults to C<0>.

=head2 pid_to_wheel_map

=over 4

=item B<pid_to_wheel_map> - accessor

=back

A read-only HashRef used to map process IDs to L<POE::Wheel::Run> objects

=head2 wid_to_wheel_map

=over 4

=item B<wid_to_wheel_map> - accessor

=back

A read-only HashRef used to map Wheel IDs to L<POE::Wheel::Run> objects

=head2 worker_stderr_log_level

=over 4

=item B<worker_stderr_log_level> - reader

=back

Log level to use when logging stderr output that comes from the child processes.

=head2 worker_stdout_log_level

=over 4

=item B<worker_stdout_log_level> - reader

=back

Log level to use when logging stdout output that comes from the child processes.

=head1 METHODS

=head2 BUILD

=over 4

=item B<arguments:> C<\%args>

=item B<return value:> none

=back

Sets up the manager session and its event handlers.

=head2 current_worker_count

=over 4

=item B<arguments:> none

=item B<return value:> C<$number_of_live_children>

=back

Returns the number of children workers that are still alive.

=head2 worker_wheels

=over 4

=item B<arguments:> none

=item <return value:> C<@worker_poe_wheel_run_objects>

=back

Returns all of the wheel objects for currently living children workers

=head2 signal_workers

=over 4

=item B<arguments:> C<$signal>

=item <return value:>  none

=back

Sends a signal to all worker processes.

=head2 start

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

Start the manager and begin spawning workers.

=head2 pause

=over 4

=item B<arguments:> C<$until>

=item B<return value:> none

=back

Pause the manager and stop it from spawning any new workers.

=head2 resume

=over 4

=item B<arguments:> C<$when>

=item B<return value:> none

=back

Resume the manager and resume spawning workers.

=head2 shutdown

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

Stop the manager from spawning any new workers and end the session after all
workers have finished working.

=head1 EVENT HANDLERS

The following methods are L<POE> event handlers. They are not menat to be called
directly and will not work if you do. When applicable, arguments will be passed
into the methods in ARG0, ARG1, etc.

=head2 _spawn_workers

=over 4

=item B<handles event:> C<spawn_workers>

=item B<arguments:> none

=item B<return value:> none

=back

Spawn workers if C<current_worker_count> is less than C<workers>. This is also
the place where an alarm to retire a worker will be set if workers have a
maximum age.

The following events are set up to communicate with children processes:

=over 4

=item C<worker_process_stdout> - StdoutEvent

=item C<worker_process_stderr> - StderrEvent

=item C<worker_process_close> - CloseEvent

=item C<worker_process_sig_chld> - SIGCHLD

=back

=head2 _retire_worker

=over 4

=item B<handles event:> C<retire_worker>

=item B<arguments:> C<$wheel_id>

=item B<return value:> none

=back

If the worker process working under $wheel_id is still alive, send a sig TERM

=head2 _worker_process_close

=over 4

=item B<handles event:> C<worker_process_close>

=item B<arguments:> none

=item B<return value:> none

=back

See L<POE::Wheel::Run>

=head2 _worker_process_sig_chld

=over 4

=item B<handles event:> C<worker_process_sig_chld>

=item B<arguments:> C<$pid, $exit_status_code>

=item B<return value:> none

=back

Once a sig CHLD comes back from a worker, this event will schedule a
C<spawn_workers> event to make sure there's enough workers alive.

=head2 _worker_process_stdout

=over 4

=item B<handles event:> C<worker_process_stdout>

=item B<arguments:> C<$line>

=item B<return value:> none

=back

This event will be triggered for every line that the child process outputs
to STDOUT. By default, these will be logged to the log-level selcted with
C<worker_stdout_log_level>. See L<POE::Wheel::Run> for more.

=head2 _worker_process_stderr

=over 4

=item B<handles event:> C<worker_process_stderr>

=item B<arguments:> C<$line>

=item B<return value:> none

=back

This event will be triggered for every line that the child process outputs
to STDOUT. By default, these will be logged to the log-level selcted with
C<worker_stdout_log_level>. See L<POE::Wheel::Run> for more.

=head2 _start

=over 4

=item B<handles event:> C<_start>

=item B<arguments:> none

=item B<return value:> none

=back

Start the manager session.

=head2 _pause

=over 4

=item B<handles event:> C<_pause>

=item B<arguments:> none

=item B<return value:> none

=back

Signal workers to stop polling until notified and suspend the spawning of
new workers. The pause event can be triggered by sending signal C<USR1>

=head2 _resume

=over 4

=item B<handles event:> C<_resume>

=item B<arguments:> none

=item B<return value:> none

=back

Signal workers to resume polling and resume the spawning of new workers.
The resume event can be triggered sending signal C<USR2>

=head2 _shutdown

=over 4

=item B<handles event:> C<shutdown>

=item B<arguments:> none

=item B<return value:> none

=back

Remove all alarms, signal the workers to shutdown and wait for the session to die
The shutdown event can be triggered sending signal C<INT> or C<TERM>

=head1 OTHER EVENTS

=over 4

=item B<_keep_alive> - Used to keep the session alive while paused. Does nothing
other than schedule the next keep alive_1000 seconds away.

=item B<sig_int> - mark sig INT as handled and yield to C<shutdown>

=item B<sig_term> - mark sig TERM as handled and yield to C<shutdown>

=item B<sig_usr1> - mark sig USR1 as handled and yield to C<_pause>

=item B<sig_usr2> - mark sig USR2 as handled and yield to C<_resume>

=back

=head1 SEE ALSO

L<Cantella::Worker::Role::Worker>, L<Cantella::Worker::Role::Beanstalk>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009-2010 by Guillermo Roditi.
This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
