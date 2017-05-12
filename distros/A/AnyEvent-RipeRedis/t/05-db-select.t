use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::RipeRedis qw( :err_codes );
require 't/test_helper.pl';

my $server_info = run_redis_instance();
if ( !defined $server_info ) {
  plan skip_all => 'redis-server is required for this test';
}
plan tests => 18;

t_auto_select($server_info);
t_select($server_info);
t_invalid_db_index($server_info);
t_auto_select_after_reconn($server_info);

$server_info->{server}->stop;

$server_info = run_redis_instance(
  requirepass => 'testpass',
);

t_auto_select_after_auth($server_info);


sub t_auto_select {
  my $server_info = shift;

  my $redis_db1 = AnyEvent::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    database => 1,
  );
  my $redis_db2 = AnyEvent::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    database => 2,
  );

  ev_loop(
    sub {
      my $cv = shift;

      my $reply_cnt = 0;

      my $on_reply = sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          diag( $err->message );
        }

        if ( ++$reply_cnt == 2 ) {
          $cv->send;
        }
      };

      $redis_db1->ping($on_reply);
      $redis_db2->ping($on_reply);
    }
  );

  my $db1_index = $redis_db1->database;
  my $db2_index = $redis_db2->database;

  my $t_data = set_get( $redis_db1, $redis_db2 );

  my $t_npref = 'auto-selection of DB';
  is( $db1_index, 1, "$t_npref; first DB index" );
  is( $db2_index, 2, "$t_npref; second DB index" );
  is_deeply( $t_data,
    { db1 => 'bar1',
      db2 => 'bar2',
    },
    "$t_npref; SET and GET"
  );

  return;
}

sub t_select {
  my $server_info = shift;

  my $redis_db1 = AnyEvent::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
  );
  my $redis_db2 = AnyEvent::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
  );

  ev_loop(
    sub {
      my $cv = shift;

      my $reply_cnt = 0;

      my $on_reply = sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          diag( $err->message );
        }

        if ( ++$reply_cnt == 2 ) {
          $cv->send;
        }
      };

      $redis_db1->select( 1, $on_reply );
      $redis_db2->select( 2, $on_reply );
    }
  );

  my $db1_index = $redis_db1->database;
  my $db2_index = $redis_db2->database;

  my $t_data = set_get( $redis_db1, $redis_db2 );

  my $t_npref = 'SELECT';
  is( $db1_index, 1, "$t_npref; first DB index" );
  is( $db2_index, 2, "$t_npref; second DB index" );
  is_deeply( $t_data,
    { db1 => 'bar1',
      db2 => 'bar2',
    },
    "$t_npref; SET and GET"
  );

  return;
}

sub t_invalid_db_index {
  my $server_info = shift;

  my $redis;

  my $t_cli_err;
  my $t_cmd_err;

  ev_loop(
    sub {
      my $cv = shift;

      $redis = AnyEvent::RipeRedis->new(
        host     => $server_info->{host},
        port     => $server_info->{port},
        database => 42,

        on_error => sub {
          $t_cli_err = shift;
        },
      );

      $redis->ping(
        sub {
          my $reply  = shift;
          $t_cmd_err = shift;

          $cv->send;
        }
      );
    }
  );

  my $t_npref = 'invalid DB index';
  isa_ok( $t_cmd_err, 'AnyEvent::RipeRedis::Error' );
  like( $t_cmd_err->message, qr/^Operation "ping" aborted:/,
      "$t_npref; command error message" );
  is( $t_cmd_err->code, E_OPRN_ERROR, "$t_npref; command error code" );
  isa_ok( $t_cli_err, 'AnyEvent::RipeRedis::Error' );
  ok( defined $t_cli_err->message, "$t_npref; client error message" );
  is( $t_cli_err->code, E_OPRN_ERROR, "$t_npref; client error code" );

  return;
}

