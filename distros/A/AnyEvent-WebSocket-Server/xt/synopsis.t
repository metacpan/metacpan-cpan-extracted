use strict;
use warnings;
use AnyEvent::WebSocket::Client;
use Test::More;
use AnyEvent;

######################

use AnyEvent::Socket qw(tcp_server);
use AnyEvent::WebSocket::Server;
        
my $server = AnyEvent::WebSocket::Server->new();
        
my $tcp_server;
$tcp_server = tcp_server undef, 8080, sub {
    my ($fh) = @_;
    $server->establish($fh)->cb(sub {
        my $connection = eval { shift->recv };
        if($@) {
            warn "Invalid connection request: $@\n";
            close($fh);
            return;
        }
        $connection->on(each_message => sub {
            my ($connection, $message) = @_;
            $connection->send($message); ## echo
        });
        $connection->on(finish => sub {
            undef $connection;
        });
    });
};

#####################

## $conn->on(finish => sub { undef $conn }) is (maybe) necessary to
## make the $conn half-immortal

my $client = AnyEvent::WebSocket::Client->new;
my @conns = ();

foreach my $id (0 .. 9) {
    my $conn = $client->connect("ws://127.0.0.1:8080/")->recv;
    push(@conns, { conn => $conn, id => $id });
}

my $finish_cv = AnyEvent->condvar;
my %received_id_counts = ();

foreach my $conn_entry (reverse @conns) {
    $finish_cv->begin;
    $conn_entry->{conn}->on(next_message => sub {
        my ($conn, $message) = @_;
        $received_id_counts{$message->body}++;
        $finish_cv->end;
    });
    $conn_entry->{conn}->send($conn_entry->{id});
}

$finish_cv->recv;
is_deeply \%received_id_counts, +{ map { $_ => 1 } (0..9) }, "received_id_counts OK";

done_testing;
