use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
my $beagle_cmd = Beagle::Test->beagle_command;

my $root = Beagle::Test->init;

run_ok( $beagle_cmd, [ 'info', ], "info", );
like( last_script_stdout(), qr/id: \w{32}/, 'info output' );
like(
    last_script_stdout(),
    qr!avatar: system/images/beagle\.png!,
    'default avatar'
);

run_ok( $beagle_cmd, [ 'info', '--set', 'url=http://sunnavy.net', ],
    "info --set", );
is( last_script_stdout(), 'updated info.' . newline, 'info --set output' );
run_ok( $beagle_cmd, [ 'info', ], "info", );
like( last_script_stdout(), qr!url: http://sunnavy\.net!, 'info output' );

run_ok( $beagle_cmd, [ 'info', '--unset', 'url', ], "info --unset", );
is( last_script_stdout(), 'updated info.' . newline, 'info --set output' );

run_ok( $beagle_cmd, [ 'info', ], "info", );
like( last_script_stdout(), qr!url:\s*$!m, 'info output' );

done_testing();
