package AnyEvent::RipeRedis::Cluster;

use 5.008000;
use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.28';

use AnyEvent::RipeRedis;
use AnyEvent::RipeRedis::Error;

use AnyEvent::Socket;
use List::MoreUtils qw( bsearch );
use Scalar::Util qw( looks_like_number weaken );
use Carp qw( croak );

my %ERROR_CODES;

BEGIN {
  %ERROR_CODES = %AnyEvent::RipeRedis::Error::ERROR_CODES;
  my @err_codes  = keys %ERROR_CODES;
  our @EXPORT_OK = ( @err_codes, qw( crc16 hash_slot ) );
  our %EXPORT_TAGS = ( err_codes => \@err_codes );
}

use constant {
  D_REFRESH_INTERVAL => 15,

  %ERROR_CODES,

  # Operation status
  S_NEED_DO     => 1,
  S_IN_PROGRESS => 2,
  S_DONE        => 3,

  MAX_SLOTS => 16384,
};

my @CRC16_TAB = (
  0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
  0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
  0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
  0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
  0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
  0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
  0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
  0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
  0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
  0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
  0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12,
  0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
  0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
  0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
  0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
  0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
  0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
  0x1080, 0x00a1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
  0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
  0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
  0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
  0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
  0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
  0x26d3, 0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
  0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
  0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3,
  0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
  0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0, 0x2ab3, 0x3a92,
  0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
  0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
  0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
  0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0,
);

my %PREDEFINED_CMDS = (
  sort        => { readonly => 0, key_pos => 1 },
  zunionstore => { readonly => 0, key_pos => 1 },
  zinterstore => { readonly => 0, key_pos => 1 },
  eval        => { readonly => 0, movablekeys => 1, key_pos => 0 },
  evalsha     => { readonly => 0, movablekeys => 1, key_pos => 0 },
);

my %SUB_CMDS = (
  subscribe  => 1,
  psubscribe => 1,
);


sub new {
  my $class  = shift;
  my %params = @_;

  my $self = bless {}, $class;

  unless ( defined $params{startup_nodes} ) {
    croak 'Startup nodes not specified';
  }
  unless ( ref( $params{startup_nodes} ) eq 'ARRAY' ) {
    croak 'Startup nodes must be specified as array reference';
  }
  unless ( @{ $params{startup_nodes} } ) {
    croak 'Specified empty list of startup nodes';
  }

  $self->{startup_nodes} = $params{startup_nodes};
  $self->{allow_slaves}  = $params{allow_slaves};
  $self->{lazy}          = $params{lazy};
  $self->refresh_interval( $params{refresh_interval} );

  $self->{on_node_connect}    = $params{on_node_connect};
  $self->{on_node_disconnect} = $params{on_node_disconnect};
  $self->{on_node_error}      = $params{on_node_error};
  $self->on_error( $params{on_error} );

  my %node_params;
  foreach my $name ( qw( password utf8 connection_timeout read_timeout
      reconnect reconnect_interval handle_params ) )
  {
    next unless defined $params{$name};
    $node_params{$name} = $params{$name};
  }
  $self->{_node_params} = \%node_params;

  $self->_reset_internals;
  $self->{_input_queue} = [];
  $self->{_temp_queue}  = [];

  unless ( $self->{lazy} ) {
    $self->_init;
  }

  return $self;
}

sub execute {
  my $self     = shift;
  my $cmd_name = shift;

  my $cmd = $self->_prepare( $cmd_name, [@_] );
  $self->_route($cmd);

  return;
}

sub disconnect {
  my $self = shift;

  foreach my $node ( values %{ $self->{_nodes_pool} } ) {
    $node->disconnect;
  }
  $self->_reset_internals;
  $self->_abort;

  return;
}

sub nodes {
  my $self         = shift;
  my $key          = shift;
  my $allow_slaves = shift;

  return unless defined $self->{_slots};

  my $slot;
  if ( defined $key ) {
    $slot = hash_slot($key);
  }

  my $nodes = $self->_nodes( $slot, $allow_slaves );

  return wantarray
      ? @{ $self->{_nodes_pool} }{ @{$nodes} }
      : $self->{_nodes_pool}{ $nodes->[0] };
}

