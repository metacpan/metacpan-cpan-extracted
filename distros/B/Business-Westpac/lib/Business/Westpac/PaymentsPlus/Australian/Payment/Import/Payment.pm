package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment

=head1 SYNOPSIS

    use Moose;
    extends 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment';

=head1 DESCRIPTION

Abstract class for modeling payment data in the context of Westpac CSV files.

=cut

use feature qw/ signatures /;

use Moose;
with 'Business::Westpac::Role::CSV';
no warnings qw/ experimental::signatures /;

use Carp qw/ croak /;
use Business::Westpac::Types qw/
    add_max_string_attribute
/;

sub record_type { croak( "You must override record_type" ); }

=head1 ATTRIBUTES

All attributes are optional, except were stated, and are read only

=over

=item recipient_number (Str, max 20 chars)

=item funding_account_number (Str, max 9 chars)

=item payer_payment_reference (Str, max 15 chars)

=item recipient_reference (Str, max 18 chars)

=item funding_bsb_number (BSBNumber)

=item payment_amount (PositiveNum, required)

=back

=cut

foreach my $str_attr (
    'RecipientNumber[20]',
    'FundingAccountNumber[9]',
    'PayerPaymentReference[15]',
    'RecipientReference[18]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

has [ qw/
    funding_bsb_number
/ ] => (
    is       => 'ro',
    isa      => 'BSBNumber',
    required => 0,
);

has [ qw/
    payment_amount
/ ] => (
    is       => 'ro',
    isa      => 'PositiveNum',
    required => 1,
);

=head1 SEE ALSO

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
