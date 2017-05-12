use 5.008000;
use strict;
use warnings;

package AnyEvent::Redis::RipeRedis;

use base qw( Exporter );

our $VERSION = '1.62';

use AnyEvent;
use AnyEvent::Handle;
use Encode qw( find_encoding is_utf8 );
use Scalar::Util qw( looks_like_number weaken );
use Digest::SHA qw( sha1_hex );
use Carp qw( croak );

my %ERROR_CODES;

BEGIN {
  %ERROR_CODES = (
    E_CANT_CONN                  => 1,
    E_LOADING_DATASET            => 2,
    E_IO                         => 3,
    E_CONN_CLOSED_BY_REMOTE_HOST => 4,
    E_CONN_CLOSED_BY_CLIENT      => 5,
    E_NO_CONN                    => 6,
    E_OPRN_ERROR                 => 9,
    E_UNEXPECTED_DATA            => 10,
    E_NO_SCRIPT                  => 11,
    E_READ_TIMEDOUT              => 12,
    E_BUSY                       => 13,
    E_MASTER_DOWN                => 14,
    E_MISCONF                    => 15,
    E_READONLY                   => 16,
    E_OOM                        => 17,
    E_EXEC_ABORT                 => 18,
    E_NO_AUTH                    => 19,
    E_WRONG_TYPE                 => 20,
    E_NO_REPLICAS                => 21,
    E_BUSY_KEY                   => 22,
    E_CROSS_SLOT                 => 23,
    E_TRY_AGAIN                  => 24,
    E_ASK                        => 25,
    E_MOVED                      => 26,
    E_CLUSTER_DOWN               => 27,
  );
}

BEGIN {
  our @EXPORT_OK   = keys %ERROR_CODES;
  our %EXPORT_TAGS = ( err_codes => \@EXPORT_OK, );
}

