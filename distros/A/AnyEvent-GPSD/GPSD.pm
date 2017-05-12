=head1 NAME

AnyEvent::GPSD - event based interface to GPSD

=head1 SYNOPSIS

   use AnyEvent::GPSD;

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements an interface to GPSD (http://gpsd.berlios.de/).

You need to consult the GPSD protocol desription in the manpage to make
better sense of this module.

=head2 METHODS

=over 4

=cut

package AnyEvent::GPSD;

use strict;
no warnings;

use Carp ();
use Errno ();
use Scalar::Util ();
use Geo::Forward ();

use AnyEvent ();
use AnyEvent::Util ();
use AnyEvent::Socket ();
use AnyEvent::Handle ();

our $VERSION = '1.0';

=item $gps = new AnyEvent::GPSD [key => value...]

Creates a (virtual) connection to the GPSD. If the C<"hostname:port">
argument is missing then C<localhost:2947> will be used.

If the connection cannot be established, then it will retry every
second. Otherwise, the connection is put into watcher mode.

You can specify various configuration parameters, most of them callbacks:

=over 4

=item host => $hostname

The host to connect to, default is C<locahost>.

=item port => $port

The port to connect to, default is C<2947>.

=item min_speed => $speed_in_m_per_s

Sets the mininum speed (default: 0) that is considered real for the
purposes of replay compression or estimate. Speeds below this value will
be considered 0.

=item on_error => $cb->($gps)

Called on every connection or protocol failure, reason is in C<$!>
(protocl errors are signalled via EBADMSG). Can be used to bail out if you
are not interested in retries.

=item on_connect => $cb->($gps)

Nornormally used: Called on every successful connection establish.

=item on_response => $cb->($gps, $type, $data, $time)

Not normally used: Called on every response received from GPSD. C<$type>
is the single letter type and C<$data> is the data portion, if
any. C<$time> is the timestamp that this message was received at.

=item on_satellite_info => $cb->($gps, {satellite-info}...)

Called each time the satellite info changes, also on first connect. Each
C<satellite-info> hash contains at least the following members (mnemonic:
all keys have three letters):

C<prn> holds the satellite PRN (1..32 GPS, anything higher is
wASS/EGNOS/MCAS etc, see L<GPS::PRN>).

C<ele>, C<azi> contain the elevation (0..90) and azimuth (0..359) of the satellite.

C<snr> contains the signal strength in decibals (28+ is usually the
minimum value for a good fix).

C<fix> contains either C<1> to indicate that this satellite was used for
the last position fix, C<0> otherwise. EGNOS/WAAS etc. satellites will
always show as C<0>, even if their correction info was used.

The passed hash references are read-only.

=item on_fix => $cb->({point})

Called regularly (usually about once/second), even when there is no
connection to the GPSD (so is useful to update your idea of the current
position). The passed hash reference must I<not> be modified in any way.

If C<mode> is C<2> or C<3>, then the C<{point}> hash contains at least the
following members, otherwise it is undefined which members exist. Members
whose values are not known are C<undef> (usually the error values, speed
and so on).

   time         when this fix was received (s)

   lat          latitude (S -90..90 N)
   lon          longitude (W -180..180 E)
   alt          altitude

   herr         estimated horizontal error (m)
   verr         estimated vertical error (m)

   bearing	bearing over ground (0..360)
   berr		estimated error in bearing (degrees)
   speed	speed over ground (m/s)
   serr         estimated error in speed over ground (m/s)
   vspeed       vertical velocity, positive = upwards (m/s)
   vserr        estimated error in vspeed (m/s)

   mode         1 = no fix, 2 = 2d fix, 3 = 3d fix

=back

=cut

sub new {
   my $class = shift;
   my $self  = bless {
      @_,
      interval => 1,
      fix      => { time => AnyEvent->now, mode => 1 },
   }, $class;

   $self->interval_timer;
   $self->connect;

   $self
}

sub DESTROY {
   my ($self) = @_;

   $self->record_log;
}

sub event {
   my $event = splice @_, 1, 1, ();

   #warn "event<$event,@_>\n";#d#
   if ($event = $_[0]{"on_$event"}) {
      &$event;
   }
}

sub retry {
   my ($self) = @_;

   delete $self->{fh};
   delete $self->{command};

   Scalar::Util::weaken $self;
   $self->{retry_w} = AnyEvent->timer (after => 1, cb => sub {
      delete $self->{retry_w};
      $self->connect;
   });
}

# make sure we send "no fix" updates when we lose connectivity
sub interval_timer {
   my ($self) = @_;

   $self->{interval_w} = AnyEvent->timer (after => $self->{interval}, cb => sub {
      if (AnyEvent->now - $self->{fix}{time} > $self->{interval} * 1.9) {
         $self->{fix}{mode} = 1;
         $self->event (fix => $self->{fix});
      }

      $self->interval_timer;
   });

   Scalar::Util::weaken $self;
}

sub connect {
   my ($self) = @_;

   return if $self->{fh};

   AnyEvent::Socket::tcp_connect $self->{host} || "localhost", $self->{port} || 2947, sub {
      my ($fh) = @_;

      return unless $self;

      if ($fh) {
         # unbelievable, but true: gpsd does not support command pipelining.
         # it's an immensely shitty piece of software, actually, as it blocks
         # randomly and for extended periods of time, has a surprisingly broken
         # and non-configurable baud autoconfiguration system (it does stuff
         # like switching to read-only mode when my bluetooth gps mouse temporarily
         # loses the connection etc.) and uses rather idiotic and wasteful
         # programming methods.

         $self->{fh} = new AnyEvent::Handle
            fh        => $fh,
            low_delay => 1,
            on_error  => sub {
               $self->event ("error");
               $self->retry;
            },
            on_eof    => sub {
               $! = &Errno::EPIPE;
               $self->event ("error");
               $self->log ("disconnect");
               $self->retry;
            },
            on_read   => sub {
               $_[0]{rbuf} =~ s/^([^\015\012]*)\015\012//
                  or return;

               $self->feed ($1)
                  unless $self->{replay_cb};
            },
         ;

         $self->send ("w");
         $self->send ("o");
         $self->send ("y");
         $self->send ("c");

         $self->event ("connect");
         $self->log ("connect");
      } else {
         $self->event ("error");
      }
   };

   Scalar::Util::weaken $self;
}

sub drain_wbuf {
   my ($self) = @_;

   $self->{fh}->push_write (join "", @{ $self->{command}[0] });
}

sub send {
   my ($self, $command, $args) = @_;

   # curse them, we simply expect that each comamnd will result in a response using
   # the same letter

   push @{ $self->{command} }, [uc $command, $args];
   $self->drain_wbuf if @{ $self->{command} } == 1;
}

sub feed {
   my ($self, $line) = @_;

   $self->{now} = AnyEvent->now;

   $self->log (raw => $line)
      if $self->{logfh};

   unless ($line =~ /^GPSD,(.)=(.*)$/) {
      $! = &Errno::EBADMSG;
      $self->event ("error");
      return $self->retry;
   }

   my ($type, $data) = ($1, $2);

   #warn "$type=$data\n";#d#

   $self->{state}{$type} = [$data => $self->{now}];

   if ($type eq "O") {
      my @data = split /\s+/, $data;

      my $fix = $self->{fix};

      $fix->{time} = $self->{now};

      if (@data > 3) {
         # the gpsd time is virtually useless as it is truncated :/
         for (qw(tag _time _terr lat lon alt herr verr bearing speed vspeed berr serr vserr mode)) {
            $type = shift @data;
            $fix->{$_} = $type eq "?" ? undef : $type;
         }

         if (my $s = $self->{stretch}) {
            $s = 1 / $s;

            $fix->{herr}   *= $s; # ?
            $fix->{verr}   *= $s; # ?
            $fix->{berr}   *= $s; # ?
            $fix->{serr}   *= $s; # ?
            $fix->{vserr}  *= $s; # ?

            $fix->{speed}  *= $s;
            $fix->{vspeed} *= $s;
         }

         $fix->{mode} = 2 if $fix->{mode} eq "?"; # arbitrary choice
      } else {
         $fix->{mode} = 1;
      }

      $self->event (fix => $fix);

   } elsif ($type eq "Y") {
      my (undef, @sats) = split /:/, $data;
      
      $self->{satellite_info} = [map {
         my @sat = split /\s+/;
         {
            prn => $sat[0],
            ele => $sat[1],
            azi => $sat[2],
            snr => $sat[3],
            fix => $sat[4],
         }
      } @sats];

      $self->event (satellite_update => $self->{satellite_info});
      
   } elsif ($type eq "C") {
      $self->{interval} = $data >= 1 ? $data * 1 : 1;
   }

   # we (wrongly) assume that gpsd responses are always in response
   # to an earlier command

   if (@{ $self->{command} } && $self->{command}[0][0] eq $type) {
      shift @{ $self->{command} };
      $self->drain_wbuf if @{ $self->{command} };
   }
}

=item ($lat, $lon) = $gps->estimate ([$max_seconds])

This returns an estimate of the current position based on the last fix and
the time passed since then.

Useful for interactive applications where you want more frequent updates,
but not very useful to store, as the next fix might well be totally
off. For example, when displaying a real-time map, you could simply call
C<estimate> ten times a second and update the cursor or map position, but
you should use C<on_fix> to actually gather data to plot the course itself.

If the fix is older then C<$max_seconds> (default: C<1.9> times the update
interval, i.e. usually C<1.9> seconds) or if no fix is available, returns
the empty list.

=cut

sub estimate {
   my ($self, $max) = @_;

   $max ||= 1.9 * $self->{interval} unless defined $max;

   my $geo = $self->{geo_forward} ||= new Geo::Forward;

   my $fix = $self->{fix} or return;
   $fix->{mode} >= 2 or return;

   my $diff = AnyEvent->time - $fix->{time};

   $diff <= $max or return;

   if ($fix->{speed} >= $self->{min_speed}) {
      my ($lat, $lon) = $geo->forward ($fix->{lat}, $fix->{lon}, $fix->{bearing}, $fix->{speed} * $diff);
      ($lat, $lon)

   } else {
      # if we likely have zero speed, return the point itself
      ($fix->{lat}, $fix->{lon})
   }
}

sub log {
   my ($self, @arg) = @_;

   syswrite $self->{logfh}, JSON::encode_json ([AnyEvent->time, @arg]) . "\n"
      if $self->{logfh};
}

=item $gps->record_log ($path)

If C<$path> is defined, then that file will be created or truncated and a
log of all (raw) packets received will be written to it. This log file can
later be replayed by calling C<< $gps->replay_log ($path) >>.

If C<$path> is undefined then the log will be closed.

=cut

sub record_log {
   my ($self, $path) = @_;

   if (defined $path) {
      $self->record_log;

      require JSON;

      open $self->{logfh}, ">:perlio", $path
         or Carp::croak "$path: $!";

      $self->log (start => $VERSION, 0, 0, { interval => $self->{interval} });
   } elsif ($self->{logfh}) {
      $self->log ("stop");
      delete $self->{logfh};
   }
}

=item $gps->replay_log ($path, %options)

Replays a log file written using C<record_log> (or stops replaying when
C<$path> is undefined). While the log file replays, real GPS events will
be ignored. This comes in handy when testing.

Please note that replaying a log will change configuration options that
will not be restored, so it's best not to reuse a gpsd object after a
replay.

The C<AnyEvent::GPSD> distribution comes with an example log
(F<eg/example.aegps>) that you can replay for testing or enjoyment
purposes.

The options include:

=over 4

=item compress => 1

If set to a true value (default: false), then passages without fix will be
replayed much faster than passages with fix. The same happens for passages
without much movement.

=item stretch => $factor

Multiplies all times by the given factor. Values < 1 make the log replay
faster, values > 1 slower. Note that the frequency of fixes will not be
increased, o stretch factors > 1 do not work well.

A stretch factor of zero is not allowed, but if you want to replay a log
instantly you may speicfy a very low value (e.g. 1e-10).

=back

=cut

sub replay_log {
   my ($self, $path, %option) = @_;

   if (defined $path) {
      $self->replay_log;

      require JSON;

      open my $fh, "<:perlio", $path
         or Carp::croak "$path: $!";

      $self->{stretch}  = $option{stretch} || 1;
      $self->{compress} = $option{compress};

      $self->{imterval} /= $self->{stretch};

      Scalar::Util::weaken $self;

      $self->{replay_cb} = sub {
         my $line = <$fh>;

         if (2 > length $line) {
            $self->replay_log;
         } else {
            my ($time, $type, @data) = @{ JSON::decode_json ($line) };

            $time *= $self->{stretch};

            if ($type eq "start") {
               my ($module_version, $major_version, $minor_version, $args) = @data;

               $self->{interval} = ($args->{interval} || 1) / $self->{stretch};
            }

            if (
               $type eq "start"
               or ($self->{compress}
                   and $self->{fix} && ($self->{fix}{mode} < 2 || $self->{fix}{speed} < $self->{min_speed}))
            ) {
               $self->{replay_now} = $time;
            }

            $self->{replay_timer} = AnyEvent->timer (after => $time - $self->{replay_now}, cb => sub {
               $self->{replay_now} = $time;
               $self->{command} = []; # no can do
               $self->feed ($data[0]) if $type eq "raw";
               $self->{replay_cb}();
            });
         }
      };

      $self->{replay_cb}();

   } else {
      delete $self->{stretch};
      delete $self->{compress};
      delete $self->{replay_timer};
      delete $self->{replay_cb};
   }
}

=back

=head1 SEE ALSO

L<AnyEvent>.

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

=cut

1

