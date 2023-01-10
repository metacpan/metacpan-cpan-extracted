# Tests for Connector::Builtin::File::Path
#

use strict;
use warnings;
use English;

use Test::More tests => 24;

# diag "LOAD MODULE\n";

Log::Log4perl->easy_init( { level   => 'ERROR' } );

BEGIN {
    use_ok( 'Connector::Builtin::File::Path' );
}

require_ok( 'Connector::Builtin::File::Path' );


# diag "Connector::Proxy::File::Path tests\n";
###########################################################################
my $conn = Connector::Builtin::File::Path->new(
    {
	LOCATION  => 't/config/',
    });

ok($conn->set('test.txt', 'Hello'),'write file');
is($conn->get('test.txt'), 'Hello');

$conn->file('[% ARGS.0 %].txt');
# diag "Use dynamic filename";
ok($conn->set('test', 'Hello Alice'),'write file');
ok(-f 't/config/test.txt', 'file exists');
is($conn->get('test'), 'Hello Alice');


$conn->content("[% HELLO %] - [% NAME %]\n");
# diag "Use dynamic content";
ok($conn->set('test', { HELLO => 'Hello', NAME => 'Alice'}),'write file');
is($conn->get('test'), "Hello - Alice\n");

# diag "Append";
$conn->ifexists('append');
ok($conn->set('test', { HELLO => 'Hello', NAME => 'Bob'}),'write file');
is($conn->get('test'), "Hello - Alice\nHello - Bob\n");

# diag "Fail on Exist";
$conn->ifexists('fail');
eval {
    $conn->set('test', 'wont see');
};
like($EVAL_ERROR,"/File .* exists/",'die on overwrite');
is($conn->get('test'), "Hello - Alice\nHello - Bob\n");

# diag "Silent Fail";
$conn->ifexists('silent');
eval {
    $conn->set('test', 'wont see');
};
is( $EVAL_ERROR, '', 'silent fail');
is($conn->get('test'), "Hello - Alice\nHello - Bob\n");

is($conn->get_meta()->{TYPE}, 'connector', 'Identifies as connector');
is($conn->get_meta('test')->{TYPE}, 'scalar', 'Identifies as scalar');

ok ($conn->exists(''), 'Connector exists');
ok ($conn->exists('test'), 'Node Exists');
ok ($conn->exists( [ 'test' ] ), 'Leaf Exists Array');
ok (!$conn->exists('test2'), 'Not exists');

$conn->mode("8999");
$conn->ifexists('replace');
eval { $conn->set('testumask', 'wont see'); };
like( $EVAL_ERROR, "/Given mode string '8999' is not valid/", 'wrong umask');

$conn->mode("0640");
$conn->set('testumask', 'wont see');

SKIP: {
    skip  "skipping chown test - set CONN_PATH_USER in ENV", 1 unless ( $ENV{CONN_PATH_USER} );
    $conn->user($ENV{CONN_PATH_USER} );
    $conn->set('testuser', 'wont see');
    is ($ENV{CONN_PATH_USER}, getpwuid(( stat "t/config/testuser.txt")[4]));
}

SKIP: {
    skip  "skipping chown test - set CONN_PATH_GROUP in ENV", 1 unless ( $ENV{CONN_PATH_GROUP} );
    $conn->group($ENV{CONN_PATH_GROUP} );
    $conn->set('testuser', 'wont see');
    is ($ENV{CONN_PATH_GROUP}, getgrgid(( stat "t/config/testuser.txt")[5]));
}
