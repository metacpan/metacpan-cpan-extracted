use strict;
use Test::More tests => 8;

use Apache::Session::PHP;
use PHP::Session;

# init

my %session;
tie %session, 'Apache::Session::PHP', undef, {
    SavePath => 't',
};

$session{foo} = "bar";
$session{bar} = { 'bar' => 1, 'baz' => 2 };

my $sid = $session{_session_id};
untie %session;

# reload

tie %session, 'Apache::Session::PHP', $sid, {
    SavePath => 't',
};

is $session{foo}, 'bar';
is_deeply $session{bar}, { 'bar' => 1, 'baz' => 2 };

untie %session;

# from PHP::Session

ok my $php = PHP::Session->new($sid, { save_path => 't' });
is $php->get('foo'), 'bar';
is_deeply $php->get('bar'), { 'bar' => 1, 'baz' => 2 };
$php->set(xxx => 'yyy');
$php->save;

# from A::S::PHP again

tie %session, 'Apache::Session::PHP', $sid, {
    SavePath => 't',
};

is $session{foo}, 'bar';
is_deeply $session{bar}, { 'bar' => 1, 'baz' => 2 };
is $session{xxx}, 'yyy';

tied(%session)->delete;

untie %session;




