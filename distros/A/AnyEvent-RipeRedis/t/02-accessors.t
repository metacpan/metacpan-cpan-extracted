use 5.008000;
use strict;
use warnings;

use Test::More tests => 38;
use AnyEvent::RipeRedis qw( :err_codes );
use AnyEvent::RipeRedis::Error;

my $redis = AnyEvent::RipeRedis->new(
  password           => 'test',
  connection_timeout => 10,
  read_timeout       => 5,
  reconnect          => 1,
  reconnect_interval => 5,

  on_connect => sub {
    return 1;
  },

  on_disconnect => sub {
    return 2;
  },

  on_error => sub {
    return 3;
  },
);

can_ok( $redis, 'host' );
can_ok( $redis, 'port' );
can_ok( $redis, 'database' );
can_ok( $redis, 'connection_timeout' );
can_ok( $redis, 'read_timeout' );
can_ok( $redis, 'utf8' );
can_ok( $redis, 'reconnect' );
can_ok( $redis, 'reconnect_interval' );
can_ok( $redis, 'on_connect' );
can_ok( $redis, 'on_disconnect' );
can_ok( $redis, 'on_error' );

t_host($redis);
t_port($redis);
t_database($redis);
t_conn_timeout($redis);
t_read_timeout($redis);
t_reconnect($redis);
t_reconnect_interval($redis);
t_utf8($redis);
t_on_connect($redis);
t_on_disconnect($redis);
t_on_error($redis);


sub t_host {
  my $redis = shift;

  is( $redis->host, 'localhost', 'get host' );

  return;
}

sub t_port {
  my $redis = shift;

  is( $redis->port, 6379, 'get port' );

  return;
}

sub t_database {
  my $redis = shift;

  is( $redis->database, 0, 'get database index' );

  return;
}

sub t_conn_timeout {
  my $redis = shift;

  is( $redis->connection_timeout, 10, q{get "connection_timeout"} );

  $redis->connection_timeout(undef);
  is( $redis->connection_timeout, undef,
    q{reset to default "connection_timeout"} );

  $redis->connection_timeout(15);
  is( $redis->connection_timeout, 15, q{set "connection_timeout"} );

  return;
}

sub t_read_timeout {
  my $redis = shift;

  is( $redis->read_timeout, 5, q{get "read_timeout"} );

  $redis->read_timeout(undef);
  is( $redis->read_timeout, undef, q{disable "read_timeout"} );

  $redis->read_timeout(10);
  is( $redis->read_timeout, 10, q{set "read_timeout"} );

  return;
}

sub t_reconnect {
  my $redis = shift;

  is( $redis->reconnect, 1, q{get current reconnection mode state} );

  $redis->reconnect(undef);
  is( $redis->reconnect, undef, q{disable reconnection mode} );

  $redis->reconnect(1);
  is( $redis->reconnect, 1, q{enable reconnection mode} );

  return;
}

sub t_reconnect_interval {
  my $redis = shift;

  is( $redis->reconnect_interval, 5, q{get "reconnect_interval"} );

  $redis->reconnect_interval(undef);
  is( $redis->reconnect_interval, undef,
      q{disable "reconnect_interval"} );

  $redis->reconnect_interval(10);
  is( $redis->reconnect_interval, 10, q{set "reconnect_interval"} );

  return;
}

sub t_utf8 {
  my $redis = shift;

  is(  $redis->utf8, 1, q{get current UTF8 mode state} );

  $redis->utf8(undef);
  is( $redis->utf8, undef, q{disable UTF8 mode} );

  $redis->utf8(1);
  is( $redis->utf8, 1, q{enable UTF8 mode} );

  return;
}

sub t_on_connect {
  my $redis = shift;

  is( $redis->on_connect->(), 1, q{get "on_connect" callback} );

  $redis->on_connect(undef);
  is( $redis->on_connect, undef, q{disable "on_connect" callback} );

  $redis->on_connect(
    sub {
      return 4;
    }
  );
  is( $redis->on_connect->(), 4, q{set "on_connect" callback} );

  return;
}

sub t_on_disconnect {
  my $redis = shift;

  is( $redis->on_disconnect->(), 2, q{get "on_disconnect" callback} );

  $redis->on_disconnect(undef);
  is( $redis->on_disconnect, undef, q{disable "on_disconnect" callback} );

  $redis->on_disconnect(
    sub {
      return 5;
    }
  );
  is( $redis->on_disconnect->(), 5, q{set "on_disconnect" callback} );

  return;
}

sub t_on_error {
  my $redis = shift;

  is( $redis->on_error->(), 3, q{get "on_error" callback} );

  local %SIG;
  my $t_err;
  $SIG{__WARN__} = sub {
    $t_err = shift;
    chomp($t_err);
  };

  $redis->on_error(undef);

  my $err = AnyEvent::RipeRedis::Error->new( 'Some error', E_OPRN_ERROR );
  $redis->on_error->($err);

  is( $t_err, 'Some error', q{reset to default "on_error" callback} );

  $redis->on_error(
    sub {
      return 6;
    }
  );

  is( $redis->on_error->(), 6, q{set "on_error" callback} );

  return;
}
