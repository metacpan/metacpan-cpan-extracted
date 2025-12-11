package Business::NAB::BPAY::Payments::Results::TrailerRecord;
$Business::NAB::BPAY::Payments::Results::TrailerRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::BPAY::Payments::TrailerRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Payments::TrailerRecord;

    # parse
    my $Trailer = Business::NAB::BPAY::Payments::Results::TrailerRecord
        ->new_from_record( $line );

    # create
    my $Trailer = Business::NAB::BPAY::Payments::Results::TrailerRecord->new(
        total_value_of_payments => 189915,
        total_number_of_payments => 5,
        total_number_of_successful_payments => 2,
        total_value_of_successful_payments => 9914,
        total_number_of_declined_payments => 3,
        total_value_of_declined_payments => 180001,
    );

    my $line = $Trailer->to_record;

=head1 DESCRIPTION

Class for trailer record in the "BPAY Batch User Guide" responses

All methods and attributes are inherited from
L<Business::NAB::BPAY::Payments::TrailerRecord>

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::BPAY::Payments::TrailerRecord';

use Carp qw/ croak /;

no warnings qw/ experimental::signatures /;

=head1 ATTRIBUTES

Additional attributes are inherited from
L<Business::NAB::BPAY::Payments::HeaderRecord>

=over

=item total_number_of_successful_payments (NAB::Type::PositiveIntOrZero)

=item total_value_of_successful_payments (NAB::Type::PositiveIntOrZero)

=item total_number_of_declined_payments (NAB::Type::PositiveIntOrZero)

=item total_value_of_declined_payments (NAB::Type::PositiveIntOrZero)

=back

=cut

foreach my $attr (
    qw/
    total_value_of_successful_payments
    total_value_of_declined_payments
    total_number_of_successful_payments
    total_number_of_declined_payments
    /
) {
    has $attr => (
        is       => 'ro',
        isa      => 'NAB::Type::PositiveIntOrZero',
        required => 1,
        trigger  => sub {
            my ( $self, $value, $old_value ) = @_;
            $self->{ $attr } = int( $value );
        },
    );
}

sub _pack_template {
    return "A1 A10 A13 A10 A13 A10 A13";
}

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $total_successful_number,
        $total_successful_value,
        $total_declined_number,
        $total_declined_value,
        $total_transactions,
        $total_value,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne '9' ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        total_number_of_successful_payments => $total_successful_number,
        total_value_of_successful_payments  => $total_successful_value,
        total_number_of_declined_payments   => $total_declined_number,
        total_value_of_declined_payments    => $total_declined_value,
        total_number_of_payments            => $total_transactions,
        total_value_of_payments             => $total_value,
    );
}

sub to_record ( $self ) {

    my $record = pack(
        $self->_pack_template(),
        "9",
        sprintf( "%010s", $self->total_number_of_successful_payments ),
        sprintf( "%013s", $self->total_value_of_successful_payments ),
        sprintf( "%010s", $self->total_number_of_declined_payments ),
        sprintf( "%013s", $self->total_value_of_declined_payments ),
        sprintf( "%010s", $self->total_number_of_payments ),
        sprintf( "%013s", $self->total_value_of_payments ),
    );

    return $record;
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::BPAY::Payments::TrailerRecord>

=cut

__PACKAGE__->meta->make_immutable;
