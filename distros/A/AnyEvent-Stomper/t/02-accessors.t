use 5.008000;
use strict;
use warnings;

use Test::More tests => 24;
use AnyEvent::Stomper qw( :err_codes );
use AnyEvent::Stomper::Error;

my $stomper = AnyEvent::Stomper->new(
  connection_timeout => 10,
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

can_ok( $stomper, 'host' );
can_ok( $stomper, 'port' );
can_ok( $stomper, 'connection_timeout' );
can_ok( $stomper, 'reconnect_interval' );
can_ok( $stomper, 'on_connect' );
can_ok( $stomper, 'on_disconnect' );
can_ok( $stomper, 'on_error' );

t_host($stomper);
t_port($stomper);
t_conn_timeout($stomper);
t_reconnect_interval($stomper);
t_on_connect($stomper);
t_on_disconnect($stomper);
t_on_error($stomper);


sub t_host {
  my $stomper = shift;

  is( $stomper->host, 'localhost', 'get host' );

  return;
}

sub t_port {
  my $stomper = shift;

  is( $stomper->port, 61613, 'get port' );

  return;
}

sub t_conn_timeout {
  my $stomper = shift;

  is( $stomper->connection_timeout, 10, q{get "connection_timeout"} );

  $stomper->connection_timeout(undef);
  is( $stomper->connection_timeout, undef,
    q{reset to default "connection_timeout"} );

  $stomper->connection_timeout(15);
  is( $stomper->connection_timeout, 15, q{set "connection_timeout"} );

  return;
}

sub t_reconnect_interval {
  my $stomper = shift;

  is( $stomper->reconnect_interval, 5, q{get "reconnect_interval"} );

  $stomper->reconnect_interval(undef);
  is( $stomper->reconnect_interval, undef,
      q{disable "reconnect_interval"} );

  $stomper->reconnect_interval(10);
  is( $stomper->reconnect_interval, 10, q{set "reconnect_interval"} );

  return;
}

sub t_on_connect {
  my $stomper = shift;

  is( $stomper->on_connect->(), 1, q{get "on_connect" callback} );

  $stomper->on_connect(undef);
  is( $stomper->on_connect, undef, q{disable "on_connect" callback} );

  $stomper->on_connect(
    sub {
      return 4;
    }
  );
  is( $stomper->on_connect->(), 4, q{set "on_connect" callback} );

  return;
}

sub t_on_disconnect {
  my $stomper = shift;

  is( $stomper->on_disconnect->(), 2, q{get "on_disconnect" callback} );

  $stomper->on_disconnect(undef);
  is( $stomper->on_disconnect, undef, q{disable "on_disconnect" callback} );

  $stomper->on_disconnect(
    sub {
      return 5;
    }
  );
  is( $stomper->on_disconnect->(), 5, q{set "on_disconnect" callback} );

  return;
}

sub t_on_error {
  my $stomper = shift;

  is( $stomper->on_error->(), 3, q{get "on_error" callback} );

  local %SIG;
  my $t_err;
  $SIG{__WARN__} = sub {
    $t_err = shift;
    chomp($t_err);
  };

  $stomper->on_error(undef);

  my $err = AnyEvent::Stomper::Error->new( 'Some error', E_OPRN_ERROR );
  $stomper->on_error->($err);

  is( $t_err, 'Some error', q{reset to default "on_error" callback} );

  $stomper->on_error(
    sub {
      return 6;
    }
  );

  is( $stomper->on_error->(), 6, q{set "on_error" callback} );

  return;
}
