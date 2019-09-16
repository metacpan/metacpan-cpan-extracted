=head1 NAME

AnyEvent::ZabbixSender - simple and efficient zabbix data submission

=head1 SYNOPSIS

   use AnyEvent::ZabbixSender;

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

I't implements the zabbix version 2.0-3.4 protocol for item data
submission.

=head2 METHODS

=over 4

=cut

package AnyEvent::ZabbixSender;

use common::sense;

use Errno ();
use Scalar::Util ();

use AnyEvent ();
use AnyEvent::Socket ();
use AnyEvent::Handle ();

our $VERSION = '1.1';

=item $zbx = new AnyEvent::ZabbixSender [key => value...]

Creates a (virtual) connection to a zabbix server. Since each submission
requires a new TCP connection, creating the connection object does not
actually contact the server.

The connection object will linger in the destructor until all data has
been submitted or thrown away.

You can specify various configuration parameters. The term C<@items>
refers to an array with C<[key, value, clock]> array-refs.

=over 4

=item server => "$hostname:$port" (default: C<localhost:10051>)

The zabbix server to connect to.

=item host => $name (default: local nodename)

The submission host, the "technical" name from tghe zabbix configuration.

=item delay => $seconds (default: C<0>)

If non-zero, then the module will gather data submissions for up to this
number of seconds before actually submitting them as a single batch.

Submissions can get batched even if C<0>, as events submitted while the
connection is being established or retried will be batched together in any
case.

=item queue_time => $seconds (default: C<3600>)

The amount of time a data item will be queued until it is thrown away when
the server cannot be reached.

=item linger_time => $seconds (default: same as C<queue_time>)

The amount of time the module will linger in its destructor until all
items have been submitted.

=item retry_min => $seconds (default: C<30>)

=item retry_max => $seconds (default: C<300>)

The minimum and maximum retry times when the server cannot be reached.

=item on_error => $cb->($zbx, \@items, $msg) (default: log and continue)

Called on any protocol errors - these generally indicate that something
other than a zabbix server is running on a port. The given key-value pairs
are the lost items.

=item on_loss => $cb->($zbx, \@items) (default: log and continue)

Will be called when some data items are thrown away (this happens if the
server isn't reachable for at least C<queue_time> seconds),

=item on_response => $cb->($zbx, \@items, \%response) (default: not called)

Will be called with the (generally rather useless) response form the
zabbix server.

=back

=cut

our $NOP = sub { };

my $json = eval { require JSON::XS; JSON::XS->new } || do { require JSON::PP; JSON::PP->new };

$json->utf8;

sub new {
   my $class = shift;
   my $self  = bless {
      server      => "localhost:10051",
      delay       => 0,
      retry_min   => 30,
      retry_max   => 300,
      queue_time  => 3600,
      on_response => $NOP,
      on_error    => sub {
         AE::log 4 => "$_[0]{zhost}:$_[0]{zport}: $_[2]"; # error
      },
      on_loss     => sub {
         my $nitems = @{ $_[1] };
         AE::log 5 => "$_[0]{zhost}:$_[0]{zport}: $nitems items lost"; # warn
      },

      @_,

      on_clear    => $NOP,
   }, $class;

   ($self->{zhost}, $self->{zport}) = AnyEvent::Socket::parse_hostport $self->{server}, 10051;

   $self->{host} //= do {
      require POSIX;
      (POSIX::uname())[1]
   };

   $self->{linger_time} //= $self->{queue_time};

   $self
}

sub DESTROY {
   my ($self) = @_;

   $self->_wait;

   %$self = ();
}

sub _wait {
   my ($self) = @_;

   while (@{ $self->{queue} } || $self->{sending}) {
      my $cv = AE::cv;

      my $to = AE::timer $self->{linger_time}, 0, $cv;
      local $self->{on_clear} = $cv;

      $cv->recv;
   }
}

=item $zbx->submit ($k, $v[, $clock[, $host]])

