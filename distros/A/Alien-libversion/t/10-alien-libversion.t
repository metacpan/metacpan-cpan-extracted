#perl -T

use Test2::V0;
use Test::Alien;
use Alien::libversion;

alien_ok 'Alien::libversion';

diag('libs: ' . Alien::libversion->libs);
diag('cflags: ' . Alien::libversion->cflags);
diag('Dynamic libs: ' . join(':', Alien::libversion->dynamic_libs));
diag('bin dir: ' . join(' ', Alien::libversion->bin_dir));

done_testing;
