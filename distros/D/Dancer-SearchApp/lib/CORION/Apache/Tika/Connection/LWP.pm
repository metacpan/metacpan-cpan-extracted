package CORION::Apache::Tika::Connection::LWP;
use LWP::UserAgent;
use LWP::ConnCache;
use Promises qw(deferred);
use Try::Tiny;
use Moo;
with 'CORION::Apache::Tika::Connection';

use vars '$VERSION';
$VERSION = '0.06';

has ua => (
    is => 'ro',
    #isa => 'Str',
    default => sub { my $ua= LWP::UserAgent->new(); $ua->conn_cache( LWP::ConnCache->new ); $ua },
);

sub request {
    my( $self, $method, $url, $content, @headers ) = @_;
    # Should initialize
    
    my $content_size = length $content;
    
    # 'text/plain' for the language
    unshift @headers, "Content-Length" => $content_size;
    my %headers= (($content
               ? ('Content' => $content)
               : ()),
               @headers);
    my $res = $self->ua->$method( $url, %headers);
    
    my $p = deferred;
    my ( $code, $response ) = $self->process_response(
        $res->request,                      # request
        $res->code,    # code
        $res->message,    # msg
        $res->decoded_content,                        # body
        $res->headers                      # headers
    );
    $p->resolve( $code, $response );
    
    $p->promise
}

1;