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
plan tests => 14;

my $R_CONSUM = AnyEvent::Redis::RipeRedis->new(
  host => $SERVER_INFO->{host},
  port => $SERVER_INFO->{port},
);
my $R_TRANSM = AnyEvent::Redis::RipeRedis->new(
  host => $SERVER_INFO->{host},
  port => $SERVER_INFO->{port},
);

t_subunsub_mth1( $R_CONSUM, $R_TRANSM );
t_subunsub_mth2( $R_CONSUM, $R_TRANSM );

t_psubunsub_mth1( $R_CONSUM, $R_TRANSM );
t_psubunsub_mth2( $R_CONSUM, $R_TRANSM );

$R_CONSUM->disconnect();
$R_TRANSM->disconnect();

t_sub_after_multi( $SERVER_INFO );


sub t_subunsub_mth1 {
  my $r_consum = shift;
  my $r_transm = shift;

  my @t_sub_data;
  my @t_sub_msgs;

  ev_loop(
    sub {
      my $cv = shift;

      my $msg_cnt = 0;

      $r_consum->subscribe( qw( foo bar ),
        { on_done => sub {
            my $ch_name  = shift;
            my $subs_num = shift;

            push( @t_sub_data,
              { ch_name  => $ch_name,
                subs_num => $subs_num,
              }
            );

            $r_transm->publish( $ch_name, "test$subs_num" );
          },

          on_message => sub {
            my $ch_name = shift;
            my $msg     = shift;

            push( @t_sub_msgs,
              { ch_name => $ch_name,
                message => $msg,
              }
            );

            if ( ++$msg_cnt == 2 ) {
              $cv->send();
            }
          },
        }
      );
    }
  );

  is_deeply( \@t_sub_data,
    [ { ch_name  => 'foo',
        subs_num => 1,
      },
      { ch_name  => 'bar',
        subs_num => 2,
      },
    ],
    'SUBSCRIBE; on_done used'
  );

  is_deeply( \@t_sub_msgs,
    [ { ch_name => 'foo',
        message => 'test1',
      },
      { ch_name => 'bar',
        message => 'test2',
      },
    ],
    'publish message from on_done'
  );

  my @t_unsub_data;

  ev_loop(
    sub {
      my $cv = shift;

      $r_consum->unsubscribe( qw( foo bar ),
        { on_done => sub {
            my $ch_name  = shift;
            my $subs_num = shift;

            push( @t_unsub_data,
              { ch_name  => $ch_name,
                subs_num => $subs_num,
              }
            );

            if ( $subs_num == 0 ) {
              $cv->send();
            }
          },
        }
      );
    }
  );

  is_deeply( \@t_unsub_data,
    [ { ch_name  => 'foo',
        subs_num => 1,
      },
      { ch_name  => 'bar',
        subs_num => 0,
      },
    ],
    'UNSUBSCRIBE; on_done used'
  );

  return;
}

