package AnyEvent::RipeRedis;

use 5.008000;
use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.48';

use AnyEvent::RipeRedis::Error;

use AnyEvent;
use AnyEvent::Handle;
use Scalar::Util qw( looks_like_number weaken );
use Digest::SHA qw( sha1_hex );
use Carp qw( croak );

my %ERROR_CODES;

BEGIN {
  %ERROR_CODES = %AnyEvent::RipeRedis::Error::ERROR_CODES;
  our @EXPORT_OK   = keys %ERROR_CODES;
  our %EXPORT_TAGS = ( err_codes => \@EXPORT_OK );
}

use constant {
  # Default values
  D_HOST     => 'localhost',
  D_PORT     => 6379,
  D_DB_INDEX => 0,

  %ERROR_CODES,

  # Operation status
  S_NEED_DO     => 1,
  S_IN_PROGRESS => 2,
  S_DONE        => 3,

  # String terminator
  EOL        => "\r\n",
  EOL_LENGTH => 2,
};

my %SUB_CMDS = (
  subscribe  => 1,
  psubscribe => 1,
);

my %SUBUNSUB_CMDS = (
  %SUB_CMDS,
  unsubscribe  => 1,
  punsubscribe => 1,
);

my %MESSAGE_TYPES = (
  message  => 1,
  pmessage => 1,
);

my %NEED_PREPROCESS = (
  multi       => 1,
  exec        => 1,
  discard     => 1,
  eval_cached => 1,
  %SUBUNSUB_CMDS,
);

my %NEED_POSTPROCESS = (
  info         => 1,
  cluster_info => 1,
  select       => 1,
  quit         => 1,
);

my %ERR_PREFS_MAP = (
  LOADING     => E_LOADING_DATASET,
  NOSCRIPT    => E_NO_SCRIPT,
  BUSY        => E_BUSY,
  MASTERDOWN  => E_MASTER_DOWN,
  MISCONF     => E_MISCONF,
  READONLY    => E_READONLY,
  OOM         => E_OOM,
  EXECABORT   => E_EXEC_ABORT,
  NOAUTH      => E_NO_AUTH,
  WRONGTYPE   => E_WRONG_TYPE,
  NOREPLICAS  => E_NO_REPLICAS,
  BUSYKEY     => E_BUSY_KEY,
  CROSSSLOT   => E_CROSS_SLOT,
  TRYAGAIN    => E_TRY_AGAIN,
  ASK         => E_ASK,
  MOVED       => E_MOVED,
  CLUSTERDOWN => E_CLUSTER_DOWN,
  NOTBUSY     => E_NOT_BUSY,
);

my %EVAL_CACHE;


