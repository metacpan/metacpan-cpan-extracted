use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::Redis::RipeRedis qw( :err_codes );
use Scalar::Util qw( weaken );
use version 0.77;
require 't/test_helper.pl';

BEGIN {
  eval "use Test::LeakTrace 0.15";
  if ( $@ ) {
    plan skip_all => 'Test::LeakTrace 0.15 required for this test';
  }
}

my $SERVER_INFO = run_redis_instance();
if ( !defined $SERVER_INFO ) {
  plan skip_all => 'redis-server is required for this test';
}
plan tests => 12;

my $REDIS = AnyEvent::Redis::RipeRedis->new(
  host => $SERVER_INFO->{host},
  port => $SERVER_INFO->{port},
);

t_leaks_status_reply_mth1( $REDIS );
t_leaks_status_reply_mth2( $REDIS );

t_leaks_bulk_reply_mth1( $REDIS );
t_leaks_bulk_reply_mth2( $REDIS );

t_leaks_mbulk_reply_mth1( $REDIS );
t_leaks_mbulk_reply_mth2( $REDIS );

t_leaks_nested_mbulk_reply_mth1( $REDIS );
t_leaks_nested_mbulk_reply_mth2( $REDIS );

t_leaks_subunsub_mth1( $REDIS );
t_leaks_subunsub_mth2( $REDIS );

my $ver = get_redis_version( $REDIS );

SKIP: {
  if ( $ver < version->parse( 'v2.6' ) ) {
    skip 'redis-server 2.6 or higher is required for this test', 2;
  }

  t_leaks_eval_cached_mth1( $REDIS );
  t_leaks_eval_cached_mth2( $REDIS );
}

$REDIS->disconnect();


sub t_leaks_status_reply_mth1 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->set( 'foo', "some\r\nstring",
          { on_done => sub {
              my $reply = shift;
            },
          }
        );

        $redis->del( 'foo',
          { on_done => sub {
              $cv->send();
            }
          }
        );
      }
    );
  } "leaks; 'on_done' used; status reply";

  return;
}

sub t_leaks_status_reply_mth2 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->set( 'foo', "some\r\nstring",
          sub {
            my $reply = shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );
            }
          }
        );

        $redis->del( 'foo',
          sub {
            shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );
            }

            $cv->send();
          }
        );
      }
    );
  } "leaks; 'on_reply' used; status reply";

  return;
}

sub t_leaks_bulk_reply_mth1 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->set( 'foo', "some\r\nstring" );

        $redis->get( 'foo',
          { on_done => sub {
              my $reply = shift;
            },
          }
        );

        $redis->del( 'foo',
          { on_done => sub {
              $cv->send();
            }
          }
        );
      }
    );
  } "leaks; 'on_done' used; bulk reply";

  return;
}

sub t_leaks_bulk_reply_mth2 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->set( 'foo', "some\r\nstring" );

        $redis->get( 'foo',
          sub {
            my $reply = shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );
            }
          }
        );

        $redis->del( 'foo',
          sub {
            shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );
            }

            $cv->send();
          }
        );
      }
    );
  } "leaks; 'on_reply' used; bulk reply";

  return;
}

sub t_leaks_mbulk_reply_mth1 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        for ( my $i = 1; $i <= 3; $i++ ) {
          $redis->rpush( 'list', "element_$i" );
        }

        $redis->lrange( 'list', 0, -1,
          { on_done => sub {
              my $reply = shift;
            },
          }
        );

        $redis->del( 'list',
          { on_done => sub {
              $cv->send();
            }
          }
        );
      }
    );
  } "leaks; 'on_done' used; multi-bulk reply";

  return;
}

sub t_leaks_mbulk_reply_mth2 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        for ( my $i = 1; $i <= 3; $i++ ) {
          $redis->rpush( 'list', "element_$i" );
        }

        $redis->lrange( 'list', 0, -1,
          sub {
            my $reply = shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );
            }
          }
        );

        $redis->del( 'list',
          sub {
            shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );
            }

            $cv->send();
          }
        );
      }
    );
  } "leaks; 'on_reply' used; multi-bulk reply";

  return;
}

