package Business::Giropay::Role::Request;

=head1 NAME

Business::Giropay::Role::Request - Moo::Role consumed by all Request classes

=cut

use Business::Giropay::Types qw/Bool Enum HashRef Int Str/;
use Carp;
use Digest::HMAC_MD5 'hmac_md5_hex';
use HTTP::Tiny;
use Module::Runtime 'use_module';

use Moo::Role;
with 'Business::Giropay::Role::Core', 'Business::Giropay::Role::Network';

requires qw(parameters uri);

=head1 ATTRIBUTES

See also L<Business::Giropay::Role::Core> and
L<Business::Giropay::Role::Network>.

=head2 base_uri

The base URI used for all requests. Defaults to:
C<https://payment.girosolution.de/girocheckout/api/v2>

=cut

has base_uri => (
    is      => 'ro',
    isa     => Str,
    default => 'https://payment.girosolution.de/girocheckout/api/v2',
);

=head2 data

The constructed hash reference of parameters to be used in the POST request
to Giropay.

=cut

has data => (
    is       => 'lazy',
    isa      => HashRef,
    init_arg => undef,
);

sub _build_data {
    my $self = shift;

    # we might need to cleanup some data if we are sandboxed
    $self->sandbox_data if $self->sandbox;

    my $data = {
        merchantId => $self->merchantId,
        projectId  => $self->projectId,
        secret     => $self->secret,
        hash       => $self->hash,
    };
    foreach my $parameter ( @{ $self->parameters } ) {
        $data->{$parameter} = $self->$parameter if $self->$parameter;
    }
    return $data;
}

=head2 hash

The constructed HMAC hash of the constructed parameter values sent in the
request. This is built automatically.

=cut

has hash => (
    is       => 'lazy',
    isa      => Str,      # Varchar[32]
    init_arg => undef,
);

sub _build_hash {
    my $self = shift;

    my @parameters;
    foreach my $parameter ( @{ $self->parameters } ) {
        push @parameters, $self->$parameter if $self->$parameter;
    }
    return hmac_md5_hex(
        join( '', $self->merchantId, $self->projectId, @parameters ),
        $self->secret );
}

=head2 url

The full URL for the request. This is built from L</base_uri> along with
the C<uri> attribute of the specific request class.

=cut

has url => (
    is       => 'lazy',
    isa      => Str,
    init_arg => undef,
);

sub _build_url {
    my $self = shift;
    return join( '/', $self->base_uri, $self->uri );
}

=head1 METHODS

=head2 submit

Submits the request to Giropay and returns an appropriate response object.

=cut

sub submit {
    my $self     = shift;
    my $http     = HTTP::Tiny->new( verify_SSL => 1 );
    my $response = $http->post_form( $self->url, $self->data );

    return use_module( $self->response_class )->new(
        network => $self->network,
        hash    => $response->{headers}->{hash},
        json    => $response->{content},
        secret  => $self->secret,
    );
}

=head2 sandbox_data

Individual Request class can override this method to massage data when
L</sandbox> is true.

=cut

sub sandbox_data {}

1;
