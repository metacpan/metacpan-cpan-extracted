use v5.40;
use Test::More;
use blib;
use Acme::Parataxis;
use IO::Socket::INET;
Acme::Parataxis::run(
    sub {
        my $listener = IO::Socket::INET->new( LocalAddr => '127.0.0.1', Listen => 5, Reuse => 1, Blocking => 0 );
        my $port     = $listener->sockport;
        Acme::Parataxis->spawn(
            sub {
                Acme::Parataxis->await_read( $listener, 1000 );
                my $client = $listener->accept();
                if ($client) {
                    syswrite( $client, 'HI' );
                    $client->close();
                }
            }
        );
        my $client = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => $port );
        Acme::Parataxis->await_read( $client, 1000 );
        my $buf;
        sysread( $client, $buf, 2 );
        is $buf, 'HI', 'Socket communication works';
        $client->close();
        $listener->close();
        Acme::Parataxis::stop();
    }
);
done_testing();
