
package AWS::S3::ResponseParser;

use constant DEBUG => $ENV{AWS_S3_DEBUG};
use Moose;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Log::Any qw( $LOG );

has 'expect_nothing' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 0,
    trigger  => sub {
        my ( $self, $expect_nothing) = @_;
        if ( $expect_nothing ) {
            my $code = $self->response->code;
            if ( $code =~ m{^2\d\d} && !$self->response->content ) {
                return; # not sure what jdrago wanted this to do originally
            }
            else {
                if ( $self->_parse_errors() ) {
                    # die $self->friendly_error();
                }
                else {
                    return;
                }
            }
        }
    }
);

has 'response' => (
    is       => 'ro',
    isa      => 'HTTP::Response',
    required => 1,
);

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'libxml' => (
    is       => 'ro',
    isa      => 'XML::LibXML',
    required => 1,
    default  => sub { return XML::LibXML->new() },
);

has 'error_code' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'error_message' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'xml' => (
    is       => 'ro',
    isa      => 'XML::LibXML::Document',
    required => 0,
    lazy    => 1,
    clearer => '_clear_xml',
    default => sub {
        my $self = shift;

        my $src = $self->response->content;
        print STDERR ">>> AWS Response:\n", $src, "\n" if DEBUG;

        return unless $src =~ m/^[[:space:]]*</s;
        return $self->libxml->parse_string( $src );
    }
);

has 'xpc' => (
    is       => 'ro',
    isa      => 'XML::LibXML::XPathContext',
    required => 0,
    lazy    => 1,
    clearer => '_clear_xpc',
    default => sub {
        my $self = shift;
        my $doc = $self->xml;
        return unless $doc;

        my $xpc = XML::LibXML::XPathContext->new( $doc );
        $xpc->registerNs( 's3', 'http://s3.amazonaws.com/doc/2006-03-01/' );

        return $xpc;
    }
);

has 'friendly_error' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    lazy     => 1,
    required => 0,
    default  => sub {
        my $s = shift;

        return unless $s->error_code || $s->error_message;
        $s->type . " call had errors: [" . $s->error_code . "] " . $s->error_message;
    }
);

sub _parse_errors {
    my $self = shift;

    my $src = $self->response->content;

    # Do not try to parse non-xml:
    unless ( $src =~ m/^[[:space:]]*</s ) {
        ( my $code = $src ) =~ s/^[[:space:]]*\([0-9]*\).*$/$1/s;
        $LOG->error('Error response from AWS', {code => $code, msg => $src});
        $self->error_code( $code );
        $self->error_message( $src );
        return 1;
    }    # end unless()

    ## Originally at this point the re-setting of xpc would happen
    ## Does not seem to be needed but it may be a problem area
    ## Feel free to delete - Evan Carroll 2012/06/14
    #### $s->_clear_xpc;

    if ( $self->xpc->findnodes( "//Error" ) ) {
        my $code = $self->xpc->findvalue( "//Error/Code" );
        my $msg = $self->xpc->findvalue( "//Error/Message" );
        $LOG->error('Error response from AWS', {code => $code, msg => $msg});
        $self->error_code( $code );
        $self->error_message( $msg );
        return 1;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
