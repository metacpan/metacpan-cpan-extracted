use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::help2man;
use Env qw( @PATH );

alien_ok 'Alien::help2man';

my @cmd = ('help2man', '--version');

if($^O eq 'MSWin32')
{
  require Alien::MSYS;
  push @PATH, Alien::MSYS::msys_path();
  @cmd = ('sh', -c => 'help2man --version');
}

run_ok(\@cmd)
  ->success
  ->note;

done_testing;