sub new {
  my $class  = shift;
  my %params = @_;

  my $self = bless {}, $class;

  $self->{host} = $params{host} || D_HOST;
  $self->{port} = $params{port} || D_PORT;
  $self->{password} = $params{password};
  $self->{database}
      = defined $params{database} ? $params{database} : D_DB_INDEX;
  $self->{utf8}          = exists $params{utf8} ? $params{utf8} : 1;
  $self->{lazy}          = $params{lazy};
  $self->{reconnect}     = exists $params{reconnect} ? $params{reconnect} : 1;
  $self->{handle_params} = $params{handle_params} || {};
  $self->{on_connect}    = $params{on_connect};
  $self->{on_disconnect} = $params{on_disconnect};

  $self->connection_timeout( $params{connection_timeout} );
  $self->read_timeout( $params{read_timeout} );
  $self->reconnect_interval( $params{reconnect_interval} );
  $self->on_error( $params{on_error} );

  $self->_reset_internals;
  $self->{_input_queue}      = [];
  $self->{_temp_queue}       = [];
  $self->{_processing_queue} = [];
  $self->{_channels}         = {};
  $self->{_channel_cnt}      = 0;
  $self->{_pchannel_cnt}     = 0;

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

sub disconnect {
  my $self = shift;

  $self->_disconnect;

  return;
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

  foreach my $name ( qw( host port database ) ) {
    *{$name} = sub {
      my $self = shift;
      return $self->{$name};
    }
  }

  foreach my $name ( qw( connection_timeout read_timeout
      reconnect_interval ) )
  {
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

  foreach my $name ( qw( utf8 reconnect on_connect on_disconnect ) ) {
    *{$name} = sub {
      my $self = shift;

      if (@_) {
        $self->{$name} = shift;
      }

      return $self->{$name};
    };
  }
}

sub _connect {
  my $self = shift;

  $self->{_handle} = AnyEvent::Handle->new(
    %{ $self->{handle_params} },
    connect          => [ $self->{host}, $self->{port} ],
    on_prepare       => $self->_create_on_prepare,
    on_connect       => $self->_create_on_connect,
    on_connect_error => $self->_create_on_connect_error,
    on_rtimeout      => $self->_create_on_rtimeout,
    on_eof           => $self->_create_on_eof,
    on_error         => $self->_create_on_handle_error,
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

    unless ( defined $self->{password} ) {
      $self->{_auth_state} = S_DONE;
    }
    if ( $self->{database} == 0 ) {
      $self->{_db_selection_state} = S_DONE;
    }

    if ( $self->{_auth_state} == S_NEED_DO ) {
      $self->_auth;
    }
    elsif ( $self->{_db_selection_state} == S_NEED_DO ) {
      $self->_select_database;
    }
    else {
      $self->{_ready} = 1;
      $self->_process_input_queue;
    }

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

sub _create_on_rtimeout {
  my $self = shift;

  weaken($self);

  return sub {
    if ( @{ $self->{_processing_queue} } ) {
      my $err = _new_error( 'Read timed out.', E_READ_TIMEDOUT );
      $self->_disconnect($err);
    }
    else {
      $self->{_handle}->rtimeout(undef);
    }
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

sub _create_on_read {
  my $self = shift;

  weaken($self);

  my $str_len;
  my @bufs;
  my $bufs_num = 0;

  return sub {
    my $handle = shift;

    MAIN: while (1) {
      return if $handle->destroyed;

      my $reply;
      my $err_code;

      if ( defined $str_len ) {
        if ( length( $handle->{rbuf} ) < $str_len + EOL_LENGTH ) {
          return;
        }

        $reply = substr( $handle->{rbuf}, 0, $str_len, '' );
        substr( $handle->{rbuf}, 0, EOL_LENGTH, '' );
        if ( $self->{utf8} ) {
          utf8::decode($reply);
        }

        undef $str_len;
      }
      else {
        my $eol_pos = index( $handle->{rbuf}, EOL );

        if ( $eol_pos < 0 ) {
          return;
        }

        $reply = substr( $handle->{rbuf}, 0, $eol_pos, '' );
        my $type = substr( $reply, 0, 1, '' );
        substr( $handle->{rbuf}, 0, EOL_LENGTH, '' );

        if ( $type ne '+' && $type ne ':' ) {
          if ( $type eq '$' ) {
            if ( $reply >= 0 ) {
              $str_len = $reply;
              next;
            }

            undef $reply;
          }
          elsif ( $type eq '*' ) {
            if ( $reply > 0 ) {
              push( @bufs,
                { reply      => [],
                  err_code   => undef,
                  chunks_cnt => $reply,
                }
              );
              $bufs_num++;

              next;
            }
            elsif ( $reply == 0 ) {
              $reply = [];
            }
            else {
              undef $reply;
            }
          }
          elsif ( $type eq '-' ) {
            $err_code = E_OPRN_ERROR;
            if ( $reply =~ m/^([A-Z]{3,}) / ) {
              if ( exists $ERR_PREFS_MAP{$1} ) {
                $err_code = $ERR_PREFS_MAP{$1};
              }
            }
          }
          else {
            my $err = _new_error( 'Unexpected reply received.',
                E_UNEXPECTED_DATA );
            $self->_disconnect($err);

            return;
          }
        }
      }

      while ( $bufs_num > 0 ) {
        my $curr_buf = $bufs[-1];
        if ( defined $err_code ) {
          unless ( ref($reply) ) {
            $reply = _new_error( $reply, $err_code );
          }
          $curr_buf->{err_code} = E_OPRN_ERROR;
        }
        push( @{ $curr_buf->{reply} }, $reply );
        if ( --$curr_buf->{chunks_cnt} > 0 ) {
          next MAIN;
        }

        $reply    = $curr_buf->{reply};
        $err_code = $curr_buf->{err_code};
        pop @bufs;
        $bufs_num--;
      }

      $self->_process_reply( $reply, $err_code );
    }

    return;
  };
}

sub _prepare {
  my $self     = shift;
  my $cmd_name = shift;
  my $args     = shift;

  my $cbs;
  if ( ref( $args->[-1] ) eq 'HASH' ) {
    $cbs = pop @{$args};
  }
  else {
    $cbs = {};
    if ( ref( $args->[-1] ) eq 'CODE' ) {
      if ( exists $SUB_CMDS{$cmd_name} ) {
        $cbs->{on_message} = pop @{$args};
      }
      else {
        $cbs->{on_reply} = pop @{$args};
      }
    }
  }

  my @kwds
      = $cmd_name eq 'eval_cached'
      ? ('evalsha')
      : split( m/_/, lc($cmd_name) );

  my $cmd = {
    name => $cmd_name,
    kwds => \@kwds,
    args => $args,
    %{$cbs},
  };

  unless ( defined $cmd->{on_reply} ) {
    weaken($self);

    $cmd->{on_reply} = sub {
      my $err = $_[1];

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

  if ( $self->{_multi_mode}
    && ( exists $SUBUNSUB_CMDS{ $cmd->{name} }
      || exists $NEED_POSTPROCESS{ $cmd->{name} } ) )
  {
    croak qq{Command "$cmd->{name}" not allowed after "multi" command.}
        . ' First, the transaction must be finalized.';
  }

  if ( exists $NEED_PREPROCESS{ $cmd->{name} } ) {
    if ( $cmd->{name} eq 'multi' ) {
      $self->{_multi_mode} = 1;
    }
    elsif ( $cmd->{name} eq 'exec'
      || $cmd->{name} eq 'discard' )
    {
      $self->{_multi_mode} = 0;
    }
    elsif ( $cmd->{name} eq 'eval_cached' ) {
      my $script = $cmd->{args}[0];
      unless ( exists $EVAL_CACHE{$script} ) {
        $EVAL_CACHE{$script} = sha1_hex($script);
      }
      $cmd->{args}[0] = $EVAL_CACHE{$script};
      $cmd->{script}  = $script;
    }
    else {    # subscribe, unsubscribe, psubscribe, punsubscribe
      if ( exists $SUB_CMDS{ $cmd->{name} }
        && !defined $cmd->{on_message} )
      {
        croak '"on_message" callback must be specified';
      }

      if ( @{ $cmd->{args} } ) {
        $cmd->{reply_cnt} = scalar @{ $cmd->{args} };
      }
    }
  }

  unless ( $self->{_ready} ) {
    if ( defined $self->{_handle} ) {
      if ( $self->{_connected} ) {
        if ( $self->{_auth_state} == S_DONE ) {
          if ( $self->{_db_selection_state} == S_NEED_DO ) {
            $self->_select_database;
          }
        }
        elsif ( $self->{_auth_state} == S_NEED_DO ) {
          $self->_auth;
        }
      }
    }
    elsif ( $self->{lazy} ) {
      undef $self->{lazy};
      $self->_connect;
    }
    elsif ( $self->{reconnect} ) {
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
    else {
      AE::postpone {
        my $err = _new_error( qq{Operation "$cmd->{name}" aborted:}
            . ' No connection to the server.', E_NO_CONN );
        $cmd->{on_reply}->( undef, $err );
      };

      return;
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

  my $cmd_str = '';
  my @tokens  = ( @{ $cmd->{kwds} }, @{ $cmd->{args} } );
  foreach my $token (@tokens) {
    unless ( defined $token ) {
      $token = '';
    }
    elsif ( $self->{utf8} ) {
      utf8::encode($token);
    }
    $cmd_str .= '$' . length($token) . EOL . $token . EOL;
  }
  $cmd_str = '*' . scalar(@tokens) . EOL . $cmd_str;

  my $handle = $self->{_handle};

  if ( defined $self->{read_timeout}
    && !@{ $self->{_processing_queue} } )
  {
    $handle->rtimeout_reset;
    $handle->rtimeout( $self->{read_timeout} );
  }

  push( @{ $self->{_processing_queue} }, $cmd );
  $handle->push_write($cmd_str);

  return;
}

sub _auth {
  my $self = shift;

  weaken($self);
  $self->{_auth_state} = S_IN_PROGRESS;

  $self->_push_write(
    { name => 'auth',
      kwds => ['auth'],
      args => [ $self->{password} ],

      on_reply => sub {
        my $err = $_[1];

        if ( defined $err
          && $err->message ne 'ERR Client sent AUTH, but no password is set' )
        {
          $self->{_auth_state} = S_NEED_DO;
          $self->_abort($err);

          return;
        }

        $self->{_auth_state} = S_DONE;

        if ( $self->{_db_selection_state} == S_NEED_DO ) {
          $self->_select_database;
        }
        else {
          $self->{_ready} = 1;
          $self->_process_input_queue;
        }
      },
    }
  );

  return;
}

sub _select_database {
  my $self = shift;

  weaken($self);
  $self->{_db_selection_state} = S_IN_PROGRESS;

  $self->_push_write(
    { name => 'select',
      kwds => ['select'],
      args => [ $self->{database} ],

      on_reply => sub {
        my $err = $_[1];

        if ( defined $err ) {
          $self->{_db_selection_state} = S_NEED_DO;
          $self->_abort($err);

          return;
        }

        $self->{_db_selection_state} = S_DONE;

        $self->{_ready} = 1;
        $self->_process_input_queue;
      },
    }
  );

  return;
}

sub _process_input_queue {
  my $self = shift;

  $self->{_temp_queue}  = $self->{_input_queue};
  $self->{_input_queue} = [];

  while ( my $cmd = shift @{ $self->{_temp_queue} } ) {
    $self->_push_write($cmd);
  }

  return;
}

sub _process_reply {
  my $self     = shift;
  my $reply    = shift;
  my $err_code = shift;

  if ( defined $err_code ) {
    $self->_process_error( $reply, $err_code );
  }
  elsif ( $self->{_channel_cnt} + $self->{_pchannel_cnt} > 0
    && ref($reply) && exists $MESSAGE_TYPES{ $reply->[0] } )
  {
    $self->_process_message($reply);
  }
  else {
    $self->_process_success($reply);
  }

  return;
}

sub _process_error {
  my $self     = shift;
  my $reply    = shift;
  my $err_code = shift;

  my $cmd = shift @{ $self->{_processing_queue} };

  unless ( defined $cmd ) {
    my $err = _new_error(
      q{Don't know how process error message. Processing queue is empty.},
      E_UNEXPECTED_DATA
    );
    $self->_disconnect($err);

    return;
  }

  if ( $err_code == E_NO_AUTH ) {
    my $err = _new_error( $reply, $err_code );
    $self->_disconnect($err);

    return;
  }

  if ( $cmd->{name} eq 'eval_cached'
    && $err_code == E_NO_SCRIPT )
  {
    $cmd->{kwds}[0] = 'eval';
    $cmd->{args}[0] = $cmd->{script};

    $self->_push_write($cmd);

    return;
  }

  if ( ref($reply) ) {
    my $err = _new_error(
        qq{Operation "$cmd->{name}" completed with errors.}, $err_code );
    $cmd->{on_reply}->( $reply, $err );
  }
  else {
    my $err = _new_error( $reply, $err_code );
    $cmd->{on_reply}->( undef, $err );
  }

  return;
}

sub _process_message {
  my $self = shift;
  my $msg  = shift;

  my $cmd = $self->{_channels}{ $msg->[1] };

  unless ( defined $cmd ) {
    my $err = _new_error(
      q{Don't know how process published message.}
          . qq{ Unknown channel or pattern "$msg->[1]".},
      E_UNEXPECTED_DATA
    );
    $self->_disconnect($err);

    return;
  }

  $cmd->{on_message}->(
    $msg->[0] eq 'pmessage'
    ? @{$msg}[ 3, 1, 2 ]
    : @{$msg}[ 2, 1 ]
  );

  return;
}

sub _process_success {
  my $self  = shift;
  my $reply = shift;

  my $cmd = $self->{_processing_queue}[0];

  unless ( defined $cmd ) {
    my $err = _new_error(
      q{Don't know how process reply. Processing queue is empty.},
      E_UNEXPECTED_DATA
    );
    $self->_disconnect($err);

    return;
  }

  if ( exists $SUBUNSUB_CMDS{ $cmd->{name} } ) {
    if ( $cmd->{name} eq 'subscribe' ) {
      $self->{_channels}{ $reply->[1] } = $cmd;
      $self->{_channel_cnt}++;
    }
    elsif ( $cmd->{name} eq 'psubscribe' ) {
      $self->{_channels}{ $reply->[1] } = $cmd;
      $self->{_pchannel_cnt}++;
    }
    elsif ( $cmd->{name} eq 'unsubscribe' ) {
      unless ( defined $cmd->{reply_cnt} ) {
        $cmd->{reply_cnt} = $self->{_channel_cnt};
      }

      delete $self->{_channels}{ $reply->[1] };
      $self->{_channel_cnt}--;
    }
    else {    # punsubscribe
      unless ( defined $cmd->{reply_cnt} ) {
        $cmd->{reply_cnt} = $self->{_pchannel_cnt};
      }

      delete $self->{_channels}{ $reply->[1] };
      $self->{_pchannel_cnt}--;
    }

    $reply = $reply->[2];
  }

  if ( !defined $cmd->{reply_cnt}
    || --$cmd->{reply_cnt} == 0 )
  {
    shift @{ $self->{_processing_queue} };

    if ( exists $NEED_POSTPROCESS{ $cmd->{name} } ) {
      if ( $cmd->{name} eq 'info'
        || $cmd->{name} eq 'cluster_info' )
      {
        $reply = _parse_info($reply);
      }
      elsif ( $cmd->{name} eq 'select' ) {
        $self->{database} = $cmd->{args}[0];
      }
      else {    # quit
        $self->_disconnect;
      }
    }

    $cmd->{on_reply}->($reply);
  }

  return;
}

sub _parse_info {
  return { map { split( m/:/, $_, 2 ) }
      grep { m/^[^#]/ } split( EOL, $_[0] ) };
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

  $self->{_handle}             = undef;
  $self->{_connected}          = 0;
  $self->{_auth_state}         = S_NEED_DO;
  $self->{_db_selection_state} = S_NEED_DO;
  $self->{_ready}              = 0;
  $self->{_multi_mode}         = 0;
  $self->{_reconnect_timer}    = undef;

  return;
}

sub _abort {
  my $self = shift;
  my $err  = shift;

  my @queued_commands = $self->_queued_commands;
  my %channels        = %{ $self->{_channels} };

  $self->{_input_queue}      = [];
  $self->{_temp_queue}       = [];
  $self->{_processing_queue} = [];
  $self->{_channels}         = {};
  $self->{_channel_cnt}      = 0;
  $self->{_pchannel_cnt}     = 0;

  if ( !defined $err && @queued_commands ) {
    $err = _new_error( 'Connection closed by client prematurely.',
        E_CONN_CLOSED_BY_CLIENT );
  }

  if ( defined $err ) {
    my $err_msg  = $err->message;
    my $err_code = $err->code;

    $self->{on_error}->($err);

    if ( %channels && $err_code != E_CONN_CLOSED_BY_CLIENT ) {
      foreach my $name ( keys %channels ) {
        my $err = _new_error(
          qq{Subscription to channel "$name" lost: $err_msg},
          $err_code
        );

        my $cmd = $channels{$name};
        $cmd->{on_reply}->( undef, $err );
      }
    }

    foreach my $cmd (@queued_commands) {
      my $err = _new_error( qq{Operation "$cmd->{name}" aborted: $err_msg},
          $err_code );
      $cmd->{on_reply}->( undef, $err );
    }
  }

  return;
}

sub _queued_commands {
  my $self = shift;

  return (
    @{ $self->{_processing_queue} },
    @{ $self->{_temp_queue} },
    @{ $self->{_input_queue} },
  );
}

sub _new_error {
  return AnyEvent::RipeRedis::Error->new(@_);
}

sub AUTOLOAD {
  our $AUTOLOAD;
  my $cmd_name = $AUTOLOAD;
  $cmd_name =~ s/^.+:://;

  my $sub = sub {
    my $self = shift;

    my $cmd = $self->_prepare( $cmd_name, [@_] );
    $self->_execute($cmd);

    return;
  };

  do {
    no strict 'refs';
    *{$cmd_name} = $sub;
  };

  goto &{$sub};
}

sub DESTROY {
  my $self = shift;

  if ( defined $self->{_handle} ) {
    $self->{_handle}->destroy;
  }

  if ( defined $self->{_processing_queue} ) {
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

AnyEvent::RipeRedis - Flexible non-blocking Redis client

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::RipeRedis;

  my $redis = AnyEvent::RipeRedis->new(
    host     => 'localhost',
    port     => 6379,
    password => 'yourpass',
  );

  my $cv = AE::cv;

  $redis->set( 'foo', 'bar',
    sub {
      my $err = $_[1];

      if ( defined $err ) {
        warn $err->message . "\n";
        $cv->send;

        return;
      }

      $redis->get( 'foo',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            warn $err->message . "\n";
            $cv->send;

            return;
          }

          print "$reply\n";
          $cv->send;
        }
      );
    }
  );

  $cv->recv;

=head1 DESCRIPTION

AnyEvent::RipeRedis is flexible non-blocking Redis client. Supports
subscriptions, transactions and can automaticaly restore connection after
failure.

Requires Redis 1.2 or higher, and any supported event loop.

=head1 CONSTRUCTOR

=head2 new( %params )

  my $redis = AnyEvent::RipeRedis->new(
    host               => 'localhost',
    port               => 6379,
    password           => 'yourpass',
    database           => 7,
    connection_timeout => 5,
    read_timeout       => 5,
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

Server hostname (default: 127.0.0.1)

=item port => $port

Server port (default: 6379)

=item password => $password

If the password is specified, the C<AUTH> command is sent to the server
after connection.

=item database => $index

Database index. If the index is specified, the client switches to the specified
database after connection. You can also switch to another database after
connection by using C<SELECT> command. The client remembers last selected
database after reconnection and switches to it automaticaly.

The default database index is C<0>.

=item utf8 => $boolean

If enabled, all strings will be converted to UTF-8 before sending to
the server, and all results will be decoded from UTF-8.

Enabled by default.

=item connection_timeout => $fractional_seconds

Specifies connection timeout. If the client could not connect to the server
after specified timeout, the C<on_error> callback is called with the
C<E_CANT_CONN> error. The timeout specifies in seconds and can contain a
fractional part.

  connection_timeout => 10.5,

By default the client use kernel's connection timeout.

=item read_timeout => $fractional_seconds

Specifies read timeout. If the client could not receive a reply from the server
after specified timeout, the client close connection and call the C<on_error>
callback with the C<E_READ_TIMEDOUT> error. The timeout is specifies in seconds
and can contain a fractional part.

  read_timeout => 3.5,

Not set by default.

=item lazy => $boolean

If enabled, the connection establishes at time when you will send the first
command to the server. By default the connection establishes after calling of
the C<new> method.

Disabled by default.

=item reconnect => $boolean

If the connection to the server was lost and the parameter C<reconnect> is
TRUE (default), the client will try to restore the connection when you execute
next command. The client will try to reconnect only once and, if attempt fails,
the error object is passed to command callback. If you need several attempts of
the reconnection, you must retry a command from the callback as many times, as
you need. Such behavior allows to control reconnection procedure.

Enabled by default.

=item reconnect_interval => $fractional_seconds

If the parameter is specified, the client will try to reconnect only after
this interval. Commands executed between reconnections will be queued.

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

=head1 COMMAND EXECUTION

=head2 <command>( [ @args ] [, $cb->( $reply, $err ) ] )

To execute the command you must call specific method with corresponding name.
The reply to the command is passed to the callback in first argument. If any
error occurred during the command execution, the error object is passed to the
callback in second argument. Error object is the instance of the class
L<AnyEvent::RipeRedis::Error>.

The command callback is optional. If it is not specified and any error
occurred, the C<on_error> callback of the client is called.

The full list of the Redis commands can be found here: L<http://redis.io/commands>.

  $redis->get( 'foo',
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        my $err_msg  = $err->message;
        my $err_code = $err->code;

        # error handling...

        return;
      }

      print "$reply\n";
    }
  );

  $redis->lrange( 'list', 0, -1,
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        my $err_msg  = $err->message;
        my $err_code = $err->code;

        # error handling...

        return;
      }

      foreach my $value ( @{$reply}  ) {
        print "$value\n";
      }
    }
  );

  $redis->incr( 'counter' );

You can execute multi-word commands like this:

  $redis->client_getname(
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        my $err_msg  = $err->message;
        my $err_code = $err->code;

        # error handling...

        return;
      }

      print "$reply\n";
    }
  );

=head2 execute( $command, [ @args ] [, $cb->( $reply, $err ) ] )

An alternative method to execute commands. In some cases it can be more
convenient.

  $redis->execute( 'get', 'foo',
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        my $err_msg  = $err->message;
        my $err_code = $err->code;

        return;
      }

      print "$reply\n";
    }
  );

=head1 TRANSACTIONS

The detailed information about the Redis transactions can be found here:
L<http://redis.io/topics/transactions>.

=head2 multi( [ $cb->( $reply, $err ) ] )

Marks the start of a transaction block. Subsequent commands will be queued for
atomic execution using C<EXEC>.

=head2 exec( [ $cb->( $reply, $err ) ] )

Executes all previously queued commands in a transaction and restores the
connection state to normal. When using C<WATCH>, C<EXEC> will execute commands
only if the watched keys were not modified.

If during a transaction at least one command fails, to the callback will be
passed error object, and the reply will be contain nested error objects for
every failed command.

  $redis->multi();
  $redis->set( 'foo', 'string' );
  $redis->incr('foo');    # causes an error
  $redis->exec(
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        my $err_msg  = $err->message();
        my $err_code = $err->code();

        if ( defined $reply ) {
          foreach my $nested_reply ( @{$reply} ) {
            if ( ref($nested_reply) eq 'AnyEvent::RipeRedis::Error' ) {
              my $nested_err_msg  = $nested_reply->message();
              my $nested_err_code = $nested_reply->code();

              # error handling...
            }
          }

          return;
        }

        # error handling...

        return;
      }

      # reply handling...
    },
  );

=head2 discard( [ $cb->( $reply, $err ) ] )

Flushes all previously queued commands in a transaction and restores the
connection state to normal.

If C<WATCH> was used, C<DISCARD> unwatches all keys.

=head2 watch( @keys [, $cb->( $reply, $err ) ] )

Marks the given keys to be watched for conditional execution of a transaction.

=head2 unwatch( [ $cb->( $reply, $err ) ] )

Forget about all watched keys.

=head1 SUBSCRIPTIONS

Once the client enters the subscribed state it is not supposed to issue any
other commands, except for additional C<SUBSCRIBE>, C<PSUBSCRIBE>,
C<UNSUBSCRIBE>, C<PUNSUBSCRIBE> and C<QUIT> commands.

The detailed information about Redis Pub/Sub can be found here:
L<http://redis.io/topics/pubsub>

=head2 subscribe( @channels, ( $cb->( $msg, $channel ) | \%cbs ) )

Subscribes the client to the specified channels.

Method can accept two callbacks: C<on_reply> and C<on_message>. The C<on_reply>
callback is called when subscription to all specified channels will be
activated. In first argument to the callback is passed the number of channels
we are currently subscribed. If subscription to specified channels was lost,
the C<on_reply> callback is called with the error object in the second argument.

The C<on_message> callback is called on every published message. If the
C<subscribe> method is called with one callback, this callback will be act as
C<on_message> callback.

  $redis->subscribe( qw( foo bar ),
    { on_reply => sub {
        my $channels_num = shift;
        my $err          = shift;

        if ( defined $err ) {
          # error handling...

          return;
        }

        # reply handling...
      },

      on_message => sub {
        my $msg     = shift;
        my $channel = shift;

        # message handling...
      },
    }
  );

  $redis->subscribe( qw( foo bar ),
    sub {
      my $msg     = shift;
      my $channel = shift;

      # message handling...
    }
  );

=head2 psubscribe( @patterns, ( $cb->( $msg, $pattern, $channel ) | \%cbs ) )

Subscribes the client to the given patterns. See C<subscribe()> method for
details.

  $redis->psubscribe( qw( foo_* bar_* ),
    { on_reply => sub {
        my $channels_num = shift;
        my $err          = shift;

        if ( defined $err ) {
          # error handling...

          return;
        }

        # reply handling...
      },

      on_message => sub {
        my $msg     = shift;
        my $pattern = shift;
        my $channel = shift;

        # message handling...
      },
    }
  );

  $redis->psubscribe( qw( foo_* bar_* ),
    sub {
      my $msg     = shift;
      my $pattern = shift;
      my $channel = shift;

      # message handling...
    }
  );

=head2 publish( $channel, $message [, $cb->( $reply, $err ) ] )

Posts a message to the given channel.

=head2 unsubscribe( [ @channels ] [, $cb->( $reply, $err ) ] )

Unsubscribes the client from the given channels, or from all of them if none
is given. In first argument to the callback is passed the number of channels we
are currently subscribed or zero if we were unsubscribed from all channels.

  $redis->unsubscribe( qw( foo bar ),
    sub {
      my $channels_num = shift;
      my $err          = shift;

      if ( defined $err ) {
        # error handling...

        return;
      }

      # reply handling...
    }
  );

=head2 punsubscribe( [ @patterns ] [, $cb->( $reply, $err ) ] )

Unsubscribes the client from the given patterns, or from all of them if none
is given. See C<unsubscribe()> method for details.


  $redis->punsubscribe( qw( foo_* bar_* ),
    sub {
      my $channels_num = shift;
      my $err          = shift;

      if ( defined $err ) {
        # error handling...

        return;
      }

      # reply handling...
    }
  );

=head1 CONNECTION VIA UNIX-SOCKET

Redis 2.2 and higher support connection via UNIX domain socket. To connect via
a UNIX-socket in the parameter C<host> you have to specify C<unix/>, and in
the parameter C<port> you have to specify the path to the socket.

  my $redis = AnyEvent::RipeRedis->new(
    host => 'unix/',
    port => '/tmp/redis.sock',
  );

=head1 LUA SCRIPTS EXECUTION

Redis 2.6 and higher support execution of Lua scripts on the server side.
To execute a Lua script you can send one of the commands C<EVAL> or C<EVALSHA>,
or use the special method C<eval_cached()>.

=head2 eval_cached( $script, $keys_num [, @keys ] [, @args ] [, $cb->( $reply, $err ) ] ] );

When you call the C<eval_cached()> method, the client first generate a SHA1
hash for a Lua script and cache it in memory. Then the client optimistically
send the C<EVALSHA> command under the hood. If the C<E_NO_SCRIPT> error will be
returned, the client send the C<EVAL> command.

If you call the C<eval_cached()> method with the same Lua script, client don not
generate a SHA1 hash for this script repeatedly, it gets a hash from the cache
instead.

  $redis->eval_cached( 'return { KEYS[1], KEYS[2], ARGV[1], ARGV[2] }',
      2, 'key1', 'key2', 'first', 'second',
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        # error handling...

        return;
      }

      foreach my $value ( @{$reply}  ) {
        print "$value\n";
      }
    }
  );

Be care, passing a different Lua scripts to C<eval_cached()> method every time
cause memory leaks.

If Lua script returns multi-bulk reply with at least one error reply, to the
callback will be passed error object, and the reply will be contain nested
error objects.

  $redis->eval_cached( "return { 'foo', redis.error_reply( 'Error.' ) }", 0,
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        my $err_msg  = $err->message;
        my $err_code = $err->code;

        if ( defined $reply ) {
          foreach my $nested_reply ( @{$reply} ) {
            if ( ref($nested_reply) eq 'AnyEvent::RipeRedis::Error' ) {
              my $nested_err_msg  = $nested_reply->message();
              my $nested_err_code = $nested_reply->code();

              # error handling...
            }
          }
        }

        # error handling...

        return;
      }

      # reply handling...
    }
  );

=head1 ERROR CODES

Every error object, passed to callback, contain error code, which can be used
for programmatic handling of errors. AnyEvent::RipeRedis provides constants for
error codes. They can be imported and used in expressions.

  use AnyEvent::RipeRedis qw( :err_codes );

=over

=item E_CANT_CONN

Can't connect to the server. All operations were aborted.

=item E_LOADING_DATASET

Redis is loading the dataset in memory.

=item E_IO

Input/Output operation error. The connection to the Redis server was closed and
all operations were aborted.

=item E_CONN_CLOSED_BY_REMOTE_HOST

The connection closed by remote host. All operations were aborted.

=item E_CONN_CLOSED_BY_CLIENT

Connection closed by client prematurely. Uncompleted operations were aborted.

=item E_NO_CONN

No connection to the Redis server. Connection was lost by any reason on previous
operation.

=item E_OPRN_ERROR

Operation error. For example, wrong number of arguments for a command.

=item E_UNEXPECTED_DATA

The client received unexpected reply from the server. The connection to the Redis
server was closed and all operations were aborted.

=item E_READ_TIMEDOUT

Read timed out. The connection to the Redis server was closed and all operations
were aborted.

=back

Error codes available since Redis 2.6.

=over

=item E_NO_SCRIPT

No matching script. Use the C<EVAL> command.

=item E_BUSY

Redis is busy running a script. You can only call C<SCRIPT KILL>
or C<SHUTDOWN NOSAVE>.

=item E_NOT_BUSY

No scripts in execution right now.

=item E_MASTER_DOWN

Link with MASTER is down and slave-serve-stale-data is set to 'no'.

=item E_MISCONF

Redis is configured to save RDB snapshots, but is currently not able to persist
on disk. Commands that may modify the data set are disabled. Please check Redis
logs for details about the error.

=item E_READONLY

You can't write against a read only slave.

=item E_OOM

Command not allowed when used memory > 'maxmemory'.

=item E_EXEC_ABORT

Transaction discarded because of previous errors.

=back

Error codes available since Redis 2.8.

=over

=item E_NO_AUTH

Authentication required.

=item E_WRONG_TYPE

Operation against a key holding the wrong kind of value.

=item E_NO_REPLICAS

Not enough good slaves to write.

=item E_BUSY_KEY

Target key name already exists.

=back

Error codes available since Redis 3.0.

=over

=item E_CROSS_SLOT

Keys in request don't hash to the same slot.

=item E_TRY_AGAIN

Multiple keys request during rehashing of slot.

=item E_ASK

Redirection required. For more information see:
L<http://redis.io/topics/cluster-spec>

=item E_MOVED

Redirection required. For more information see:
L<http://redis.io/topics/cluster-spec>

=item E_CLUSTER_DOWN

The cluster is down or hash slot not served.

=back

=head1 DISCONNECTION

When the connection to the server is no longer needed you can close it in three
ways: call the method C<disconnect()>, send the C<QUIT> command or you can just
"forget" any references to an AnyEvent::RipeRedis object, but in this
case the client object is destroyed without calling any callbacks, including
the C<on_disconnect> callback, to avoid an unexpected behavior.

=head2 disconnect()

The method for synchronous disconnection. All uncompleted operations will be
aborted.

=head2 quit( [ $cb->( $reply, $err ) ] )

The method for asynchronous disconnection.

=head1 OTHER METHODS

=head2 info( [ $section ] [, $cb->( $reply, $err ) ] )

Gets and parses information and statistics about the server. The result
is passed to callback as a hash reference.

More information about C<INFO> command can be found here:
L<http://redis.io/commands/info>

=head2 host()

Gets current host of the client.

=head2 port()

Gets current port of the client.

=head2 select( $index, [, $cb->( $reply, $err ) ] )

Selects the database by numeric index.

=head2 database()

Gets selected database index.

=head2 utf8( [ $boolean ] )

Enables or disables UTF-8 mode.

=head2 connection_timeout( [ $fractional_seconds ] )

Gets or sets the C<connection_timeout> of the client. The C<undef> value resets
the C<connection_timeout> to default value.

=head2 read_timeout( [ $fractional_seconds ] )

Gets or sets the C<read_timeout> of the client.

=head2 reconnect( [ $boolean ] )

Enables or disables reconnection mode of the client.

=head2 reconnect_interval( [ $fractional_seconds ] )

Gets or sets C<reconnect_interval> of the client.

=head2 on_connect( [ $callback ] )

Gets or sets the C<on_connect> callback.

=head2 on_disconnect( [ $callback ] )

Gets or sets the C<on_disconnect> callback.

=head2 on_error( [ $callback ] )

Gets or sets the C<on_error> callback.

=head1 SEE ALSO

L<AnyEvent::RipeRedis::Cluster>, L<AnyEvent>, L<Redis::hiredis>, L<Redis>,
L<RedisDB>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

Sponsored by SMS Online, E<lt>dev.opensource@sms-online.comE<gt>

=head2 Special thanks

=over

=item *

Alexey Shrub

=item *

Vadim Vlasov

=item *

Konstantin Uvarin

=item *

Ivan Kruglov

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2021, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
