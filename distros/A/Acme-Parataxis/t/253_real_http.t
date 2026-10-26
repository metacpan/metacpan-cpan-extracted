use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
use HTTP::Tiny;
use Time::HiRes qw[time];

# Check for network connectivity
my $http_check = HTTP::Tiny->new( timeout => 2 );
if ( !$http_check->get('http://www.google.com')->{success} && !$http_check->get('http://www.example.com')->{success} ) {
    skip_all('No network connectivity detected');
}
#
{

    package Acme::Parataxis::Test::RealHTTP;
    use parent 'HTTP::Tiny';

    sub _open_handle {
        my ( $self, $request, $scheme, $host, $port, $peer ) = @_;
        my $handle = Acme::Parataxis::Test::RealHTTP::Handle->new(
            timeout            => $self->{timeout},
            SSL_options        => $self->{SSL_options},
            verify_SSL         => $self->{verify_SSL},
            keep_alive         => $self->{keep_alive},
            keep_alive_timeout => $self->{keep_alive_timeout},
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
{

    package Acme::Parataxis::Test::RealHTTP::Handle;
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
        my $http = Acme::Parataxis::Test::RealHTTP->new( timeout => 10, verify_SSL => 0 );
        my @urls = qw[
            http://example.com
            https://www.google.com/
            https://www.perl.org/
            https://metacpan.org/
            https://www.cpan.org/
            https://github.com/
        ];
        my @futures;

        for my $url (@urls) {
            push @futures, Acme::Parataxis->spawn(
                sub {
                    my $fid = Acme::Parataxis->current_fid;
                    diag "Fiber $fid: Fetching $url...";
                    my $res = $http->get($url);
                    diag "Fiber $fid: Done fetching $url.";
                    $res;
                }
            );
        }
        for my $i ( 0 .. $#urls ) {
            my $url = $urls[$i];
            my $res = $futures[$i]->await();
            todo "External network fetch for $url might fail" => sub {
                is( $res->{status}, 200, "Fetched $url successfully" ) or
                    diag "Failed to fetch $url: $res->{status} $res->{reason}\nContent: " . ( $res->{content} // '' );
                if ( $res->{status} == 200 ) {
                    like( $res->{content}, qr/<html/i, "$url content looks like HTML" );
                }
            };
        }
        Acme::Parataxis::stop();
    }
);
done_testing();
