use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
my $beagle_cmd = Beagle::Test->beagle_command;

Beagle::Test->init_kennel;

run_ok( $beagle_cmd, [qw/init --name foo --type fs/], 'init foo' );
is( last_script_stdout(), 'initialized.' . newline(), 'init output' );

run_ok(
    $beagle_cmd,
    [qw/article --title foo --body bar -n foo/],
    "create article foo",
);

ok( last_script_stdout() =~ /^created (\w{32}).\s+$/, 'create article output' );

my $id = $1;
run_ok( $beagle_cmd, [ 'cat', $id ], "cat $id right after create", );

ok( last_script_stdout() =~ /bar/, 'cat output' );

done_testing();