sub refresh_interval {
  my $self = shift;

  if (@_) {
    my $seconds = shift;

    if ( defined $seconds ) {
      if ( !looks_like_number($seconds) || $seconds < 0 ) {
        croak qq{"refresh_interval" must be a positive number};
      }
      $self->{refresh_interval} = $seconds;
    }
    else {
      $self->{refresh_interval} = D_REFRESH_INTERVAL;
    }
  }

  return $self->{refresh_interval};
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
        my $err = shift;
        warn $err->message . "\n";
      };
    }
  }

  return $self->{on_error};
}

sub crc16 {
  my $data = shift;

  unless ( utf8::downgrade( $data, 1 ) ) {
    utf8::encode($data);
  }

  my $crc = 0;
  foreach my $char ( split //, $data ) {
    $crc = ( $crc << 8 & 0xff00 )
        ^ $CRC16_TAB[ ( ( $crc >> 8 ) ^ ord($char) ) & 0x00ff ];
  }

  return $crc;
}

sub hash_slot {
  my $key = shift;

  my $hashtag = $key;

  if ( $key =~ m/\{([^}]*?)\}/ ) {
    if ( length $1 > 0 ) {
      $hashtag = $1;
    }
  }

  return crc16($hashtag) % MAX_SLOTS;
}

sub _init {
  my $self = shift;

  $self->{_init_state} = S_IN_PROGRESS;
  undef $self->{_refresh_timer};

  weaken($self);

  $self->_discover_cluster(
    sub {
      my $err = $_[1];

      if ( defined $err ) {
        $self->{_init_state} = S_NEED_DO;

        $self->{_ready} = 0;
        $self->_abort($err);

        return;
      }

      $self->{_init_state} = S_DONE;

      $self->{_ready} = 1;
      $self->_process_input_queue;

      if ( $self->{refresh_interval} > 0 ) {
        $self->{_refresh_timer} = AE::timer(
          $self->{refresh_interval}, 0,
          sub {
            $self->{_init_state} = S_NEED_DO;
            $self->{_ready}      = 0;
          }
        );
      }
    }
  );

  return;
}

sub _discover_cluster {
  my $self = shift;
  my $cb   = shift;

  my $nodes;

  if ( defined $self->{_slots} ) {
    $nodes = $self->_nodes( undef, $self->{allow_slaves} );
  }
  else {
    my %nodes_pool;

    foreach my $node_params ( @{ $self->{startup_nodes} } ) {
      my $hostport = "$node_params->{host}:$node_params->{port}";

      unless ( defined $nodes_pool{$hostport} ) {
        $nodes_pool{$hostport} = $self->_new_node(
            $node_params->{host}, $node_params->{port} );
      }
    }

    $self->{_nodes_pool} = \%nodes_pool;
    $nodes = [ keys %nodes_pool ];
  }

  weaken($self);

  $self->_execute(
    { name => 'cluster_state',
      args => [],

      on_reply => sub {
        my $err = $_[1];

        if ( defined $err ) {
          $cb->( undef, $err );
          return;
        }

        $self->_execute(
          { name => 'cluster_slots',
            args => [],

            on_reply => sub {
              my $slots = shift;
              my $err   = shift;

              if ( defined $err ) {
                $cb->( undef, $err );
                return;
              }

              $self->_prepare_nodes( $slots,
                sub {
                  unless ( defined $self->{_commands} ) {
                    $self->_load_commands($cb);
                    return;
                  }

                  $cb->();
                }
              );
            }
          },
          $nodes
        );
      }
    },
    $nodes
  );

  return;
}

