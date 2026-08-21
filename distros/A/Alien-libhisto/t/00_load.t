use Test2::V0;
use Alien::libhisto;

ok( Alien::libhisto->cflags, 'Alien::libhisto->cflags returns string' );
ok( Alien::libhisto->libs,   'Alien::libhisto->libs returns string' );
note "cflags: " . (Alien::libhisto->cflags // 'undef');
note "libs:   " . (Alien::libhisto->libs // 'undef');
note "install_type: " . Alien::libhisto->install_type;

done_testing;