sub t_subunsub_mth2 {
  my $r_consum = shift;
  my $r_transm = shift;

  my @t_sub_data;
  my @t_sub_msgs;

  ev_loop(
    sub {
      my $cv = shift;

      my $msg_cnt = 0;

      $r_consum->subscribe( qw( foo bar ),
        sub {
          my $ch_name = shift;
          my $msg     = shift;

          push( @t_sub_msgs,
            { ch_name => $ch_name,
              message => $msg,
            }
          );

          $msg_cnt++;
        }
      );

      $r_consum->subscribe( qw( events signals ),
        { on_reply => sub {
            my $data = shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );

              return;
            }

            push( @t_sub_data,
              { ch_name  => $data->[0],
                subs_num => $data->[1],
              }
            );

            if ( $data->[0] eq 'events' ) {
              $r_transm->publish( 'foo', 'test1' );
              $r_transm->publish( 'bar', 'test2' );
            }
            $r_transm->publish( $data->[0], "test$data->[1]" );
          },

          on_message => sub {
            my $ch_name = shift;
            my $msg     = shift;

            push( @t_sub_msgs,
              { ch_name => $ch_name,
                message => $msg,
              }
            );

            if ( ++$msg_cnt == 4 ) {
              $cv->send();
            }
          },
        }
      );
    }
  );

  is_deeply( \@t_sub_data,
    [ { ch_name  => 'events',
        subs_num => 3,
      },
      { ch_name  => 'signals',
        subs_num => 4,
      },
    ],
    'SUBSCRIBE; on_reply used'
  );

  is_deeply( \@t_sub_msgs,
    [ { ch_name => 'foo',
        message => 'test1',
      },
      { ch_name => 'bar',
        message => 'test2',
      },
      { ch_name => 'events',
        message => 'test3',
      },

      { ch_name => 'signals',
        message => 'test4',
      },
    ],
    'publish message from on_reply'
  );

  my @t_unsub_data;

  ev_loop(
    sub {
      my $cv = shift;

      $r_consum->unsubscribe( qw( foo bar events signals ),
        sub {
          my $data = shift;

          if ( @_ ) {
            my $err_msg = shift;

            diag( $err_msg );

            return;
          }

          push( @t_unsub_data,
            { ch_name  => $data->[0],
              subs_num => $data->[1],
            }
          );

          if ( $data->[1] == 0 ) {
            $cv->send();
          }
        }
      );
    }
  );

  is_deeply( \@t_unsub_data,
    [ { ch_name  => 'foo',
        subs_num => 3,
      },
      { ch_name  => 'bar',
        subs_num => 2,
      },
      { ch_name  => 'events',
        subs_num => 1,
      },
      { ch_name  => 'signals',
        subs_num => 0,
      },
    ],
    'UNSUBSCRIBE; on_reply used'
  );

  return;
}

sub t_psubunsub_mth1 {
  my $r_consum = shift;
  my $r_transm = shift;

  my @t_sub_data;
  my @t_sub_msgs;

  ev_loop(
    sub {
      my $cv = shift;

      my $msg_cnt = 0;

      $r_consum->psubscribe( qw( foo_* bar_* ),
        { on_done => sub {
            my $ch_pattern = shift;
            my $subs_num   = shift;

            push( @t_sub_data,
              { ch_pattern => $ch_pattern,
                subs_num   => $subs_num,
              }
            );

            my $ch_name = $ch_pattern;
            $ch_name =~ s/\*/test/;
            $r_transm->publish( $ch_name, "test$subs_num" );
          },

          on_message => sub {
            my $ch_name    = shift;
            my $msg        = shift;
            my $ch_pattern = shift;

            push( @t_sub_msgs,
              { ch_name    => $ch_name,
                message    => $msg,
                ch_pattern => $ch_pattern,
              }
            );

            if ( ++$msg_cnt == 2 ) {
              $cv->send();
            }
          },
        }
      );
    }
  );

  is_deeply( \@t_sub_data,
    [ { ch_pattern => 'foo_*',
        subs_num   => 1,
      },
      { ch_pattern => 'bar_*',
        subs_num   => 2,
      },
    ],
    'PSUBSCRIBE; on_done used'
  );

  is_deeply( \@t_sub_msgs,
    [ { ch_name    => 'foo_test',
        message    => 'test1',
        ch_pattern => 'foo_*',
      },
      { ch_name    => 'bar_test',
        message    => 'test2',
        ch_pattern => 'bar_*',
      },
    ],
    'publish message from on_done'
  );

  my @t_unsub_data;

  ev_loop(
    sub {
      my $cv = shift;

      $r_consum->punsubscribe( qw( foo_* bar_* ),
        { on_done => sub {
            my $ch_pattern = shift;
            my $subs_num   = shift;

            push( @t_unsub_data,
              { ch_pattern => $ch_pattern,
                subs_num   => $subs_num,
              }
            );

            if ( $subs_num == 0 ) {
              $cv->send();
            }
          },
        }
      );
    }
  );

  is_deeply( \@t_unsub_data,
    [ { ch_pattern => 'foo_*',
        subs_num   => 1,
      },
      { ch_pattern => 'bar_*',
        subs_num   => 0,
      },
    ],
    'PUNSUBSCRIBE; on_done used'
  );

  return;
}

