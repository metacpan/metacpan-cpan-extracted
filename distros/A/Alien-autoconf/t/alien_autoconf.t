use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::autoconf;
use Env qw( @PATH );
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

alien_ok 'Alien::autoconf';

my $wrapper;
if($^O eq 'MSWin32')
{
  eval {
    require Alien::MSYS;
    push @PATH, Alien::MSYS::msys_path();
  };
  $wrapper = sub { [ 'sh', -c => "@_" ] };
}
else
{
  $wrapper = sub { [@_] };
}

my $dist_dir = path(Alien::autoconf->dist_dir);

run_ok($wrapper->($_, '--version'))
  ->success
  ->note for qw( autoconf autoheader autom4te autoreconf autoscan autoupdate ifnames );

my $configure_ac = path('corpus/configure.ac')->absolute;

subtest 'try with very basic configure.ac' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  $configure_ac->copy('configure.ac');

  run_ok($wrapper->('autoconf', -o => 'configure', $configure_ac))
    ->success
    ->note;

  run_ok($wrapper->('./configure', '--version'))
    ->success
    ->note;
};

done_testing;
