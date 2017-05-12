# $Id$

use strict;
use Data::YUID::Client;
use File::Spec;
use FindBin qw( $Bin );
use IO::Socket::INET;
use Test::More tests => 25;

use constant PORT => 11000;
our %Children;

END { kill_children() }

start_server(PORT);
start_server(PORT + 1);

## Sleep, wait for servers to start up before connecting workers.
wait_for_port(PORT);
wait_for_port(PORT + 1);

my $client = Data::YUID::Client->new(
        servers => [ map '127.0.0.1:' . $_, PORT, PORT + 1 ],
);
isa_ok($client, 'Data::YUID::Client');

my $id1 = $client->get_id;
isgoodid($id1);

my $id2 = $client->get_id;
isgoodid($id2);

## Kill off all but one of the servers we've started, then try
## to get an ID. Try it 10 times, to make sure we're not just getting
## lucky and hitting the running server.
my @pids = grep $Children{$_} eq 'S', keys %Children;
kill INT => @pids[1..$#pids];
isgoodid($client->get_id) for 1..10;

my %Seen;
sub isgoodid {
    my($id) = @_;
    ok($id, 'The ID ' . $id . ' is non-0');
    ok(!$Seen{$id}++, 'The ID ' . $id . ' has not been seen before');
}

sub start_server {
    my($port) = @_;
    my $server = File::Spec->catfile($Bin, '..', 'bin', 'yuidd');
    my $pid = start_child([ $server, '-p', $port ]);
    $Children{$pid} = 'S';
}

sub start_child {
    my($cmd) = @_;
    my $pid = fork();
    die $! unless defined $pid;
    unless ($pid) {
        exec $^X, '-Iblib/lib', '-Ilib', @$cmd or die $!;
    }
    $pid;
}

sub kill_children {
    kill INT => keys %Children;
}

sub wait_for_port {
    my($port) = @_;
    my $start = time;
    while (1) {
        my $sock = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        return 1 if $sock;
        select undef, undef, undef, 0.25;
        die "Timeout waiting for port $port to startup" if time > $start + 5;
    }
}
