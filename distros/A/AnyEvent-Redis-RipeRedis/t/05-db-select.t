use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::Redis::RipeRedis qw( :err_codes );
require 't/test_helper.pl';

my $SERVER_INFO = run_redis_instance();
if ( !defined $SERVER_INFO ) {
  plan skip_all => 'redis-server is required for this test';
}
plan tests => 16;

t_auto_select( $SERVER_INFO );
t_select( $SERVER_INFO );
t_invalid_db_index( $SERVER_INFO );
t_auto_select_after_reconn( $SERVER_INFO );

$SERVER_INFO->{server}->stop();

$SERVER_INFO = run_redis_instance(
  requirepass => 'testpass',
);

t_auto_select_after_auth( $SERVER_INFO );


sub t_auto_select {
  my $server_info = shift;

  my $redis_db1 = AnyEvent::Redis::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    database => 1,
  );
  my $redis_db2 = AnyEvent::Redis::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    database => 2,
  );

  ev_loop(
    sub {
      my $cv = shift;

      my $done_cnt = 0;
      my $on_done_cb = sub {
        if ( ++$done_cnt == 2 ) {
          $cv->send();
        }
      };
      $redis_db1->ping( { on_done => $on_done_cb } );
      $redis_db2->ping( { on_done => $on_done_cb } );
    }
  );
  my $db1_index = $redis_db1->selected_database();
  my $db2_index = $redis_db2->selected_database();

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

  my $redis_db1 = AnyEvent::Redis::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
  );
  my $redis_db2 = AnyEvent::Redis::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
  );

  ev_loop(
    sub {
      my $cv = shift;

      my $done_cnt = 0;
      my $on_done_cb = sub {
        if ( ++$done_cnt == 2 ) {
          $cv->send();
        }
      };
      $redis_db1->select( 1, { on_done => $on_done_cb } );
      $redis_db2->select( 2, { on_done => $on_done_cb } );
    }
  );
  my $db1_index = $redis_db1->selected_database();
  my $db2_index = $redis_db2->selected_database();

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

  my $t_cli_err_msg;
  my $t_cli_err_code;
  my $t_cmd_err_msg;
  my $t_cmd_err_code;

  ev_loop(
    sub {
      my $cv = shift;

      $redis = AnyEvent::Redis::RipeRedis->new(
        host     => $server_info->{host},
        port     => $server_info->{port},
        database => 42,

        on_error => sub {
          $t_cli_err_msg  = shift;
          $t_cli_err_code = shift;
        },
      );

      $redis->ping(
        { on_error => sub {
            $t_cmd_err_msg = shift;
            $t_cmd_err_code = shift;

            $cv->send();
          },
        }
      );
    }
  );

  my $t_npref = 'invalid DB index';
  like( $t_cmd_err_msg, qr/^Operation "ping" aborted:/,
      "$t_npref; command error message" );
  is( $t_cmd_err_code, E_OPRN_ERROR, "$t_npref; command error code" );
  ok( defined $t_cli_err_msg, "$t_npref; client error message" );
  is( $t_cli_err_code, E_OPRN_ERROR, "$t_npref; client error code" );

  return;
}

sub t_auto_select_after_reconn {
  my $server_info = shift;

  my $redis_db1 = AnyEvent::Redis::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
  );
  my $redis_db2 = AnyEvent::Redis::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
  );

  ev_loop(
    sub {
      my $cv = shift;

      $redis_db1->select( 1 );
      $redis_db2->select( 2 );

      $redis_db1->set( 'foo', 'bar1' );
      $redis_db2->set( 'foo', 'bar2' );

      my $done_cnt = 0;
      my $on_done_cb = sub {
        if ( ++$done_cnt == 2 ) {
          $cv->send();
        }
      };
      $redis_db1->quit( { on_done => $on_done_cb } );
      $redis_db2->quit( { on_done => $on_done_cb } );
    }
  );

  ev_loop(
    sub {
      my $cv = shift;

      my $done_cnt = 0;
      my $on_done_cb = sub {
        if ( ++$done_cnt == 2 ) {
          $cv->send();
        }
      };
      $redis_db1->ping( { on_done => $on_done_cb } );
      $redis_db2->ping( { on_done => $on_done_cb } );
    }
  );
  my $db1_index = $redis_db1->selected_database();
  my $db2_index = $redis_db2->selected_database();

  my %t_data;

  ev_loop(
    sub {
      my $cv = shift;

      $redis_db1->get( 'foo',
        { on_done => sub {
            $t_data{db1} = shift;
          },
        }
      );
      $redis_db2->get( 'foo',
        { on_done => sub {
            $t_data{db2} = shift;
          },
        }
      );

      my $done_cnt = 0;
      my $on_done_cb = sub {
        if ( ++$done_cnt == 2 ) {
          $cv->send();
        }
      };
      $redis_db1->del( 'foo', { on_done => $on_done_cb } );
      $redis_db2->del( 'foo', { on_done => $on_done_cb } );
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

  my $redis_db1 = AnyEvent::Redis::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    password => $server_info->{password},
    database => 1,
  );
  my $redis_db2 = AnyEvent::Redis::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    password => $server_info->{password},
    database => 2,
  );

  ev_loop(
    sub {
      my $cv = shift;

      my $done_cnt = 0;
      my $on_done_cb = sub {
        if ( ++$done_cnt == 2 ) {
          $cv->send();
        }
      };
      $redis_db1->ping( { on_done => $on_done_cb } );
      $redis_db2->ping( { on_done => $on_done_cb } );
    }
  );

  my $db1_index = $redis_db1->selected_database();
  my $db2_index = $redis_db2->selected_database();

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

      my $done_cnt = 0;
      my $on_done = sub {
        ++$done_cnt;
        if ( $done_cnt == 2 ) {
          $cv->send();
        }
      };
      $redis_db1->set( 'foo', 'bar1', { on_done => $on_done } );
      $redis_db2->set( 'foo', 'bar2', { on_done => $on_done } );
    }
  );

  my %t_data;

  ev_loop(
    sub {
      my $cv = shift;

      $redis_db1->get( 'foo',
        { on_done => sub {
            $t_data{db1} = shift;
          },
        }
      );
      $redis_db2->get( 'foo',
        { on_done => sub {
            $t_data{db2} = shift;
          },
        }
      );

      my $done_cnt = 0;
      my $on_done = sub {
        $done_cnt++;
        if ( $done_cnt == 2 ) {
          $cv->send();
        }
      };
      $redis_db1->del( 'foo', { on_done => $on_done } );
      $redis_db2->del( 'foo', { on_done => $on_done } );
    }
  );

  return \%t_data;
}
