package AnyEvent::RetryTimer;
use common::sense;
use Scalar::Util qw/weaken/;
use AnyEvent;

our $VERSION = '0.1';

=head1 NAME

AnyEvent::RetryTimer - Retry timers for AnyEvent

=head1 VERSION

0.1

=head1 SYNOPSIS

   use AnyEvent::RetryTimer;

   my $con =
      Something::Connection->new;

   my $timer;

   $con->on_disconnect (sub {
      $timer ||=
         AnyEvent::RetryTimer->new (
            on_retry => sub {
               $con->connect;
            });

      $timer->retry;

      my $secs = $timer->current_interval;

      warn "Lost connection, reconnecting in $secs seconds!";
   });

   $con->on_connect (sub {
      warn "Connected successfully!";

      $timer->success;
      undef $timer;
   });

=head1 DESCRIPTION

This is a small helper utility to manage timed retries.

This is a pattern I often stumble across when managing network connections.
And I'm tired to reimplement it again and again. So I wrote this module.

At the moment it only implements a simple exponential back off retry mechanism
(with configurable multiplier) using L<AnyEvent> timers. If there are
other back off strategies you find useful you are free to send a
feature request or even better a patch!

=head1 METHODS

=over 4

=item my $timer = AnyEvent::RetryTimer->new (%args)

This is the constructor, it constructs the object.

At the end of the objects lifetime, when you get rid of the last reference to
C<$timer>, it will stop and running timeouts and not call any of the configured
callbacks again.

C<%args> can contain these keys:

=over 4

=item on_retry => $retry_cb->($timer)

C<$retry_cb> is the callback that will be called for (re)tries.

When this constructor is called and no C<no_first_try> is given,
an initial retry interval of the length 0 is started, which counts as the
first try.

Later it is also called after a retry interval has passed, which was initiated
by a call to the C<retry> method.

The first argument is the C<$timer> object itself.

=item no_first_try => $bool

This parameter defines whether the C<$retry_cb> will be called when the
L<AnyEvent::RetryTimer> object is created or not. If C<$bool> is true
C<$retry_cb> will not be called.

The default is false.

=item backoff => 'exponential'

This is the back off algorithm that is used. Currently
only C<exponential> is implemented and is the default.

=item max_retries => $max_retry_cnt

This is the maximum number of retries that are done
between the first call to C<retry> and the finishing
call to C<success>.

If the number of retries is exceeded by a call to C<retry>
the C<on_max_retries> callback is called (see below).

Please note that a call to C<success> will of course reset the internal count
of calls to C<retry>.

Default for this option is C<0> (disabled).

=item on_max_retries => $max_retry_cb->($timer)

After C<max_retries> the C<$max_retry_cb> callback will be
called with the C<$timer> as first argument.

It is usually called when a call to C<retry> would exceed
C<max_retries>.

=back

And then there are keys that are specific to the C<backoff>
method used:

=over 4

=item B<exponential>

=over 4

=item start_interval => $secs

This is the length of the first interval. Given in seconds.

Default is C<10>.

=item multiplier => $float

This is the multiplier for the retry intervals. Each time
a C<retry> is done the previous (if any) interval will be
multiplied with C<$float> and used for the next interval.

Default is C<1.5>.

=item max_interval => $max_interval_secs

As exponential back off intervals can increase quite a lot
you can give the maximum time to wait in C<$max_interval_secs>.

Default is C<3600 * 4>, which is 4 hours.

=back

=back

=cut

sub new {
   my $this  = shift;
   my $class = ref ($this) || $this;
   my $self  = {
      backoff        => 'exponential',
      multiplier     => 1.5,
      max_interval   => 3600 * 4, # 6 hours
      max_retries    => 0,        # infinite
      start_interval => 10,
      @_
   };
   bless $self, $class;

   my $rself = $self;

   weaken $self;

   $self->{timer} = AE::timer 0, 0, sub {
      delete $self->{timer};
      $self->{on_retry}->($self) if $self;
   };

   return $rself
}

=item $timer->retry

This method initiates or continues retries. If already a retry interval
is installed (eg. by the constructor or another previous unfinished call
to C<retry>), the call will be a nop.

That means you can call C<retry> directly after you created this object and
will not cause the initial try to be "retried".

If you are interested in the length of the current interval (after a
call to this method), you can call the C<current_interval> method.

=cut

sub retry {
   my ($self) = @_;

   weaken $self;

   return if $self->{timer};

   if ($self->{backoff} eq 'exponential') {
      my $r;

      # layout of $r = [$interval, $retry_cnt]
      if ($r = $self->{r}) {

         if ($self->{max_retries}
             && $self->{on_max_retries}
             && $r->[1] >= $self->{max_retries})
         {
            delete $self->{r};
            $self->{on_max_retries}->($self);
            return;
         }

         $r->[0] *= $self->{multiplier};
         $r->[0] =
            $r->[0] > $self->{max_interval}
               ? $self->{max_interval}
               : $r->[0];

      } else {
         $r = $self->{r} = [$self->{start_interval}];
      }

      $self->{timer} = AE::timer $r->[0], 0, sub {
         $r->[1]++;
         delete $self->{timer};
         $self->{on_retry}->($self)
            if $self && $self->{on_retry};
      };
   }
}

=item $timer->success

This signals that the last retry was successful and it will
reset any state or intervals to the initial settings given
to the constructor.

You can reuse the C<$timer> object after a call to C<success>.

=cut

sub success {
   my ($self) = @_;
   delete $self->{r}; # reset timer & wait counter
   delete $self->{timer};
}

=item my $secs = $timer->current_interval

Returns the length of the current interval to the
next call to the C<$retry_cb>.

=cut

sub current_interval {
   my ($self) = @_;

   # specialcase: first call
   return 0 if $self->{timer} && not $self->{r};

   if ($self->{backoff} eq 'exponential') {
      return unless $self->{r};
      return $self->{r}->[0];
   }

   undef
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex@ta-sa.org> >>

=head1 SEE ALSO

L<AnyEvent>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