sub _prepare_nodes {
  my $self      = shift;
  my $slots_raw = shift;
  my $cb        = shift;

  my %nodes_pool;
  my @slots;
  my @masters_nodes;
  my @slave_nodes;

  my $nodes_pool_old = $self->{_nodes_pool};

  foreach my $range ( @{$slots_raw} ) {
    my $range_start = shift @{$range};
    my $range_end   = shift @{$range};

    my @nodes;
    my $is_master = 1;

    foreach my $node_info ( @{$range} ) {
      my $hostport = "$node_info->[0]:$node_info->[1]";

      unless ( defined $nodes_pool{$hostport} ) {
        if ( defined $nodes_pool_old->{$hostport} ) {
          $nodes_pool{$hostport} = delete $nodes_pool_old->{$hostport};
        }
        else {
          $nodes_pool{$hostport} = $self->_new_node( @{$node_info}[ 0, 1 ] );

          unless ($is_master) {
            push( @slave_nodes, $hostport );
          }
        }

        if ($is_master) {
          push( @masters_nodes, $hostport );
          $is_master = 0;
        }
      }

      push( @nodes, $hostport );
    }

    push( @slots, [ $range_start, $range_end, \@nodes ] );
  }

  @slots = sort { $a->[0] <=> $b->[0] } @slots;

  foreach my $node ( values %{$nodes_pool_old} ) {
    $node->disconnect;
  }

  $self->{_nodes_pool}   = \%nodes_pool;
  $self->{_nodes}        = [ keys %nodes_pool ];
  $self->{_master_nodes} = \@masters_nodes;
  $self->{_slots}        = \@slots;

  if ( $self->{allow_slaves} && @slave_nodes ) {
    $self->_prepare_slaves( \@slave_nodes, $cb );
    return;
  }

  $cb->();

  return;
}

sub _prepare_slaves {
  my $self        = shift;
  my $slave_nodes = shift;
  my $cb          = shift;

  my $reply_cnt = scalar @{$slave_nodes};

  my $cmd = {
    name => 'readonly',
    args => [],

    on_reply => sub {
      return if --$reply_cnt > 0;
      $cb->();
    }
  };

  foreach my $hostport ( @{$slave_nodes} ) {
    $self->_execute( $cmd, [ $hostport ] );
  }

  return;
}

sub _load_commands {
  my $self = shift;
  my $cb   = shift;

  my $nodes = $self->_nodes( undef, $self->{allow_slaves} );

  weaken($self);

  $self->_execute(
    { name => 'command',
      args => [],

      on_reply => sub {
        my $commands_raw = shift;
        my $err          = shift;

        if ( defined $err ) {
          $cb->( undef, $err);
          return;
        }

        my %commands = %PREDEFINED_CMDS;

        foreach my $cmd_raw ( @{$commands_raw} ) {
          my $kwd = lc( $cmd_raw->[0] );

          next if exists $commands{$kwd};

          my $readonly = 0;
          foreach my $flag ( @{ $cmd_raw->[2] } ) {
            if ( $flag eq 'readonly' ) {
              $readonly = 1;
              last;
            }
          }

          $commands{$kwd} = {
            readonly => $readonly,
            key_pos  => $cmd_raw->[3],
          };
        }

        $self->{_commands} = \%commands;

        $cb->();
      }
    },
    $nodes
  );

  return;
}

sub _new_node {
  my $self = shift;
  my $host = shift;
  my $port = shift;

  return AnyEvent::RipeRedis->new(
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

    if ( defined $self->{on_node_error} ) {
      $self->{on_node_error}->( $err, $host, $port );
    }
  };
}

