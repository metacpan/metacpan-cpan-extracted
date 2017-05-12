use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
my $beagle_cmd = Beagle::Test->beagle_command;

my $root = Beagle::Test->init;

run_ok(
    $beagle_cmd,
    [qw/article --title test --body bar/],
    "create article test",
);

ok( last_script_stdout() =~ /^created (\w{32}).\s+$/, 'create article output' );

my $id = $1;

run_ok(
    $beagle_cmd,
    [ 'mark', '--set', 'foo', '--set', 'bar', $id ],
    "create marks for $id",
);
is( last_script_stdout(), 'updated.' . newline, 'mark --set output' );

run_ok( $beagle_cmd, ['mark'], "list marks", );
is( last_script_stdout(), "$id bar, foo" . newline(), 'mark output' );

run_ok( $beagle_cmd, ['mark'], "list marks", );
is( last_script_stdout(), "$id bar, foo" . newline(), 'mark output' );

run_ok( $beagle_cmd, [ 'mark', '--add', 'baz', $id ], "list marks", );
is( last_script_stdout(), 'updated.' . newline, 'mark --add output' );

run_ok( $beagle_cmd, ['mark'], "list marks", );
is( last_script_stdout(), "$id bar, baz, foo" . newline(), 'mark output' );

run_ok( $beagle_cmd, [ 'mark', '--delete', 'bar', $id ], "list marks", );
is( last_script_stdout(), 'updated.' . newline, 'mark --delete output' );

run_ok( $beagle_cmd, ['mark'], "list marks", );
is( last_script_stdout(), "$id baz, foo" . newline(), 'mark output' );

run_ok( $beagle_cmd, [ 'ls', '--marks', 'foo,bar' ], "list --marks", );
is( last_script_stdout(), '', 'ls --marks output' );

run_ok( $beagle_cmd, [ 'ls', '--marks', 'foo,baz' ], "list --marks", );
is( last_script_stdout(), "$id test" . newline(), 'ls --marks output' );

run_ok( $beagle_cmd, [ 'mark', '--unset', $id ], "list marks", );
is( last_script_stdout(), 'updated.' . newline, 'mark --delete output' );

run_ok( $beagle_cmd, ['mark'], "list marks", );
is( last_script_stdout(), '', 'mark output' );

done_testing();
