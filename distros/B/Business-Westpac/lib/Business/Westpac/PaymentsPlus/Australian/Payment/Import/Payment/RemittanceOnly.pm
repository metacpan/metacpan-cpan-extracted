package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RemittanceOnly;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RemittanceOnly

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RemittanceOnly;

    my $RemittanceOnly = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RemittanceOnly->new(
        payer_payment_reference => 'REF00006',
        payment_amount => '16.35',
        recipient_reference => 'REF00006',
    );

=head1 DESCRIPTION

Class for modeling Remittance Only payments in the context of Westpac CSV files.

Extends L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>.

=cut

use feature qw/ signatures /;

use Moose;
extends 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

sub record_type { 'RO' }

=head1 ATTRIBUTES

All are inherited from L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>

=cut

=head1 METHODS

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $RemittanceOnly->to_csv;

=cut

sub to_csv ( $self ) {

    return $self->attributes_to_csv(
        qw/
            record_type
            recipient_number
            payer_payment_reference
            recipient_reference
            payment_amount
        /
    );
}

=head1 SEE ALSO

L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment>

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
