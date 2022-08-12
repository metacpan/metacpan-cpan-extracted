use Test2::V0 -no_srand => 1;
use Test::Alien 2.52;
use Alien::autoconf;
use Alien::automake;
use Env qw( @PATH );

unshift @PATH, Alien::autoconf->bin_dir;

alien_ok 'Alien::automake';

interpolate_run_ok("%{$_} --version")
  ->success
  ->note for qw( automake aclocal );

done_testing;
