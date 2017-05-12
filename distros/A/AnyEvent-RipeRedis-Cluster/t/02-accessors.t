use 5.008000;
use strict;
use warnings;

use Test::More tests => 8;
use AnyEvent::RipeRedis::Error;
BEGIN {
  require 't/test_helper.pl';
}

my $cluster = new_cluster(
  refresh_interval => 5,

  on_error => sub {
    return 1;
  },
);

can_ok( $cluster, 'refresh_interval' );
can_ok( $cluster, 'on_error' );

t_refresh_interval($cluster);
t_on_error($cluster);


sub t_refresh_interval {
  my $cluster = shift;

  is( $cluster->refresh_interval, 5, q{get "refresh_interval"} );

  $cluster->refresh_interval(undef);
  is( $cluster->refresh_interval, 15,
    q{reset to default "refresh_interval"} );

  $cluster->refresh_interval(10);
  is( $cluster->refresh_interval, 10, q{set "refresh_interval"} );

  return;
}

sub t_on_error {
  my $cluster = shift;

  is( $cluster->on_error->(), 1, q{get "on_error" callback} );

  local %SIG;
  my $t_err;
  $SIG{__WARN__} = sub {
    $t_err = shift;
    chomp($t_err);
  };

  $cluster->on_error(undef);

  my $err = AnyEvent::RipeRedis::Error->new( 'Some error', E_OPRN_ERROR );
  $cluster->on_error->($err);

  is( $t_err, 'Some error', q{reset to default "on_error" callback} );

  $cluster->on_error(
    sub {
      return 2;
    }
  );

  is( $cluster->on_error->(), 2, q{set "on_error" callback} );

  return;
}
