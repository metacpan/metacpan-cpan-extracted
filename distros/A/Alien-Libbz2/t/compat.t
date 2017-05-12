use Test2::Bundle::Extended;
use Alien::bz2;

diag '';
diag '';
diag '';

diag 'cflags          = ' . Alien::bz2->cflags;
diag 'libs            = ' . Alien::bz2->libs;
diag 'dlls            = ' . $_ for Alien::bz2->dlls;
diag 'version         = ' . Alien::bz2->version;
diag 'install_type    = ' . Alien::bz2->install_type;

diag '';
diag '';

ok 1;

done_testing;
