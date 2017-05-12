use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Beagle::Util;
use Test::Script::Run ':all';
my $type = Beagle::Test::which('git') ? 'git' : 'fs';

my $beagle_cmd = Beagle::Test->beagle_command;

use File::Temp 'tempdir';
my $kennel = Beagle::Test->init_kennel;

my $tmpdir = tempdir( CLEANUP => 1 );
for my $name (qw/foo bar/) {
    my $root = catdir( $tmpdir, $name );
    run_ok( $beagle_cmd, [ 'init', $root ], "init $root" );
    my $expect =
      "initialized, please run `beagle follow $root --type $type` to continue.";
    is( last_script_stdout(), $expect . newline(), "init $root output" );
}

my $foo = catdir( $tmpdir, 'foo' );
run_ok( $beagle_cmd, [ 'follow', $foo, qw/--name baz/ ], "follow $foo as baz" );
is( last_script_stdout(), "followed $foo." . newline(), "follow $foo output" );

run_ok( $beagle_cmd, ['exists', 'baz'], 'baz' );
is( last_script_stdout(), 'true' . newline(), 'exists output' );

my $bar = catdir( $tmpdir, 'bar' );
run_ok( $beagle_cmd, [ 'follow', $bar ], "follow $bar" );
is( last_script_stdout(), "followed $bar." . newline(), "follow $bar output" );

run_ok( $beagle_cmd, ['exists', 'bar'], 'bar' );
is( last_script_stdout(), 'true' . newline(), 'exists output' );

run_ok( $beagle_cmd, ['which'], "which" );
is( last_script_stdout(), "global" . newline(), "no default beagle" );

local $ENV{BEAGLE_NAME} = 'baz';
run_ok( $beagle_cmd, ['which'], "which" );
is( last_script_stdout(), "baz" . newline(), "follow $bar output" );

run_ok( $beagle_cmd, [ 'unfollow', 'bar' ], 'unfollow bar' );
is( last_script_stdout(), 'unfollowed bar.' . newline(),
    'unfollow bar output' );
run_ok( $beagle_cmd, [ 'unfollow', 'baz' ], 'unfollow baz' );
is( last_script_stdout(), 'unfollowed baz.' . newline(),
    'unfollow baz output' );

run_ok( $beagle_cmd, ['names'], "names" );
is( last_script_stdout(), '', 'no names' );

done_testing();

