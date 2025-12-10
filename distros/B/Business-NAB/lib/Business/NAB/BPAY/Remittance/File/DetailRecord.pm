package Business::NAB::BPAY::Remittance::File::DetailRecord;
$Business::NAB::BPAY::Remittance::File::DetailRecord::VERSION = '0.01';
=head1 NAME

Business::NAB::BPAY::Remittance::File::DetailRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Remittance::File::DetailRecord;

    # parse
    my $Detail = Business::NAB::BPAY::Remittance::File::DetailRecord;
        ->new_from_record( $line );

    # create
    my $Detail = Business::NAB::BPAY::Remittance::File::DetailRecord->new(
        biller_code => ...
        customer_reference_number => ...
        payment_instruction_type => ...
        transaction_reference_number => ...
        original_reference_number => ...
        error_correction_reason => ...
        amount => ...
        payment_date => ...
        payment_time => ...
        settlement_date => ...
    );

    my $line = $Detail->to_record;

=head1 DESCRIPTION

Class for detail record in the "BPAY Remittance File"

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

=item customer_reference_number (Str, max length 20)

=item payment_instruction_type (Str, max length 2)

=item transaction_reference_number (Str, max length 21)

=item original_reference_number (Str, max length 21)

=item error_correction_reason (Str, max length 3)

=item amount (NAB::Type::PositiveInt)

=item payment_date (NAB::Type::StatementDate)

=item payment_time (Str, max length 6)

=item settlement_date (NAB::Type::StatementDate)

=back

=cut

has [ qw/ amount / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveInt',
    required => 1,
);

has [ qw/ payment_date settlement_date / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::StatementDate',
    required => 1,
    coerce   => 1,
);

foreach my $str_attr (
    'biller_code[10]',
    'customer_reference_number[20]',
    'payment_instruction_type[2]',
    'transaction_reference_number[21]',
    'original_reference_number[21]',
    'error_correction_reason[3]',
    'payment_time[6]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

sub _pack_template {
    return "A2 A10 A20 A2 A21 A21 A3 A12 A8 A6 A8 A106";
}

=head1 METHODS

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Record = Business::NAB::BPAY::Remittance::File::DetailRecord
        ->new_from_record( $line );

=cut

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $biller_code,
        $customer_reference_number,
        $payment_instruction_type,
        $transaction_reference_number,
        $original_reference_number,
        $error_correction_reason,
        $amount,
        $payment_date,
        $payment_time,
        $settlement_date,
        undef,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne '50' ) {
        croak( "unsupported record type ($record_type)" );
    }

    $biller_code =~ s/^0+//;
    $amount      =~ s/^0+//;

    return $class->new(
        biller_code                  => $biller_code,
        customer_reference_number    => $customer_reference_number,
        payment_instruction_type     => $payment_instruction_type,
        transaction_reference_number => $transaction_reference_number,
        original_reference_number    => $original_reference_number,
        error_correction_reason      => $error_correction_reason,
        amount                       => $amount,
        payment_date                 => $payment_date,
        payment_time                 => $payment_time,
        settlement_date              => $settlement_date,
    );
}

=head2 to_record

Returns a string constructed from the object's attributes, representing
the record for use in a batch file:

    my $line = $Detail->to_record;

=cut

sub to_record ( $self ) {

    my $record = pack(
        $self->_pack_template(),
        "50",
        sprintf( "%010d", $self->biller_code ),
        sprintf( "%-20s", $self->customer_reference_number ),
        sprintf( "%02d",  $self->payment_instruction_type ),
        sprintf( "%21s",  $self->transaction_reference_number ),
        sprintf( "%21s",  $self->original_reference_number ),
        sprintf( "%03d",  $self->error_correction_reason ),
        sprintf( "%012d", $self->amount ),
        $self->payment_date->ymd( '' ),
        $self->payment_time,
        $self->settlement_date->ymd( '' ),
        "",
    );

    return $record;
}

=head2 is_payment

=head2 is_correction

=head2 is_reversal

Boolean check on the record's payment_instruction_type:

    if ( $Detail->is_payment ) {
        ...
    }

=cut

sub is_payment    ( $self ) { return $self->payment_instruction_type eq '05' }
sub is_correction ( $self ) { return $self->payment_instruction_type eq '15' }
sub is_reversal   ( $self ) { return $self->payment_instruction_type eq '25' }

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
