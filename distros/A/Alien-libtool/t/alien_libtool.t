use Test2::V0 -no_srand => 1;
use Test::Alien 2.52;
use Alien::libtool;
use Env qw( @PATH );
use File::chdir;
use File::Temp qw( tempdir );

alien_ok 'Alien::libtool';
plugin_ok 'Build::MSYS';

interpolate_run_ok("%{$_} --version")
  ->success
  ->note for qw( libtool libtoolize );

subtest 'test running out of blib' => sub {

  local $CWD = tempdir( CLEANUP => 1);

  interpolate_run_ok("%{libtoolize} --copy")
    ->success
    ->note;

};

done_testing;
