use 5.008000;
use strict;
use warnings;

use Test::More tests => 15;
use Test::Fatal;
use AnyEvent::Redis::RipeRedis;

t_conn_timeout();
t_read_timeout();
t_min_reconnect_interval();
t_encoding();
t_on_message();


sub t_conn_timeout {
  like(
    exception {
      my $redis = AnyEvent::Redis::RipeRedis->new(
        connection_timeout => 'invalid',
      );
    },
    qr/"connection_timeout" must be a positive number/,
    'invalid connection timeout (character string; constructor)'
  );

  like(
    exception {
      my $redis = AnyEvent::Redis::RipeRedis->new(
        connection_timeout => -5,
      );
    },
    qr/"connection_timeout" must be a positive number/,
    'invalid connection timeout (negative number; constructor)'
  );

  my $redis = AnyEvent::Redis::RipeRedis->new();

  like(
    exception {
      $redis->connection_timeout('invalid');
    },
    qr/"connection_timeout" must be a positive number/,
    'invalid connection timeout (character string; accessor)'
  );

  like(
    exception {
      $redis->connection_timeout(-5);
    },
    qr/"connection_timeout" must be a positive number/,
    'invalid connection timeout (negative number; accessor)'
  );

  return;
}

sub t_read_timeout {
  like(
    exception {
      my $redis = AnyEvent::Redis::RipeRedis->new(
        read_timeout => 'invalid',
      );
    },
    qr/"read_timeout" must be a positive number/,
    'invalid read timeout (character string; constructor)',
  );

  like(
    exception {
      my $redis = AnyEvent::Redis::RipeRedis->new(
        read_timeout => -5,
      );
    },
    qr/"read_timeout" must be a positive number/,
    'invalid read timeout (negative number; constructor)',
  );

  my $redis = AnyEvent::Redis::RipeRedis->new();

  like(
    exception {
      $redis->read_timeout('invalid');
    },
    qr/"read_timeout" must be a positive number/,
    'invalid read timeout (character string; accessor)',
  );

  like(
    exception {
      $redis->read_timeout(-5);
    },
    qr/"read_timeout" must be a positive number/,
    'invalid read timeout (negative number; accessor)',
  );

  return;
}

sub t_min_reconnect_interval {
  like(
    exception {
      my $redis = AnyEvent::Redis::RipeRedis->new(
        min_reconnect_interval => 'invalid',
      );
    },
    qr/"min_reconnect_interval" must be a positive number/,
    "invalid 'min_reconnect_interval' (character string; constructor)",
  );

  like(
    exception {
      my $redis = AnyEvent::Redis::RipeRedis->new(
        min_reconnect_interval => -5,
      );
    },
    qr/"min_reconnect_interval" must be a positive number/,
    "invalid 'min_reconnect_interval' (negative number; constructor)",
  );

  my $redis = AnyEvent::Redis::RipeRedis->new();

  like(
    exception {
      $redis->min_reconnect_interval('invalid');
    },
    qr/"min_reconnect_interval" must be a positive number/,
    "invalid 'min_reconnect_interval' (character string; accessor)",
  );

  like(
    exception {
      $redis->min_reconnect_interval(-5);
    },
    qr/"min_reconnect_interval" must be a positive number/,
    "invalid 'min_reconnect_interval' (negative number; accessor)",
  );

  return;
}

sub t_encoding {
  like(
    exception {
      my $redis = AnyEvent::Redis::RipeRedis->new(
        encoding => 'utf88',
      );
    },
    qr/Encoding "utf88" not found/,
    'invalid encoding (constructor)',
  );

  my $redis = AnyEvent::Redis::RipeRedis->new();

  like(
    exception {
      $redis->encoding('utf88');
    },
    qr/Encoding "utf88" not found/,
    'invalid encoding (accessor)',
  );

  return;
}

sub t_on_message {
  my $redis = AnyEvent::Redis::RipeRedis->new();

  like(
    exception {
      $redis->subscribe('channel');
    },
    qr/"on_message" callback must be specified/,
    "\"on_message\" callback not specified",
  );

  return;
}
