package Cantella::Worker::Role::Worker;

use Moose::Role;
use POE;
use MooseX::Types::Log::Dispatch qw(Logger);
use Data::GUID;

our $VERSION = '0.001001';
$VERSION = eval $VERSION;

requires qw/get_work work/;

has logger => (
  is => 'ro',
  isa => Logger,
  coerce => 1,
  required => 1,
  default => sub {
    Log::Dispatch->new(outputs => [ ['Screen', min_level => 'debug' ] ]);
  }
);

has alias => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  default => sub{ Data::GUID->new->as_string }
);

has interval => (
  is => 'rw',
  isa => 'Num',
  required => 1,
  default => sub { 2 },
);

sub BUILD {}

after BUILD => sub {
  my ($self, $args) = @_;
  POE::Session->create(
    object_states => [
      $self, {
        poll => '_poll',
        work => '_work',
        _start   => '_start',
        _pause   => '_pause',
        _resume  => '_resume',
        shutdown => '_shutdown',
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
};

sub start {
  $poe_kernel->run;
}

sub pause {
  my ($self, $until) = @_;
  $poe_kernel->call($self->alias, '_pause');
}

sub resume {
  my ($self, $when) = @_;
  $poe_kernel->call($self->alias, '_resume');
}

sub shutdown {
  my ($self) = @_;
  #$self->pause;
  $poe_kernel->post($self->alias, 'shutdown');
}

#--------#---------#---------#---------#---------#---------#---------#--------#

sub _poll {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  return unless exists($heap->{poll}) && $heap->{poll};

  if ( defined(my $work = $self->get_work()) ) {
    $kernel->yield(work => $work);
    $kernel->yield('poll');
    return;
  }

  $kernel->delay(poll => $self->interval);
}

sub _work {
  my ($self, $kernel, $work) = @_[OBJECT, KERNEL, ARG0];
  $self->work($work);
}

#--------#---------#---------#---------#---------#---------#---------#--------#

sub _start {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $kernel->sig(INT => 'sig_int');
  $kernel->sig(TERM => 'sig_term');
  $kernel->sig(USR1 => 'sig_usr1');
  $kernel->sig(USR2 => 'sig_usr2');

  # set up polling
  # set alias for ourselves and remember it
  $heap->{poll} = 1;
  $kernel->alias_set($self->alias);
  $kernel->yield('poll');
}

sub _pause {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $self->logger->info("pausing worker ${$}");
  $heap->{poll} = 0;
  $kernel->delay('poll'); #clear any alarm, if it exists
  $kernel->delay(_keep_alive => 1000); #keep the session alive
}

sub _resume {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $self->logger->info("resuming worker ${$}");
  $heap->{poll} = 1;
  $kernel->delay('poll'); #clear any alarm, if it exists
  $kernel->yield('poll');
}

sub _shutdown {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $self->logger->info("shutting down worker with pid ${$}");

  $kernel->alarm_remove_all();
  #cleaup heap, alias, alarms (no lingering refs n ish)
  %$heap = ();
  $kernel->alias_remove($self->alias);
}

#--------#---------#---------#---------#---------#---------#---------#--------#

1;

__END__;

=head1 NAME

Cantella::Worker::Role::Worker - Polling POE worker

=head1 SYNOPSIS

    package TestWorkerPool;

    use Moose;
    with 'Cantella::Worker::Role::Worker';

    my @work_stack = ( 1 .. 10);
    sub get_work {
      my $self = shift;
      if( @work_stack ){
        return shift @work_stack;
      } else {
        $self->shutdown;
        return;
      }
    }

    sub work {
      my ($self, $args) = @_;
      sleep(1);
    }

=head1 REQUIRED METHODS

=head2 get_work

=over 4

=item B<arguments:> none

=item B<return value:> C<$work_data>

=back

Should return C<undef> if there's no work avaliable and a single defined scalar
representing the inputs to the work if there is.

=head2 work

=over 4

=item B<arguments:> C<$work_data>

=item B<return value:> none

=back

Do whatever!

=head1 ATTRIBUTES

=head2 logger

=over 4

=item B<logger> - reader

=back

Read-only L<Log::Dispatch> instance. Defaults to a device that logs
to Null. This attribute can coerce from a hash or array reference, see
L<MooseX::Types::Log::Dispatch> for details.

=head2 interval

=over 4

=item B<interval> - accessor

=back

Read-write integer. The number of seconds to wait between C<poll> events. Will
default to C<2> seconds.

=head2 alias

=over 4

=item B<alias> - accessor

=back

Read-only string. This is the alias of the session managing the workers and will
default to a UUID string by default.

=head1 METHODS

=head2 BUILD

=over 4

=item B<arguments:> C<\%args>

=item B<return value:> none

=back

C<after BUILD> Sets up the polling session and its event handlers.

=head2 start

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

Begin the event loop

=head2 pause

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

Stop polling for work.

=head2 resume

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

Resume polling for work.

=head2 shutdown

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

Stop polling for work and end the session after current jobs are done.

=head1 EVENT HANDLERS

The following methods are L<POE> event handlers. They are not meant to be called
directly and will not work if you do. When applicable, arguments will be passed
into the methods in ARG0, ARG1, etc.

=head2 _poll

=over 4

=item B<handles event:> C<poll>

=item B<arguments:> none

=item B<return value:> none

=back

Poll for work. If we find work, schedule another poll event due to execute
after the work event. If no jobs are found, schedule the next poll for
C<interval> seconds in the future. This ensures that the worker will always be
busy while there is work, but will control it's polling for work when there
isn't any available.

=head2 _work

=over 4

=item B<handles event:> C<work>

=item B<arguments:> C<$work_info>

=item B<return value:> none

=back

Do this one job.

=head2 _start

=over 4

=item B<handles event:> C<_start>

=item B<arguments:> none

=item B<return value:> none

=back

Start the polling process

=head2 _pause

=over 4

=item B<handles event:> C<_pause>

=item B<arguments:> C<$until>

=item B<return value:> none

=back

Pause the polling process until C<$until>

=head2 _resume

=over 4

=item B<handles event:> C<_resume>

=item B<arguments:> none

=item B<return value:> none

=back

Resume the polling process

=head2 _shutdown

=over 4

=item B<handles event:> C<shutdown>

=item B<arguments:> none

=item B<return value:> none

=back

Remove all alarms and wait for the session to die

=head1 OTHER EVENTS

=over 4

=item B<_keep_alive> - Used to keep the session alive while paused. Does nothing
other than schedule the next keep alive 1000 seconds away.

=item B<sig_int> - mark sig INT as handled and yield to C<shutdown>

=item B<sig_term> - mark sig TERM as handled and yield to C<shutdown>

=item B<sig_usr1> - mark sig USR1 as handled and yield to C<_pause>

=item B<sig_usr2> - mark sig USR2 as handled and yield to C<_resume>

=back

=head1 SEE ALSO

L<Cantella::Worker::Manager::Prefork>, L<Cantella::Worker::Role::Beanstalk>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009-2010 by Guillermo Roditi.
This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
