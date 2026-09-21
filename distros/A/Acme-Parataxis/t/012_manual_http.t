use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
use IO::Socket::INET;
#
Acme::Parataxis::run(
    sub {
        my $listener = IO::Socket::INET->new( LocalAddr => '127.0.0.1', Listen => 5, Reuse => 1, Blocking => 0 );
        my $port     = $listener->sockport;
        Acme::Parataxis->spawn(
            sub {
                Acme::Parataxis->await_read( $listener, 1000 );
                my $client = $listener->accept();
                if ($client) {
                    Acme::Parataxis->await_read( $client, 1000 );
                    my $req;
                    sysread( $client, $req, 1024 );
                    my $res = <<~'EOF';
                    HTTP/1.1 200 OK
                    Content-Length: 2

                    HI
                    EOF
                    Acme::Parataxis->await_write( $client, 1000 );
                    syswrite( $client, $res );
                    $client->close();
                }
            }
        );
        my $client = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => $port );
        my $req    = <<~'EOF';
        GET / HTTP/1.1
        Host: 127.0.0.1

        EOF
        Acme::Parataxis->await_write( $client, 1000 );
        syswrite( $client, $req );
        my $buf;
        eval {
            Acme::Parataxis->await_read( $client, 1000 );
            sysread( $client, $buf, 1024 );
        };
        like $buf, qr/HI/, 'Manual HTTP with eval works';
        $client->close();
        $listener->close();
        Acme::Parataxis::stop();
    }
);
#
done_testing();
