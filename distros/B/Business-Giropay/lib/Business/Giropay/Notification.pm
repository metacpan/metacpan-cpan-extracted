package Business::Giropay::Notification;

=head1 NAME

Business::Giropay::Notification - payment notification object

=cut

use Carp;
use Digest::HMAC_MD5 'hmac_md5_hex';
use Business::Giropay::Types qw/Int Str/;
use Moo;
with 'Business::Giropay::Role::Core';
use namespace::clean;

# see http://api.girocheckout.de/en:girocheckout:resultcodes
my %messages = (
    4000 => 'transaction successful',

    # giropay
    4001 => 'bank offline',
    4002 => 'online banking account invalid',
    4500 => 'Zahlungsaugang unbekannt',

    # Lastschrift
    4051 => 'invalid bank account',

    # Kreditkarte
    4101 => 'issuing country invalid or unknown',
    4102 => '3D-Secure or MasterCard SecureCode authorization failed',
    4103 => 'validation date of card exceeded',
    4104 => 'invalid or unknown card type',
    4105 => 'limited-use card',
    4106 => 'invalid pseudo-cardnumber',
    4107 => 'card stolen, suspicious or marked to move in',

    # PayPal
    4151 => 'invalid PayPal token',
    4152 => 'post-processing necessary at PayPal',
    4153 => 'change PayPal payment method',
    4154 => 'PayPal-payment is not completed',

    # Allgemein
    4501 => 'timeout / no user input',
    4502 => 'user aborted',
    4503 => 'duplicate transaction',
    4504 => 'suspicion of manipulation or payment method temporarily blocked',
    4505 => 'payment method blocked or rejected',
    4900 => 'transaction rejected ',

    # Age verification (giropay)
    4020 => 'age verification successful',
    4021 => 'age verification not possible',
    4022 => 'age verification unsuccessful',
);

=head1 ATTRIBUTES

=head2 reference

Unique GiroCheckout transaction ID.

Should match L<Business::Giropay::Response::Transaction/reference>
from an earlier request.

=cut

has reference => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    init_arg => 'gcReference',
);

=head2 merchantTxId

Merchant transaction ID.

Should match L<Business::Giropay::Response::Transaction/merchantTxId>
from an earlier request.

=cut

has merchantTxId => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    init_arg => 'gcMerchantTxId',
);

=head2 backendTxId

Payment processor transaction ID.

=cut

has backendTxId => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    init_arg => 'gcBackendTxId',
);

=head2 amount

If a decimal currency is used, the amount has to be in the smallest unit of
value, eg. cent, penny.

=cut

has amount => (
    is       => 'ro',
    isa      => Int,
    required => 1,
    init_arg => 'gcAmount',
);

=head2 currency

Three letter currency code.

=cut

has currency => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    init_arg => 'gcCurrency',
);

=head2 resultPayment

Payment result code.

=cut

has resultPayment => (
    is       => 'ro',
    isa      => Int,
    required => 1,
    init_arg => 'gcResultPayment',
);

=head2 message

The descriptive message for L</resultPayment>.

=cut

has message => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $messages{ $_[0]->resultPayment } || '' },
);

=head2 hash

Payment result code.

=cut

has hash => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    init_arg => 'gcHash',
);

=head1 METHODS

=head2 BUILD

Check that the hash matches what we expect. Die on mismatch

=cut

sub BUILD {
    my $self = shift;

    my $verify = hmac_md5_hex(
        join( '',
            $self->reference, $self->merchantTxId, $self->backendTxId,
            $self->amount,    $self->currency,     $self->resultPayment ),
        $self->secret
    );

    croak(
        "Returned HMAC hash ",            $self->hash,
        " does not match expected hash ", $verify
    ) unless $verify eq $self->hash;
}

1;