Submits a new key-value pair to the zabbix server. If C<$clock> is missing
or C<undef>, then C<AE::now> is used for the event timestamp. If C<$host>
is missing, then the default set during object creation is used.

=item $zbx->submit_multiple ([ [$k, $v, $clock, $host]... ])

Like C<submit>, but submits many key-value pairs at once.

=cut

sub submit_multiple {
   my ($self, $kvcs) = @_;

   push @{ $self->{queue} }, [AE::now, $kvcs];

   $self->_send
      unless $self->{sending};
}

sub submit {
   my ($self, $k, $v, $clock, $host) = @_;

   push @{ $self->{queue} }, [AE::now, [[$k, $v, $clock, $host]]];

   $self->_send;
}

# start sending
sub _send {
   my ($self) = @_;

   if ($self->{delay}) {
      Scalar::Util::weaken $self;
      $self->{delay_w} ||= AE::timer $self->{delay}, 0, sub {
         delete $self->{delay_w};
         $self->{send_immediate} = 1;
         $self->_send2 unless $self->{sending}++;
      };
   } else {
      $self->{send_immediate} = 1;
      $self->_send2 unless $self->{sending}++;
   }
}

# actually do send
sub _send2 {
   my ($self) = @_;

   Scalar::Util::weaken $self;
   $self->{connect_w} = AnyEvent::Socket::tcp_connect $self->{zhost}, $self->{zport}, sub {
      my ($fh) = @_;

      $fh
         or return $self->_retry;
         
      delete $self->{retry};

      delete $self->{send_immediate};
      my $data = delete $self->{queue};
      my $items = [map @{ $_->[1] }, @$data];

      my $fail = sub {
         $self->{on_error}($self, $items, $_[0]);
         $self->_retry;
      };

      $self->{hdl} = new AnyEvent::Handle
         fh => $fh,
         on_error  => sub {
            $fail->($_[2]);
         },
         on_read   => sub {
            if (13 <= length $_[0]{rbuf}) {
               my ($zbxd, $version, $length) = unpack "a4 C Q<", $_[0]{rbuf};

               $zbxd eq "ZBXD"
                  or return $fail->("protocol mismatch");
               $version == 1
                  or return $fail->("protocol version mismatch");

               if (13 + $length <= length $_[0]{rbuf}) {
                  delete $self->{hdl};

                  my $res = eval { $json->decode (substr $_[0]{rbuf}, 13) }
                     or return $fail->("protocol error");

                  $self->{on_response}($self, $items, $res);

                  delete $self->{sending};

                  $self->_send2 if delete $self->{send_immediate} && $self->{queue};

                  $self->{on_clear}();
               }
            }
         },
      ;

      my $json = $json->encode ({
         request => "sender data",
         clock => int AE::now,
         data => [
            map {
               my $slot = $_;

               map {
                  key   => $_->[0],
                  value => $_->[1],
                  clock => int ($_->[2] // $slot->[0]),
                  host  => $_->[3] // $self->{host},
               }, @{ $slot->[1] }
            } @$data
         ],
      });

      $self->{hdl}->push_write (pack "a4 C Q</a", "ZBXD", 1, $json);
   };
}

sub _retry {
   my ($self) = @_;

   Scalar::Util::weaken $self;

   delete $self->{hdl};

   my $expire = AE::now - $self->{queue_time};
   while (@{ $self->{queue} } && $self->{queue}[0][0] < $expire) {
      $self->{on_loss}($self, [shift @{ $self->{queue} }]);
   }

   unless (@{ $self->{queue} }) {
      delete $self->{sending};
      $self->{on_clear}();
      return;
   }

   my $retry = $self->{retry_min} * 2 ** $self->{retry}++;
   $retry = $self->{retry_max} if $retry > $self->{retry_max};
   $self->{retry_w} = AE::timer $retry, 0, sub {
      delete $self->{retry_w};
      $self->_send2;
   };
}

=back

=head1 SEE ALSO

L<AnyEvent>.

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

=cut

1

