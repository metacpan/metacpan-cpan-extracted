use v5.40;
use blib;
$|++;
use Acme::Parataxis;
use IO::Socket::INET;

# Create a simple echo server in a coroutine
Acme::Parataxis::run(
    sub {
        my $server = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 5, Reuse => 1 ) or
            die 'Could not create server: ' . $!;
        my $port = $server->sockport;
        $server->blocking(0);
        $server->autoflush(1);
        say "Server listening on 127.0.0.1:$port";
        my $client_done = 0;
        Acme::Parataxis->spawn(
            sub {
                say 'Client starting...';
                my $client = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp' ) or
                    die 'Could not create client: ' . $!;
                $client->blocking(0);
                $client->autoflush(1);
                say 'Client connected, waiting to write...';
                Acme::Parataxis->await_write($client);
                $client->print("Hello from Parataxis!\n");
                say 'Client waiting for response...';
                Acme::Parataxis->await_read($client);
                my $line = <$client>;
                say 'Client received: ' . ( $line // 'UNDEF' );
                $client->close();
                $client_done = 1;
                say 'Client finished, stopping runtime...';
                Acme::Parataxis::stop();
            }
        );
        while ( !$client_done ) {

            # Check if there is a connection waiting (non-blocking-ish)
            # We use a short sleep to not hog the CPU while polling client_done
            # but in a real app you'd just wait on the server socket.
            my $res = Acme::Parataxis->await_read($server);
            last if $client_done;    # Check immediately after waking up
            if ( $res > 0 ) {
                my $conn = $server->accept();
                if ($conn) {
                    say 'Server accepted connection!';
                    Acme::Parataxis->spawn(
                        sub {
                            $conn->blocking(0);
                            $conn->autoflush(1);
                            say '  Handler started for ' . fileno($conn);
                            Acme::Parataxis->await_read($conn);
                            my $line = <$conn>;
                            if ( defined $line ) {
                                chomp $line;
                                say '  Server echoing: ' . $line;
                                Acme::Parataxis->await_write($conn);
                                $conn->print("Echo: $line\n");
                            }
                            else {
                                say '  Server got EOF';
                            }
                            $conn->close();
                            say '  Handler finished';
                        }
                    );
                }
            }

            # If no client connection and client is done, we exit the loop
            last if $client_done;
        }
        say 'Main server loop exiting...';
        $server->close();
    }
);
say 'Script finished.';