sub t_auto_select_after_reconn {
  my $server_info = shift;

  my $redis_db1 = AnyEvent::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
  );
  my $redis_db2 = AnyEvent::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
  );

  ev_loop(
    sub {
      my $cv = shift;

      $redis_db1->select(1);
      $redis_db2->select(2);

      $redis_db1->set( 'foo', 'bar1' );
      $redis_db2->set( 'foo', 'bar2' );

      my $reply_cnt = 0;

      my $on_reply = sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          diag( $err->message );
        }

        if ( ++$reply_cnt == 2 ) {
          $cv->send;
        }
      };

      $redis_db1->quit($on_reply);
      $redis_db2->quit($on_reply);
    }
  );

  ev_loop(
    sub {
      my $cv = shift;

      my $reply_cnt = 0;

      my $on_reply = sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          diag( $err->message );
        }

        if ( ++$reply_cnt == 2 ) {
          $cv->send;
        }
      };

      $redis_db1->ping($on_reply);
      $redis_db2->ping($on_reply);
    }
  );

  my $db1_index = $redis_db1->database;
  my $db2_index = $redis_db2->database;

  my %t_data;

  ev_loop(
    sub {
      my $cv = shift;

      $redis_db1->get( 'foo',
        sub {
          $t_data{db1} = shift;
          my $err      = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );
      $redis_db2->get( 'foo',
        sub {
          $t_data{db2} = shift;
          my $err      = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      my $reply_cnt = 0;

      my $on_reply = sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          diag( $err->message );
        }

        if ( ++$reply_cnt == 2 ) {
          $cv->send;
        }
      };

      $redis_db1->del( 'foo', $on_reply );
      $redis_db2->del( 'foo', $on_reply );
    }
  );

  my $t_npref = 'auto-selection of DB after reconnection';
  is( $db1_index, 1, "$t_npref; first DB index" );
  is( $db2_index, 2, "$t_npref; second DB index" );
  is_deeply( \%t_data,
    { db1 => 'bar1',
      db2 => 'bar2',
    },
    "$t_npref; SET and GET"
  );


  return;
}

sub t_auto_select_after_auth {
  my $server_info = shift;

  my $redis_db1 = AnyEvent::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    password => $server_info->{password},
    database => 1,
  );
  my $redis_db2 = AnyEvent::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    password => $server_info->{password},
    database => 2,
  );

  ev_loop(
    sub {
      my $cv = shift;

      my $reply_cnt = 0;

      my $on_reply = sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          diag( $err->message );
        }

        if ( ++$reply_cnt == 2 ) {
          $cv->send;
        }
      };

      $redis_db1->ping($on_reply);
      $redis_db2->ping($on_reply);
    }
  );

  my $db1_index = $redis_db1->database;
  my $db2_index = $redis_db2->database;

  my $t_data = set_get( $redis_db1, $redis_db2 );

  my $t_npref = 'auto-selection of DB after authentication';
  is( $db1_index, 1, "$t_npref; first DB index" );
  is( $db2_index, 2, "$t_npref; second DB index" );
  is_deeply( $t_data,
    { db1 => 'bar1',
      db2 => 'bar2',
    },
    "$t_npref; SET and GET"
  );

  return;
}

sub set_get {
  my $redis_db1 = shift;
  my $redis_db2 = shift;

  ev_loop(
    sub {
      my $cv = shift;

      my $reply_cnt = 0;

      my $on_reply = sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          diag( $err->message );
        }

        if ( ++$reply_cnt == 2 ) {
          $cv->send;
        }
      };

      $redis_db1->set( 'foo', 'bar1', $on_reply );
      $redis_db2->set( 'foo', 'bar2', $on_reply );
    }
  );

  my %t_data;

  ev_loop(
    sub {
      my $cv = shift;

      $redis_db1->get( 'foo',
        sub {
          $t_data{db1} = shift;
          my $err      = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );
      $redis_db2->get( 'foo',
        sub {
          $t_data{db2} = shift;
          my $err      = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      my $reply_cnt = 0;

      my $on_reply = sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          diag( $err->message );
        }

        if ( ++$reply_cnt == 2 ) {
          $cv->send;
        }
      };
      $redis_db1->del( 'foo', $on_reply );
      $redis_db2->del( 'foo', $on_reply );
    }
  );

  return \%t_data;
}
