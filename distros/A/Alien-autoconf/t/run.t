use Test2::V0;
use Test::Alien;
use Alien::autoconf;
use Env qw( @PATH );

alien_ok 'Alien::autoconf';

my @cmd = ('autoconf', '--version');

if($^O eq 'MSWin32')
{
  require Alien::MSYS;
  push @PATH, Alien::MSYS::msys_path();
  @cmd = ('sh', -c => 'autoconf --version');
}

run_ok(\@cmd)
  ->success
  ->note;

done_testing;
