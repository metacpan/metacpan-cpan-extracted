use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN { use_ok( 'Alien::NSS::ConfigData' ); }

my $type = Alien::NSS::ConfigData->config('install_type');
if ( $type eq 'system' ) {
  # installed in system, no pkg_config
  done_testing();
  exit(0);
}

my $pkgconfig = Alien::NSS::ConfigData->config('pkgconfig');
ok(defined($pkgconfig), 'got pkgconfig');
diag(Dumper($pkgconfig));
is(scalar keys %$pkgconfig, 1, 'only 1 key in pkgconfig');

done_testing(3);
