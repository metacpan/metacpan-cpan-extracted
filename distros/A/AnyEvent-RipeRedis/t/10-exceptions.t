use 5.008000;
use strict;
use warnings;

use Test::More tests => 20;
use Test::Fatal;
use AnyEvent::RipeRedis;

t_conn_timeout();
t_read_timeout();
t_reconnect_interval();
t_not_allowed_after_multi();
t_on_message();


sub t_conn_timeout {
  like(
    exception {
      my $redis = AnyEvent::RipeRedis->new(
        connection_timeout => 'invalid',
      );
    },
    qr/"connection_timeout" must be a positive number/,
    'invalid connection timeout (character string; constructor)'
  );

  like(
    exception {
      my $redis = AnyEvent::RipeRedis->new(
        connection_timeout => -5,
      );
    },
    qr/"connection_timeout" must be a positive number/,
    'invalid connection timeout (negative number; constructor)'
  );

  my $redis = AnyEvent::RipeRedis->new();

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
      my $redis = AnyEvent::RipeRedis->new(
        read_timeout => 'invalid',
      );
    },
    qr/"read_timeout" must be a positive number/,
    'invalid read timeout (character string; constructor)',
  );

  like(
    exception {
      my $redis = AnyEvent::RipeRedis->new(
        read_timeout => -5,
      );
    },
    qr/"read_timeout" must be a positive number/,
    'invalid read timeout (negative number; constructor)',
  );

  my $redis = AnyEvent::RipeRedis->new();

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

sub t_reconnect_interval {
  like(
    exception {
      my $redis = AnyEvent::RipeRedis->new(
        reconnect_interval => 'invalid',
      );
    },
    qr/"reconnect_interval" must be a positive number/,
    q{invalid "reconnect_interval" (character string; constructor)},
  );

  like(
    exception {
      my $redis = AnyEvent::RipeRedis->new(
        reconnect_interval => -5,
      );
    },
    qr/"reconnect_interval" must be a positive number/,
    q{invalid "reconnect_interval" (negative number; constructor)},
  );

  my $redis = AnyEvent::RipeRedis->new();

  like(
    exception {
      $redis->reconnect_interval('invalid');
    },
    qr/"reconnect_interval" must be a positive number/,
    q{invalid "reconnect_interval" (character string; accessor)},
  );

  like(
    exception {
      $redis->reconnect_interval(-5);
    },
    qr/"reconnect_interval" must be a positive number/,
    q{invalid "reconnect_interval" (negative number; accessor)},
  );

  return;
}

sub t_not_allowed_after_multi {
  my $redis = AnyEvent::RipeRedis->new(
    on_error => sub {
      # do not print error
    }
  );

  $redis->multi;

  like(
    exception {
      $redis->subscribe('channel');
    },
    qr/Command "subscribe" not allowed after "multi" command/,
    "not allowed after MULTI command; SUBSCRIBE",
  );

  like(
    exception {
      $redis->unsubscribe('channel');
    },
    qr/Command "unsubscribe" not allowed after "multi" command/,
    "not allowed after MULTI command; UNSUBSCRIBE",
  );

  like(
    exception {
      $redis->psubscribe('pattern_*');
    },
    qr/Command "psubscribe" not allowed after "multi" command/,
    "not allowed after MULTI command; PSUBSCRIBE",
  );

  like(
    exception {
      $redis->punsubscribe('pattern_*');
    },
    qr/Command "punsubscribe" not allowed after "multi" command/,
    "not allowed after MULTI command; PUNSUBSCRIBE",
  );

  like(
    exception {
      $redis->info;
    },
    qr/Command "info" not allowed after "multi" command/,
    "not allowed after MULTI command; INFO",
  );

  like(
    exception {
      $redis->select(2);
    },
    qr/Command "select" not allowed after "multi" command/,
    "not allowed after MULTI command; SELECT",
  );

  like(
    exception {
      $redis->quit;
    },
    qr/Command "quit" not allowed after "multi" command/,
    "not allowed after MULTI command; QUIT",
  );

  $redis->disconnect;

  return;
}

sub t_on_message {
  my $redis = AnyEvent::RipeRedis->new();

  like(
    exception {
      $redis->subscribe('channel');
    },
    qr/"on_message" callback must be specified/,
    "\"on_message\" callback not specified",
  );

  return;
}
