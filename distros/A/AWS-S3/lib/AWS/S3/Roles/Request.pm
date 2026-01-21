package AWS::S3::Roles::Request;
use Moose::Role;
use HTTP::Request;
use AWS::S3::ResponseParser;
use MooseX::Types::URI qw(Uri);
use URI::Escape qw/ uri_escape /;
use AWS::S3::Signer::V4;
use Log::Any qw( $LOG );

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
        if ( $m->has_attribute('key') ) {
            my $escaped_path = uri_escape( $self->key,"^A-Za-z0-9\-\._~\/:=" );

            # if we have a leading slash in the key name we need to add *another*
            # slash in the call to ->path to ensure it is retained
            if ( $escaped_path =~ m!^/! && $self->s3->honor_leading_slashes ) {
                $uri->path( '/'.$escaped_path )
            } else {
                $uri->path( $escaped_path )
            }
        }

        $uri->query_keywords( $self->_subresource )
          if $m->has_attribute('_subresource');

        $uri;
    }
);

has 'signerv4' => (
    is       => 'ro',
    isa      => 'AWS::S3::Signer::V4',
    lazy     => 1,
    default  => sub {
        my $s = shift;
        AWS::S3::Signer::V4->new(
            -access_key => $s->s3->access_key_id,
            -secret_key => $s->s3->secret_access_key,
        );
    }
);

sub _send_request {
    my ( $s, $method, $uri, $headers, $content ) = @_;
    $LOG->debug('Making AWS request', {method => $method, uri => "$uri"});

    my $req = HTTP::Request->new( $method => $uri );
    $req->content( $content ) if $content;

    delete($headers->{Authorization}); # we will use a v4 signature
    map { $req->header( $_ => $headers->{$_} ) } keys %$headers;

    $s->_sign($req);
    my $res = $s->s3->ua->request( $req );

    # After creating a bucket and setting its location constraint, we get this
    # strange 'TemporaryRedirect' response.  Deal with it.
    if ( $res->header( 'location' ) && $res->content =~ m{>TemporaryRedirect<}s ) {
        $req->uri( $res->header( 'location' ) );
        $res = $s->s3->ua->request( $req );
    }
    return $s->parse_response( $res );
}

sub _sign {
  my ($s, $request) = @_;
  my $signer = $s->signerv4;
  if (defined $s->s3->session_token) {
    $request->header('X-Amz-Security-Token', $s->s3->session_token);
  }
  my $digest = Digest::SHA::sha256_hex($request->content);
  $request->header('X-Amz-Content-SHA256', $digest);
  $signer->sign($request, $s->s3->region, $digest);
  $request;
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
