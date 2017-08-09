use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::autoconf;
use Alien::automake;
use Env qw( @PATH );

unshift @PATH, Alien::autoconf->bin_dir;

alien_ok 'Alien::automake';

my $wrapper = sub { [@_] };

if($^O eq 'MSWin32')
{
  eval {
    require Alien::MSYS;
    push @PATH, Alien::MSYS::msys_path();
  };
  $wrapper = sub { [ 'sh', -c => "@_" ] };
}

run_ok($wrapper->($_, '--version'))
  ->success
  ->note for qw( automake aclocal );

done_testing;
