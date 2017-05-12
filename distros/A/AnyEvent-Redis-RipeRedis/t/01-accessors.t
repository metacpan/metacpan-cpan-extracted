use 5.008000;
use strict;
use warnings;

use lib 't/tlib';
use Test::More tests => 37;
use AnyEvent::Redis::RipeRedis qw( :err_codes );

my $REDIS = AnyEvent::Redis::RipeRedis->new(
  password               => 'test',
  connection_timeout     => 10,
  read_timeout           => 5,
  reconnect              => 1,
  min_reconnect_interval => 5,
  encoding               => 'utf8',

  on_connect => sub {
    return 1;
  },

  on_disconnect => sub {
    return 2;
  },

  on_connect_error => sub {
    return 3;
  },

  on_error => sub {
    return 4;
  },
);

can_ok( $REDIS, 'connection_timeout' );
can_ok( $REDIS, 'read_timeout' );
can_ok( $REDIS, 'selected_database' );
can_ok( $REDIS, 'reconnect' );
can_ok( $REDIS, 'encoding' );
can_ok( $REDIS, 'on_connect' );
can_ok( $REDIS, 'on_disconnect' );
can_ok( $REDIS, 'on_connect_error' );
can_ok( $REDIS, 'on_error' );

t_conn_timeout($REDIS);
t_read_timeout($REDIS);
t_reconnect($REDIS);
t_min_reconnect_interval($REDIS);
t_encoding($REDIS);
t_on_connect($REDIS);
t_on_disconnect($REDIS);
t_on_connect_error($REDIS);
t_on_error($REDIS);
t_selected_database($REDIS);


sub t_conn_timeout {
  my $redis = shift;

  my $t_conn_timeout = $redis->connection_timeout;
  is( $t_conn_timeout, 10, "get 'connection_timeout'" );

  $redis->connection_timeout(undef);
  is( $redis->connection_timeout, undef,
    "reset to default 'connection_timeout'" );

  $redis->connection_timeout(15);
  is( $redis->connection_timeout, 15, "set 'connection_timeout'" );

  return;
}

sub t_read_timeout {
  my $redis = shift;

  my $t_read_timeout = $redis->read_timeout;
  is( $t_read_timeout, 5, "get 'read_timeout'" );

  $redis->read_timeout(undef);
  is( $redis->read_timeout, undef, "disable 'read_timeout'" );

  $redis->read_timeout(10);
  is( $redis->read_timeout, 10, "set 'read_timeout'" );

  return;
}

sub t_reconnect {
  my $redis = shift;

  my $reconn_state = $redis->reconnect;
  is( $reconn_state, 1, "get current reconnection mode state" );

  $redis->reconnect(undef);
  is( $redis->reconnect, undef, "disable reconnection mode" );

  $redis->reconnect(1);
  is( $redis->reconnect, 1, "enable reconnection mode" );

  return;
}

sub t_min_reconnect_interval {
  my $redis = shift;

  my $t_min_reconnect_interval = $redis->min_reconnect_interval;
  is( $t_min_reconnect_interval, 5, "get 'min_reconnect_interval'" );

  $redis->min_reconnect_interval(undef);
  is( $redis->min_reconnect_interval, undef,
      "disable 'min_reconnect_interval'" );

  $redis->min_reconnect_interval(10);
  is( $redis->min_reconnect_interval, 10, "set 'min_reconnect_interval'" );

  return;
}

sub t_encoding {
  my $redis = shift;

  my $t_enc = $redis->encoding;
  is( $t_enc->name, 'utf8', "get 'encoding'" );

  $redis->encoding(undef);
  is( $redis->encoding, undef, "disable 'encoding'" );

  $redis->encoding('UTF-16');
  $t_enc = $redis->encoding;
  is( $t_enc->name, 'UTF-16', "set 'encoding'" );

  return;
}

sub t_on_connect {
  my $redis = shift;

  my $on_conn = $redis->on_connect;
  is( $on_conn->(), 1, "get 'on_connect' callback" );

  $redis->on_connect(undef);
  is( $redis->on_connect, undef, "disable 'on_connect' callback" );

  $redis->on_connect(
    sub {
      return 5;
    }
  );
  is( $redis->on_connect->(), 5, "set 'on_connect' callback" );

  return;
}

sub t_on_disconnect {
  my $redis = shift;

  my $on_disconn = $redis->on_disconnect;
  is( $on_disconn->(), 2, "get 'on_disconnect' callback" );

  $redis->on_disconnect(undef);
  is( $redis->on_disconnect, undef, "disable 'on_disconnect' callback" );

  $redis->on_disconnect(
    sub {
      return 6;
    }
  );
  is( $redis->on_disconnect->(), 6, "set 'on_disconnect' callback" );

  return;
}

sub t_on_connect_error {
  my $redis = shift;

  my $on_conn_error = $redis->on_connect_error;
  is( $on_conn_error->(), 3, "get 'on_connect_error' callback" );

  $redis->on_connect_error(undef);
  is( $redis->on_connect_error, undef,
      "disable 'on_connect_error' callback" );

  $redis->on_connect_error(
    sub {
      return 7;
    }
  );
  is( $redis->on_connect_error->(), 7, "set 'on_connect_error' callback" );

  return;
}

sub t_on_error {
  my $redis = shift;

  my $on_error = $redis->on_error();
  is( $on_error->(), 4, "get 'on_error' callback" );

  local %SIG;
  my $t_err;
  $SIG{__WARN__} = sub {
    $t_err = shift;
    chomp($t_err);
  };
  $redis->on_error(undef);
  $redis->on_error->( 'Some error', E_OPRN_ERROR );
  is( $t_err, 'Some error', "reset to default 'on_error' callback" );

  $redis->on_error(
    sub {
      return 8;
    }
  );
  is( $redis->on_error->(), 8, "set 'on_error' callback" );

  return;
}

sub t_selected_database {
  my $redis = shift;

  my $db_index = $redis->selected_database();

  is( $db_index, 0, 'get selected database' );

  return;
}
