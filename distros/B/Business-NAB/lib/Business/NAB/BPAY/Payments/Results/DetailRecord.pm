package Business::NAB::BPAY::Payments::Results::DetailRecord;
$Business::NAB::BPAY::Payments::Results::DetailRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::BPAY::Payments::Results::DetailRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Payments::Results::DetailRecord;

    # parse
    my $Detail = Business::NAB::BPAY::Payments::Results::DetailRecord;
        ->new_from_record( $line );

    # create
    my $Detail = Business::NAB::BPAY::Payments::Results::DetailRecord->new(
        biller_code => $biller_code,
        payment_account_bsb => $payment_account_bsb,
        payment_account_number => $payment_account_number,
        customer_reference_number => $customer_reference_number,
        amount => $amount,
        lodgement_reference_1 => $lodgement_reference_1,
        lodgement_reference_2 => $lodgement_reference_2,
        lodgement_reference_3 => $lodgement_reference_3,
        return_code => $return_code,
        return_code_desc => $return_code_desc,
        transaction_reference_number => $transaction_reference_number,
    );

    my $line = $Detail->to_record;

=head1 DESCRIPTION

Class for detail record in the "BPAY Batch User Guide" responses

All methods and attributes are inherited from
L<Business::NAB::BPAY::Payments::DetailRecord>

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::BPAY::Payments::DetailRecord';

use Carp qw/ croak /;
no warnings qw/ experimental::signatures /;

=head1 ATTRIBUTES

Additional attributes are inherited from
L<Business::NAB::BPAY::Payments::DetailRecord>

=over

=item return_code (Str, max length 4)

=item return_code_desc (Str, max length 50)

=item transaction_reference_number (Str, max length 21)

=back

=cut

foreach my $str_attr (
    'return_code[4]',
    'return_code_desc[50]',
    'transaction_reference_number[21]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

sub _pack_template {
    return "A1 A10 A6 A9 A20 A13 A10 A20 A50 A4 A50 A21";
}

=head1 METHODS

See L<Business::NAB::BPAY::Payments::DetailRecord> for details of
C<new_from_record> and C<to_record>

=cut

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $biller_code,
        $payment_account_bsb,
        $payment_account_number,
        $customer_reference_number,
        $amount,
        $lodgement_reference_1,
        $lodgement_reference_2,
        $lodgement_reference_3,
        $return_code,
        $return_code_desc,
        $trans_ref_number,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne '2' ) {
        croak( "unsupported record type ($record_type)" );
    }

    $biller_code =~ s/^0+//;
    $amount      =~ s/^0+//;

    return $class->new(
        biller_code                  => $biller_code,
        payment_account_bsb          => $payment_account_bsb,
        payment_account_number       => $payment_account_number,
        customer_reference_number    => $customer_reference_number,
        amount                       => $amount,
        lodgement_reference_1        => $lodgement_reference_1,
        lodgement_reference_2        => $lodgement_reference_2,
        lodgement_reference_3        => $lodgement_reference_3,
        return_code                  => $return_code,
        return_code_desc             => $return_code_desc,
        transaction_reference_number => $trans_ref_number,
    );
}

=head2 is_successful

=head2 is_failed

Boolean check on if the transaction in question was successful or not

    if ( $Detail->is_successful ) {
        ...
    }

=cut

sub is_successful ( $self ) { return $self->return_code eq '0000' }
sub is_failed     ( $self ) { return !$self->is_successful }

sub to_record ( $self ) {

    # remove the - char (well, any non-digits). the various specs are
    # a bit all over the place, some keep this char and some don't
    my $bsb = $self->payment_account_bsb =~ s/\D//gr;

    my $record = pack(
        $self->_pack_template(),
        "2",
        sprintf( "%010s", $self->biller_code ),
        $bsb,
        $self->payment_account_number,
        $self->customer_reference_number,
        sprintf( "%013s", $self->amount ),
        $self->lodgement_reference_1 // '',
        $self->lodgement_reference_2 // '',
        $self->lodgement_reference_3 // '',
        $self->return_code,
        $self->return_code_desc,
        $self->transaction_reference_number,
    );

    return $record;
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::BPAY::Payments::Results::DetailRecord>

=cut

__PACKAGE__->meta->make_immutable;
