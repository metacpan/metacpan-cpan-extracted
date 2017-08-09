use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::libtool;
use Env qw( @PATH );
use File::chdir;
use File::Temp qw( tempdir );

alien_ok 'Alien::libtool';

my @cmd = ('libtool', '--version');

my $wrapper = sub { [@_] };

if($^O eq 'MSWin32')
{
  skip_all 'test requires Alien::MSYS on Windows'
    unless eval q{ require Alien::MSYS; 1 };
  push @PATH, Alien::MSYS::msys_path();
  $wrapper = sub { ['sh', -c => "@_"] };
}

run_ok($wrapper->($_, '--version'))
  ->success
  ->note for qw( libtool libtoolize );

subtest 'test running out of blib' => sub {

  local $CWD = tempdir( CLEANUP => 1);
  
  run_ok($wrapper->('libtoolize', '--copy'))
    ->success
    ->note;

};

done_testing;
