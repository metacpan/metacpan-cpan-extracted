package MockServer;

use strict;
use IO::Socket::INET;
use IO::Select;

$| = 1;

use vars qw ($socket @messages $select);

sub start {
    # No LocalPort means use any available unprivileged port
    $socket = new IO::Socket::INET(
        LocalAddr => '127.0.0.1',
        Proto     => 'udp',
    ) or die "unable to create socket: $!\n";

    $select = IO::Select->new($socket);
    reset_messages();
    return $socket->sockport();
}

my $_data = "";

sub run {
    my $timeout = shift || 3;
    while (1) {
        my @ready = $select->can_read($timeout);
        last unless @ready;

        $socket->recv($_data, 1024);
        $_data =~ s/^\s+//;
        $_data =~ s/\s+$//;
        last if $_data =~ /^quit/i;

        push @messages, $_data;
    }
}

sub get_messages {
    process();
    return @messages;
}

sub get_and_reset_messages {
    my @msg = get_messages();
    reset_messages();
    return @msg;
}

sub reset_messages { @messages = () }

sub stop {
    my $s_send = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1:' . $socket->sockport(),
        Proto    => 'udp',
    ) or die "failed to create client socket: $!\n";
    $s_send->send("quit");
    $s_send->close();
}

sub process {
    stop();
    run();
}

1;
