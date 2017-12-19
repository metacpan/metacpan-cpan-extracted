package AnyEvent::Stomper::Cluster;

use 5.008000;
use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.36';

use AnyEvent::Stomper;
use AnyEvent::Stomper::Error;

use Scalar::Util qw( weaken );
use Carp qw( croak );

our %ERROR_CODES;

BEGIN {
  %ERROR_CODES = %AnyEvent::Stomper::Error::ERROR_CODES;
  our @EXPORT_OK   = keys %ERROR_CODES;
  our %EXPORT_TAGS = ( err_codes => \@EXPORT_OK );
}

use constant \%ERROR_CODES;

my %ACK_CMDS = (
  ACK  => 1,
  NACK => 1,
);

my %CAN_REPEAT = (
  SEND      => 1,
  SUBSCRIBE => 1,
  BEGIN     => 1,
);


sub new {
  my $class  = shift;
  my %params = @_;

  my $self = bless {}, $class;

  unless ( defined $params{nodes} ) {
    croak 'Nodes not specified';
  }
  unless ( ref( $params{nodes} ) eq 'ARRAY' ) {
    croak 'Nodes must be specified as array reference';
  }
  unless ( @{ $params{nodes} } ) {
    croak 'Specified empty list of nodes';
  }

  $self->{nodes}              = $params{nodes};
  $self->{on_node_connect}    = $params{on_node_connect};
  $self->{on_node_disconnect} = $params{on_node_disconnect};
  $self->{on_node_error}      = $params{on_node_error};
  $self->on_error( $params{on_error} );

  my %node_params;
  foreach my $name ( qw( login passcode vhost heartbeat connection_timeout
      reconnect_interval handle_params default_headers command_headers ) )
  {
    next unless defined $params{$name};
    $node_params{$name} = $params{$name};
  }
  $self->{_node_params} = \%node_params;

  $self->_reset_internals;
  $self->_init;

  return $self;
}

sub execute {
  my $self     = shift;
  my $cmd_name = shift;

  my $cmd = $self->_prepare( $cmd_name, [@_] );
  $self->_execute($cmd);

  return;
}

# Generate methods
{
  no strict qw( refs );

  foreach my $name ( qw( send subscribe unsubscribe ack nack begin commit
      abort disconnect ) )
  {
    *{$name} = sub {
      my $self = shift;

      my $cmd = $self->_prepare( $name, [@_] );
      $self->_execute($cmd);

      return;
    }
  }
}

sub nodes {
  my $self = shift;
  return values %{ $self->{_nodes_pool} };
}

sub on_error {
  my $self = shift;

  if (@_) {
    my $on_error = shift;

    if ( defined $on_error ) {
      $self->{on_error} = $on_error;
    }
    else {
      $self->{on_error} = sub {
        my $err = shift;
        warn $err->message . "\n";
      };
    }
  }

  return $self->{on_error};
}

sub force_disconnect {
  my $self = shift;

  foreach my $node ( $self->nodes ) {
    $node->force_disconnect;
  }
  $self->_reset_internals;

  return;
}

sub _init {
  my $self = shift;

  my $nodes_pool = $self->{_nodes_pool};

  foreach my $node_params ( @{ $self->{nodes} } ) {
    my $hostport = "$node_params->{host}:$node_params->{port}";

    unless ( defined $nodes_pool->{$hostport} ) {
      $nodes_pool->{$hostport}
          = $self->_new_node( $node_params->{host}, $node_params->{port} );
    }
  }

  $self->{_nodes}       = [ keys %{ $self->{_nodes_pool} } ];
  $self->{_active_node} = $self->_next_node;

  return;
}

sub _new_node {
  my $self = shift;
  my $host = shift;
  my $port = shift;

  return AnyEvent::Stomper->new(
    %{ $self->{_node_params} },
    host          => $host,
    port          => $port,
    lazy          => 1,
    on_connect    => $self->_create_on_node_connect( $host, $port ),
    on_disconnect => $self->_create_on_node_disconnect( $host, $port ),
    on_error      => $self->_create_on_node_error( $host, $port ),
  );
}

sub _create_on_node_connect {
  my $self = shift;
  my $host = shift;
  my $port = shift;

  weaken($self);

  return sub {
    if ( defined $self->{on_node_connect} ) {
      $self->{on_node_connect}->( $host, $port );
    }
  };
}