sub t_psubunsub_mth2 {
  my $r_consum = shift;
  my $r_transm = shift;

  my @t_sub_data;
  my @t_sub_msgs;

  ev_loop(
    sub {
      my $cv = shift;

      my $msg_cnt = 0;

      $r_consum->psubscribe( qw( foo_* bar_* ),
        sub {
          my $ch_name    = shift;
          my $msg        = shift;
          my $ch_pattern = shift;

          push( @t_sub_msgs,
            { ch_name    => $ch_name,
              message    => $msg,
              ch_pattern => $ch_pattern,
            }
          );

          $msg_cnt++;
        }
      );

      $r_consum->psubscribe( qw( events_* signals_* ),
        { on_reply => sub {
            my $data = shift;

            if ( @_ ) {
              my $err_msg = shift;

              diag( $err_msg );

              return;
            }

            push( @t_sub_data,
              { ch_pattern => $data->[0],
                subs_num   => $data->[1],
              }
            );

            if ( $data->[0] eq 'events_*' ) {
              $r_transm->publish( 'foo_test', 'test1' );
              $r_transm->publish( 'bar_test', 'test2' );
            }
            my $ch_name = $data->[0];
            $ch_name =~ s/\*/test/;
            $r_transm->publish( $ch_name, "test$data->[1]" );
          },

          on_message => sub {
            my $ch_name    = shift;
            my $msg        = shift;
            my $ch_pattern = shift;

            push( @t_sub_msgs,
              { ch_name    => $ch_name,
                message    => $msg,
                ch_pattern => $ch_pattern,
              }
            );

            if ( ++$msg_cnt == 4 ) {
              $cv->send();
            }
          },
        }
      );
    }
  );

  is_deeply( \@t_sub_data,
    [ { ch_pattern => 'events_*',
        subs_num   => 3,
      },
      { ch_pattern => 'signals_*',
        subs_num   => 4,
      },
    ],
    'PSUBSCRIBE; on_reply used'
  );

  is_deeply( \@t_sub_msgs,
    [ { ch_name    => 'foo_test',
        message    => 'test1',
        ch_pattern => 'foo_*',
      },
      { ch_name    => 'bar_test',
        message    => 'test2',
        ch_pattern => 'bar_*',
      },
      { ch_name    => 'events_test',
        message    => 'test3',
        ch_pattern => 'events_*',
      },
      { ch_name    => 'signals_test',
        message    => 'test4',
        ch_pattern => 'signals_*',
      },
    ],
    'publish message from on_reply'
  );

  my @t_unsub_data;

  ev_loop(
    sub {
      my $cv = shift;

      $r_consum->punsubscribe( qw( foo_* bar_* events_* signals_* ),
        sub {
          my $data = shift;

          if ( @_ ) {
            my $err_msg = shift;

            diag( $err_msg );

            return;
          }

          push( @t_unsub_data,
            { ch_pattern => $data->[0],
              subs_num   => $data->[1],
            }
          );

          if ( $data->[1] == 0 ) {
            $cv->send();
          }
        }
      );
    }
  );

  is_deeply( \@t_unsub_data,
    [ { ch_pattern => 'foo_*',
        subs_num   => 3,
      },
      { ch_pattern => 'bar_*',
        subs_num   => 2,
      },
      { ch_pattern => 'events_*',
        subs_num   => 1,
      },
      { ch_pattern => 'signals_*',
        subs_num   => 0,
      },
    ],
    'PUNSUBSCRIBE; on_reply used'
  );

  return;
}

sub t_sub_after_multi {
  my $server_info = shift;

  my $redis = AnyEvent::Redis::RipeRedis->new(
    host => $server_info->{host},
    port => $server_info->{port},
    on_error => sub {
      # do not print this errors
    },
  );

  my $t_err_msg;
  my $t_err_code;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->multi();
      $redis->subscribe( 'channel',
        { on_message => sub {},

          on_error => sub {
            $t_err_msg  = shift;
            $t_err_code = shift;

            $cv->send();
          },
        }
      );
    }
  );

  $redis->disconnect();

  my $t_pname = 'subscription after MULTI command';
  is( $t_err_msg, "Command \"subscribe\" not allowed"
      . " after \"multi\" command. First, the transaction must be finalized.",
      "$t_pname; error message" );
  is( $t_err_code, E_OPRN_ERROR, "$t_pname; error code" );

  return;
}
