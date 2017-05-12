package Business::Giropay::Role::Response;

=head1 NAME

Business::Giropay::Role::Response - Moo::Role consumed by all Response classes

=cut

use Carp;
use Digest::HMAC_MD5 'hmac_md5_hex';
use Business::Giropay::Types qw/Bool HashRef Int Maybe Str/;
use JSON::MaybeXS;
use Moo::Role;
with 'Business::Giropay::Role::Network';

=head1 ATTRIBUTES

=head2 json

The json message data returned from giropay. Required.

=cut

has json => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 data

L</json> data converted to a hash reference.

=cut

has data => (
    is       => 'lazy',
    isa      => HashRef,
    init_arg => undef,
);

sub _build_data {
    return decode_json( shift->json );
}

=head2 rc

Response code / error number.

=cut

has rc => (
    is       => 'lazy',
    isa      => Int,
    init_arg => undef,
);

sub _build_rc {
    shift->data->{rc};
}

=head2 msg

Additional information on error (possibly empty).

=cut

has msg => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_msg {
    shift->data->{msg};
}

=head2 hash

The HMAC hash of the returned message. Required.

=cut

has hash => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 secret

The Giropay shared secret for current C</merchantId> and C</projectId>,

=cut

has secret => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 success

Boolean response indicating whether L</rc> indicates success.

=cut

has success => (
    is => 'lazy',
    isa => Bool,
    init_arg => undef,
);

sub _build_success {
    return shift->rc == 0 ? 1 : 0;
}

=head1 METHODS

=head2 BUILD

Check that the hash matches what we expect. Die on mismatch

=cut

sub BUILD {
    my $self = shift;

    my $verify = hmac_md5_hex( $self->json, $self->secret );

    croak(
        "Returned HMAC hash ", $self->hash,
        " does not match expected hash ", $verify, " for json ", $self->json
    ) unless $verify eq $self->hash;
}

1;