sub _create_on_node_disconnect {
  my $self = shift;
  my $host = shift;
  my $port = shift;

  weaken($self);

  return sub {
    if ( defined $self->{on_node_disconnect} ) {
      $self->{on_node_disconnect}->( $host, $port );
    }
  };
}

sub _create_on_node_error {
  my $self = shift;
  my $host = shift;
  my $port = shift;

  weaken($self);

  return sub {
    my $err = shift;

    my $err_code = $err->code;

    if ( $err_code != E_OPRN_ERROR
      && $err_code != E_CONN_CLOSED_BY_CLIENT )
    {
      $self->{_active_node} = $self->_next_node;
    }

    if ( defined $self->{on_node_error} ) {
      $self->{on_node_error}->( $err, $host, $port );
    }
  };
}

sub _prepare {
  my $self     = shift;
  my $cmd_name = uc(shift);
  my $args     = shift;

  my %params;

  if ( ref( $args->[-1] ) eq 'CODE'
    && scalar @{$args} % 2 > 0 )
  {
    if ( $cmd_name eq 'SUBSCRIBE' ) {
      $params{on_message} = pop @{$args};
    }
    else {
      $params{on_receipt} = pop @{$args};
    }
  }

  my %headers = @{$args};

  foreach my $name ( qw( body on_receipt on_message on_node_error ) ) {
    if ( defined $headers{$name} ) {
      $params{$name} = delete $headers{$name};
    }
  }
  if ( exists $ACK_CMDS{$cmd_name} ) {
    $params{message} = delete $headers{message};
  }

  my $cmd = {
    name    => $cmd_name,
    headers => \%headers,
    %params,
  };

  unless ( defined $cmd->{on_receipt} ) {
    weaken($self);

    $cmd->{on_receipt} = sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        $self->{on_error}->($err);
        return;
      }
    };
  }

  return $cmd;
}

sub _execute {
  my $self      = shift;
  my $cmd       = shift;
  my $fails_cnt = shift || 0;

  my $hostport = $self->{_active_node};
  my $node     = $self->{_nodes_pool}{$hostport};

  weaken($self);

  $node->execute( $cmd->{name}, %{ $cmd->{headers} },
    body => $cmd->{body},

    on_receipt => sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        my $err_code = $err->code;

        my $on_node_error = $cmd->{on_node_error} || $self->{on_node_error};
        if ( defined $on_node_error ) {
          my $node = $self->{_nodes_pool}{$hostport};
          $on_node_error->( $err, $node->host, $node->port );
        }

        if ( $CAN_REPEAT{ $cmd->{name} }
          && $err_code != E_OPRN_ERROR
          && $err_code != E_CONN_CLOSED_BY_CLIENT
          && ++$fails_cnt < scalar @{ $self->{_nodes} } )
        {
          $self->_execute( $cmd, $fails_cnt );
          return;
        }

        $cmd->{on_receipt}->( $receipt, $err );

        return;
      }

      $cmd->{on_receipt}->($receipt);
    },

    defined $cmd->{message}
    ? ( message => $cmd->{message} )
    : (),

    defined $cmd->{on_message}
    ? ( on_message => $cmd->{on_message} )
    : (),
  );

  return;
}

sub _next_node {
  my $self = shift;

  unless ( defined $self->{_node_index} ) {
    $self->{_node_index} = int( rand( scalar @{ $self->{_nodes} } ) );
  }
  elsif ( $self->{_node_index} == scalar @{ $self->{_nodes} } ) {
    $self->{_node_index} = 0;
  }

  return $self->{_nodes}[ $self->{_node_index}++ ];
}

sub _reset_internals {
  my $self = shift;

  $self->{_nodes_pool}  = {};
  $self->{_nodes}       = undef;
  $self->{_node_index}  = undef;
  $self->{_active_node} = undef;

  return;
}

1;
__END__

=head1 NAME

