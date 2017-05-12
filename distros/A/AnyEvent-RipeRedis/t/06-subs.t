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
plan tests => 8;

my $r_consum = AnyEvent::RipeRedis->new(
  host => $server_info->{host},
  port => $server_info->{port},
);
my $r_transm = AnyEvent::RipeRedis->new(
  host => $server_info->{host},
  port => $server_info->{port},
);

t_subunsub( $r_consum, $r_transm );
t_psubunsub( $r_consum, $r_transm );

$r_consum->disconnect;
$r_transm->disconnect;

my $redis = AnyEvent::RipeRedis->new(
  host => $server_info->{host},
  port => $server_info->{port},
  on_error => sub {
    # do not print this errors
  },
);

$redis->disconnect;


sub t_subunsub {
  my $r_consum = shift;
  my $r_transm = shift;

  my $t_sub_reply;
  my @t_sub_msgs;

  ev_loop(
    sub {
      my $cv = shift;

      my $msg_cnt = 0;

      $r_consum->subscribe( qw( foo bar ),
        sub {
          my $msg     = shift;
          my $ch_name = shift;

          push( @t_sub_msgs,
            { message => $msg,
              ch_name => $ch_name,
            }
          );

          $msg_cnt++;
        }
      );

      $r_consum->subscribe( qw( events signals ),
        { on_reply => sub {
            $t_sub_reply = shift;
            my $err      = shift;

            if ( defined $err ) {
              diag( $err->message );
              return;
            }

            $r_transm->publish( 'foo',     'message_foo' );
            $r_transm->publish( 'bar',     'message_bar' );
            $r_transm->publish( 'events',  'message_events' );
            $r_transm->publish( 'signals', 'message_signals' );
          },

          on_message => sub {
            my $msg     = shift;
            my $ch_name = shift;

            push( @t_sub_msgs,
              { ch_name => $ch_name,
                message => $msg,
              }
            );

            if ( ++$msg_cnt == 4 ) {
              $cv->send;
            }
          },
        }
      );
    }
  );

  is( $t_sub_reply, 4, 'SUBSCRIBE' );

  is_deeply( \@t_sub_msgs,
    [ { message => 'message_foo',
        ch_name => 'foo',
      },
      { message => 'message_bar',
        ch_name => 'bar',
      },
      { message => 'message_events',
        ch_name => 'events',
      },

      { message => 'message_signals',
        ch_name => 'signals',
      },
    ],
    'SUBSCRIBE; publish message'
  );

  my $t_unsub_reply_1;
  my $t_unsub_reply_2;

  ev_loop(
    sub {
      my $cv = shift;

      $r_consum->unsubscribe( qw( foo bar ),
        sub {
          $t_unsub_reply_1 = shift;
          my $err          = shift;

          if ( defined $err ) {
            diag( $err->message );
            return;
          }
        }
      );

      $r_consum->unsubscribe(
        sub {
          $t_unsub_reply_2 = shift;
          my $err          = shift;

          if ( defined $err ) {
            diag( $err->message );
            return;
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_unsub_reply_1, 2, 'UNSUBSCRIBE; from specified channels' );
  is( $t_unsub_reply_2, 0, 'UNSUBSCRIBE; from all channels' );

  return;
}

sub t_psubunsub {
  my $r_consum = shift;
  my $r_transm = shift;

  my $t_psub_reply;
  my @t_sub_msgs;

  ev_loop(
    sub {
      my $cv = shift;

      my $msg_cnt = 0;

      $r_consum->psubscribe( qw( foo_* bar_* ),
        sub {
          my $msg        = shift;
          my $ch_pattern = shift;
          my $ch_name    = shift;

          push( @t_sub_msgs,
            { message    => $msg,
              ch_pattern => $ch_pattern,
              ch_name    => $ch_name,
            }
          );

          $msg_cnt++;
        }
      );

      $r_consum->psubscribe( qw( events_* signals_* ),
        { on_reply => sub {
            $t_psub_reply = shift;
            my $err       = shift;

            if ( defined $err ) {
              diag( $err->message );
              return;
            }

            $r_transm->publish( 'foo_test',     'message_foo_test' );
            $r_transm->publish( 'bar_test',     'message_bar_test' );
            $r_transm->publish( 'events_test',  'message_events_test' );
            $r_transm->publish( 'signals_test', 'message_signals_test' );
          },

          on_message => sub {
            my $msg        = shift;
            my $ch_pattern = shift;
            my $ch_name    = shift;

            push( @t_sub_msgs,
              { message    => $msg,
                ch_pattern => $ch_pattern,
                ch_name    => $ch_name,
              }
            );

            if ( ++$msg_cnt == 4 ) {
              $cv->send;
            }
          },
        }
      );
    }
  );

  is( $t_psub_reply, 4, 'PSUBSCRIBE' );

  is_deeply( \@t_sub_msgs,
    [ { message    => 'message_foo_test',
        ch_pattern => 'foo_*',
        ch_name    => 'foo_test',
      },
      { message    => 'message_bar_test',
        ch_pattern => 'bar_*',
        ch_name    => 'bar_test',
      },
      { message    => 'message_events_test',
        ch_pattern => 'events_*',
        ch_name    => 'events_test',
      },
      {
        message    => 'message_signals_test',
        ch_pattern => 'signals_*',
        ch_name    => 'signals_test',
      },
    ],
    'PSUBSCRIBE; publish message'
  );

  my $t_punsub_reply_1;
  my $t_punsub_reply_2;

  ev_loop(
    sub {
      my $cv = shift;

      $r_consum->punsubscribe( qw( foo_* bar_* ),
        sub {
          $t_punsub_reply_1 = shift;
          my $err           = shift;

          if ( defined $err ) {
            diag( $err->message );
            return;
          }
        }
      );

      $r_consum->punsubscribe(
        sub {
          $t_punsub_reply_2 = shift;
          my $err           = shift;

          if ( defined $err ) {
            diag( $err->message );
            return;
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_punsub_reply_1, 2, 'PUNSUBSCRIBE; from specified patterns' );
  is( $t_punsub_reply_2, 0, 'PUNSUBSCRIBE; from all patterns' );

  return;
}
