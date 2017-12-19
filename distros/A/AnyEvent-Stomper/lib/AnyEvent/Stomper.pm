package AnyEvent::Stomper;

use 5.008000;
use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.36';

use AnyEvent::Stomper::Frame;
use AnyEvent::Stomper::Error;

use AnyEvent;
use AnyEvent::Handle;
use Scalar::Util qw( looks_like_number weaken );
use List::Util qw( max );
use List::MoreUtils qw( bsearch_index );
use Carp qw( croak );

my %ERROR_CODES;

BEGIN {
  %ERROR_CODES = %AnyEvent::Stomper::Error::ERROR_CODES;
  our @EXPORT_OK   = keys %ERROR_CODES;
  our %EXPORT_TAGS = ( err_codes => \@EXPORT_OK );
}

use constant {
  # Default values
  D_HOST      => 'localhost',
  D_PORT      => 61613,
  D_HEARTBEAT => [ 0, 0 ],

  %ERROR_CODES,

  # Operation status
  S_NEED_DO     => 1,
  S_IN_PROGRESS => 2,
  S_DONE        => 3,

  EOL    => "\n",
  RE_EOL => qr/\r?\n/,
};

my %SUBUNSUB_CMDS = (
  SUBSCRIBE   => 1,
  UNSUBSCRIBE => 1,
);

my %ACK_CMDS = (
  ACK  => 1,
  NACK => 1,
);

my %NEED_RECEIPT = (
  CONNECT    => 1,
  DISCONNECT => 1,
  %SUBUNSUB_CMDS,
);

my %ESCAPE_MAP = (
  "\r" => "\\r",
  "\n" => "\\n",
  ':'  => "\\c",
  "\\" => "\\\\",
);
my %UNESCAPE_MAP = reverse %ESCAPE_MAP;

my $RECEIPT_SEQ = 1;
my $MESSAGE_SEQ = 1;


