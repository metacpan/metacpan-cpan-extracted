package Business::NAB::Australian::DirectEntry::Payments::TotalRecord;
$Business::NAB::Australian::DirectEntry::Payments::TotalRecord::VERSION = '0.01';
=head1 NAME

Business::NAB::Australian::DirectEntry::Payments::TotalRecord

=head1 SYNOPSIS

    use Business::NAB::Australian::DirectEntry::Payments::TotalRecord;

    # parse
    my $Record = Business::NAB::Australian::DirectEntry
        ::Payments::TotalRecord->new_from_record( $line );

    # create
    my $Record = Business::NAB::Australian::DirectEntry
        ::Payments::TotalRecord->new(
            bsb_number => '123-456',
            net_total_amount => 33333,
            credit_total_amount => 11111,
            debit_total_amount => 22222,
            record_count => 10,
    );

    my $line = $Record->to_record;

=head1 DESCRIPTION

Class for total record in the "Australian Direct Entry Payments and
Dishonour report"

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

=item bsb_number (NAB::Type::BSBNumber)

=item net_total_amount (NAB::Type::PositiveIntOrZero)

=item credit_total_amount (NAB::Type::PositiveIntOrZero)

=item debit_total_amount (NAB::Type::PositiveIntOrZero)

=item record_count (NAB::Type::PositiveIntOrZero)

=back

=cut

has [ qw/ bsb_number / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::BSBNumber',
    required => 1,
    coerce   => 1,
);

foreach my $attr (
    qw/
    net_total_amount
    credit_total_amount
    debit_total_amount
    record_count
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
    return "A1 A7 A12 A10 A10 A10 A24 A6 A40";
}

sub record_type { 7 }

=head1 METHODS

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Record = Business::NAB::Australian::DirectEntry
        ::Payments::TotalRecord->new_from_record( $line );

=cut

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $bsb_number,
        undef,
        $net_total_amount,
        $credit_total_amount,
        $debit_total_amount,
        undef,
        $record_count,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne $class->record_type ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        bsb_number          => $bsb_number,
        net_total_amount    => $net_total_amount,
        credit_total_amount => $credit_total_amount,
        debit_total_amount  => $debit_total_amount,
        record_count        => $record_count,
    );
}

=head2 to_record

Returns a string constructed from the object's attributes, representing
the record for use in a batch file:

    my $line = $Record->to_record;

=cut

sub to_record ( $self ) {

    my $record = pack(
        $self->_pack_template(),
        $self->record_type,
        $self->bsb_number,
        "",
        sprintf( "%010s", $self->net_total_amount ),
        sprintf( "%010s", $self->credit_total_amount ),
        sprintf( "%010s", $self->debit_total_amount ),
        "",
        sprintf( "%06s", $self->record_count ),
        "",
    );

    return $record;
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