use constant {
  # Default values
  D_HOST     => 'localhost',
  D_PORT     => 6379,
  D_DB_INDEX => 0,

  %ERROR_CODES,

  # Operation status
  S_NEED_PERFORM => 1,
  S_IN_PROGRESS  => 2,
  S_IS_DONE      => 3,

  # String terminator
  EOL     => "\r\n",
  EOL_LEN => 2,
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

my %NEED_POSTPROCESS = (
  %SUBUNSUB_CMDS,
  info   => 1,
  select => 1,
  quit   => 1,
);

my %MSG_TYPES = (
  message  => 1,
  pmessage => 1,
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
);

my %EVAL_CACHE;


# Constructor
sub new {
  my $proto  = shift;
  my %params = @_;

  my $self = ref( $proto ) ? $proto : bless {}, $proto;

  $self->{host} = $params{host} || D_HOST;
  $self->{port} = $params{port} || D_PORT;
  $self->{password} = $params{password};
  $self->{database}
      = defined $params{database} ? $params{database} : D_DB_INDEX;
  $self->{reconnect} = exists $params{reconnect} ? $params{reconnect} : 1;
  $self->{on_connect}       = $params{on_connect};
  $self->{on_disconnect}    = $params{on_disconnect};
  $self->{on_connect_error} = $params{on_connect_error};

  $self->encoding( $params{encoding} );
  $self->connection_timeout( $params{connection_timeout} );
  $self->read_timeout( $params{read_timeout} );
  $self->min_reconnect_interval( $params{min_reconnect_interval} );
  $self->on_error( $params{on_error} );

  my $hdl_params = $params{handle_params} || {};
  foreach my $name ( qw( linger autocork ) ) {
    if ( !exists $hdl_params->{$name} && defined $params{$name} ) {
      $hdl_params->{$name} = $params{$name};
    }
  }
  $self->{handle_params} = $hdl_params;

  $self->{_handle}           = undef;
  $self->{_connected}        = 0;
  $self->{_lazy_conn_st}     = $params{lazy};
  $self->{_auth_st}          = S_NEED_PERFORM;
  $self->{_select_db_st}     = S_NEED_PERFORM;
  $self->{_ready_to_write}   = 0;
  $self->{_input_queue}      = [];
  $self->{_temp_queue}       = [];
  $self->{_processing_queue} = [];
  $self->{_txn_lock}         = 0;
  $self->{_channels}         = {};
  $self->{_channel_cnt}      = 0;
  $self->{_reconnect_timer}  = undef;

  unless ( $self->{_lazy_conn_st} ) {
    $self->_connect();
  }

  return $self;
}

sub multi {
  my $self = shift;
  my $cmd  = $self->_prepare_cmd( 'multi', [ @_ ] );

  $self->{_txn_lock} = 1;
  $self->_execute_cmd( $cmd );

  return;
}

sub exec {
  my $self = shift;
  my $cmd  = $self->_prepare_cmd( 'exec', [ @_ ] );

  $self->{_txn_lock} = 0;
  $self->_execute_cmd( $cmd );

  return;
}

sub eval_cached {
  my $self = shift;
  my $cmd  = $self->_prepare_cmd( 'evalsha', [ @_ ] );

  $cmd->{script} = $cmd->{args}[0];
  unless ( exists $EVAL_CACHE{ $cmd->{script} } ) {
    $EVAL_CACHE{ $cmd->{script} } = sha1_hex( $cmd->{script} );
  }
  $cmd->{args}[0] = $EVAL_CACHE{ $cmd->{script} };

  $self->_execute_cmd( $cmd );

  return;
}

sub disconnect {
  my $self = shift;

  $self->_disconnect();

  return;
}

sub encoding {
  my $self = shift;

  if ( @_ ) {
    my $enc = shift;

    if ( defined $enc ) {
      $self->{encoding} = find_encoding( $enc );

      unless ( defined $self->{encoding} ) {
        croak "Encoding \"$enc\" not found";
      }
    }
    else {
      undef $self->{encoding};
    }
  }

  return $self->{encoding};
}

sub on_error {
  my $self = shift;

  if ( @_ ) {
    my $on_error = shift;

    if ( defined $on_error ) {
      $self->{on_error} = $on_error;
    }
    else {
      $self->{on_error} = sub {
        my $err_msg = shift;

        warn "$err_msg\n";
      };
    }
  }

  return $self->{on_error};
}

sub selected_database {
  my $self = shift;

  return $self->{database};
}

# Generate additional methods and accessors
{
  no strict 'refs';

  foreach my $kwd ( keys %SUBUNSUB_CMDS ) {
    *{$kwd} = sub {
      my $self = shift;
      my $cmd  = $self->_prepare_cmd( $kwd, [ @_ ] );

      if ( exists $SUB_CMDS{ $cmd->{kwd} } && !defined $cmd->{on_message} ) {
        croak "\"on_message\" callback must be specified";
      }

      if ( $self->{_txn_lock} ) {
        AE::postpone(
          sub {
            $self->_process_cmd_error( $cmd,
                "Command \"$cmd->{kwd}\" not allowed after \"multi\" command."
                    . ' First, the transaction must be finalized.',
                E_OPRN_ERROR );
          }
        );

        return;
      }

      $cmd->{replies_cnt} = scalar @{ $cmd->{args} };

      if ( defined $cmd->{on_done} ) {
        my $on_done = $cmd->{on_done};

        $cmd->{on_done} = sub {
          $on_done->( @{ $_[0] } );
        }
      }

      $self->_execute_cmd( $cmd );

      return;
    },
  }

  foreach my $name ( qw( connection_timeout read_timeout min_reconnect_interval ) ) {
    *{$name} = sub {
      my $self = shift;

      if ( @_ ) {
        my $seconds = shift;

        if ( defined $seconds
          && ( !looks_like_number($seconds) || $seconds < 0 ) )
        {
          croak "\"$name\" must be a positive number";
        }
        $self->{$name} = $seconds;
      }

      return $self->{$name};
    }
  }

  foreach my $name ( qw( reconnect on_connect on_disconnect on_connect_error ) ) {
    *{$name} = sub {
      my $self = shift;

      if ( @_ ) {
        $self->{$name} = shift;
      }

      return $self->{$name};
    }
  }
}

sub _connect {
  my $self = shift;

  $self->{_handle} = AnyEvent::Handle->new(
    %{ $self->{handle_params} },
    connect          => [ $self->{host}, $self->{port} ],
    on_prepare       => $self->_get_on_prepare(),
    on_connect       => $self->_get_on_connect(),
    on_connect_error => $self->_get_on_connect_error(),
    on_rtimeout      => $self->_get_on_rtimeout(),
    on_eof           => $self->_get_on_eof(),
    on_error         => $self->_get_handle_on_error(),
    on_read          => $self->_get_on_read(),
  );

  return;
}

sub _get_on_prepare {
  my $self = shift;

  weaken( $self );

  return sub {
    if ( defined $self->{connection_timeout} ) {
      return $self->{connection_timeout};
    }

    return;
  };
}

sub _get_on_connect {
  my $self = shift;

  weaken( $self );

  return sub {
    $self->{_connected} = 1;

    unless ( defined $self->{password} ) {
      $self->{_auth_st} = S_IS_DONE;
    }
    if ( $self->{database} == 0 ) {
      $self->{_select_db_st} = S_IS_DONE;
    }

    if ( $self->{_auth_st} == S_NEED_PERFORM ) {
      $self->_auth();
    }
    elsif ( $self->{_select_db_st} == S_NEED_PERFORM ) {
      $self->_select_db();
    }
    else {
      $self->{_ready_to_write} = 1;
      $self->_flush_input_queue();
    }

    if ( defined $self->{on_connect} ) {
      $self->{on_connect}->();
    }
  };
}

sub _get_on_connect_error {
  my $self = shift;

  weaken( $self );

  return sub {
    my $err_msg = pop;

    $self->_disconnect(
      "Can't connect to $self->{host}:$self->{port}: $err_msg",
      E_CANT_CONN
    );
  };
}

sub _get_on_rtimeout {
  my $self = shift;

  weaken( $self );

  return sub {
    if ( @{ $self->{_processing_queue} } ) {
      $self->_disconnect( 'Read timed out.', E_READ_TIMEDOUT );
    }
    else {
      $self->{_handle}->rtimeout( undef );
    }
  };
}

sub _get_on_eof {
  my $self = shift;

  weaken( $self );

  return sub {
    $self->_disconnect( 'Connection closed by remote host.',
        E_CONN_CLOSED_BY_REMOTE_HOST );
  };
}

sub _get_handle_on_error {
  my $self = shift;

  weaken( $self );

  return sub {
    my $err_msg = pop;

    $self->_disconnect( $err_msg, E_IO );
  };
}

sub _get_on_read {
  my $self = shift;

  weaken( $self );

  my $str_len;
  my @bufs;
  my $bufs_num = 0;

  return sub {
    my $handle = shift;

    MAIN: while ( 1 ) {
      if ( $handle->destroyed() ) {
        return;
      }

      my $reply;
      my $err_code;

      if ( defined $str_len ) {
        if ( length( $handle->{rbuf} ) < $str_len + EOL_LEN ) {
          return;
        }

        $reply = substr( $handle->{rbuf}, 0, $str_len, '' );
        substr( $handle->{rbuf}, 0, EOL_LEN, '' );
        if ( defined $self->{encoding} ) {
          $reply = $self->{encoding}->decode( $reply );
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
        substr( $handle->{rbuf}, 0, EOL_LEN, '' );

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
                { data       => [],
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
            $self->_disconnect( 'Unexpected reply received.',
                E_UNEXPECTED_DATA );

            return;
          }
        }
      }

      while ( $bufs_num > 0 ) {
        my $curr_buf = $bufs[-1];
        if ( defined $err_code ) {
          unless ( ref($reply) ) {
            $reply
                = AnyEvent::Redis::RipeRedis::Error->new( $reply, $err_code );
          }
          $curr_buf->{err_code} = E_OPRN_ERROR;
        }
        push( @{ $curr_buf->{data} }, $reply );
        if ( --$curr_buf->{chunks_cnt} > 0 ) {
          next MAIN;
        }

        $reply    = $curr_buf->{data};
        $err_code = $curr_buf->{err_code};
        pop @bufs;
        $bufs_num--;
      }

      $self->_process_reply( $reply, $err_code );
    }

    return;
  };
}

sub _prepare_cmd {
  my $self = shift;
  my $kwd  = shift;
  my $args = shift;

  my $cmd;
  if ( ref( $args->[-1] ) eq 'HASH' ) {
    $cmd = pop @{$args};
  }
  else {
    $cmd = {};
    if ( ref( $args->[-1] ) eq 'CODE' ) {
      if ( exists $SUB_CMDS{$kwd} ) {
        $cmd->{on_message} = pop @{$args};
      }
      else {
        $cmd->{on_reply} = pop @{$args};
      }
    }
  }
  $cmd->{kwd}  = $kwd;
  $cmd->{args} = $args;

  return $cmd;
}

sub _execute_cmd {
  my $self = shift;
  my $cmd  = shift;

  unless ( $self->{_ready_to_write} ) {
    if ( defined $self->{_handle} ) {
      if ( $self->{_connected} ) {
        if ( $self->{_auth_st} == S_IS_DONE ) {
          if ( $self->{_select_db_st} == S_NEED_PERFORM ) {
            $self->_select_db();
          }
        }
        elsif ( $self->{_auth_st} == S_NEED_PERFORM ) {
          $self->_auth();
        }
      }
    }
    elsif ( $self->{_lazy_conn_st} ) {
      $self->{_lazy_conn_st} = 0;
      $self->_connect();
    }
    elsif ( $self->{reconnect} ) {
      if ( defined $self->{min_reconnect_interval}
        && $self->{min_reconnect_interval} > 0 )
      {
        unless ( defined $self->{_reconnect_timer} ) {
          $self->{_reconnect_timer} = AE::timer( $self->{min_reconnect_interval}, 0,
            sub {
              undef $self->{_reconnect_timer};
              $self->_connect();
            }
          );
        }
      }
      else {
        $self->_connect();
      }
    }
    else {
      AE::postpone(
        sub {
          $self->_process_cmd_error( $cmd, "Operation \"$cmd->{kwd}\" aborted:"
              . ' No connection to the server.', E_NO_CONN );
        }
      );

      return;
    }

    push( @{ $self->{_input_queue} }, $cmd );

    return;
  }

  $self->_push_write( $cmd );

  return;
}

sub _push_write {
  my $self = shift;
  my $cmd  = shift;

  my $cmd_str = '';
  foreach my $token ( $cmd->{kwd}, @{ $cmd->{args} } ) {
    unless ( defined $token ) {
      $token = '';
    }
    elsif ( defined $self->{encoding} && is_utf8( $token ) ) {
      $token = $self->{encoding}->encode( $token );
    }
    $cmd_str .= '$' . length( $token ) . EOL . $token . EOL;
  }
  $cmd_str = '*' . ( scalar( @{ $cmd->{args} } ) + 1 ) . EOL . $cmd_str;

  my $handle = $self->{_handle};
  if ( defined $self->{read_timeout} && !@{ $self->{_processing_queue} } ) {
    $handle->rtimeout_reset();
    $handle->rtimeout( $self->{read_timeout} );
  }
  push( @{ $self->{_processing_queue} }, $cmd );

  $handle->push_write( $cmd_str );

  return;
}

sub _auth {
  my $self = shift;

  weaken( $self );

  $self->{_auth_st} = S_IN_PROGRESS;

  $self->_push_write(
    { kwd  => 'auth',
      args => [ $self->{password} ],

      on_done => sub {
        $self->{_auth_st} = S_IS_DONE;

        if ( $self->{_select_db_st} == S_NEED_PERFORM ) {
          $self->_select_db();
        }
        else {
          $self->{_ready_to_write} = 1;
          $self->_flush_input_queue();
        }
      },

      on_error => sub {
        $self->{_auth_st} = S_NEED_PERFORM;
        $self->_abort_all( @_ );
      },
    }
  );

  return;
}

sub _select_db {
  my $self = shift;

  weaken( $self );

  $self->{_select_db_st} = S_IN_PROGRESS;

  $self->_push_write(
    { kwd  => 'select',
      args => [ $self->{database} ],

      on_done => sub {
        $self->{_select_db_st}   = S_IS_DONE;
        $self->{_ready_to_write} = 1;
        $self->_flush_input_queue();
      },

      on_error => sub {
        $self->{_select_db_st} = S_NEED_PERFORM;
        $self->_abort_all( @_ );
      },
    }
  );

  return;
}

sub _flush_input_queue {
  my $self = shift;

  $self->{_temp_queue}  = $self->{_input_queue};
  $self->{_input_queue} = [];

  while ( my $cmd = shift @{ $self->{_temp_queue} } ) {
    $self->_push_write( $cmd );
  }

  return;
}

sub _process_reply {
  my $self     = shift;
  my $reply    = shift;
  my $err_code = shift;

  if ( defined $err_code ) {
    my $cmd = shift @{ $self->{_processing_queue} };

    unless ( defined $cmd ) {
      $self->_disconnect(
        "Don't know how process error message. Processing queue is empty.",
        E_UNEXPECTED_DATA,
      );

      return;
    }

    $self->_process_cmd_error( $cmd, ref($reply)
        ? ( "Operation \"$cmd->{kwd}\" completed with errors.",
            $err_code, $reply )
        : $reply, $err_code );
  }
  elsif ( $self->{_channel_cnt} > 0
    && ref( $reply ) && exists $MSG_TYPES{ $reply->[0] } )
  {
    my $cmd = $self->{_channels}{ $reply->[1] };

    unless ( defined $cmd ) {
      $self->_disconnect(
        "Don't know how process published message."
            . " Unknown channel or pattern \"$reply->[1]\".",
        E_UNEXPECTED_DATA
      );

      return;
    }

    $cmd->{on_message}->( $reply->[0] eq 'pmessage'
        ? @{$reply}[ 2, 3, 1 ] : @{$reply}[ 1, 2 ] );
  }
  else {
    my $cmd = $self->{_processing_queue}[0];

    unless ( defined $cmd ) {
      $self->_disconnect(
        "Don't know how process reply. Processing queue is empty.",
        E_UNEXPECTED_DATA
      );

      return;
    }

    if ( !defined $cmd->{replies_cnt} || --$cmd->{replies_cnt} <= 0 ) {
      shift @{ $self->{_processing_queue} };
    }
    $self->_process_cmd_success( $cmd, $reply );
  }

  return;
}

sub _process_cmd_error {
  my $self = shift;
  my $cmd  = shift;

  if ( $_[1] == E_NO_SCRIPT && defined $cmd->{script} ) {
    $cmd->{kwd}     = 'eval';
    $cmd->{args}[0] = delete $cmd->{script};

    $self->_push_write( $cmd );

    return;
  }

  if ( defined $cmd->{on_error} ) {
    $cmd->{on_error}->( @_ );
  }
  elsif ( defined $cmd->{on_reply} ) {
    $cmd->{on_reply}->( @_[ 2, 0, 1 ] );
  }
  else {
    $self->{on_error}->( @_ );
  }

  return;
}

sub _process_cmd_success {
  my $self  = shift;
  my $cmd   = shift;
  my $reply = shift;

  if ( exists $NEED_POSTPROCESS{ $cmd->{kwd} } ) {
    my $kwd = $cmd->{kwd};

    if ( exists $SUBUNSUB_CMDS{$kwd} ) {
      shift @{$reply};

      if ( exists $SUB_CMDS{$kwd} ) {
        $self->{_channels}{ $reply->[0] } = $cmd;
      }
      else { # unsubscribe or punsubscribe
        delete $self->{_channels}{ $reply->[0] };
      }

      $self->{_channel_cnt} = $reply->[1];
    }
    elsif ( $kwd eq 'info' ) {
      $reply = $self->_parse_info( $reply );
    }
    elsif ( $kwd eq 'select' ) {
      $self->{database} = $cmd->{args}[0];
    }
    else { # quit
      $self->_disconnect();
    }
  }

  if ( defined $cmd->{on_done} ) {
    $cmd->{on_done}->( $reply );
  }
  elsif ( defined $cmd->{on_reply} ) {
    $cmd->{on_reply}->( $reply );
  }

  return;
}

sub _parse_info {
  return {
    map { split( m/:/, $_, 2 ) }
    grep { m/^[^#]/ } split( EOL, $_[1] )
  };
}

sub _disconnect {
  my $self     = shift;
  my $err_msg  = shift;
  my $err_code = shift;

  my $was_connected = $self->{_connected};

  if ( defined $self->{_handle} ) {
    $self->{_handle}->destroy();
    undef $self->{_handle};
  }
  $self->{_connected}      = 0;
  $self->{_auth_st}        = S_NEED_PERFORM;
  $self->{_select_db_st}   = S_NEED_PERFORM;
  $self->{_ready_to_write} = 0;
  $self->{_txn_lock}       = 0;

  $self->_abort_all( $err_msg, $err_code );

  if ( $was_connected && defined $self->{on_disconnect} ) {
    $self->{on_disconnect}->();
  }

  return;
}

sub _abort_all {
  my $self     = shift;
  my $err_msg  = shift;
  my $err_code = shift;

  my @unfin_cmds = (
    @{ $self->{_processing_queue} },
    @{ $self->{_temp_queue} },
    @{ $self->{_input_queue} },
  );

  my %channels = %{ $self->{_channels} };

  $self->{_input_queue}      = [];
  $self->{_temp_queue}       = [];
  $self->{_processing_queue} = [];
  $self->{_channels}         = {};
  $self->{_channel_cnt}      = 0;

  if ( !defined $err_msg && @unfin_cmds ) {
    $err_msg  = 'Connection closed by client prematurely.';
    $err_code = E_CONN_CLOSED_BY_CLIENT;
  }

  if ( defined $err_msg ) {
    if ( defined $self->{on_connect_error} && $err_code == E_CANT_CONN ) {
      $self->{on_connect_error}->( $err_msg );
    }
    else {
      $self->{on_error}->( $err_msg, $err_code );
    }

    if ( %channels && $err_code != E_CONN_CLOSED_BY_CLIENT ) {
      foreach my $name ( keys %channels ) {
        my $cmd = $channels{$name};
        $self->_process_cmd_error( $cmd, "Subscription \"$name\" lost: "
            . $err_msg, $err_code );
      }
    }
    foreach my $cmd ( @unfin_cmds ) {
      $self->_process_cmd_error( $cmd, "Operation \"$cmd->{kwd}\" aborted: "
          . $err_msg, $err_code );
    }
  }

  return;
}

sub AUTOLOAD {
  our $AUTOLOAD;
  my $method = $AUTOLOAD;
  $method =~ s/^.+:://;
  my ( $kwd, @args ) = split( m/_/, lc( $method ) );

  my $sub = sub {
    my $self = shift;
    my $cmd  = $self->_prepare_cmd( $kwd, [ @args, @_ ] );

    $self->_execute_cmd( $cmd );

    return;
  };

  do {
    no strict 'refs';
    *{$method} = $sub;
  };

  goto &{$sub};
}

sub DESTROY {
  my $self = shift;

  if ( defined $self->{_handle} ) {
    my @unfin_cmds = (
      @{ $self->{_processing_queue} },
      @{ $self->{_temp_queue} },
      @{ $self->{_input_queue} },
    );

    foreach my $cmd ( @unfin_cmds ) {
      warn "Operation \"$cmd->{kwd}\" aborted:"
          . " Client object destroyed prematurely.\n";
    }
  }

  return;
}


package AnyEvent::Redis::RipeRedis::Error;

# Constructor
sub new {
  my $class    = shift;
  my $err_msg  = shift;
  my $err_code = shift;

  my $self = bless {}, $class;

  $self->{message} = $err_msg;
  $self->{code}    = $err_code;

  return $self;
}

sub message {
  my $self = shift;

  return $self->{message};
}

sub code {
  my $self = shift;

  return $self->{code};
}

1;
__END__

=head1 NAME

AnyEvent::Redis::RipeRedis - DEPRECATED. Use AnyEvent::RipeRedis instead

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Redis::RipeRedis;

  my $cv = AE::cv();

  my $redis = AnyEvent::Redis::RipeRedis->new(
    host     => 'localhost',
    port     => 6379,
    password => 'yourpass',
  );

  $redis->incr( 'foo',
    sub {
      my $reply = shift;

      if (@_) {
        my $err_msg  = shift;
        my $err_code = shift;

        warn "[$err_code] $err_msg\n";

        return;
      }

      print "$reply\n";
    }
  );

  $redis->set( 'bar', 'string',
    { on_error => sub {
        my $err_msg  = shift;
        my $err_code = shift;

        warn "[$err_code] $err_msg\n";
      }
    }
  );

  $redis->get( 'bar',
    { on_done => sub {
        my $reply = shift;

        print "$reply\n";
      },

      on_error => sub {
        my $err_msg  = shift;
        my $err_code = shift;

        warn "[$err_code] $err_msg\n";
      },
    }
  );

  $redis->quit(
    sub {
      my $reply = shift;

      if (@_) {
        my $err_msg  = shift;
        my $err_code = shift;

        warn "[$err_code] $err_msg\n";
      }

      $cv->send();
    }
  );

  $cv->recv();

=head1 DESCRIPTION

MODULE IS DEPRECATED. Use L<AnyEvent::RipeRedis> instead. The interface of
L<AnyEvent::RipeRedis> has several differences from interface of
AnyEvent::Redis::RipeRedis. For more information see documentation.

AnyEvent::Redis::RipeRedis is the flexible non-blocking Redis client with
reconnect feature. The client supports subscriptions, transactions and connection
via UNIX-socket.

Requires Redis 1.2 or higher, and any supported event loop.

=head1 CONSTRUCTOR

=head2 new( %params )

  my $redis = AnyEvent::Redis::RipeRedis->new(
    host                   => 'localhost',
    port                   => 6379,
    password               => 'yourpass',
    database               => 7,
    lazy                   => 1,
    connection_timeout     => 5,
    read_timeout           => 5,
    reconnect              => 1,
    min_reconnect_interval => 5,
    encoding               => 'utf8',

    on_connect => sub {
      # handling...
    },

    on_disconnect => sub {
      # handling...
    },

    on_connect_error => sub {
      my $err_msg = shift;

      # error handling...
    },

    on_error => sub {
      my $err_msg  = shift;
      my $err_code = shift;

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

Database index. If the index is specified, the client is switched to
the specified database after connection. You can also switch to another database
after connection by using C<SELECT> command. The client remembers last selected
database after reconnection.

The default database index is C<0>.

=item encoding => $encoding_name

Used for encode/decode strings at time of input/output operations.

Not set by default.

=item connection_timeout => $fractional_seconds

Specifies connection timeout. If the client could not connect to the server
after specified timeout, the C<on_error> or C<on_connect_error> callback is
called. In case when C<on_error> callback is called, C<E_CANT_CONN> error code
is passed to callback in the second argument. The timeout specifies in seconds
and can contain a fractional part.

  connection_timeout => 10.5,

By default the client use kernel's connection timeout.

=item read_timeout => $fractional_seconds

Specifies read timeout. If the client could not receive a reply from the
server after specified timeout, the client close connection and call the
C<on_error> callback with the C<E_READ_TIMEDOUT> error code. The timeout is
specifies in seconds and can contain a fractional part.

  read_timeout => 3.5,

Not set by default.

=item lazy => $boolean

If enabled, the connection establishes at time when you will send the first
command to the server. By default the connection establishes after calling of
the C<new> method.

Disabled by default.

=item reconnect => $boolean

If the connection to the Redis server was lost and the parameter C<reconnect> is
TRUE, the client try to restore the connection on a next command executuion
unless C<min_reconnect_interval> is specified. The client try to reconnect only
once and if it fails, is called the C<on_error> callback. If you need several
attempts of the reconnection, just retry a command from the C<on_error>
callback as many times, as you need. This feature made the client more
responsive.

Enabled by default.

=item min_reconnect_interval => $fractional_seconds

If the parameter is specified, the client will try to reconnect not often than
after this interval.

  min_reconnect_interval => 5,

Not set by default.

=item handle_params => \%params

Specifies L<AnyEvent::Handle> parameters.

  handle_params => {
    autocork => 1,
    linger   => 60,
  }

=item linger => $fractional_seconds

Parameter is DEPRECATED. Use C<handle_params> parameter instead.

This option is in effect when, for example, code terminates connection by calling
C<disconnect> but there are ongoing operations. In this case destructor of
underlying L<AnyEvent::Handle> object will keep the write buffer in memory for
long time (see default value) causing temporal 'memory leak'. See
L<AnyEvent::Handle> for more information.

By default is applied default setting of L<AnyEvent::Handle> (i.e. 3600 seconds).

=item autocork => $boolean

Parameter is DEPRECATED. Use C<handle_params> parameter instead.

When enabled, writes to socket will always be queued till the next event loop
iteration. This is efficient when you execute many operations per iteration, but
less efficient when you execute a single operation only per iteration (or when
the write buffer often is full). It also increases operation latency. See
L<AnyEvent::Handle> for more information.

Disabled by default.

=item on_connect => $cb->()

The C<on_connect> callback is called when the connection is successfully
established.

Not set by default.

=item on_disconnect => $cb->()

The C<on_disconnect> callback is called when the connection is closed by any
reason.

Not set by default.

=item on_connect_error => $cb->( $err_msg )

The C<on_connect_error> callback is called, when the connection could not be
established. If this collback isn't specified, the common C<on_error> callback
is called with the C<E_CANT_CONN> error code.

Not set by default.

=item on_error => $cb->( $err_msg, $err_code )

The common C<on_error> callback is called when ocurred some error, which was
affected on whole client (e. g. connection error). Also this callback is called
on other errors if neither C<on_error> callback nor C<on_reply> callback is
specified in the command method. If common C<on_error> callback is not specified,
the client just print an error messages to C<STDERR>.

=back

=head1 COMMAND EXECUTION

=head2 <command>( [ @args ] [, $cb | \%cbs ] )

The full list of the Redis commands can be found here: L<http://redis.io/commands>.

  $redis->incr( 'foo',
    sub {
      my $reply = shift;

      if (@_) {
        my $err_msg  = shift;
        my $err_code = shift;

        # error handling...

        return;
      }

      print "$reply\n";
    },
  );

  $redis->incr( 'foo',
    { on_reply => sub {
        my $reply = shift;

        if (@_) {
          my $err_msg  = shift;
          my $err_code = shift;

          # error handling...

          return;
        }

        print "$reply\n";
      },
    }
  );

  $redis->set( 'bar', 'string' );

  $redis->get( 'bar',
    { on_done => sub {
        my $reply = shift;

        print "$reply\n";
      },

      on_error => sub {
        my $err_msg  = shift;
        my $err_code = shift;

        # error handling...
      }
    }
  );

  $redis->lrange( 'list', 0, -1,
    { on_done => sub {
        my $reply = shift;

        foreach my $val ( @{$reply}  ) {
          print "$val\n";
        }
      },

      on_error => sub {
        my $err_msg  = shift;
        my $err_code = shift;

        # error handling...
      },
    }
  );

=over

=item on_done => $cb->( [ $reply ] )

The C<on_done> callback is called when the current operation was completed
successfully.

=item on_error => $cb->( $err_msg, $err_code )

The C<on_error> callback is called when some error occurred.

=item on_reply => $cb->( [ $reply ] [, $err_msg, $err_code ] )

Since version 1.300 of the client you can specify single, C<on_reply> callback,
instead of two, C<on_done> and C<on_error> callbacks. The C<on_reply> callback
is called in both cases: when operation was completed successfully or when some
error occurred. In first case to callback is passed only reply data. In second
case to callback is passed three arguments: The C<undef> value or reply data
with error objects (see below), error message and error code.

=back

=head1 TRANSACTIONS

The detailed information abount the Redis transactions can be found here:
L<http://redis.io/topics/transactions>.

=head2 multi( [ $cb | \%cbs ] )

Marks the start of a transaction block. Subsequent commands will be queued for
atomic execution using C<EXEC>.

=head2 exec( [ $cb | \%cbs ] )

Executes all previously queued commands in a transaction and restores the
connection state to normal. When using C<WATCH>, C<EXEC> will execute commands
only if the watched keys were not modified.

If after execution of C<EXEC> command at least one operation fails, the
C<on_error> or C<on_reply> callback is called and in addition to error message
and error code to callback is passed reply data, which contain replies of
successful operations and error objects for each failed operation. To
C<on_error> callback reply data is passed in third argument and to C<on_reply>
callback in first argument. Error object is an instance of class
C<AnyEvent::Redis::RipeRedis::Error> and has two methods: C<message()> to get
error message and C<code()> to get error code.

  $redis->multi();
  $redis->set( 'foo', 'string' );
  $redis->incr( 'foo' ); # causes an error
  $redis->exec(
    sub {
      my $reply = shift;

      if (@_) {
        my $err_msg  = shift;
        my $err_code = shift;

        if ( defined $reply ) {
          foreach my $nested_reply ( @{$reply} ) {
            if ( ref($nested_reply) eq 'AnyEvent::Redis::RipeRedis::Error' ) {
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

  $redis->multi();
  $redis->set( 'foo', 'string' );
  $redis->incr( 'foo' ); # causes an error
  $redis->exec(
    { on_done => sub {
        my $reply = shift;

        # handling...
      },

      on_error => sub {
        my $err_msg  = shift;
        my $err_code = shift;
        my $reply    = shift;

        if ( defined $reply ) {
          foreach my $nested_reply ( @{$reply} ) {
            if ( ref($nested_reply) eq 'AnyEvent::Redis::RipeRedis::Error' ) {
              my $nested_err_msg  = $nested_reply->message();
              my $nested_err_code = $nested_reply->code();

              # error handling...
            }
          }
        }

        # error handling...
      },
    }
  );

=head2 discard( [ $cb | \%cbs ] )

Flushes all previously queued commands in a transaction and restores the
connection state to normal.

If C<WATCH> was used, C<DISCARD> unwatches all keys.

=head2 watch( @keys [, $cb | \%cbs ] )

Marks the given keys to be watched for conditional execution of a transaction.

=head2 unwatch( [ $cb | \%cbs ] )

Forget about all watched keys.

=head1 SUBSCRIPTIONS

The detailed information about Redis Pub/Sub can be found here:
L<http://redis.io/topics/pubsub>

Once the client enters the subscribed state it is not supposed to issue any
other commands, except for additional C<SUBSCRIBE>, C<PSUBSCRIBE>, C<UNSUBSCRIBE>,
C<PUNSUBSCRIBE> and C<QUIT> commands.

If the connection was lost when the client has active subscriptions, the C<on_error>
or C<on_reply> callback in appropriate C<(p)subscribe> method is called.

=head2 subscribe( @channels, ( $cb | \%cbs ) )

Subscribes the client to the specified channels.

  $redis->subscribe( qw( foo bar ),
    { on_reply => sub {
        my $reply = shift;

        if (@_) {
          my $err_msg  = shift;
          my $err_code = shift;

          # error handling...

          return;
        }

        my $channel      = $reply->[0];
        my $channels_num = $reply->[1];

        # handling...
      },

      on_message => sub {
        my $channel = shift;
        my $msg     = shift;

        # message handling...
      },
    }
  );

  $redis->subscribe( qw( foo bar ),
    sub {
      my $channel = shift;
      my $msg     = shift;

      # message handling...
    }
  );

  $redis->subscribe( qw( foo bar ),
    { on_done =>  sub {
        my $channel      = shift;
        my $channels_num = shift;

        # handling...
      },

      on_message => sub {
        my $channel = shift;
        my $msg     = shift;

        # message handling...
      },

      on_error => sub {
        my $err_msg  = shift;
        my $err_code = shift;

        # error handling...
      },
    }
  );

=over

=item on_done => $cb->( $channel, $channels_num )

The C<on_done> callback is called on every specified channel when the
subscription operation was completed successfully.

=item on_message => $cb->( $channel, $msg )

The C<on_message> callback is called when a published message was received.

=item on_error => $cb->( $err_msg, $err_code )

The C<on_error> callback is called if the subscription operation fails.

=item on_reply => $cb->( [ $reply ] [, $err_msg, $err_code ] )

The C<on_reply> callback is called in both cases: when the subscription operation
was completed successfully or when subscription operation fails. In first case
C<on_reply> callback is called on every specified channel. Information about
channel name and subscription number is passed to callback in first argument as
an array reference.

=back

=head2 psubscribe( @patterns, ( $cb | \%cbs ) )

Subscribes the client to the given patterns.

  $redis->psubscribe( qw( foo_* bar_* ),
    { on_reply => sub {
        my $reply = shift;

        if (@_) {
          my $err_msg  = shift;
          my $err_code = shift;

          # error handling...

          return;
        }

        my $pattern      = $reply->[0];
        my $channels_num = $reply->[1];

        # handling...
      },

      on_message => sub {
        my $channel = shift;
        my $msg     = shift;
        my $pattern = shift;

        # message handling...
      },
    }
  );

  $redis->psubscribe( qw( foo_* bar_* ),
    sub {
      my $channel = shift;
      my $msg     = shift;
      my $pattern = shift;

      # message handling...
    }
  );

  $redis->psubscribe( qw( foo_* bar_* ),
    { on_done =>  sub {
        my $pattern      = shift;
        my $channels_num = shift;

        # handling...
      },

      on_message => sub {
        my $channel = shift;
        my $msg     = shift;
        my $pattern = shift;

        # message handling...
      },

      on_error => sub {
        my $err_msg  = shift;
        my $err_code = shift;

        # error handling...
      },
    }
  );

=over

=item on_done => $cb->( $pattern, $channels_num )

The C<on_done> callback is called on every specified pattern when the
subscription operation was completed successfully.

=item on_message => $cb->( $channel, $msg, $pattern )

The C<on_message> callback is called when published message was received.

=item on_error => $cb->( $err_msg, $err_code )

The C<on_error> callback is called if the subscription operation fails.

=item on_reply => $cb->( [ $reply ] [, $err_msg, $err_code ] )

The C<on_reply> callback is called in both cases: when the subscription
operation was completed successfully or when subscription operation fails.
In first case C<on_reply> callback is called on every specified pattern.
Information about channel pattern and subscription number is passed to callback
in first argument as an array reference.

=back

=head2 publish( $channel, $message [, $cb | \%cbs ] )

Posts a message to the given channel.

=head2 unsubscribe( [ @channels ] [, $cb | \%cbs ] )

Unsubscribes the client from the given channels, or from all of them if none
is given.

When no channels are specified, the client is unsubscribed from all the
previously subscribed channels. In this case, a message for every unsubscribed
channel will be sent to the client.

  $redis->unsubscribe( qw( ch_foo ch_bar ),
    sub {
      my $reply = shift;

      if (@_) {
        my $err_msg  = shift;
        my $err_code = shift;

        # error handling...

        return;
      }

      my $channel      = $reply->[0];
      my $channels_num = $reply->[1];

      # handling...
    }
  );

  $redis->unsubscribe( qw( ch_foo ch_bar ),
    { on_done => sub {
        my $channel      = shift;
        my $channels_num = shift;

        # handling...
      },
    }
  );

=over

=item on_done => $cb->( $channel, $channels_num )

The C<on_done> callback is called on every specified channel when the
unsubscription operation was completed successfully.

=item on_error => $cb->( $err_msg, $err_code )

The C<on_error> callback is called if the unsubscription operation fails.

=item on_reply => $cb->( [ $reply ] [, $err_msg, $err_code ] )

The C<on_reply> callback is called in both cases: when the unsubscription
operation was completed successfully or when unsubscription operation fails.
In first case C<on_reply> callback is called on every specified channel.
Information about channel name and number of remaining subscriptions is passed
to callback in first argument as an array reference.

=back

=head2 punsubscribe( [ @patterns ] [, $cb | \%cbs ] )

Unsubscribes the client from the given patterns, or from all of them if none
is given.

When no patters are specified, the client is unsubscribed from all the
previously subscribed patterns. In this case, a message for every unsubscribed
pattern will be sent to the client.

  $redis->punsubscribe( qw( foo_* bar_* ),
    sub {
      my $reply = shift;

      if (@_) {
        my $err_msg  = shift;
        my $err_code = shift;

        # error handling...

        return;
      }

      my $pattern      = $reply->[0];
      my $channels_num = $reply->[1];

      # handling...
    }
  );

  $redis->punsubscribe( qw( foo_* bar_* ),
    { on_done => sub {
        my $pattern      = shift;
        my $channels_num = shift;

        # handling...
      },
    }
  );

=over

=item on_done => $cb->( $channel, $channels_num )

The C<on_done> callback is called on every specified pattern when the
unsubscription operation was completed successfully.

=item on_error => $cb->( $err_msg, $err_code )

The C<on_error> callback is called if the unsubscription operation fails.

=item on_reply => $cb->( [ $reply ] [, $err_msg, $err_code ] )

The C<on_reply> callback is called in both cases: when the unsubscription
operation was completed successfully or when unsubscription operation fails.
In first case C<on_reply> callback is called on every specified pattern.
Information about channel pattern and number of remaining subscriptions is
passed to callback in first argument as an array reference.

=back

=head1 CONNECTION VIA UNIX-SOCKET

Redis 2.2 and higher support connection via UNIX domain socket. To connect via
a UNIX-socket in the parameter C<host> you have to specify C<unix/>, and in
the parameter C<port> you have to specify the path to the socket.

  my $redis = AnyEvent::Redis::RipeRedis->new(
    host => 'unix/',
    port => '/tmp/redis.sock',
  );

=head1 LUA SCRIPTS EXECUTION

Redis 2.6 and higher support execution of Lua scripts on the server side.
To execute a Lua script you can send one of the commands C<EVAL> or C<EVALSHA>,
or use the special method C<eval_cached()>.

=head2 eval_cached( $script, $numkeys [, @keys ] [, @args ] [, $cb | \%cbs ] );

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

      if (@_) {
        my $err_msg  = shift;
        my $err_code = shift;

        # error handling...

        return;
      }

      foreach my $val ( @{$reply}  ) {
        print "$val\n";
      }
    }
  );

Be care, passing a different Lua scripts to C<eval_cached()> method every time
cause memory leaks.

If Lua script returns multi-bulk reply with at least one error reply, the
C<on_error> or C<on_reply> callback is called and in addition to error message
and error code to callback is passed reply data, which contain successful
replies and error objects for each error reply, as well as described for C<EXEC>
command.

  $redis->eval_cached( "return { 'foo', redis.error_reply( 'Error.' ) }", 0,
    sub {
      my $reply = shift;

      if ( @_ ) {
        my $err_msg  = shift;
        my $err_code = shift;

        if ( defined $reply ) {
          foreach my $nested_reply ( @{$reply} ) {
            if ( ref($nested_reply) eq 'AnyEvent::Redis::RipeRedis::Error' ) {
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

  $redis->eval_cached( "return { 'foo', redis.error_reply( 'Error.' ) }", 0,
    { on_done => sub {
         my $reply = shift;

         # handling...
      },

      on_error => sub {
        my $err_msg  = shift;
        my $err_code = shift;
        my $reply     = shift;

        if ( defined $reply ) {
          foreach my $nested_reply ( @{$reply} ) {
            if ( ref($nested_reply) eq 'AnyEvent::Redis::RipeRedis::Error' ) {
              my $nested_err_msg  = $nested_reply->message();
              my $nested_err_code = $nested_reply->code();

              # error handling...
            }
          }
        }

        # error handling...
      }
    }
  );

=head1 SERVER INFORMATION AND STATISTICS

=head2 info( [ $section ] [, $cb | \%cbs ] )

Gets and parses information and statistics about the server. The result
is passed to C<on_done> or C<on_reply> callback as a hash reference.

More information abount C<INFO> command can be found here:
L<http://redis.io/commands/info>

=head1 ERROR CODES

Every time when error occurred the error code is passed to C<on_error> or to
C<on_reply> callback. Error codes can be used for programmatic handling of errors.

AnyEvent::Redis::RipeRedis provides constants of error codes, which can be
imported and used in expressions.

  use AnyEvent::Redis::RipeRedis qw( :err_codes );

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

The client received unexpected data from the server. The connection to the Redis
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
"forget" any references to an AnyEvent::Redis::RipeRedis object, but in this
case a client object is destroyed without calling any callbacks, including
the C<on_disconnect> callback, to avoid an unexpected behavior.

=head2 disconnect()

The method for synchronous disconnection. All uncompleted operations will be
aborted.

  $redis->disconnect();

=head2 quit()

The method for asynchronous disconnection.

  $redis->quit(
    sub {
      # handling...
    }
  );

=head1 OTHER METHODS

=head2 connection_timeout( [ $fractional_seconds ] )

Get or set the C<connection_timeout> of the client. The C<undef> value resets
the C<connection_timeout> to default value.

=head2 read_timeout( [ $fractional_seconds ] )

Get or set the C<read_timeout> of the client.

=head2 reconnect( [ $boolean ] )

Enables or disables reconnection mode of the client.

=head2 min_reconnect_interval( [ $fractional_seconds ] )

Get or set C<min_reconnect_interval> of the client.

=head2 encoding( [ $enc_name ] )

Get or set the current C<encoding> of the client.

=head2 on_connect( [ $callback ] )

Get or set the C<on_connect> callback.

=head2 on_disconnect( [ $callback ] )

Get or set the C<on_disconnect> callback.

=head2 on_connect_error( [ $callback ] )

Get or set the C<on_connect_error> callback.

=head2 on_error( [ $callback ] )

Get or set the C<on_error> callback.

=head2 selected_database()

Get currently selected database index.

=head1 KNOWN BUGS

Methods C<unsubscribe()> and C<punsubscribe()> without arguments don't works
correctly. This issue fixed in L<AnyEvent::RipeRedis>.

=head1 SEE ALSO

L<AnyEvent::RipeRedis>, L<AnyEvent>, L<Redis::hiredis>, L<Redis>, L<RedisDB>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

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

Copyright (c) 2012-2016, Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
