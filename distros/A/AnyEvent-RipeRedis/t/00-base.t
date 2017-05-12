use 5.008000;
use strict;
use warnings;

use Test::More tests => 8;

my $t_client_class;
my $t_err_class;

BEGIN {
  $t_client_class = 'AnyEvent::RipeRedis';
  use_ok( $t_client_class );

  $t_err_class = 'AnyEvent::RipeRedis::Error';
  use_ok( $t_err_class );
}

can_ok( $t_client_class, 'new' );
my $redis = new_ok( $t_client_class );

can_ok( $t_err_class, 'new' );
my $err = new_ok( $t_err_class => [ 'Some error', 9 ] );

can_ok( $err, 'message' );
can_ok( $err, 'code' );
