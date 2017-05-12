package AWS::S3::Roles::Request;
use Moose::Role;
use HTTP::Request;
use AWS::S3::ResponseParser;
use MooseX::Types::URI qw(Uri);
use URI::Escape qw/ uri_escape /;

has 's3' => (
    is       => 'ro',
    isa      => 'AWS::S3',
    required => 1,
);

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'protocol' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        shift->s3->secure ? 'https' : 'http';
    }
);

has 'endpoint' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        shift->s3->endpoint;
    }
);

# XXX should be required=>1; https://rt.cpan.org/Ticket/Display.html?id=77863
has "_action" => (
    isa       => 'Str',
    is        => 'ro',
    init_arg  => undef,
    #required  => 1
);

has '_expect_nothing' => ( isa => 'Bool', is => 'ro', init_arg => undef );

has '_uri' => (
    isa     => Uri,
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $m = $self->meta;

        my $uri = URI->new(
            $self->protocol . '://'
            . ( $m->has_attribute('bucket') ? $self->bucket . '.' : '' )
            . $self->endpoint
            . '/'
        );

		# note we add some extra exceptions to uri_escape to prevent
		# encoding of things like "/", ":", "="
        $uri->path( uri_escape( $self->key,"^A-Za-z0-9\-\._~\/:=" ) )
          if $m->has_attribute('key');

        $uri->query_keywords( $self->_subresource )
          if $m->has_attribute('_subresource');

        $uri;
    }
);

sub _send_request {
    my ( $s, $method, $uri, $headers, $content ) = @_;

    my $req = HTTP::Request->new( $method => $uri );
    $req->content( $content ) if $content;
    map { $req->header( $_ => $headers->{$_} ) } keys %$headers;

    my $res = $s->s3->ua->request( $req );

    # After creating a bucket and setting its location constraint, we get this
    # strange 'TemporaryRedirect' response.  Deal with it.
    if ( $res->header( 'location' ) && $res->content =~ m{>TemporaryRedirect<}s ) {
        $req->uri( $res->header( 'location' ) );
        $res = $s->s3->ua->request( $req );
    }
    return $s->parse_response( $res );
}

sub parse_response {
    my ( $self, $res ) = @_;

    AWS::S3::ResponseParser->new(
        response       => $res,
        expect_nothing => $self->_expect_nothing,
        type           => $self->type,
    );
}

1;
