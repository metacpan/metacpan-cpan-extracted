use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
my $beagle_cmd = Beagle::Test->beagle_command;

my $root = Beagle::Test->init;

run_ok( $beagle_cmd, [ 'alias', ], "alias" );
like( last_script_stdout(), qr/^System aliases:/, 'alias output' );

run_ok( $beagle_cmd, [ 'alias', '--set', 'foo=bar', ], "alias --set" );
is( last_script_stdout(), 'set foo.' . newline, 'alias --set output' );

run_ok( $beagle_cmd, [ 'alias', ], "alias" );
like( last_script_stdout(), qr/^Personal aliases:\s+foo: bar/m, 'alias output' );

run_ok( $beagle_cmd, [ 'alias', '--unset', 'foo', ], "alias --unset" );
is( last_script_stdout(), 'unset foo.' . newline, 'alias --unset output' );

run_ok( $beagle_cmd, ['alias'], "alias" );
unlike( last_script_stdout(), qr/^Personal aliases:\s+foo: bar/, 'alias output' );

done_testing();
