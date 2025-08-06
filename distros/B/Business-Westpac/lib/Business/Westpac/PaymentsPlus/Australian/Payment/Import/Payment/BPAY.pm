package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::BPAY;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::BPAY

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::BPAY;

    my $Bpay = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::BPAY->new(
        payer_payment_reference => 'REF00003',
        payment_amount => '191.57',
        recipient_reference => '1234500012',
        bsb_number => '062-000',
        bpay_biller_number => '401234',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
    );

=head1 DESCRIPTION

Class for modeling BPAY payments in the context of Westpac CSV files.

Extends L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>.

=cut

use feature qw/ signatures /;

use Moose;
extends 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

sub record_type { 'B' }

=head1 ATTRIBUTES

All attributes are required, except were stated, and are read only

=over

=item bpay_biller_number (Str, max 10 chars)

=item recipient_reference (Str, max 20 chars)

=back

=cut

foreach my $str_attr (
    'BpayBillerNumber[10]',
    'RecipientReference[20]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $Bpay->to_csv;

=cut

sub to_csv ( $self ) {

    return $self->attributes_to_csv(
        qw/
            record_type
            recipient_number
            payer_payment_reference
            payment_amount
            bpay_biller_number
            recipient_reference
            funding_bsb_number
            funding_account_number
        /
    );
}

=head1 SEE ALSO

L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
