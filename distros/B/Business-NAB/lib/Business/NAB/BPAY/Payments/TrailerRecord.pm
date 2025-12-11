package Business::NAB::BPAY::Payments::TrailerRecord;
$Business::NAB::BPAY::Payments::TrailerRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::BPAY::Payments::TrailerRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Payments::TrailerRecord;

    # parse
    my $Trailer = Business::NAB::BPAY::Payments::TrailerRecord
        ->new_from_record( $line );

    # create
    my $Trailer = Business::NAB::BPAY::Payments::TrailerRecord->new(
        total_number_of_payments => 10,
        total_value_of_payments => 11111,
    );

    my $line = $Trailer->to_record;

=head1 DESCRIPTION

Class for trailer record in the "BPAY Batch User Guide"

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

=item total_number_of_payments (NAB::Type::PositiveIntOrZero)

=item total_value_of_payments (NAB::Type::PositiveIntOrZero)

=back

=cut

foreach my $attr (
    qw/
    total_number_of_payments
    total_value_of_payments
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
    return "A1 A10 A13 A120";
}

=head1 METHODS

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Trailer = Business::NAB::BPAY::Payments::TrailerRecord
        ->new_from_record( $line );

=cut

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $total_number,
        $total_value,
        undef,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne '9' ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        total_value_of_payments  => $total_value,
        total_number_of_payments => $total_number,
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
        "9",
        sprintf( "%010s", $self->total_number_of_payments ),
        sprintf( "%013s", $self->total_value_of_payments ),
        "",
    );

    return $record;
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
