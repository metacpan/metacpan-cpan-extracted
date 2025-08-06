package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::OTT;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::OTT

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::OTT;

    my $OTT = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::OTT->new(
        payer_payment_reference => 'REF00007',
        payment_amount => 759.63,
        payment_currency => 'USD',
        recipient_reference => 'REF00007',
        swift_code => 'WBC12345XXX',
        account_number_iban => '032000000026',
        payee_account_name => 'Payee 07',
        payee_street_1 => 'Level 1',
        payee_street_2 => 'Wallsend Plaza',
        payee_city => 'Wallsend',
        payee_state => 'NSW',
        payee_post_code => '2287',
        payee_country => 'AU',
        funding_amount => 995.58,
        funding_currency => 'AUD',
        dealer_reference => '0123456789',
        exchange_rate => '0.7630',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
        outgoing_payment_information_line_1 => 'REF00071',
        outgoing_payment_information_line_2 => 'REF00072',
    );

=head1 DESCRIPTION

Class for modeling Overseas Telegraphic Transfers in the context
of Westpac CSV files.

Extends L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>.

=cut

use feature qw/ signatures /;

use Moose;
extends 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

sub record_type { 'OTT' }

=head1 ATTRIBUTES

All attributes are required, except were stated, and are read only

=over

=item recipient_reference (Str, max 16 chars)

=item payment_currency (Str, max 3 chars)

=item swift_code (Str, max 11 chars)

=item account_number_iban (Str, max 40 chars)

=item payee_account_name (Str, max 128 chars)

=item payee_street_1 (Str, max 35 chars)

=item payee_country (Str, max 25 chars)

=item payee_country (Str, max 2 chars)

=item intermediary_swift_code (Str, required, max 11 chars)

=item payee_street_2 (Str, required, max 35 chars)

=item payee_street_3 (Str, required, max 35 chars)

=item payee_state (Str, required, max 3 chars)

=item payee_post_code (Str, required, max 9 chars)

=item funding_currency (Str, required, max 3 chars)

=item dealer_reference (Str, required, max 16 chars)

=item outgoing_payment_information_line_1 (Str, required, max 35 chars)

=item outgoing_payment_information_line_2 (Str, required, max 35 chars)

=item charge_bearer_code (Str, required, max 4 chars)

=back

=cut

foreach my $str_attr (
    'RecipientReference[16]',
    'PaymentCurrency[3]',
    'SwiftCode[11]',
    'AccountNumberIban[40]',
    'PayeeAccountName[128]',
    'PayeeStreet_1[35]',
    'PayeeCity[25]',
    'PayeeCountry[2]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

foreach my $str_attr (
    'IntermediarySwiftCode[11]',
    'PayeeStreet_2[35]',
    'PayeeStreet_3[35]',
    'PayeeState[3]',
    'PayeePostCode[9]',
    'FundingCurrency[3]',
    'DealerReference[16]',
    'OutgoingPaymentInformationLine_1[35]',
    'OutgoingPaymentInformationLine_2[35]',
    'ChargeBearerCode[4]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

has [ qw/
    funding_amount
/ ] => (
    is       => 'ro',
    isa      => 'PositiveNum',
    required => 1,
);

has [ qw/
    exchange_rate
/ ] => (
    is       => 'ro',
    isa      => 'PositiveNum',
    required => 1,
);

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $OTT->to_csv;

=cut

sub to_csv ( $self ) {

    return $self->attributes_to_csv(
        qw/
            record_type
            recipient_number
            payer_payment_reference
            payment_amount
            payment_currency
            recipient_reference
            swift_code
            account_number_iban
            intermediary_swift_code
            payee_account_name
            payee_street_1
            payee_street_2
            payee_street_3
            payee_city
            payee_state
            payee_post_code
            payee_country
            funding_amount
            funding_currency
            dealer_reference
            exchange_rate
            funding_bsb_number
            funding_account_number
            outgoing_payment_information_line_1
            outgoing_payment_information_line_2
            charge_bearer_code
        /
    );
}

=head1 SEE ALSO

L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