sub _prepare {
  my $self     = shift;
  my $cmd_name = shift;
  my $args     = shift;

  weaken($self);

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

sub _route {
  my $self = shift;
  my $cmd  = shift;

  unless ( $self->{_ready} ) {
    if ( $self->{_init_state} == S_NEED_DO ) {
      $self->_init;
    }
    push( @{ $self->{_input_queue} }, $cmd );

    return;
  }

  my $key;
  my $kwds = $cmd->{kwds};
  my $args = $cmd->{args};
  my $cmd_info = $self->{_commands}{ $kwds->[0] };

  if ( defined $cmd_info ) {
    if ( $cmd_info->{key_pos} > 0 ) {
      $key = $args->[ $cmd_info->{key_pos} - scalar @{$kwds} ];
    }
    # Exception for EVAL and EVALSHA commands
    elsif ( $cmd_info->{movablekeys}
      && $args->[1] > 0 )
    {
      $key = $args->[2];
    }
  }

  my $slot;
  my $allow_slaves = $self->{allow_slaves};

  if ( defined $key ) {
    $slot = hash_slot($key);
    $allow_slaves &&= $cmd_info->{readonly};
  }

  my $nodes = $self->_nodes( $slot, $allow_slaves );
  $self->_execute( $cmd, $nodes );

  return;
}

sub _execute {
  my $self       = shift;
  my $cmd        = shift;
  my $nodes      = shift;
  my $node_index = shift;
  my $fails_cnt  = shift || 0;

  unless ( defined $node_index ) {
    $node_index = int( rand( scalar @{$nodes} ) );
  }
  elsif ( $node_index == scalar @{$nodes} ) {
    $node_index = 0;
  }
  my $hostport = $nodes->[$node_index];
  my $node     = $self->{_nodes_pool}{$hostport};

  my $cmd_name = $cmd->{name} eq 'cluster_state'
      ? 'cluster_info'
      : $cmd->{name};

  weaken($self);

  $node->execute( $cmd_name, @{ $cmd->{args} },
    { on_reply => sub {
        my $reply = shift;
        my $err   = shift;

        if ( $cmd->{name} eq 'cluster_state' ) {
          unless ( defined $err ) {
            if ( $reply->{cluster_state} eq 'ok' ) {
              $reply = 1;
            }
            else {
              $err = _new_error( 'CLUSTERDOWN The cluster is down',
                  E_CLUSTER_DOWN );
            }
          }
        }

        if ( defined $err ) {
          my $err_code   = $err->code;
          my $nodes_pool = $self->{_nodes_pool};

          if ( $err_code == E_MOVED || $err_code == E_ASK ) {
            if ( $err_code == E_MOVED ) {
              $self->{_init_state} = S_NEED_DO;
              $self->{_ready}      = 0;
            }

            my ($fwd_hostport) = ( split( m/\s+/, $err->message ) )[2];

            unless ( defined $nodes_pool->{$fwd_hostport} ) {
              my ( $host, $port ) = parse_hostport($fwd_hostport);
              $nodes_pool->{$fwd_hostport} = $self->_new_node( $host, $port );
            }

            $self->_execute( $cmd, [ $fwd_hostport ] );

            return;
          }

          my $on_node_error = $cmd->{on_node_error} || $self->{on_node_error};
          if ( defined $on_node_error ) {
            my $node = $nodes_pool->{$hostport};
            $on_node_error->( $err, $node->host, $node->port );
          }

          if ( $err_code != E_CONN_CLOSED_BY_CLIENT
            && ++$fails_cnt < scalar @{$nodes} )
          {
            $self->_execute( $cmd, $nodes, ++$node_index, $fails_cnt );
            return;
          }

          $cmd->{on_reply}->( $reply, $err );

          return;
        }

        $cmd->{on_reply}->($reply);
      },

      defined $cmd->{on_message}
      ? ( on_message => $cmd->{on_message} )
      : (),
    }
  );

  return;
}

sub _nodes {
  my $self = shift;
  my $slot = shift;
  my $allow_slaves = shift;

  if ( defined $slot ) {
    my ($range) = bsearch {
      $slot > $_->[1] ? -1 : $slot < $_->[0] ? 1 : 0;
    }
    @{ $self->{_slots} };

    return $allow_slaves
        ? $range->[2]
        : [ $range->[2][0] ];
  }

  return $allow_slaves
      ? $self->{_nodes}
      : $self->{_master_nodes};
}

sub _process_input_queue {
  my $self = shift;

  $self->{_temp_queue}  = $self->{_input_queue};
  $self->{_input_queue} = [];

  while ( my $cmd = shift @{ $self->{_temp_queue} } ) {
    $self->_route($cmd);
  }

  return;
}

sub _reset_internals {
  my $self = shift;

  $self->{_nodes_pool}    = undef;
  $self->{_nodes}         = undef;
  $self->{_master_nodes}  = undef;
  $self->{_slots}         = undef;
  $self->{_commands}      = undef;
  $self->{_init_state}    = S_NEED_DO;
  $self->{_refresh_timer} = undef;
  $self->{_ready}         = 0;

  return;
}

sub _abort {
  my $self = shift;
  my $err  = shift;

  my @queued_commands = $self->_queued_commands;

  $self->{_input_queue} = [];
  $self->{_temp_queue}  = [];

  if ( !defined $err && @queued_commands ) {
    $err = _new_error( 'Connection closed by client prematurely.',
        E_CONN_CLOSED_BY_CLIENT );
  }

  if ( defined $err ) {
    my $err_msg  = $err->message;
    my $err_code = $err->code;

    $self->{on_error}->($err);

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
    $self->_route($cmd);

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

  if ( defined $self->{_input_queue} ) {
    my @queued_commands = $self->_queued_commands;

    foreach my $cmd (@queued_commands) {
      warn "Operation \"$cmd->{name}\" aborted:"
          . " Client object destroyed prematurely.\n";
    }
  }

  return;
}

1;
__END__

=head1 NAME

AnyEvent::RipeRedis::Cluster - Non-blocking Redis Cluster client

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::RipeRedis::Cluster;

  my $cluster = AnyEvent::RipeRedis::Cluster->new(
    startup_nodes => [
      { host => 'localhost', port => 7000 },
      { host => 'localhost', port => 7001 },
      { host => 'localhost', port => 7002 },
    ],
  );

  my $cv = AE::cv;

  $cluster->set( 'foo', 'bar',
    sub {
      my $err = $_[1];

      if ( defined $err ) {
        warn $err->message . "\n";
        $cv->send;

        return;
      }

      $cluster->get( 'foo',
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

AnyEvent::RipeRedis::Cluster is non-blocking Redis Cluster client built on top
of the L<AnyEvent::RipeRedis>.

Requires Redis 3.0 or higher, and any supported event loop.

For more information about Redis Cluster see here:

=over

=item *

L<http://redis.io/topics/cluster-tutorial>

=item *

L<http://redis.io/topics/cluster-spec>

=back

=head1 CONSTRUCTOR

=head2 new( %params )

  my $cluster = AnyEvent::RipeRedis::Cluster->new(
    startup_nodes => [
      { host => 'localhost', port => 7000 },
      { host => 'localhost', port => 7001 },
      { host => 'localhost', port => 7002 },
    ],
    password           => 'yourpass',
    connection_timeout => 5,
    read_timeout       => 5,
    refresh_interval   => 5,
    lazy               => 1,
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

=item startup_nodes => \@nodes

Specifies the list of startup nodes. Parameter should contain the array of
hashes that contains addresses of some nodes in the cluster. Each hash should
contain C<host> and C<port> elements. The client will try to connect to random
node from the list to retrieve information about all cluster nodes and slots
mapping. If the client could not connect to first selected node, it will try
to connect to another random node from the list.

=item password => $password

If the password is specified, the C<AUTH> command is sent to all nodes
of the cluster after connection.

=item allow_slaves => $boolean

If enabled, the client will try to send read-only commands to slave nodes.

Disabled by default.

=item utf8 => $boolean

If enabled, all strings will be converted to UTF-8 before sending to nodes,
and all results will be decoded from UTF-8.

Enabled by default.

=item connection_timeout => $fractional_seconds

Specifies connection timeout. If the client could not connect to the node
after specified timeout, the C<on_node_error> callback is called with the
C<E_CANT_CONN> error. The timeout specifies in seconds and can contain a
fractional part.

  connection_timeout => 10.5,

By default the client use kernel's connection timeout.

=item read_timeout => $fractional_seconds

Specifies read timeout. If the client could not receive a reply from the node
after specified timeout, the client close connection and call the
C<on_node_error> callback with the C<E_READ_TIMEDOUT> error. The timeout is
specifies in seconds and can contain a fractional part.

  read_timeout => 3.5,

Not set by default.

=item lazy => $boolean

If enabled, the initial connection to the startup node establishes at time when
you will send the first command to the cluster. By default the initial
connection establishes after calling of the C<new> method.

Disabled by default.

=item reconnect => $boolean

If the connection to the node was lost and the parameter C<reconnect> is
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

=item refresh_interval => $fractional_seconds

Cluster state refresh interval. If set to zero, cluster state will be updated
only on MOVED redirect.

By default is 15 seconds.

=item handle_params => \%params

Specifies L<AnyEvent::Handle> parameters.

  handle_params => {
    autocork => 1,
    linger   => 60,
  }

Enabling of the C<autocork> parameter can improve performance. See
documentation on L<AnyEvent::Handle> for more information.

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

The C<on_error> callback is called when occurred an error, which was affected
on entire client (e. g. nodes discovery error). Also the C<on_error> callback is
called on command errors if the command callback is not specified. If the
C<on_error> callback is not specified, the client just print an error messages
to C<STDERR>.

=back

=head1 COMMAND EXECUTION

=head2 <command>( [ @args ] [, ( $cb->( $reply, $err ) | \%cbs ) ] )

To execute the command you must call particular method with corresponding name.
The reply to the command is passed to the callback in first argument. If any
error occurred during the command execution, the error object is passed to the
callback in second argument. The error object is the instance of the class
L<AnyEvent::RipeRedis::Error>.

Before the command execution, the client determines the pool of nodes, on which
the command can be executed. The pool can contain the one or more nodes
depending on the cluster and the client configurations, and the command type.
The client will try to execute the command on random node from the pool and, if
the command failed on selected node, the client will try to execute it on
another random node.

The command callback is optional. If it is not specified and any error
occurred, the C<on_error> callback of the client is called.

The full list of the Redis commands can be found here: L<http://redis.io/commands>.

  $cluster->get( 'foo',
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

  $cluster->lrange( 'list', 0, -1,
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

  $cluster->incr( 'counter' );

If you want to track errors on particular nodes, you must specify C<on_node_error>
callback in command method.

  $cluster->get( 'foo',
    { on_reply => sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          my $err_msg  = $err->message;
          my $err_code = $err->code;

          # error handling...

          return;
        }

        print "$reply\n";
      },

      on_node_error => sub {
        my $err  = shift;
        my $host = shift;
        my $port = shift;

        # error handling...
      }
    }
  );

=head2 execute( $command [, @args ] [, ( $cb->( $reply, $err ) | \%cbs ) ] )

An alternative method to execute commands. In some cases it can be more
convenient.

  $cluster->execute( 'get', 'foo',
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

=head1 TRANSACTIONS

To perform the transaction you must get the master node by the key using
C<nodes> method and then execute all commands on this node. Nodes must be
discovered first.

  $node = $cluster->nodes('foo');

  $node->multi;
  $node->set( '{foo}bar', "some\r\nstring" );
  $node->set( '{foo}car', 42 );
  $node->exec(
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        # error handling...

        return;
      }

      # reply handling...
    }
  );

The detailed information about the Redis transactions can be found in
documentation on L<AnyEvent::RipeRedis> and here:
L<http://redis.io/topics/transactions>.

=head1 ERROR CODES

Every error object, passed to callback, contain error code, which can be used
for programmatic handling of errors. AnyEvent::RipeRedis::Cluster provides
constants for error codes. They can be imported and used in expressions.

  use AnyEvent::RipeRedis::Cluster qw( :err_codes );

Full list of error codes see in documentation on L<AnyEvent::RipeRedis>.

=head1 DISCONNECTION

When the connection to the cluster is no longer needed you can close it in two
ways: call the method C<disconnect()> or just "forget" any references to an
AnyEvent::RipeRedis::Cluster object, but in this case the client object is
destroyed without calling any callbacks, including the C<on_disconnect>
callback, to avoid an unexpected behavior.

=head2 disconnect()

The method for disconnection. All uncompleted operations will be
aborted.

=head1 OTHER METHODS

=head2 nodes( [ $key ] [, $allow_slaves ] )

Gets particular nodes of the cluster. Nodes must be discovered first. In scalar
context method returns the first node from the list.

Getting all master nodes of the cluster:

  my @master_nodes = $cluster->nodes;

Getting all nodes of the cluster, including slave nodes:

  my @nodes = $cluster->nodes( undef, 1 );

Getting master node by the key:

  my $master_node = $cluster->nodes('foo');

Getting nodes by the key, including slave nodes:

  my @nodes = $cluster->nodes( 'foo', 1 );

=head2 refresh_interval( [ $fractional_seconds ] )

Gets or sets the C<refresh_interval> of the client. The C<undef> value resets
the C<refresh_interval> to default value.

=head2 on_error( [ $callback ] )

Gets or sets the C<on_error> callback.

=head1 SERVICE FUNCTIONS

Service functions provided by AnyEvent::RipeRedis::Cluster can be imported.

  use AnyEvent::RipeRedis::Cluster qw( crc16 hash_slot );

=head2 crc16( $data )

Compute CRC16 for the specified data as defined in Redis Cluster specification.

=head2 hash_slot( $key );

Returns slot number by the key.

=head1 SEE ALSO

L<AnyEvent::RipeRedis>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

Sponsored by SMS Online, E<lt>dev.opensource@sms-online.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
