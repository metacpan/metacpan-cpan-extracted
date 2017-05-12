
package AWS::S3::HTTPRequest;

use Moose;
use Moose::Util::TypeConstraints;
use AWS::S3::Signer;

use HTTP::Headers;
use URI;

with 'AWS::S3::Roles::Bucket';

my $METADATA_PREFIX      = 'x-amz-meta-';
my $AMAZON_HEADER_PREFIX = 'x-amz-';

enum 'HTTPMethod' => [qw( HEAD GET PUT POST DELETE )];

has 's3' => (
    is       => 'ro',
    required => 1,
    isa      => 'AWS::S3',
);

has 'method' => (
    is       => 'ro',
    required => 1,
    isa      => 'HTTPMethod'
);

has 'path' => (
    is       => 'ro',
    required => 1,
    isa      => 'Str',
);

class_type( 'HTTP::Headers' );

coerce 'HTTP::Headers'
    => from 'HashRef'
    => via { my $h = HTTP::Headers->new( %$_ ) };

has 'headers' => (
    is       => 'ro',
    required => 1,
    isa      => 'HTTP::Headers',
    lazy     => 1,
    default  => sub { HTTP::Headers->new() },
    coerce   => 1,
);

has 'content' => (
    is       => 'ro',
    required => 1,
    isa      => 'Str|ScalarRef|CodeRef',
    default  => '',
);

has 'metadata' => (
    is       => 'ro',
    required => 1,
    isa      => 'HashRef',
    default  => sub { {} },
);

has 'contenttype' => (
    is       => 'ro',
    required => 0,
    isa      => 'Str',
);

# Make the HTTP::Request object:
sub http_request {
    my $s        = shift;
    my $method   = $s->method;
    my $headers  = $s->headers;
    my $content  = $s->content;
    my $metadata = $s->metadata;

    my $uri = $s->bucket_uri( $s->path );

    my $signer = AWS::S3::Signer->new(
        s3      => $s->s3,
        method  => $method,
        uri     => $uri,
        content => $content ? \$content : undef,
        headers => [ $headers->flatten ],
    );

    $headers->header( 'Authorization'  => $signer->auth_header );
    $headers->header( 'Date'           => $signer->date );
    $headers->header( 'Host'           => URI->new( $uri )->host );
    $headers->header( 'content-length' => $signer->content_length ) if $content;
    $headers->header( 'content-type'   => $signer->content_type ) if $content;

    my $request = HTTP::Request->new( $method, $uri, $headers, $content );

    return $request;
}    # end http_request()

__PACKAGE__->meta->make_immutable;

