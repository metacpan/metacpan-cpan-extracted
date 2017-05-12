package Business::Giropay::Request::Transaction;

=head1 NAME

Business::Giropay::Request::Transaction - start payment transaction request

=cut

use Business::Giropay::Types qw/Int Maybe Str/;
use Carp;
use Moo;
with 'Business::Giropay::Role::Request', 'Business::Giropay::Role::Urls';
use namespace::clean;

=head1 ATTRIBUTES

See L<Business::Giropay::Role::Request/ATTRIBUTES> for attributes common to
all request classes and also L<Business::Giropay::Role::Urls/ATTRIBUTES>.

=head2 response_class

The response class to use. Defaults to
L<Business::Giropay::Response::Transaction>.

=cut

has response_class => (
    is      => 'ro',
    isa     => Str,
    default => "Business::Giropay::Response::Transaction",
);

=head2 merchantTxId

Unique transaction ID to identify this request.

=cut

has merchantTxId => (
    is       => 'ro',
    isa      => Str,    # Varchar [255]
    required => 1,
);

=head2 amount

Amount of transaction in cents/pennies/etc so EUR 23.54 will be 2354.

=cut

has amount => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

=head2 currency

Three letter currency code, e.g.: EUR for Euros

=cut

has currency => (
    is       => 'ro',
    isa      => Str,                   # Char [3]
    required => 1,
    coerce   => sub { uc( $_[0] ) },
);

=head2 purpose

Short purpose for transaction, e.g.: product purchase

=cut

has purpose => (
    is       => 'ro',
    isa      => Str,    # Varchar [27]
    required => 1,
);

=head2 bic

Bank BIC code. Required for eps and giropay.

=cut

has bic => (
    is      => 'rwp',
    isa     => Str,     # Varchar [11]
    default => '',
);

=head2 iban

Bank account IBAN. Optional for giropay only.

=cut

has iban => (
    is      => 'ro',
    isa     => Str,     # Varchar [34]
    default => '',
);

=head2 issuer

iDEAL issuer bank. Required for ideal only.

=cut

has issuer => (
    is      => 'rwp',
    isa     => Str,
    default => '',
);

=head2 info1Label

Optional for giropay only.

=head2 info1Text

Text for L</info1Label>.

=head2 info2Label

Optional for giropay only.

=head2 info2Text

Text for L</info2Label>.

=head2 info3Label

Optional for giropay only.

=head2 info3Text

Text for L</info3Label>.

=head2 info4Label

Optional for giropay only.

=head2 info4Text

Text for L</info4Label>.

=head2 info5Label

Optional for giropay only.

=head2 info5Text

Text for L</info5Label>.

=cut

has [qw(info1Label info2Label info3Label info4Label info5Label)] => (
    is      => 'ro',
    isa     => Str,    # Varchar [30]
    default => '',
);

has [qw(info1Text info2Text info3Text info4Text info5Text)] => (
    is      => 'ro',
    isa     => Str,    # Varchar [80]
    default => '',
);

=head2 urlRedirect

Override to make it required.

=cut

has '+urlRedirect' => (
    required => 1,
);

=head2 urlNotify

Shop URL to which the outgoing payment is reported.

=cut

has '+urlNotify' => (
    required => 1,
);

=head1 METHODS

See L<Business::Giropay::Role::Request/METHODS> in addition to the following:

=head2 BUILD

Different networks require different attributes to be set. Check for them here.

=cut

sub BUILD {
    my $self = shift;
    if ( $self->network =~ /^(eps|giropay)$/ ) {
        croak "Missing required argument: bic" unless $self->bic;
    }
    elsif ( $self->network eq 'ideal' ) {
        croak "Missing required argument: issuer" unless $self->issuer;
    }
}

=head2 parameters

Returns additional parameters for the request.

=cut

sub parameters {
    return [
        qw/merchantTxId amount currency purpose bic iban issuer
          info1Label info1Text info2Label info2Text info3Label
          info3Text info4Label info4Text info5Label info5Text
          urlRedirect urlNotify/
    ];
}

=head2 sandbox_data \%data

Clean up data to be submitted in request to contain only safe data for testing.

It is not normally necessary to call this method since it happens automatically
if L<Business::Giropay::Role::Core/sandbox> is true.

=cut

sub sandbox_data {
    my $self = shift;
    if ( $self->network eq 'ideal' ) {
        $self->_set_issuer('RABOBANK');
    }
    else {
        $self->_set_bic('TESTDETT421');
    }
}

=head2 uri

Returns the URI to be appended to L<Business::Giropay::Role::Request/base_uri>
to construct the appropriate URL for the request.

=cut

sub uri {
    return 'transaction/start';
}

1;
