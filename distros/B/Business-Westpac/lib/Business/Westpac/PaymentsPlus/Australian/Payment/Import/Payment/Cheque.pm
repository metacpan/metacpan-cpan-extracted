package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Cheque;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Cheque

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Cheque;

    my $Cheque = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Cheque->new(
        payer_payment_reference => 'REF00002',
        payment_amount => '718.65',
        recipient_reference => '100008',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
    );

=head1 DESCRIPTION

Class for modeling Cheque payments in the context of Westpac CSV files.

Extends L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>.
=cut

use feature qw/ signatures /;

use Moose;
extends 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

sub record_type { 'C' }

=head1 ATTRIBUTES

All attributes are optional, except were stated, and are read only

=over

=item recipient_reference (Str, max 7 chars)

=back

=cut

foreach my $str_attr (
    'RecipientReference[7]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

=head1 METHODS

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $Cheque->to_csv;

=cut

sub to_csv ( $self ) {

    return $self->attributes_to_csv(
        qw/
            record_type
            recipient_number
            payer_payment_reference
            payment_amount
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
