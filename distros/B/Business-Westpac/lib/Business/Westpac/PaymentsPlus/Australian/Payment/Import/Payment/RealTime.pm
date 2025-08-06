package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RealTime;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RealTime

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RealTime;

    my $RealTime = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RealTime->new(
        payer_payment_reference => 'REF00005',
        payment_amount => '123.23',
        recipient_reference => 'REF00005',
        account_number => '000002',
        account_name => 'Payee 5',
        bsb_number => '062-000',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
    );

=head1 DESCRIPTION

Class for modeling Real Time payments in the context of Westpac CSV files.

Extends L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>.

=cut

use feature qw/ signatures /;

use Moose;
extends 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Cheque';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

=head1 ATTRIBUTES

All attributes are required, except were stated, and are read only

=over

=item recipient_reference (Str, max 16 chars)

=item account_number (Str, max 15 chars)

=item account_name (Str, max 35 chars)

=item bsb_number (BSBNumber)

=back

=cut

foreach my $str_attr (
    'RecipientReference[16]',
    'AccountNumber[15]',
    'AccountName[35]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

sub record_type { 'RT' }

has [ qw/
    bsb_number
/ ] => (
    is       => 'ro',
    isa      => 'BSBNumber',
    required => 1,
);

=head1 METHODS

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $RealTime->to_csv;

=cut

sub to_csv ( $self ) {

    return $self->attributes_to_csv(
        qw/
            record_type
            recipient_number
            payer_payment_reference
            payment_amount
            recipient_reference
            bsb_number
            account_number
            account_name
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
