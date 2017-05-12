use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
my $beagle_cmd = Beagle::Test->beagle_command;

my $root = Beagle::Test->init;
my $name = tweak_name($root);

for my $type (qw/article review task bark/) {
    run_ok(
        $beagle_cmd,
        (
            $type =~ /article|review/
            ? [ $type, qw/--title foo --body bar/ ]
            : [ $type, 'bar' ]
        ),
        "create $type foo",
    );

    ok( last_script_stdout() =~ /^created (\w{32}).\s+$/,
        'create article output' );
    my $id = $1;

    run_ok( $beagle_cmd, ['ls'], "list entries", );

    if ( $type =~ /article|review/ ) {
        is( last_script_stdout(), "$id foo" . newline(), 'list output' );
    }
    else {
        is( last_script_stdout(), "$id bar" . newline(), 'list output' );
    }

    run_ok( $beagle_cmd, [ 'relation', $id ], "relation $id", );
    is( last_script_stdout(), "$id $name" . newline(), "relation $id output" );

    run_ok( $beagle_cmd, [ 'show', '-v', $id ], "show $id", );
    my $show_out = last_script_stdout();
    like( $show_out, qr/id: $id/, 'get id' );

    if ( $type =~ /article|review/ ) {
        like( $show_out, qr/title: foo/, 'get title' );
    }
    like( $show_out, qr/\r?\n\r?\n^bar\s*\Z/m, 'get body' );

    run_ok(
        $beagle_cmd,
        [ 'show', '-v', substr $id, 0, 3 ],
        "show with first 3 letters of $id",
    );
    is( $show_out, last_script_stdout(), 'get same result' );

    my $update = $show_out;
    $update =~ s/bar/barbar/;
    run_ok( $beagle_cmd, [ 'update', $id, '--set', 'body=baz' ],
        "update body", );
    is( last_script_stdout(), "updated $id." . newline(),
        'update body output' );

    run_ok( $beagle_cmd, [ 'show', $id ], "show $id", );
    like( last_script_stdout(), qr/\r?\n\r?\n^baz\s*\Z/m,
        'body is indeed updated' );

    run_ok( $beagle_cmd, [ 'rm', $id ], "rm $id", );
    is( last_script_stdout(), "deleted $id." . newline(), "delete $id" );

    run_ok( $beagle_cmd, ['ls'], "list entries", );
    is( last_script_stdout(), '', "$id is indeed deleted" );
}

done_testing();