sub t_leaks_nested_mbulk_reply_mth1 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        for ( my $i = 1; $i <= 3; $i++ ) {
          $redis->rpush( 'list', "element_$i" );
        }

        $redis->set( 'foo', "some\r\nstring" );

        $redis->multi();
        $redis->incr( 'bar' );
        $redis->lrange( 'list', 0, -1 );
        $redis->lrange( 'non_existent', 0, -1 );
        $redis->get( 'foo' );
        $redis->lrange( 'list', 0, -1 );
        $redis->exec(
          { on_done => sub {
              my $reply = shift;
            },
          }
        );

        $redis->del( qw( foo list bar ),
          { on_done => sub {
              $cv->send();
            },
          }
        );
      }
    );
  } "leaks; 'on_done' used; nested multi-bulk reply";

  return;
}

sub t_leaks_nested_mbulk_reply_mth2 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        for ( my $i = 1; $i <= 3; $i++ ) {
          $redis->rpush( 'list', "element_$i" );
        }

        $redis->set( 'foo', "some\r\nstring" );

        $redis->multi();
        $redis->incr( 'bar' );
        $redis->lrange( 'list', 0, -1 );
        $redis->lrange( 'non_existent', 0, -1 );
        $redis->get( 'foo' );
        $redis->lrange( 'list', 0, -1 );
        $redis->exec(
          sub {
            my $reply = shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );
            }
          },
        );

        $redis->del( qw( foo list bar ),
          sub {
            shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );
            }

            $cv->send();
          }
        );
      }
    );
  } "leaks; 'on_reply' used; nested multi-bulk reply";

  return;
}

sub t_leaks_subunsub_mth1 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->subscribe( qw( ch_foo ch_bar ),
          { on_done => sub {
              my $ch_name  = shift;
              my $subs_num = shift;
            },

            on_message => sub {
              my $ch_name = shift;
              my $msg     = shift;
            },
          }
        );

        $redis->unsubscribe( qw( ch_foo ch_bar ),
          { on_done => sub {
              my $ch_name  = shift;
              my $subs_num = shift;

              if ( $subs_num == 0 ) {
                $cv->send();
              }
            },
          }
        );
      }
    );
  } "leaks; sub/unsub; 'on_done' used";

  return;
}

sub t_leaks_subunsub_mth2 {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->subscribe( qw( ch_foo ch_bar ),
          { on_reply => sub {
              my $reply = shift;

              if ( @_ ) {
                my $err_msg = shift;

                diag( $err_msg );
              }
            },

            on_message => sub {
              my $ch_name = shift;
              my $msg     = shift;
            },
          }
        );

        $redis->unsubscribe( qw( ch_foo ch_bar ),
          sub {
            my $reply = shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );

              return;
            }

            if ( $reply->[1] == 0 ) {
              $cv->send();
            }
          }
        );
      }
    );
  } "leaks; sub/unsub; 'on_reply' used";

  return;
}

sub t_leaks_eval_cached_mth1 {
  my $redis = shift;

  my $script = <<LUA
return ARGV[1]
LUA
;
  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        my $redis = $redis;
        weaken( $redis );

        $redis->eval_cached( $script, 0, 42,
          { on_done => sub {
              my $reply = shift;

              $redis->eval_cached( $script, 0, 57,
                {
                  on_done => sub {
                    my $reply = shift;
                    $cv->send();
                  },
                }
              );
            },
          }
        );
      }
    );
  } "leaks; eval_cached; 'on_done' used";

  return;
}

sub t_leaks_eval_cached_mth2 {
  my $redis = shift;

  my $script = <<LUA
return ARGV[1]
LUA
;
  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        my $redis = $redis;
        weaken( $redis );

        $redis->eval_cached( $script, 0, 42,
          sub {
            my $reply = shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );

              return;
            }

            $redis->eval_cached( $script, 0, 57,
              sub {
                my $reply = shift;

                if ( @_ ) {
                  my $err_msg = shift;

                  diag( $err_msg );
                }

                $cv->send();
              }
            );
          }
        );
      }
    );
  } "leaks; eval_cached; 'on_reply' used";

  return;
}
