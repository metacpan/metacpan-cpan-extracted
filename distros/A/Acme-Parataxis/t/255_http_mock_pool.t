use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
use HTTP::Tiny;
use IO::Socket::INET;
use Time::HiRes qw[time];
use POSIX       ();

package Acme::Parataxis::Test::MockPoolHTTP {
    use parent 'HTTP::Tiny';

    sub _open_handle {
        my ( $self, $request, $scheme, $host, $port, $peer ) = @_;
        my $handle = Acme::Parataxis::Test::MockPoolHTTP::Handle->new(
            timeout            => $self->{timeout},
            SSL_options        => $self->{SSL_options},
            verify_SSL         => $self->{verify_SSL},
            keep_alive         => $self->{keep_alive},
            keep_alive_timeout => $self->{keep_alive_timeout}
        );
        return $handle->connect( $scheme, $host, $port, $peer );
    }

    sub request {
        my ( $self, $method, $url, $args ) = @_;
        no warnings 'uninitialized';
        $method //= 'GET';
        my %new_args = %{ $args // {} };
        my $orig_cb  = $new_args{data_callback};
        my $content  = '';
        $new_args{data_callback} = sub {
            my ( $data, $response ) = @_;
            if ($orig_cb) {
                return $orig_cb->( $data, $response );
            }
            $content .= $data;
            return 1;
        };
        my $res = $self->SUPER::request( $method, $url, \%new_args );
        $res->{content} = $content unless $orig_cb;
        return $res;
    }
}

package Acme::Parataxis::Test::MockPoolHTTP::Handle {
    use parent -norequire, 'HTTP::Tiny::Handle';

    sub _do_timeout {
        my ( $self, $type, $timeout ) = @_;
        $timeout //= $self->{timeout} // 60;
        if ( $self->{fh} ) {
            my $start = time();
            while (1) {
                return 1 if $self->SUPER::_do_timeout( $type, 0 );
                my $elapsed = time() - $start;
                return 0 if $elapsed > $timeout;
                my $wait = ( $timeout - $elapsed ) > 0.5 ? 0.5 : ( $timeout - $elapsed );
                if ( $type eq 'read' ) {
                    Acme::Parataxis->await_read( $self->{fh}, int( $wait * 1000 ) );
                }
                else {
                    Acme::Parataxis->await_write( $self->{fh}, int( $wait * 1000 ) );
                }
            }
        }
        return $self->SUPER::_do_timeout( $type, 0 );
    }
}
Acme::Parataxis::run(
    sub {
        # Start a mock HTTP server in a fiber
        my $listener = IO::Socket::INET->new( LocalAddr => '127.0.0.1', Listen => 10, Reuse => 1, Blocking => 0 ) or
            die 'Could not create listener: ' . $!;
        my $server_port = $listener->sockport;
        diag "Mock server listening on port $server_port";
        Acme::Parataxis->spawn(
            sub {
                while (1) {
                    Acme::Parataxis->await_read( $listener, 1000 );
                    while ( my $client = $listener->accept() ) {
                        $client->blocking(0);
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
                            Acme::Parataxis->await_write( $client, 1000 );
                            my $written = syswrite( $client, $response, $len - $offset, $offset );
                            if ( defined $written ) {
                                $offset += $written;
                            }
                            elsif ( $! != POSIX::EAGAIN && $! != POSIX::EWOULDBLOCK ) {
                                last;
                            }
                        }
                        $client->shutdown(1);
                        $client->close();
                    }
                }
            }
        );

        # Testing reentrancy: Use a SINGLE HTTP::Tiny object across multiple concurrent fibers
        my $http     = Acme::Parataxis::Test::MockPoolHTTP->new( timeout => 5, verify_SSL => 0 );
        my $url_base = "http://127.0.0.1:$server_port/";
        my @queue    = ($url_base) x 10;
        my @results;
        my $worker_count = 3;
        my @workers;
        diag "Main: Starting worker pool with $worker_count fibers to process " . scalar(@queue) . " requests...";

        for my $w_id ( 1 .. $worker_count ) {
            push @workers, Acme::Parataxis->spawn(
                sub {
                    while (1) {
                        my $url = shift @queue;
                        last unless $url;
                        my $res = $http->get($url);
                        push @results, $res;
                    }
                    return "Worker $w_id finished.";
                }
            );
        }

        # Wait for all workers to complete
        diag 'Main: Waiting for pool to drain...';
        $_->await for @workers;

        # Verify results
        todo "Shared CVs with yielding cause pad collisions" => sub {
            is( scalar @results, 10, 'Received 10 results' );
            for my $i ( 0 .. $#results ) {
                my $res = $results[$i];
                is( $res->{status},  200,  'Request ' . ( $i + 1 ) . ' status is 200' );
                is( $res->{content}, 'HI', 'Request ' . ( $i + 1 ) . ' content is correct' );
            }
        };
        $listener->close();
        Acme::Parataxis::stop();
    }
);
#
done_testing();
