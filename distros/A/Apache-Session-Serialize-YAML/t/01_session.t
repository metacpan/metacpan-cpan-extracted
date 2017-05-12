use strict;
use Test::More tests => 3;

use Apache::Session::Flex;

# init

my %session;
tie %session, 'Apache::Session::Flex', undef, {
    Store => 'File',
    Lock => 'Null',
    Generate => 'MD5',
    Serialize => 'YAML',
    Directory => 't/',
};

$session{foo} = "bar";
$session{bar} = { 'bar' => 1, 'baz' => 2 };

my $sid = $session{_session_id};
untie %session;

ok(-e "t/$sid", "file exists");

# reload

tie %session, 'Apache::Session::Flex', $sid, {
    Store => 'File',
    Lock => 'Null',
    Generate => 'MD5',
    Serialize => 'YAML',
    Directory => 't/',
};

is $session{foo}, 'bar';
is_deeply $session{bar}, { 'bar' => 1, 'baz' => 2 };

tied(%session)->delete;

untie %session;




