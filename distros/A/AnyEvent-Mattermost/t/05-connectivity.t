#!/usr/bin/env perl

use Test::More;
use AnyEvent;
use AnyEvent::Mattermost;

$SIG{__DIE__} = sub { warn @_; die @_ };

my $host = $ENV{'MATTERMOST_HOST'};
my $team = $ENV{'MATTERMOST_TEAM'};
my $user = $ENV{'MATTERMOST_USER'};
my $pass = $ENV{'MATTERMOST_PASS'};

if ($host && $team && $user && $pass) {
    plan tests => 4;
}
else {
    plan skip_all => 'No MATTERMOST_{HOST,TEAM,USER,PASS} env vars for testing.';
}

my $mconn = AnyEvent::Mattermost->new($host, $team, $user, $pass);
isa_ok($mconn, 'AnyEvent::Mattermost');

my $c = AnyEvent->condvar;

$mconn->on( 'hello' => sub {
    my ($self, $msg) = @_;
    isa_ok($self, 'AnyEvent::Mattermost', 'callback received appropriate AE object');
    ok(ref($msg) eq 'HASH', 'received message is a hashref');
    ok($mconn->started, 'connection started before messages received');

    $mconn->stop;
});

# TODO: more tests!

$mconn->start;
$c->recv;
