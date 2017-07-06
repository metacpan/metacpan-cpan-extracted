use Test2::V0;
use Test::Alien;
use Alien::autoconf;
use Alien::automake;
use Env qw( @PATH );

skip_all 'hard coded perl paths.  fun.';

unshift @PATH, Alien::autoconf->bin_dir;

alien_ok 'Alien::automake';

my @cmd = ('automake', '--version');

if($^O eq 'MSWin32')
{
  require Alien::MSYS;
  push @PATH, Alien::MSYS::msys_path();
  @cmd = ('sh', -c => 'automake --version');
}

run_ok(\@cmd)
  ->success
  ->note;

done_testing;
