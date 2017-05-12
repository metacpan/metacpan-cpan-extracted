use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
use File::Temp 'tempdir';
my $beagle_cmd = Beagle::Test->beagle_command;

Beagle::Test->init_kennel;

{
    run_ok( $beagle_cmd, [qw/init --name foo --type fs/], 'init foo' );
    is( last_script_stdout(), 'initialized.' . newline(), 'init output' );

    run_ok( $beagle_cmd, [qw/rename foo bar/], 'rename foo to bar' );
    is( last_script_stdout(), 'renamed foo to bar.' . newline(), 'rename output' );
}

SKIP: {
    skip 'no git found' => 2 unless Beagle::Test::which('git');
    my $dir = catdir( tempdir( CLEANUP => 1 ), 'foo' );
    run_ok( $beagle_cmd, [ 'init', $dir, '--type', 'git' ], 'init foo' );
    my $expect =
      "initialized, please run `beagle follow $dir --type git` to continue.";
    is( last_script_stdout(), $expect . newline(), 'init output' );
}

done_testing();

