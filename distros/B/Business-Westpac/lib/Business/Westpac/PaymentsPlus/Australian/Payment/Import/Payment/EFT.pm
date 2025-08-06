package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::EFT;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::EFT

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::EFT;

    my $EFT = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::EFT->new(
        payer_payment_reference => 'REF00001',
        payment_amount => '36.04',
        recipient_reference => 'REF00001',
        account_number => '000002',
        account_name => 'Payee 02',
        bsb_number => '062-000',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
        remitter_name => 'Remitter Name',
    );

=head1 DESCRIPTION

Class for modeling EFT payments in the context of Westpac CSV files.

Extends L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>.

=cut

use feature qw/ signatures /;

use Moose;
extends 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RealTime';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

=head1 ATTRIBUTES

All attributes are optional, except were stated, and are read only

=over

=item recipient_reference (Str, max 18 chars)

=item remitter_name (Str, optional, max 16 chars)

=back

=cut

foreach my $str_attr (
    'RecipientReference[18]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

foreach my $str_attr (
    'RemitterName[16]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

sub record_type { 'E' }

=head1 METHODS

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $EFT->to_csv;

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
            remitter_name
        /
    );
}

=head1 SEE ALSO

L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
