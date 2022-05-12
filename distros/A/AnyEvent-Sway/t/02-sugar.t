#!perl -T
# vim:ts=4:sw=4:expandtab

use Test::More tests => 3;
use AnyEvent::Sway;
use AnyEvent;

my $sway = sway();
my $cv = AnyEvent->condvar;

# Try to connect to Sway
$sway->connect->cb(sub { my ($v) = @_; $cv->send($v->recv) });

# But cancel if we are not connected after 0.5 seconds
my $t = AnyEvent->timer(after => 0.5, cb => sub { $cv->send(0) });
my $connected = $cv->recv;

SKIP: {
    skip 'No connection to Sway', 3 unless $connected;

    my $workspaces = sway->get_workspaces->recv;
    isa_ok($workspaces, 'ARRAY');

    ok(@{$workspaces} > 0, 'More than zero workspaces found');

    ok(defined(@{$workspaces}[0]->{num}), 'JSON deserialized');
}

diag( "Testing AnyEvent::Sway $AnyEvent::Sway::VERSION, Perl $], $^X" );
