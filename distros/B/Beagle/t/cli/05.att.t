use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
use File::Temp 'tempfile';

my $beagle_cmd = Beagle::Test->beagle_command;

my $root = Beagle::Test->init;

run_ok(
    $beagle_cmd,
    [qw/article --title foo --body bar/],
    "create article foo",
);

ok( last_script_stdout() =~ /^created (\w{32}).\s+$/, 'create article output' );

my $pid = $1;

my ( $fh, $filename ) = tempfile( 'beagle_test_att_XXXXXX', TMPDIR => 1 );
print $fh 'this is attachment foo';
close $fh;
my $name = ( splitpath($filename) )[2];

run_ok(
    $beagle_cmd,
    [ 'att', '-p', $pid, '--add', $filename ],
    "create att $name",
);
is( last_script_stdout(), "added $name." . newline(), 'added x.pl' );

run_ok( $beagle_cmd, ['att'], "list att", );
like( last_script_stdout(), qr/1 \S+ $name/, 'list att output' );
run_ok( $beagle_cmd, [ 'att', '-p', $pid ], "list att with --parent", );
like( last_script_stdout(), qr/1 \S+ $name/, 'same output' );

run_ok( $beagle_cmd, [ 'att', 1 ], "show att 1", );
is(
    last_script_stdout(),
    'this is attachment foo',
    'get att content'
);

run_ok( $beagle_cmd, [ 'att', '--delete', 1 ], "delete att 1", );
is(
    last_script_stdout(),
    "deleted $name." . newline(),
    "delete att 1 output"
);

run_ok( $beagle_cmd, ['att'], "list att", );
is( last_script_stdout(), '', "$name is indeed deleted" );

run_ok( $beagle_cmd, ['att', '--prune'], "prune att", );
is(
    last_script_stdout(),
    'no orphans found.' . newline(),
    "$name is indeed deleted"
);

done_testing();

