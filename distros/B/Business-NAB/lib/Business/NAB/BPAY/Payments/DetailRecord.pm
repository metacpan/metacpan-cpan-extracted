package Business::NAB::BPAY::Payments::DetailRecord;
$Business::NAB::BPAY::Payments::DetailRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::BPAY::Payments::DetailRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Payments::DetailRecord;

    # parse
    my $Detail = Business::NAB::BPAY::Payments::DetailRecord;
        ->new_from_record( $line );

    # create
    my $Detail = Business::NAB::BPAY::Payments::DetailRecord->new(
        biller_code => $biller_code,
        payment_account_bsb => $payment_account_bsb,
        payment_account_number => $payment_account_number,
        customer_reference_number => $customer_reference_number,
        amount => $amount,
        lodgement_reference_1 => $lodgement_reference_1,
        lodgement_reference_2 => $lodgement_reference_2,
        lodgement_reference_3 => $lodgement_reference_3,
    );

    my $line = $Detail->to_record;

=head1 DESCRIPTION

Class for detail record in the "BPAY Batch User Guide"

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

=item payment_account_bsb (NAB::Type::BSBNumberNoDash)

=item payment_account_number (NAB::Type::AccountNumber)

=item customer_reference_number (Str, max length 20)

=item amount (NAB::Type::PositiveInt)

=item lodgement_reference_1 (Str, max length 10, optional)

=item lodgement_reference_2 (Str, max length 20, optional)

=item lodgement_reference_3 (Str, max length 50, optional)

=back

=cut

has [ qw/ payment_account_bsb / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::BSBNumberNoDash',
    required => 1,
    coerce   => 1,
);

has [ qw/ payment_account_number / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::AccountNumber',
    required => 1,
);

has [ qw/ amount / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveInt',
    required => 1,
);

foreach my $str_attr (
    'biller_code[10]',
    'customer_reference_number[20]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

foreach my $str_attr (
    'lodgement_reference_1[10]',
    'lodgement_reference_2[20]',
    'lodgement_reference_3[50]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

sub _pack_template {
    return "A1 A10 A6 A9 A20 A13 A10 A20 A50 A5";
}

=head1 METHODS

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Record = Business::NAB::BPAY::Payments::DetailRecord
        ->new_from_record( $line );

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
        undef,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne '2' ) {
        croak( "unsupported record type ($record_type)" );
    }

    $biller_code =~ s/^0+//;
    $amount      =~ s/^0+//;

    return $class->new(
        biller_code               => $biller_code,
        payment_account_bsb       => $payment_account_bsb,
        payment_account_number    => $payment_account_number,
        customer_reference_number => $customer_reference_number,
        amount                    => $amount,
        lodgement_reference_1     => $lodgement_reference_1,
        lodgement_reference_2     => $lodgement_reference_2,
        lodgement_reference_3     => $lodgement_reference_3,
    );
}

=head2 to_record

Returns a string constructed from the object's attributes, representing
the record for use in a batch file:

    my $line = $Detail->to_record;

=cut

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
    );

    return $record;
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
