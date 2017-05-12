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
    [qw/article --title foo --body bar/],
    "create article foo",
);

ok( last_script_stdout() =~ /^created (\w{32}).\s+$/, 'create article output' );

my $pid = $1;

run_ok(
    $beagle_cmd,
    [ 'comment', '-p', $pid, 'comment_baz' ],
    "create comment_baz",
);
ok( last_script_stdout() =~ /^created (\w{32}).\s+$/, 'create comment output' );

my $id = $1;

run_ok( $beagle_cmd, ['comments'], "list comments", );
is( last_script_stdout(), "$id comment_baz" . newline(), 'comments output' );
run_ok(
    $beagle_cmd,
    [ 'comments', '-p', $pid ],
    "list comments with --parent",
);
is( last_script_stdout(), "$id comment_baz" . newline(), 'same output' );

run_ok( $beagle_cmd, [ 'show', '-v', $id ], "show $id", );
my $show_out = last_script_stdout();
like( $show_out, qr/id: $id/, 'get id' );

like( $show_out, qr/\r?\n\r?\n^comment_baz\s*\Z/m, 'get body' );

my $update = $show_out;
$update =~ s/bar/barbar/;
run_ok( $beagle_cmd, [ 'update', $id, '--set', 'body=comment_apple' ],
    "update body", );
is( last_script_stdout(), "updated $id." . newline(), 'update body output' );

run_ok( $beagle_cmd, [ 'show', $id ], "show $id", );
like(
    last_script_stdout(),
    qr/\r?\n\r?\n^comment_apple\s*\Z/m,
    'body is indeed updated'
);

run_ok( $beagle_cmd, [ 'rm', $id ], "rm $id", );
is( last_script_stdout(), "deleted $id." . newline(), "delete $id" );

run_ok( $beagle_cmd, ['comments'], "list comments", );
is( last_script_stdout(), '', "$id is indeed deleted" );

done_testing();

