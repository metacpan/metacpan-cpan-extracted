package Business::Payment::SSL;

use Moose::Role;

use namespace::autoclean;
use Net::SSLeay qw(make_headers make_form get_https post_https);

has 'server' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1
);

has 'port' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 443
);

has 'path' => (
    is          => 'rw',
    isa         => 'Str',
    default     => '/'
);

has 'method' => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'POST'
);

sub uri {
    my ( $self ) = @_;
    my $uri = URI->new( $self->server, 'https' );
    $uri->port( $self->port );
    $uri->path( $self->path );

    return $uri;
}

sub request { 
    my ( $self, $headers, $data ) = @_;

    $headers = ref $headers eq 'HASH' ? make_headers(%$headers) : $headers;
    $data    = ref $data eq 'HASH' ? make_form(%$data) : $data;
    my @args = ( $self->server, $self->port, $self->path, $headers, $data );
    my $method = 
    my ( $page, $response, %response_headers ) = 
        ( uc($self->method) eq 'POST' ? post_https(@args) : get_https(@args) );

    return ( $page, $response );
}

no Moose::Role;
1;
