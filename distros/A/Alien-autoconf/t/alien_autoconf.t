use Test2::V0 -no_srand => 1;
use Test::Alien 2.52;
use Alien::m4;
use Alien::autoconf;
use Env qw( @PATH );
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

alien_ok 'Alien::m4';
alien_ok 'Alien::autoconf';
plugin_ok 'Build::Autoconf';

run_ok("@{[ Alien::m4->exe ]} --version", 'test if the --version option works with m4')
  ->success
  ->note;


foreach my $command (qw( autoconf autoheader autom4te autoreconf autoscan autoupdate ifnames ))
{
  interpolate_run_ok("\%{$command} --version", "test if the --version options works with $command")
    ->success
    ->note;
}

my $configure_ac = path('corpus/configure.ac')->absolute;

subtest 'try with very basic configure.ac' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  $configure_ac->copy('configure.ac');

  interpolate_run_ok("%{autoconf} -o configure $configure_ac")
    ->success
    ->note;

  interpolate_run_ok('%{configure} --version')
    ->success
    ->note;
};

helper_ok 'autoreconf';

done_testing;
