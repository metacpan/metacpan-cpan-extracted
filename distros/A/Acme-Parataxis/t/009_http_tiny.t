use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
use HTTP::Tiny;
use IO::Socket::INET;
use Time::HiRes qw[time];
use Socket      qw[SHUT_WR];
use POSIX       ();
$|++;
#
package Acme::Parataxis::Test::HTTP {
    use parent 'HTTP::Tiny';

    sub _open_handle {
        my ( $self, $request, $scheme, $host, $port, $peer ) = @_;
        my $handle = Acme::Parataxis::Test::HTTP::Handle->new(
            timeout     => $self->{timeout},
            SSL_options => $self->{SSL_options},
            verify_SSL  => $self->{verify_SSL},
        );
        return $handle->connect( $scheme, $host, $port, $peer );
    }

    sub request {
        my ( $self, $method, $url, $args ) = @_;
        $args //= {};
        my $orig_cb = $args->{data_callback};
        my $content = '';
        $args->{data_callback} = sub {
            my ( $data, $response ) = @_;

            # diag 'Progress: Received ' . length($data) . " bytes for $url";
            if ($orig_cb) {
                return $orig_cb->( $data, $response );
            }
            $content .= $data;
            return 1;
        };
        my $res = $self->SUPER::request( $method, $url, $args );
        $res->{content} = $content unless $orig_cb;
        return $res;
    }
}
{

    package Acme::Parataxis::Test::HTTP::Handle;
    use parent -norequire, 'HTTP::Tiny::Handle';

    sub _do_timeout {
        my ( $self, $type, $timeout ) = @_;
        $timeout //= $self->{timeout};
        if ( $self->{fh} ) {
            my $start = time();
            while (1) {

                # Immediate check using original select (0 timeout)
                return 1 if $self->SUPER::_do_timeout( $type, 0 );

                # Check for overall timeout
                return 0 if ( time() - $start ) > $timeout;

                # Suspend fiber and wait for background I/O check.
                # await_* submits a job and yields 'WAITING'.
                if ( $type eq 'read' ) {
                    Acme::Parataxis->await_read( $self->{fh}, 500 );
                }
                else {
                    Acme::Parataxis->await_write( $self->{fh}, 500 );
                }
            }
        }
        return $self->SUPER::_do_timeout( $type, 0 );
    }
}
Acme::Parataxis::run(
    sub {
        my $listener = IO::Socket::INET->new(
            Listen    => 10,
            LocalAddr => '127.0.0.1',    # Force IPv4
            LocalPort => 0,              # Auto-assign port
            Proto     => 'tcp',
            ReuseAddr => 1,
            Blocking  => 0
            ) or
            die 'Could not create listener: ' . $!;
        my $server_port = $listener->sockport;
        diag 'Mock server listening on 127.0.0.1:' . $server_port;
        #
        Acme::Parataxis->spawn(
            sub {
                while (1) {

                    # Wait for a connection
                    Acme::Parataxis->await_read($listener);
                    my $client = $listener->accept();
                    next unless $client;
                    $client->blocking(0);

                    # SPAWN a new fiber per connection for true concurrency
                    Acme::Parataxis->spawn(
                        sub {
                            # Drain the request headers from client
                            my $buffer = '';
                            while (1) {
                                my $bytes = sysread( $client, $buffer, 4096, length($buffer) );
                                last if $buffer =~ /\r?\n\r?\n/;    # End of headers
                                if ( !defined $bytes ) {
                                    last if $! != POSIX::EAGAIN && $! != POSIX::EWOULDBLOCK;
                                    Acme::Parataxis->await_read( $client, 100 );
                                }
                                last if defined $bytes && $bytes == 0;    # EOF
                            }
                            #
                            my $response = <<~'EOF';
                            HTTP/1.1 200 OK
                            Content-Type: text/plain
                            Content-Length: 2
                            Connection: close

                            HI
                            EOF
                            my $offset = 0;
                            my $len    = length($response);
                            while ( $offset < $len ) {
                                my $written = syswrite( $client, $response, $len - $offset, $offset );
                                if ( defined $written ) {
                                    $offset += $written;
                                }
                                elsif ( $! != POSIX::EAGAIN && $! != POSIX::EWOULDBLOCK ) {
                                    last;
                                }
                                else {
                                    Acme::Parataxis->await_write( $client, 100 );
                                }
                            }
                            $client->shutdown(SHUT_WR);
                            $client->close();
                        }
                    );
                }
            }
        );
        #
        my @urls = ("http://127.0.0.1:$server_port/") x 3;
        my @futures;
        for my $url (@urls) {
            push @futures, Acme::Parataxis->spawn(
                sub {
                    # Create a new HTTP object per fiber to avoid connection state contention
                    my $http = Acme::Parataxis::Test::HTTP->new( timeout => 5 );
                    return $http->get($url);
                }
            );
        }

        # Verify results
        for my $i ( 0 .. $#urls ) {
            my $res = $futures[$i]->await();
            is $res->{status},  200,  'Request ' . ( $i + 1 ) . ' status is 200';
            is $res->{content}, 'HI', 'Request ' . ( $i + 1 ) . ' content is correct';
        }
        $listener->close();
        Acme::Parataxis::stop();
    }
);
#
done_testing();
