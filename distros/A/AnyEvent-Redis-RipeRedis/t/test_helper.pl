use 5.008000;
use strict;
use warnings;

use lib 't/tlib';

use Test::More;
use Test::RedisRunner;
use AnyEvent;
use version 0.77;

sub run_redis_instance {
  my %params = @_;

  my $redis_server = eval {
    return Test::RedisRunner->new(
      conf => \%params,
    );
  };
  if ( !defined $redis_server ) {
    return;
  }

  my %conn_info = $redis_server->connect_info();

  return {
    server   => $redis_server,
    host     => $conn_info{host},
    port     => $conn_info{port},
    password => $params{requirepass},
  };
}

sub ev_loop {
  my $sub = shift;

  my $cv = AE::cv();

  $sub->( $cv );

  my $timer = AE::timer( 10, 0,
    sub {
      diag( 'Emergency exit from event loop. Test failed' );
      $cv->send();
    }
  );

  $cv->recv();

  return;
}

sub get_redis_version {
  my $redis = shift;

  my $ver;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->info(
        { on_done => sub {
            my $data = shift;

            $ver = version->parse( 'v' . $data->{redis_version} );

            $cv->send();
          },
        }
      );
    }
  );

  return $ver;
}

1;
