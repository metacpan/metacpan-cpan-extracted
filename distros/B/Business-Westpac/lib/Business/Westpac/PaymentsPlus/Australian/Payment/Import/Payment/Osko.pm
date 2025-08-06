package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Osko;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Osko

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Osko;
    my $Osko = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Osko->new(
        debtor_information => 'Debtor Information 01',
        payment_amount => '100.00',
        end_to_end_id => 'EndToEndID01',
        account_identifier => '062000000002',
        account_scheme_name => 'BBAN',
        payee_account_name => 'Payee 02',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
        remittance_information_1 => 'Remittance Information 1',
        remittance_information_2 => 'Remittance Information 2',
    );

    my @csv = $Header->to_csv;

=head1 DESCRIPTION

Class for modeling Osko payments in the context of Westpac CSV files.

Extends L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>.

=cut

use feature qw/ signatures /;

use Moose;
extends 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

sub record_type { 'O' }

=head1 ATTRIBUTES

All attributes are optional, except were stated, and are read only

=over

=item debtor_information (Str, max 35 chars)

=item end_to_end_id (Str, max 35 chars)

=item remittance_information_1 (Str, max 140 chars)

=item remittance_information_2 (Str, max 140 chars)

=item account_identifier (Str, max 19 chars, required)

=item account_scheme_name (Str, max 19 chars, required)

=item payee_account_name (Str, max 140 chars, required)

=back

=cut

foreach my $str_attr (
    'DebtorInformation[35]',
    'end_to_end_id[35]',
    'RemittanceInformation_1[140]',
    'RemittanceInformation_2[140]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

foreach my $str_attr (
    'AccountIdentifier[19]',
    'AccountSchemeName[19]',
    'PayeeAccountName[140]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

=head1 METHODS

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $Osko->to_csv;

=cut

sub to_csv ( $self ) {

    return $self->attributes_to_csv(
        qw/
            record_type
            recipient_number
            debtor_information
            payment_amount
            end_to_end_id
            account_identifier
            account_scheme_name
            payee_account_name
            funding_bsb_number
            funding_account_number
            remittance_information_1
            remittance_information_2
        /
    );
}

=head1 SEE ALSO

L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
