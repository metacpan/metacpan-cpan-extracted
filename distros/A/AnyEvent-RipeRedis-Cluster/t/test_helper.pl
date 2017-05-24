use 5.008000;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::RipeRedis::Error;
use Test::MockObject;
use Clone qw( clone );

BEGIN {
  my %command_replies = (
    cluster_info => {
      cluster_state => 'ok',
    },

    cluster_slots => [
      [ '0',
        '5961',
        [ '127.0.0.1', '7000', '4b2fa9c315cddbc1c1c729b60ade711fe141d61b' ],
        [ '127.0.0.1', '7003', '14550b7425c44231090719acd5a5d42ad5424b4f' ],
        [ '127.0.0.1', '7005', '050ece77147551db844467770883cf5cd2c8bc2b' ]
      ],
      [ '5962',
        '10922',
        [ '127.0.0.1', '7001', 'f7fc4a7c3f340ea44dc8f92a6fda041dc640de90' ],
        [ '127.0.0.1', '7004', 'a859a49ad96f8312f91fc8c6b402484eda913c83' ]
      ],
      [ '10923',
        '11421',
        [ '127.0.0.1', '7000', '4b2fa9c315cddbc1c1c729b60ade711fe141d61b' ],
        [ '127.0.0.1', '7003', '14550b7425c44231090719acd5a5d42ad5424b4f' ],
        [ '127.0.0.1', '7005', '050ece77147551db844467770883cf5cd2c8bc2b' ]
      ],
      [ '11422',
        '16383',
        [ '127.0.0.1', '7002', '001dadcde7704079c3c6ea679323215c0930af57' ],
        [ '127.0.0.1', '7006', '08c40bd2b18d9c2a20e6d8a27b8da283566a665d' ]
      ],
    ],

    command => [
      [ 'command', 0, [ qw( loading stale ) ], 0, 0, 0 ],
      [ 'set', -3, [ qw( write denyoom ) ], 1, 1, 1 ],
      [ 'get', '2', [ qw( readonly fast ) ], 1, 1, 1 ],
      [ 'client', -2, [ qw( admin noscript ) ], 0, 0, 0 ],
      [ 'hget', 3, [ qw( readonly fast ) ], 1, 1, 1 ],
    ],

    ping           => 'PONG',
    readonly       => 'OK',
    set            => 'OK',
    get            => "some\r\nstring",
    client_getname => 'test',
  );

  Test::MockObject->fake_module( 'AnyEvent::RipeRedis',
    new => sub {
      my $class  = shift;
      my %params = @_;

      my $mock = Test::MockObject->new({});

      $mock->{host} = $params{host};
      $mock->{port} = $params{port};

      $mock->mock( 'execute',
        sub {
          my $self     = shift;
          my $cmd_name = shift;
          my $cbs      = pop;
          my @args     = @_;

          my $reply;
          my $err;

          if ( $cmd_name eq 'hget' ) {
            $err = AnyEvent::RipeRedis::Error->new(
                q{LOADING Redis is loading the dataset in memory}, 2 );
          }
          else {
            $reply = clone( $command_replies{$cmd_name} );
          }

          AE::postpone {
            $cbs->{on_reply}->( $reply, $err );
          };
        }
      );

      $mock->mock( 'disconnect', sub {} );

      foreach my $name ( qw( host port ) ) {
        $mock->mock( $name,
          sub {
            my $self = shift;
            return $self->{$name};
          }
        );
      }

      return $mock;
    },
  );
}

use AnyEvent::RipeRedis::Cluster qw( :err_codes );

sub new_cluster {
  my %params = @_;

  return AnyEvent::RipeRedis::Cluster->new(
    startup_nodes => [
      { host => '127.0.0.1', port => 7000 },
      { host => '127.0.0.1', port => 7001 },
      { host => '127.0.0.1', port => 7002 },
    ],
    %params,
  );
}

sub ev_loop {
  my $sub = shift;

  my $cv = AE::cv;

  $sub->($cv);

  my $timer = AE::timer( 10, 0,
    sub {
      diag( 'Emergency exit from event loop.' );
      $cv->send;
    }
  );

  $cv->recv;

  return;
}

sub nodes {
  my $cluster = shift;
  my $key     = shift;
  my $allow_slaves = shift;

  return sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] }
      map { [ $_->host, $_->port ] } $cluster->nodes( $key, $allow_slaves );

  return;
}

1;