AnyEvent::Stomper::Cluster - The client for the cluster of STOMP servers

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Stomper::Cluster;

  my $cluster = AnyEvent::Stomper::Cluster->new(
    nodes => [
      { host => 'stomp-server-1.com', port => 61613 },
      { host => 'stomp-server-2.com', port => 61613 },
      { host => 'stomp-server-3.com', port => 61613 },
    ],
    login    => 'guest',
    passcode => 'guest',
  );

  my $cv = AE::cv;

  $cluster->subscribe(
    id          => 'foo',
    destination => '/queue/foo',

    on_receipt => sub {
      my $err = $_[1];

      if ( defined $err ) {
        warn $err->message . "\n";
        $cv->send;

        return;
      }

      $cluster->send(
        destination => '/queue/foo',
        body        => 'Hello, world!',
      );
    },

    on_message => sub {
      my $msg = shift;

      my $body = $msg->body;
      print "Consumed: $body\n";

      $cv->send;
    },
  );

  $cv->recv;

=head1 DESCRIPTION

AnyEvent::Stomper::Cluster is the client for the cluster of STOMP servers.

=head1 CONSTRUCTOR

=head2 new( %params )

  my $cluster = AnyEvent::Stomper::Cluster->new(
    nodes => [
      { host => 'stomp-server-1.com', port => 61613 },
      { host => 'stomp-server-2.com', port => 61613 },
      { host => 'stomp-server-3.com', port => 61613 },
    ],
    login              => 'guest',
    passcode           => 'guest',
    vhost              => '/',
    heartbeat          => [ 5000, 5000 ],
    connection_timeout => 5,
    reconnect_interval => 5,

    on_node_connect => sub {
      my $host = shift;
      my $port = shift;

      # handling...
    },

    on_node_disconnect => sub {
      my $host = shift;
      my $port = shift;

      # handling...
    },

    on_node_error => sub {
      my $err = shift;
      my $host = shift;
      my $port = shift;

      # error handling...
    },

    on_error => sub {
      my $err = shift;

      # error handling...
    },
  );

=over

=item nodes => \@nodes

Specifies the list of nodes. Parameter should contain array of hashes. Each
hash should contain C<host> and C<port> elements. At the start the client gets
random node from this list, connects to it and sends all frames to this node.
If current active node fails, the client gets next node from the list.

=item login => $login

The user identifier used to authenticate against a secured STOMP server. Must
be the same for all nodes.

=item passcode => $passcode

The password used to authenticate against a secured STOMP server. Must be the
same for all nodes.

=item vhost => $vhost

The name of a virtual host that the client wishes to connect to. Must be the
same for all nodes.

=item heartbeat => \@heartbeat

Heart-beating can optionally be used to test the healthiness of the underlying
TCP connection and to make sure that the remote end is alive and kicking. The
first number sets interval in milliseconds between outgoing heart-beats to the
node. C<0> means, that the client will not send heart-beats. The second number
sets interval in milliseconds between incoming heart-beats from the node. C<0>
means, that the client does not want to receive heart-beats.

  heartbeat => [ 5000, 5000 ],

Not set by default.

=item connection_timeout => $connection_timeout

Specifies connection timeout. If the client could not connect to the node
after specified timeout, the C<on_node_error> callback is called with the
C<E_CANT_CONN> error. The timeout specifies in seconds and can contain a
fractional part.

  connection_timeout => 10.5,

By default the client use kernel's connection timeout.

=item reconnect_interval => $reconnect_interval

If the connection to the node was lost, the client will try to restore the
connection when you execute next command. By default reconnection is performed
immediately, on next command execution. If the C<reconnect_interval> parameter
is specified, the client will try to reconnect only after this interval and
commands executed between reconnections will be queued. The client will try to
reconnect to every available node before raise the error.

  reconnect_interval => 5,

Not set by default.

=item handle_params => \%params

Specifies L<AnyEvent::Handle> parameters.

  handle_params => {
    autocork => 1,
    linger   => 60,
  }

Enabling of the C<autocork> parameter can improve performance. See
documentation on L<AnyEvent::Handle> for more information.

=item default_headers => \%headers

Specifies default headers for all outgoing frames.

  default_headers => {
    'x-foo' => 'foo_value',
    'x-bar' => 'bar_value',
  }

=item command_headers

Specifies default headers for particular commands.

  command_headers => {
    SEND => {
      receipt => 'auto',
    },

    SUBSCRIBE => {
      durable => 'true',
      ack     => 'client',
    },
  }

=item on_node_connect => $cb->( $host, $port )

