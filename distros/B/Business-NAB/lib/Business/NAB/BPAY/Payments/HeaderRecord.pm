package Business::NAB::BPAY::Payments::HeaderRecord;
$Business::NAB::BPAY::Payments::HeaderRecord::VERSION = '0.01';
=head1 NAME

Business::NAB::BPAY::Payments::HeaderRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Payments::HeaderRecord;

    # parse
    my $Header = Business::NAB::BPAY::Payments::HeaderRecord
        ->new_from_record( $line );

    # create
    my $Header = Business::NAB::BPAY::Payments::HeaderRecord->new(
        bpay_batch_user_id => '01',
        customer_short_name => 'NAB',
        processing_date => DateTime->now,
    );

    my $line = $Header->to_record;

=head1 DESCRIPTION

Class for header record in the "BPAY Batch User Guide"

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

=item bpay_batch_user_id (Str, max length 16)

=item processing_date (NAB::Type::StatementDate, coerced from Str)

=item customer_short_name (Str, max length 20)

=back

=cut

has [
    qw/
        processing_date
        /
] => (
    is       => 'ro',
    isa      => 'NAB::Type::StatementDate',
    required => 1,
    coerce   => 1,
);

foreach my $str_attr (
    'bpay_batch_user_id[16]',
    'customer_short_name[20]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

sub _pack_template {
    return "A1 A16 A20 A8 A99";
}

=head1 METHODS

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Record = Business::NAB::BPAY::Payments::HeaderRecord
        ->new_from_record( $line );

=cut

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $bpay_batch_user_id,
        $customer_short_name,
        $processing_date,
        undef,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne '1' ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        bpay_batch_user_id  => $bpay_batch_user_id,
        customer_short_name => $customer_short_name,
        processing_date     => $processing_date,
    );
}

=head2 to_record

Returns a string constructed from the object's attributes, representing
the record for use in a batch file:

    my $line = $Header->to_record;

=cut

sub to_record ( $self ) {

    my $record = pack(
        $self->_pack_template(),
        "1",
        $self->bpay_batch_user_id,
        $self->customer_short_name,
        $self->processing_date->strftime( '%Y%m%d' ),
        "",
    );

    return $record;
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
