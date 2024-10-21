use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::fpm;

use Env qw( @GEM_PATH );

alien_diag 'Alien::fpm';
alien_ok 'Alien::fpm';

unshift @GEM_PATH, Alien::fpm->dist_dir;

# Make sure fpm is installed
run_ok(['fpm', '--version'])
  ->success
  ->note;

done_testing;
