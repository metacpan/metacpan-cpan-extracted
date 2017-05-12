use strict;
use warnings;
use Test::More;
use Test::Exception;
use Dancer::Config 'setting';
use Dancer::Session::Redis;

my $default_server = $ENV{REDIS_SERVER} || '127.0.0.1:6379';

# complete settings
setting redis_session => {
    server => $default_server,
    expire => 60,
};

my $redis_avail = eval { Redis->new(server => $default_server, debug => 0) };
plan skip_all => "Redis-server needs to be running on '$default_server' for tests" unless $redis_avail;

my $session;
lives_ok { $session = Dancer::Session::Redis->create } 'Session engine created okay';

isa_ok  $session, 'Dancer::Session::Redis', 'Engine was blessed correctly';

my $sid = $session->id;
ok      $sid,                               'Session has an session-id';
like    $sid,   qr{\d{10,}},                'Session-id contains a bunch of digits';

# unknown session-id
my $s1 = Dancer::Session::Redis->retrieve('XXX');
is      $s1,    undef,                      'Unknown session cannot be found';

# known session-id
my $s2 = Dancer::Session::Redis->retrieve($sid);
isa_ok  $s2,    'Dancer::Session::Redis',   'Session object was blessed correctly';
is      $s2->id, $sid,                      'Got session-id equals to passed session-id';

done_testing();
