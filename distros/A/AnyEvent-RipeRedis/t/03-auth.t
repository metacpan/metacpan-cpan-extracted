use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::RipeRedis qw( :err_codes );
require 't/test_helper.pl';

my $server_info = run_redis_instance(
  requirepass => 'testpass',
);
if ( !defined $server_info ) {
  plan skip_all => 'redis-server is required for this test';
}
plan tests => 8;

t_successful_auth($server_info);
t_invalid_password($server_info);


sub t_successful_auth {
  my $server_info = shift;

  my $redis = AnyEvent::RipeRedis->new(
    host     => $server_info->{host},
    port     => $server_info->{port},
    password => $server_info->{password},
  );

  can_ok( $redis, 'disconnect' );

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->ping(
        sub {
          $t_reply  = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  $redis->disconnect;

  is( $t_reply, 'PONG', 'successful AUTH' );
}

sub t_invalid_password {
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
        password => 'invalid',

        on_error => sub {
          $t_cli_err = shift;
          $cv->send;
        },
      );

      $redis->ping(
        sub {
          my $reply  = shift;
          $t_cmd_err = shift;
        }
      );
    }
  );

  $redis->disconnect;

  my $t_name_prefix = 'invalid password';
  isa_ok( $t_cmd_err, 'AnyEvent::RipeRedis::Error' );
  like( $t_cmd_err->message, qr/^Operation "ping" aborted:/,
      "$t_name_prefix; command error message" );
  is( $t_cmd_err->code, E_OPRN_ERROR, "$t_name_prefix; command error code" );
  isa_ok( $t_cli_err, 'AnyEvent::RipeRedis::Error' );
  like( $t_cli_err->message, qr/^ERR invalid password/,
      "$t_name_prefix; client error message" );
  is( $t_cli_err->code, E_OPRN_ERROR, "$t_name_prefix; client error code" );

  return;
}
