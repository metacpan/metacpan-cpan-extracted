use Test::More;

use_ok('Alien::WFDB');

my $u = Alien::WFDB->new;

like( $u->libs, qr/wfdb/ );

done_testing;