The C<on_node_connect> callback is called when the connection to particular
node is successfully established. To callback are passed two arguments: host
and port of the node to which the client was connected.

Not set by default.

=item on_node_disconnect => $cb->( $host, $port )

The C<on_node_disconnect> callback is called when the connection to particular
node is closed by any reason. To callback are passed two arguments: host and
port of the node from which the client was disconnected.

Not set by default.

=item on_node_error => $cb->( $err, $host, $port )

The C<on_node_error> callback is called when occurred an error, which was
affected on entire node (e. g. connection error or authentication error). Also
the C<on_node_error> callback can be called on command errors if the command
callback is not specified. To callback are passed three arguments: error object,
and host and port of the node on which an error occurred.

Not set by default.

=item on_error => $cb->( $err )

The C<on_error> callback is called on command errors if the command callback
is not specified. If the C<on_error> callback is not specified, the client
just print an error messages to C<STDERR>.

=back

=head1 COMMAND METHODS

To execute the STOMP command you must call appropriate method. STOMP headers
can be specified as command parameters. The client automatically adds
C<content-length> header to all outgoing frames. Every command method can also
accept two additional parameters: the C<body> parameter where you can specify
the body of the frame, and the C<on_receipt> parameter that is the alternative
way to specify the command callback.

If you want to receive C<RECEIPT> frame, you must specify C<receipt> header.
The C<receipt> header can take the special value C<auto>. If it set, the
receipt identifier will be generated automatically by the client. The
C<RECEIPT> frame is passed to the command callback in first argument as the
object of the class L<AnyEvent::Stomper::Frame>. If the C<receipt> header is
not specified the first argument of the command callback will be C<undef>.

For commands C<SUBSCRIBE>, C<UNSUBSCRIBE>, C<DISCONNECT> the client
automatically adds C<receipt> header for internal usage.

The command callback is called in one of two cases depending on the presence of
the C<receipt> header. First case, when the command was successfully sent to
the server. Second case, when the C<RECEIPT> frame will be received. If any
error occurred during the command execution, the error object is passed to the
callback in second argument. Error object is the instance of the class
L<AnyEvent::Stomper::Error>.

The command callback is optional. If it is not specified and any error
occurred, the C<on_error> callback of the client is called.

If you want to track errors on particular nodes for particular command, you
must specify C<on_node_error> callback in command method.

  $cluster->send(
    destination => '/queue/foo',
    body        => 'Hello, world!',

    on_receipt => sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        my $err_msg   = $err->message;
        my $err_code  = $err->code;
        my $err_frame = $err->frame;

        # error handling...

        return;
      }

      # receipt handling...
    },

    on_node_error => sub {
      my $err  = shift;
      my $host = shift;
      my $port = shift;

      # error handling...
    }
  );

The full list of all available headers for every command you can find in STOMP
protocol specification and in documentation on your STOMP server. For various
versions of STOMP protocol and various STOMP servers they can be differ.

=head2 send( [ %params ] [, $cb->( $receipt, $err ) ] )

Sends a message to a destination in the messaging system.

  $cluster->send(
    destination => '/queue/foo',
    body        => 'Hello, world!',
  );

  $cluster->send(
    destination => '/queue/foo',
    body        => 'Hello, world!',

    sub {
      my $err = $_[1];

      if ( defined $err ) {
        my $err_msg   = $err->message;
        my $err_code  = $err->code;
        my $err_frame = $err->frame;

        # error handling...

        return;
      }
    }
  );

  $cluster->send(
    destination => '/queue/foo',
    receipt     => 'auto',
    body        => 'Hello, world!',

    on_receipt => sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        my $err_msg   = $err->message;
        my $err_code  = $err->code;
        my $err_frame = $err->frame;

        # error handling...

        return;
      }

      # receipt handling...
    }
  );

=head2 subscribe( [ %params ] [, $cb->( $msg ) ] )

