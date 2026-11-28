use v5.40;
use blib;
use Acme::Parataxis qw[:all];
use IO::Socket::INET;
use POSIX       ();
use Socket      qw[SHUT_WR];
use Time::HiRes qw[time];
$|++;
#
package My::HTTP {
    use parent 'HTTP::Tiny';

    sub _open_handle( $self, $request, $scheme, $host, $port, $peer ) {
        My::HTTP::Handle->new(
            timeout            => $self->{timeout},
            keep_alive         => $self->{keep_alive},
            keep_alive_timeout => $self->{keep_alive_timeout},
            SSL_options        => $self->{SSL_options},
            verify_SSL         => $self->{verify_SSL}
        )->connect( $scheme, $host, $port, $peer );
    }

    # Override request to ensure we capture content correctly in non-blocking mode
    sub request ( $self, $method, $url, $args ) {
        $method //= 'GET';
        my %new_args = %{ $args // {} };
        my $orig_cb  = $new_args{data_callback};
        my $content  = '';
        $new_args{data_callback} = sub ( $data, $response ) {
            return $orig_cb->( $data, $response ) if $orig_cb;
            $content .= $data;
            return 1;
        };
        my $res = $self->SUPER::request( $method, $url, \%new_args );
        $res->{content} = $content unless $orig_cb;
        return $res;
    }
}
#
package My::HTTP::Handle {
    use parent -norequire, 'HTTP::Tiny::Handle';
    use Time::HiRes     qw[time];
    use Acme::Parataxis qw[await_read await_write];

    sub _do_timeout ( $self, $type, $timeout //= $self->{timeout} // 60 ) {
        if ( $self->{fh} ) {
            my $start = time;
            while (1) {

                # Check for readiness NOW (0 timeout)
                return 1 if $self->SUPER::_do_timeout( $type, 0 );

                # Check for overall timeout
                my $elapsed = time() - $start;
                return 0 if $elapsed > $timeout;

                # Suspend fiber and wait for background I/O check.
                # This is where the magic happens: the fiber yields control back
                # to the scheduler while waiting for the socket to be ready.
                my $wait = ( $timeout - $elapsed ) > 0.5 ? 0.5 : ( $timeout - $elapsed );
                if ( $type eq 'read' ) {
                    await_read( $self->{fh}, int( $wait * 1000 ) );
                }
                else {
                    await_write( $self->{fh}, int( $wait * 1000 ) );
                }
            }
        }
        $self->SUPER::_do_timeout( $type, 0 );
    }
}

# Use the integrated scheduler to run concurrent fetches against a local mock
# listener, so the example does not depend on public network access or TLS.
async {
    say 'Starting concurrent fetches...';
    my $listener = IO::Socket::INET->new( Listen => 10, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', ReuseAddr => 1, Blocking => 0 ) or
        die 'Could not create listener: ' . $!;
    my $port = $listener->sockport;
    fiber {
        while (1) {
            my $ready = await_read( $listener, 5000 );
            next unless $ready > 0;
            my $client = $listener->accept();
            next unless $client;
            fiber {
                $client->blocking(0);
                my $buffer = '';
                while (1) {
                    my $bytes = sysread( $client, $buffer, 4096, length($buffer) );
                    last if $buffer =~ /\r?\n\r?\n/;
                    if ( !defined $bytes ) {
                        last if $! != POSIX::EAGAIN && $! != POSIX::EWOULDBLOCK;
                        await_read( $client, 100 );
                    }
                    last if defined $bytes && $bytes == 0;
                }
                my $response = <<~'EOF';
                HTTP/1.1 200 OK
                Content-Type: text/plain
                Content-Length: 2
                Connection: close

                HI
                EOF
                my $offset = 0;
                while ( $offset < length $response ) {
                    my $written = syswrite( $client, $response, length($response) - $offset, $offset );
                    if    ( defined $written )                                { $offset += $written }
                    elsif ( $! != POSIX::EAGAIN && $! != POSIX::EWOULDBLOCK ) {last}
                    else                                                      { await_write( $client, 100 ) }
                }
                $client->shutdown(SHUT_WR);
                $client->close();
            };
        }
    };
    my @urls = map {"http://127.0.0.1:$port/$_"} qw[one two three four];
    my @futures;
    for my $url (@urls) {
        push @futures, fiber {
            my $start = time();
            say sprintf '  [Fiber %d] Fetching %s...', current_fid(), $url;
            my $http    = My::HTTP->new( timeout => 10, verify_SSL => 0 );
            my $res     = $http->get($url);
            my $elapsed = time() - $start;
            say sprintf '  [Fiber %d] Done %s (Status: %d) in %.2fs', current_fid(), $url, $res->{status}, $elapsed;
            return $res;
        };
    }

    # Wait for all fibers to complete and collect results
    for my $i ( 0 .. $#urls ) {
        my $res = await $futures[$i];
        say sprintf 'Final Result for %s: %d %s', $urls[$i], $res->{status}, $res->{reason};
    }
    $listener->close();
    say 'All tasks finished.';
    stop();
};
