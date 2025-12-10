package Business::NAB::BPAY::Remittance::File::TrailerRecord;
$Business::NAB::BPAY::Remittance::File::TrailerRecord::VERSION = '0.01';
=head1 NAME

Business::NAB::BPAY::Remittance::File::TrailerRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Remittance::File::TrailerRecord;

    # parse
    my $Trailer = Business::NAB::BPAY::Remittance::File::TrailerRecord
        ->new_from_record( $line );

    # create
    my $Trailer = Business::NAB::BPAY::Remittance::File::TrailerRecord->new(
        biller_code => ...
        number_of_payments => ...
        amount_of_payments => ...
        number_of_error_corrections => ...
        amount_of_error_corrections => ...
        number_of_reversals => ...
        amount_of_reversals => ...
        settlement_amount => ...
    );

    my $line = $Trailer->to_record;

=head1 DESCRIPTION

Class for trailer record in the "BPAY Remittance File"

=cut;

use strict;
use warnings;
use feature qw/ signatures /;

use Carp qw/ croak /;
use Moose;
use Business::NAB::Types qw/
    add_max_string_attribute
    /;

no warnings qw/ experimental::signatures /;

=head1 ATTRIBUTES

=over

=item biller_code (Str, max length 10)

=item number_of_payments (NAB::Type::BRFInt)

=item amount_of_payments (NAB::Type::BRFInt)

=item number_of_error_corrections (NAB::Type::BRFInt)

=item amount_of_error_corrections (NAB::Type::BRFInt)

=item number_of_reversals (NAB::Type::BRFInt)

=item amount_of_reversals (NAB::Type::BRFInt)

=item settlement_amount (NAB::Type::BRFInt)

=back

=cut

foreach my $str_attr (
    'biller_code[10]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

foreach my $attr (
    qw/
    number_of_payments
    amount_of_payments
    number_of_error_corrections
    amount_of_error_corrections
    number_of_reversals
    amount_of_reversals
    settlement_amount
    /
) {
    has $attr => (
        is       => 'ro',
        isa      => 'NAB::Type::BRFInt',
        required => 1,
        coerce   => 1,
        trigger  => sub {
            my ( $self, $value, $old_value ) = @_;
            $self->{ $attr } = int( $value );
        },
    );
}

sub _pack_template {
    return "A2 A10 A9 A15 A9 A15 A9 A15 A15";
}

=head1 METHODS

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Trailer = Business::NAB::BPAY::Remittance::File::TrailerRecord
        ->new_from_record( $line );

=cut

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $biller_code,
        $total_payments,
        $amount_payments,
        $total_error,
        $amount_error,
        $total_reversals,
        $amount_reversals,
        $settlement_amount,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne '99' ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        biller_code                 => $biller_code,
        number_of_payments          => $total_payments,
        amount_of_payments          => $amount_payments,
        number_of_error_corrections => $total_error,
        amount_of_error_corrections => $amount_error,
        number_of_reversals         => $total_reversals,
        amount_of_reversals         => $amount_reversals,
        settlement_amount           => $settlement_amount,
    );
}

=head2 to_record

Returns a string constructed from the object's attributes, representing
the record for use in a batch file:

    my $line = $Trailer->to_record;

=cut

sub to_record ( $self ) {

    my $record = pack(
        $self->_pack_template(),
        "99",
        $self->biller_code,
        sprintf( "%09s",  $self->_brf_int( $self->number_of_payments ) ),
        sprintf( "%015s", $self->_brf_int( $self->amount_of_payments ) ),
        sprintf( "%09s",  $self->_brf_int( $self->number_of_error_corrections ) ),
        sprintf( "%015s", $self->_brf_int( $self->amount_of_error_corrections ) ),
        sprintf( "%09s",  $self->_brf_int( $self->number_of_reversals ) ),
        sprintf( "%015s", $self->_brf_int( $self->amount_of_reversals ) ),
        sprintf( "%015s", $self->_brf_int( $self->settlement_amount ) ),
    );

    return $record;
}

sub _brf_int {
    my ( $self, $str ) = @_;

    # trailer record amounts in BPAY Remittance Files use the last
    # character to represent:
    #   - the last digit
    #   - the sign
    #
    # it's a little odd, but i guess they've historically had to squeeze
    # amounts into the 15 available spaces (which are minor units, so 13,
    # which still feels like a lot, but whatever). this is the *only*
    # NAB file type that does this, so it might actually be a BPAY thing
    #
    # see also: NAB::Type::BRFInt in Business::NAB::Types which will coerce
    # NAB's value to an actual signed integer
    my $last_char = chop( $str );

    if ( $str && $str < 0 ) {
        $str *= -1;
        $last_char =~ tr/0-9$/}J-R/;
    } else {
        $last_char =~ tr/0-9$/{A-I/;
    }

    return $str . $last_char;
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