The method is used to register to listen to a given destination. The
C<subscribe> method require the C<on_message> callback, which is called on
every received C<MESSAGE> frame from the server. The C<MESSAGE> frame is passed
to the C<on_message> callback in first argument as the object of the class
L<AnyEvent::Stomper::Frame>. If the C<subscribe> method is called with one
callback, this callback will be act as C<on_message> callback.

  $cluster->subscribe(
    id          => 'foo',
    destination => '/queue/foo',

    sub {
      my $msg = shift;

      my $headers = $msg->headers;
      my $body    = $msg->body;

      # message handling...
    },
  );

  $cluster->subscribe(
    id          => 'foo',
    destination => '/queue/foo',
    ack         => 'client',

    on_receipt => sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        my $err_msg   = $err->message;
        my $err_code  = $err->code;
        my $err_frame = $err->frame;

        return;
      }

      # receipt handling...
    },

    on_message => sub {
      my $msg = shift;

      my $headers = $msg->headers;
      my $body    = $msg->body;

      # message handling...
    },
  );

=head2 unsubscribe( [ %params ] [, $cb->( $receipt, $err ) ] )

The method is used to remove an existing subscription.

  $cluster->unsubscribe(
    id          => 'foo',
    destination => '/queue/foo',

    sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        my $err_msg   = $err->message;
        my $err_code  = $err->code;
        my $err_frame = $err->frame;

        return;
      }

      # receipt handling...
    }
  );

=head2 ack( [ %params ] [, $cb->( $receipt, $err ) ] )

The method is used to acknowledge consumption of a message from a subscription
using C<client> or C<client-individual> acknowledgment. Any messages received
from such a subscription will not be considered to have been consumed until the
message has been acknowledged via an C<ack()> method. Method C<ack()> must be
called with required parameter C<message> in which must be specified the
C<MESSAGE> frame.

  $stomper->ack( message => $msg );

  $stomper->ack(
    message => $msg,
    receipt => 'auto',

    sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        my $err_msg   = $err->message;
        my $err_code  = $err->code;
        my $err_frame = $err->frame;

        # error handling...
      }

      # receipt handling...
    }
  );

=head2 nack( [ %params ] [, $cb->( $receipt, $err ) ] )

The C<nack> method is the opposite of C<ack> method. It is used to tell the
server that the client did not consume the message. Method C<nack()> must be
called with required parameter C<message> in which must be specified the
C<MESSAGE> frame.

  $stomper->nack( message => $msg );

  $stomper->nack(
    message => $msg,
    receipt => 'auto',

    sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        my $err_msg   = $err->message;
        my $err_code  = $err->code;
        my $err_frame = $err->frame;

        # error handling...
      }

      # receipt handling...
    }
  );

=head2 begin( [ %params ] [, $cb->( $receipt, $err ) ] )

The method C<begin> is used to start a transaction.

=head2 commit( [ %params ] [, $cb->( $receipt, $err ) ] )

The method C<commit> is used to commit a transaction.

=head2 abort( [ %params ] [, $cb->( $receipt, $err ) ] )

The method C<abort> is used to roll back a transaction.

=head2 disconnect( [ %params ] [, $cb->( $receipt, $err ) ] )

A client can disconnect from the current active node at anytime by closing the
socket but there is no guarantee that the previously sent frames have been
received by the node. To do a graceful shutdown, where the client is assured
that all previous frames have been received by the node, you must call
C<disconnect> method and wait for the C<RECEIPT> frame.

=head2 execute( $command, [ %params ] [, $cb->( $receipt, $err ) ] )

An alternative method to execute commands. In some cases it can be more
convenient.

  $cluster->execute( 'SEND',
    destination => '/queue/foo',
    receipt     => 'auto',
    body        => 'Hello, world!',

    sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        my $err_msg   = $err->message;
        my $err_code  = $err->code;
        my $err_frame = $err->frame;

        # error handling...

        return;
      }

      # receipt handling...
    }
  );

=head1 ERROR CODES

Every error object, passed to callback, contain error code, which can be used
for programmatic handling of errors. AnyEvent::Stomper::Cluster provides
constants for error codes. They can be imported and used in expressions.

  use AnyEvent::Stomper::Cluster qw( :err_codes );

Full list of error codes see in documentation on L<AnyEvent::Stomper>.

=head1 OTHER METHODS

=head2 nodes()

Gets all available nodes.

=head2 on_error( [ $callback ] )

Gets or sets the C<on_error> callback.

=head2 force_disconnect()

The method for forced disconnection. All uncompleted operations will be
aborted.

=head1 SEE ALSO

L<AnyEvent::Stomper>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

Sponsored by SMS Online, E<lt>dev.opensource@sms-online.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