sub new {
  my $class  = shift;
  my %params = @_;

  my $self = bless {}, $class;

  $self->{host}            = $params{host} || D_HOST;
  $self->{port}            = $params{port} || D_PORT;
  $self->{login}           = $params{login};
  $self->{passcode}        = $params{passcode};
  $self->{vhost}           = $params{vhost};
  $self->{lazy}            = $params{lazy};
  $self->{handle_params}   = $params{handle_params} || {};
  $self->{default_headers} = $params{default_headers} || {};
  $self->{on_connect}      = $params{on_connect};
  $self->{on_disconnect}   = $params{on_disconnect};

  if ( defined $params{heartbeat} ) {
    unless ( ref( $params{heartbeat} ) eq 'ARRAY' ) {
      croak q{"heartbeat" must be specified as array reference};
    }

    foreach my $val ( @{ $params{heartbeat} } ) {
      if ( $val =~ /\D/ ) {
        croak q{"heartbeat" values must be an integer numbers};
      }
    }

    $self->{heartbeat} = $params{heartbeat};
  }
  else {
    $self->{heartbeat} = D_HEARTBEAT;
  }

  if ( defined $params{command_headers} ) {
    unless ( ref( $params{command_headers} ) eq 'HASH' ) {
      croak q{"command_headers" must be specified as hash reference};
    }

    my %command_headers;
    while ( my ( $cmd_name, $headers ) = each %{ $params{command_headers} } ) {
      $command_headers{ uc($cmd_name) } = $headers;
    }
    $self->{command_headers} = \%command_headers;
  }

  $self->connection_timeout( $params{connection_timeout} );
  $self->reconnect_interval( $params{reconnect_interval} );
  $self->on_error( $params{on_error} );

  $self->_reset_internals;
  $self->{_input_queue}      = [];
  $self->{_temp_input_queue} = [];
  $self->{_write_queue}      = [];
  $self->{_temp_write_queue} = [];
  $self->{_pending_receipts} = {};
  $self->{_subs}             = {};

  unless ( $self->{lazy} ) {
    $self->_connect;
  }

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

# Generate accessors
{
  no strict qw( refs );

  foreach my $name ( qw( host port ) ) {
    *{$name} = sub {
      my $self = shift;
      return $self->{$name};
    }
  }

  foreach my $name ( qw( connection_timeout reconnect_interval ) ) {
    *{$name} = sub {
      my $self = shift;

      if (@_) {
        my $seconds = shift;

        if ( defined $seconds
          && ( !looks_like_number($seconds) || $seconds < 0 ) )
        {
          croak qq{"$name" must be a positive number};
        }
        $self->{$name} = $seconds;
      }

      return $self->{$name};
    };
  }

  foreach my $name ( qw( on_connect on_disconnect ) ) {
    *{$name} = sub {
      my $self = shift;

      if (@_) {
        $self->{$name} = shift;
      }

      return $self->{$name};
    };
  }
}

sub force_disconnect {
  my $self = shift;

  $self->_disconnect();

  return;
}

sub _connect {
  my $self = shift;

  $self->{_handle} = AnyEvent::Handle->new(
    %{ $self->{handle_params} },
    connect          => [ $self->{host}, $self->{port} ],
    on_prepare       => $self->_create_on_prepare,
    on_connect       => $self->_create_on_connect,
    on_connect_error => $self->_create_on_connect_error,
    on_wtimeout      => $self->_create_on_wtimeout,
    on_rtimeout      => $self->_create_on_rtimeout,
    on_eof           => $self->_create_on_eof,
    on_error         => $self->_create_on_handle_error,
    on_drain         => $self->_create_on_drain,
    on_read          => $self->_create_on_read,
  );

  return;
}

sub _create_on_prepare {
  my $self = shift;

  weaken($self);

  return sub {
    if ( defined $self->{connection_timeout} ) {
      return $self->{connection_timeout};
    }

    return;
  };
}

sub _create_on_connect {
  my $self = shift;

  weaken($self);

  return sub {
    $self->{_connected} = 1;
    $self->_login;

    if ( defined $self->{on_connect} ) {
      $self->{on_connect}->();
    }
  };
}

sub _create_on_connect_error {
  my $self = shift;

  weaken($self);

  return sub {
    my $err_msg = pop;

    my $err = _new_error(
      "Can't connect to $self->{host}:$self->{port}: $err_msg",
      E_CANT_CONN
    );
    $self->_disconnect($err);
  };
}

sub _create_on_wtimeout {
  my $self = shift;

  weaken($self);

  return sub {
    $self->{_handle}->push_write(EOL);
  };
}

sub _create_on_rtimeout {
  my $self = shift;

  weaken($self);

  return sub {
    my $err = _new_error( 'Read timed out.', E_READ_TIMEDOUT );
    $self->_disconnect($err);
  };
}

sub _create_on_eof {
  my $self = shift;

  weaken($self);

  return sub {
    my $err = _new_error( 'Connection closed by remote host.',
        E_CONN_CLOSED_BY_REMOTE_HOST );
    $self->_disconnect($err);
  };
}

sub _create_on_handle_error {
  my $self = shift;

  weaken($self);

  return sub {
    my $err_msg = pop;

    my $err = _new_error( $err_msg, E_IO );
    $self->_disconnect($err);
  };
}

sub _create_on_drain {
  my $self = shift;

  weaken($self);

  return sub {
    return unless @{ $self->{_write_queue} };

    $self->{_temp_write_queue} = $self->{_write_queue};
    $self->{_write_queue} = [];

    while ( my $cmd = shift @{ $self->{_temp_write_queue} } ) {
      $cmd->{on_receipt}->();
    }
  };
}

sub _create_on_read {
  my $self = shift;

  weaken($self);

  my $cmd_name;
  my $headers;

  return sub {
    my $handle = shift;

    my $frame;

    while (1) {
      return if $handle->destroyed;

      if ( defined $cmd_name ) {
        my $content_length;
        if ( defined $headers->{'content-length'} ) {
          $content_length = $headers->{'content-length'};
          return if length( $handle->{rbuf} ) < $content_length + 1;
        }
        else {
          $content_length = index( $handle->{rbuf}, "\0" );
          return if $content_length < 0
        }

        my $body = substr( $handle->{rbuf}, 0, $content_length, '' );
        $handle->{rbuf} =~ s/^\0(?:${\(RE_EOL)})*//;

        $frame = _new_frame( $cmd_name, $headers, $body );

        undef $cmd_name;
        undef $headers;
      }
      else {
        $handle->{rbuf} =~ s/^(?:${\(RE_EOL)})+//;

        return unless $handle->{rbuf} =~ s/^(.+?)(?:${\(RE_EOL)}){2}//s;

        ( $cmd_name, my @header_strings ) = split( m/${\(RE_EOL)}/, $1 );
        foreach my $header_str (@header_strings) {
          my ( $name, $value ) = split( /:/, $header_str, 2 );
          $headers->{ _unescape($name) } = _unescape($value);
        }

        next;
      }

      $self->_process_frame($frame);
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

  foreach my $name ( qw( body on_receipt on_message ) ) {
    if ( defined $headers{$name} ) {
      $params{$name} = delete $headers{$name};
    }
  }
  if ( exists $ACK_CMDS{$cmd_name} ) {
    $params{message} = delete $headers{message};
  }

  %headers = (
    %{ $self->{default_headers} },

    defined $self->{command_headers}{$cmd_name}
    ? %{ $self->{command_headers}{$cmd_name} }
    : (),

    %headers,
  );

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
  my $self = shift;
  my $cmd  = shift;

  if ( $cmd->{name} eq 'SUBSCRIBE'
    && !defined $cmd->{on_message} )
  {
    croak '"on_message" callback must be specified';
  }
  elsif ( exists $ACK_CMDS{ $cmd->{name} }
    && !defined $cmd->{message} )
  {
    croak '"message" parameter must be specified';
  }

  unless ( $self->{_ready} ) {
    if ( defined $self->{_handle} ) {
      if ( $self->{_connected} ) {
        if ( $self->{_login_state} == S_NEED_DO ) {
          $self->_login;
        }
      }
    }
    elsif ( $self->{lazy} ) {
      undef $self->{lazy};
      $self->_connect;
    }
    else {
      if ( defined $self->{reconnect_interval}
        && $self->{reconnect_interval} > 0 )
      {
        unless ( defined $self->{_reconnect_timer} ) {
          weaken($self);

          $self->{_reconnect_timer} = AE::timer(
            $self->{reconnect_interval}, 0,
            sub {
              undef $self->{_reconnect_timer};
              $self->_connect;
            }
          );
        }
      }
      else {
        $self->_connect;
      }
    }

    push( @{ $self->{_input_queue} }, $cmd );

    return;
  }

  $self->_push_write($cmd);

  return;
}

sub _push_write {
  my $self = shift;
  my $cmd  = shift;

  my $cmd_headers = $cmd->{headers};

  if ( exists $ACK_CMDS{ $cmd->{name} } ) {
    unless ( $self->_check_ack( $cmd->{message} ) ) {
      my $err = _new_error( "Unexpected $cmd->{name} sent.", E_OPRN_ERROR );
      AE::postpone { $cmd->{on_receipt}->( undef, $err ) };

      return;
    }

    my $msg_headers = $cmd->{message}->headers;

    if ( $self->{_version} <= 1.1 ) {
      $cmd_headers->{'message-id'} = $msg_headers->{'message-id'};
      if ( $self->{_version} > 1.0 ) {
        $cmd_headers->{subscription} = $msg_headers->{subscription};
      }
    }
    else {
      $cmd_headers->{id} = $msg_headers->{ack};
    }
  }

  if ( exists $NEED_RECEIPT{ $cmd->{name} }
    || defined $cmd_headers->{receipt} )
  {
    if ( $cmd->{name} eq 'CONNECT' ) {
      $self->{_pending_receipts}{CONNECTED} = $cmd;
    }
    else {
      if ( !defined $cmd_headers->{receipt}
        || $cmd_headers->{receipt} eq 'auto' )
      {
        $cmd_headers->{receipt} = 'R_' . $self->{_session_id} . '.'
            . $RECEIPT_SEQ++;
      }
      $self->{_pending_receipts}{ $cmd_headers->{receipt} } = $cmd;
    }
  }
  else {
    push( @{ $self->{_write_queue} }, $cmd );
  }

  my $body = $cmd->{body};
  unless ( defined $body ) {
    $body = '';
  }
  unless ( defined $cmd_headers->{'content-length'} ) {
    $cmd_headers->{'content-length'} = length($body);
  }

  my $frame_str = $cmd->{name} . EOL;
  while ( my ( $name, $value ) = each %{$cmd_headers} ) {
    unless ( defined $value ) {
      $value = '';
    }
    $frame_str .= _escape($name) . ':' . _escape($value) . EOL;
  }
  $frame_str .= EOL . "$body\0";

  $self->{_handle}->push_write($frame_str);

  return;
}

sub _login {
  my $self = shift;

  my ( $cx, $cy ) = @{ $self->{heartbeat} };

  if ( $cy > 0 ) {
    $self->_rtimeout($cy);
  }

  my %cmd_headers = (
    'accept-version' => '1.0,1.1,1.2',
    'heart-beat'     => join( ',', $cx, $cy ),
  );
  if ( defined $self->{login} ) {
    $cmd_headers{login} = $self->{login};
  }
  if ( defined $self->{passcode} ) {
    $cmd_headers{passcode} = $self->{passcode};
  }
  if ( defined $self->{vhost} ) {
    $cmd_headers{host} = $self->{vhost};
  }

  weaken($self);
  $self->{_login_state} = S_IN_PROGRESS;

  $self->_push_write(
    { name    => 'CONNECT',
      headers => \%cmd_headers,

      on_receipt => sub {
        my $receipt = shift;
        my $err     = shift;

        if ( defined $err ) {
          $self->{_login_state} = S_NEED_DO;
          $self->_abort($err);

          return;
        }

        $self->{_login_state} = S_DONE;

        my $receipt_headers = $receipt->headers;

        if ( defined $receipt_headers->{'heart-beat'} ) {
          my ( $sx, $sy ) = split( /,/, $receipt_headers->{'heart-beat'} );

          if ( $sx > 0 ) {
            $self->_rtimeout( max( $cy, $sx ) );
          }
          if ( $sy > 0 ) {
            $self->_wtimeout( max( $cx, $sy ) );
          }
        }

        $self->{_ready} = 1;
        $self->{_version}
            = version->parse( $receipt_headers->{version} || 1.0 );
        $self->{_session_id} = $receipt_headers->{session} || '';

        $self->_process_input_queue;
      },
    }
  );

  return;
}

sub _rtimeout {
  my $self     = shift;
  my $rtimeout = shift;

  $self->{_handle}->rtimeout_reset;
  $self->{_handle}->rtimeout( ( $rtimeout / 1000 ) * 3 );

  return;
}

sub _wtimeout {
  my $self     = shift;
  my $wtimeout = shift;

  $self->{_handle}->wtimeout_reset;
  $self->{_handle}->wtimeout( $wtimeout / ( 1000 * 3 ) );

  return;
}

sub _process_input_queue {
  my $self = shift;

  $self->{_temp_input_queue}  = $self->{_input_queue};
  $self->{_input_queue} = [];

  while ( my $cmd = shift @{ $self->{_temp_input_queue} } ) {
    $self->_push_write($cmd);
  }

  return;
}

sub _check_ack {
  my $self = shift;
  my $msg  = shift;

  my $msg_headers = $msg->headers;
  my $sub_id  = $msg_headers->{subscription} || $msg_headers->{destination};
  my $sub     = $self->{_subs}{$sub_id};
  my $msg_tag = $msg_headers->{'message-tag'};

  if ( defined $sub ) {
    if ( defined $sub->{pending_acks} ) {
      if ( ref( $sub->{pending_acks} ) eq 'ARRAY' ) {
        my $i = bsearch_index {
          $msg_tag > $_ ? -1 : $msg_tag < $_ ? 1 : 0;
        }
        @{ $sub->{pending_acks} };

        if ( $i >= 0 ) {
          splice( @{ $sub->{pending_acks} }, 0, $i + 1 );
          return 1;
        }
      }
      else {    # HASH
        return 1 if delete $sub->{pending_acks}{$msg_tag};
      }
    }
  }

  return;
}

sub _process_frame {
  my $self  = shift;
  my $frame = shift;

  if ( $frame->command eq 'MESSAGE' ) {
    $self->_process_message($frame);
  }
  elsif ( $frame->command eq 'RECEIPT' ) {
    $self->_process_receipt($frame);
  }
  elsif ( $frame->command eq 'ERROR' ) {
    if ( defined $self->{_pending_receipts}{CONNECTED} ) {
      $frame->headers->{'receipt-id'} = 'CONNECTED';
    }
    $self->_process_error($frame);
  }
  else {    # CONNECTED
    $frame->headers->{'receipt-id'} = 'CONNECTED';
    $self->_process_receipt($frame);
  }

  return;
}

sub _process_message {
  my $self = shift;
  my $msg  = shift;

  my $msg_headers = $msg->headers;
  my $sub_id = $msg_headers->{subscription} || $msg_headers->{destination};
  my $sub    = $self->{_subs}{$sub_id};

  unless ( defined $sub ) {
    my $err = _new_error(
      qq{Don't know how process MESSAGE frame. Unknown subscription "$sub_id"},
      E_UNEXPECTED_DATA
    );
    $self->_disconnect($err);

    return;
  }

  my $msg_tag = $MESSAGE_SEQ++;
  $msg_headers->{'message-tag'} = $msg_tag;

  if ( defined $sub->{pending_acks} ) {
    if ( ref( $sub->{pending_acks} ) eq 'ARRAY' ) {
      push( @{ $sub->{pending_acks} }, $msg_tag );
    }
    else {    # HASH
      $sub->{pending_acks}{$msg_tag} = 1;
    }
  }

  $sub->{on_message}->($msg);

  return;
}

sub _process_receipt {
  my $self    = shift;
  my $receipt = shift;

  my $receipt_id = $receipt->headers->{'receipt-id'};
  my $cmd        = delete $self->{_pending_receipts}{$receipt_id};

  unless ( defined $cmd ) {
    my $err = _new_error(
      qq{Unknown RECEIPT frame received: receipt-id=$receipt_id},
      E_UNEXPECTED_DATA
    );
    $self->_disconnect($err);

    return;
  }

  if ( exists $SUBUNSUB_CMDS{ $cmd->{name} } ) {
    my $cmd_headers = $cmd->{headers};
    my $sub_id = $cmd_headers->{id} || $cmd_headers->{destination};

    if ( $cmd->{name} eq 'SUBSCRIBE' ) {
      $self->{_subs}{$sub_id} = $cmd;

      if ( defined $cmd_headers->{ack} ) {
        if ( $cmd_headers->{ack} eq 'client' ) {
          $cmd->{pending_acks} = [];
        }
        elsif ( $cmd_headers->{ack} eq 'client-individual' ) {
          $cmd->{pending_acks} = {};
        }
      }
    }
    else {    # UNSUBSCRIBE
      delete $self->{_subs}{$sub_id};
    }
  }
  elsif ( $cmd->{name} eq 'DISCONNECT' ) {
    $self->_disconnect;
  }

  $cmd->{on_receipt}->($receipt);

  return;
}

sub _process_error {
  my $self      = shift;
  my $err_frame = shift;

  my $err_headers = $err_frame->headers;
  my $err = _new_error( $err_headers->{message}, E_OPRN_ERROR, $err_frame );

  my $cmd;
  if ( defined $err_headers->{'receipt-id'} ) {
    $cmd = delete $self->{_pending_receipts}{ $err_headers->{'receipt-id'} };
  }

  if ( defined $cmd ) {
    $cmd->{on_receipt}->( undef, $err );
  }
  else {
    $self->_disconnect($err);
  }

  return;
}

sub _disconnect {
  my $self = shift;
  my $err  = shift;

  my $was_connected = $self->{_connected};

  if ( defined $self->{_handle} ) {
    $self->{_handle}->destroy;
  }
  $self->_reset_internals;
  $self->_abort($err);

  if ( $was_connected && defined $self->{on_disconnect} ) {
    $self->{on_disconnect}->();
  }

  return;
}

sub _reset_internals {
  my $self = shift;

  $self->{_handle}          = undef;
  $self->{_connected}       = 0;
  $self->{_login_state}     = S_NEED_DO;
  $self->{_ready}           = 0;
  $self->{_version}         = undef;
  $self->{_session_id}      = undef;
  $self->{_reconnect_timer} = undef;

  return;
}

sub _abort {
  my $self = shift;
  my $err  = shift;

  my @queued_commands = $self->_queued_commands;
  my %subs            = %{ $self->{_subs} };

  $self->{_input_queue}      = [];
  $self->{_temp_input_queue} = [];
  $self->{_write_queue}      = [];
  $self->{_temp_write_queue} = [];
  $self->{_pending_receipts} = {};
  $self->{_subs}             = {};

  if ( !defined $err && @queued_commands ) {
    $err = _new_error( 'Connection closed by client prematurely.',
        E_CONN_CLOSED_BY_CLIENT );
  }

  if ( defined $err ) {
    my $err_msg   = $err->message;
    my $err_code  = $err->code;
    my $err_frame = $err->frame;

    $self->{on_error}->($err);

    if ( %subs && $err_code != E_CONN_CLOSED_BY_CLIENT ) {
      foreach my $sub_id ( keys %subs ) {
        my $err = _new_error( qq{Subscription "$sub_id" lost: $err_msg},
            $err_code, $err_frame );

        my $sub = $subs{$sub_id};
        $sub->{on_receipt}->( undef, $err );
      }
    }

    foreach my $cmd (@queued_commands) {
      my $err = _new_error( qq{Operation "$cmd->{name}" aborted: $err_msg},
          $err_code, $err_frame );
      $cmd->{on_receipt}->( undef, $err );
    }
  }

  return;
}

sub _queued_commands {
  my $self = shift;

  return (
    values %{ $self->{_pending_receipts} },
    @{ $self->{_temp_write_queue} },
    @{ $self->{_write_queue} },
    @{ $self->{_temp_input_queue} },
    @{ $self->{_input_queue} },
  );
}

sub _escape {
  my $str = shift;

  $str =~ s/([\r\n:\\])/$ESCAPE_MAP{$1}/ge;

  return $str;
}

sub _unescape {
  my $str = shift;

  $str =~ s/(\\[rnc\\])/$UNESCAPE_MAP{$1}/ge;

  return $str;
}

sub _new_frame {
  return AnyEvent::Stomper::Frame->new(@_);
}

sub _new_error {
  return AnyEvent::Stomper::Error->new(@_);
}

sub DESTROY {
  my $self = shift;

  if ( defined $self->{_handle} ) {
    $self->{_handle}->destroy;
  }

  if ( defined $self->{_pending_receipts} ) {
    my @queued_commands = $self->_queued_commands;

    foreach my $cmd (@queued_commands) {
      warn qq{Operation "$cmd->{name}" aborted:}
          . " Client object destroyed prematurely.\n";
    }
  }

  return;
}

1;
__END__

=head1 NAME

AnyEvent::Stomper - Flexible non-blocking STOMP client

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Stomper;

  my $stomper = AnyEvent::Stomper->new(
    host       => 'localhost',
    prot       => '61613',
    login      => 'guest',
    passcode   => 'guest',
  );

  my $cv = AE::cv;

  $stomper->subscribe(
    id          => 'foo',
    destination => '/queue/foo',

    on_receipt => sub {
      my $err = $_[1];

      if ( defined $err ) {
        warn $err->message . "\n";
        $cv->send;

        return;
      }

      $stomper->send(
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

AnyEvent::Stomper is flexible non-blocking STOMP client. Supports following
STOMP versions: 1.0, 1.1, 1.2.

Is recommended to read STOMP protocol specification before using the client:
L<https://stomp.github.io/index.html>

=head1 CONSTRUCTOR

=head2 new( %params )

  my $stomper = AnyEvent::Stomper->new(
    host               => 'localhost',
    port               => '61613',
    login              => 'guest',
    passcode           => 'guest',
    vhost              => '/',
    heartbeat          => [ 5000, 5000 ],
    connection_timeout => 5,
    lazy               => 1,
    reconnect_interval => 5,

    on_connect => sub {
      # handling...
    },

    on_disconnect => sub {
      # handling...
    },

    on_error => sub {
      my $err = shift;

      # error handling...
    },
  );

=over

=item host => $host

Server hostname (default: localhost)

=item port => $port

Server port (default: 61613)

=item login => $login

The user identifier used to authenticate against a secured STOMP server.

=item passcode => $passcode

The password used to authenticate against a secured STOMP server.

=item vhost => $vhost

The name of a virtual host that the client wishes to connect to.

=item heartbeat => \@heartbeat

Heart-beating can optionally be used to test the healthiness of the underlying
TCP connection and to make sure that the remote end is alive and kicking. The
first number sets interval in milliseconds between outgoing heart-beats to the
STOMP server. C<0> means, that the client will not send heart-beats. The second
number sets interval in milliseconds between incoming heart-beats from the
STOMP server. C<0> means, that the client does not want to receive heart-beats.

  heartbeat => [ 5000, 5000 ],

Not set by default.

=item connection_timeout => $connection_timeout

Specifies connection timeout. If the client could not connect to the server
after specified timeout, the C<on_error> callback is called with the
C<E_CANT_CONN> error. The timeout specifies in seconds and can contain a
fractional part.

  connection_timeout => 10.5,

By default the client use kernel's connection timeout.

=item lazy => $boolean

If enabled, the connection establishes at time when you will send the first
command to the server. By default the connection establishes after calling of
the C<new> method.

Disabled by default.

=item reconnect_interval => $reconnect_interval

If the connection to the server was lost, the client will try to restore the
connection when you execute next command. By default reconnection is performed
immediately, on next command execution. If the C<reconnect_interval> parameter
is specified, the client will try to reconnect only after this interval and
commands executed between reconnections will be queued.

The client will try to reconnect only once and, if attempt fails, the error
object is passed to command callback. If you need several attempts of the
reconnection, you must retry a command from the callback as many times, as you
need.

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

=item on_connect => $cb->()

The C<on_connect> callback is called when the connection is successfully
established.

Not set by default.

=item on_disconnect => $cb->()

The C<on_disconnect> callback is called when the connection is closed by any
reason.

Not set by default.

=item on_error => $cb->( $err )

The C<on_error> callback is called when occurred an error, which was affected
on entire client (e. g. connection error or authentication error). Also the
C<on_error> callback is called on command errors if the command callback is not
specified. If the C<on_error> callback is not specified, the client just print
an error messages to C<STDERR>.

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
the C<receipt> header. First case, when the command was successfully written to
the socket. Second case, when the C<RECEIPT> frame will be received. In first
case C<on_receipt> callback can be called synchronously. If any error occurred
during the command execution, the error object is passed to the callback in
second argument. Error object is the instance of the class
L<AnyEvent::Stomper::Error>.

The command callback is optional. If it is not specified and any error
occurred, the C<on_error> callback of the client is called.

The full list of all available headers for every command you can find in STOMP
protocol specification and in documentation on your STOMP server. For various
versions of STOMP protocol and various STOMP servers they can be differ.

=head2 send( [ %params ] [, $cb->( $receipt, $err ) ] )

Sends a message to a destination in the messaging system.

  $stomper->send(
    destination => '/queue/foo',
    body        => 'Hello, world!',
  );

  $stomper->send(
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

  $stomper->send(
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

  $stomper->subscribe(
    id          => 'foo',
    destination => '/queue/foo',

    sub {
      my $msg = shift;

      my $headers = $msg->headers;
      my $body    = $msg->body;

      # message handling...
    },
  );

  $stomper->subscribe(
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

  $stomper->unsubscribe(
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

A client can disconnect from the server at anytime by closing the socket but
there is no guarantee that the previously sent frames have been received by
the server. To do a graceful shutdown, where the client is assured that all
previous frames have been received by the server, you must call C<disconnect>
method and wait for the C<RECEIPT> frame.

=head2 execute( $command, [ %params ] [, $cb->( $receipt, $err ) ] )

An alternative method to execute commands. In some cases it can be more
convenient.

  $stomper->execute( 'SEND',
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
for programmatic handling of errors. AnyEvent::Stomper provides constants for
error codes. They can be imported and used in expressions.

  use AnyEvent::Stomper qw( :err_codes );

=over

=item E_CANT_CONN

Can't connect to the server. All operations were aborted.

=item E_IO

Input/Output operation error. The connection to the STOMP server was closed and
all operations were aborted.

=item E_CONN_CLOSED_BY_REMOTE_HOST

The connection closed by remote host. All operations were aborted.

=item E_CONN_CLOSED_BY_CLIENT

Connection closed by client prematurely. Uncompleted operations were aborted

=item E_OPRN_ERROR

Operation error. For example, missing required header.

=item E_UNEXPECTED_DATA

The client received unexpected data from the server. The connection to the
STOMP server was closed and all operations were aborted.

=item E_READ_TIMEDOUT

Read timed out. The connection to the STOMP server was closed and all operations
were aborted.

=back

=head1 OTHER METHODS

=head2 host()

Gets current host of the client.

=head2 port()

Gets current port of the client.

=head2 connection_timeout( [ $fractional_seconds ] )

Gets or sets the C<connection_timeout> of the client. The C<undef> value resets
the C<connection_timeout> to default value.

=head2 reconnect_interval( [ $fractional_seconds ] )

Gets or sets C<reconnect_interval> of the client.

=head2 on_connect( [ $callback ] )

Gets or sets the C<on_connect> callback.

=head2 on_disconnect( [ $callback ] )

Gets or sets the C<on_disconnect> callback.

=head2 on_error( [ $callback ] )

Gets or sets the C<on_error> callback.

=head2 force_disconnect()

The method for forced disconnection. All uncompleted operations will be
aborted.

=head1 WORKING WITH CLUSTER

If you have the cluster of STOMP servers, you can use
L<AnyEvent::Stomper::Cluster> to work with it.

=head1 SEE ALSO

L<AnyEvent::Stomper::Cluster>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

Sponsored by SMS Online, E<lt>dev.opensource@sms-online.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
