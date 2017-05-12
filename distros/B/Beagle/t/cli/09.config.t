use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
my $beagle_cmd = Beagle::Test->beagle_command;

my $root = Beagle::Test->init;

run_ok( $beagle_cmd, [ 'config', ], "config" );
is( last_script_stdout(), '', 'config output' );

run_ok( $beagle_cmd, [ 'config', '--set', 'user_name=sunnavy', ],
    "config --set" );
is( last_script_stdout(), 'set user_name.' . newline, 'config --set output' );

run_ok( $beagle_cmd, [ 'config', ], "config" );
is( last_script_stdout(), 'user_name: sunnavy' . newline, 'config output' );

run_ok( $beagle_cmd, [ 'config', '--unset', 'user_name', ], "config --unset" );
is( last_script_stdout(), 'unset user_name.' . newline, 'config --unset output' );

run_ok( $beagle_cmd, ['config'], "config" );
is( last_script_stdout(), '', 'config output' );

done_testing();
