package Business::NAB::BPAY::Remittance::File::HeaderRecord;
$Business::NAB::BPAY::Remittance::File::HeaderRecord::VERSION = '0.01';
=head1 NAME

Business::NAB::BPAY::Remittance::File::HeaderRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Remittance::File::HeaderRecord;

    # parse
    my $Header = Business::NAB::BPAY::Remittance::File::HeaderRecord
        ->new_from_record( $line );

    # create
    my $Header = Business::NAB::BPAY::Remittance::File::HeaderRecord->new(
        biller_code => ...
        biller_short_name => ...
        biller_credit_bsb => ...
        biller_credit_account => ...
        file_creation_date => ...
        file_creation_time => ...
    );

    my $line = $Header->to_record;

=head1 DESCRIPTION

Class for header record in the "BPAY Remittance File"

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

=item biller_short_name (Str, max length 20)

=item biller_credit_bsb (NAB::Type::BSBNumberNoDash)

=item biller_credit_account (NAB::Type::AccountNumber)

=item file_creation_date (NAB::Type::StatementDate)

=item file_creation_time (Str, max length 6)

=back

=cut

foreach my $str_attr (
    'biller_code[10]',
    'biller_short_name[20]',
    'file_creation_time[6]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

has [ qw/ biller_credit_bsb / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::BSBNumberNoDash',
    required => 1,
    coerce   => 1,
);

has [ qw/ biller_credit_account / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::AccountNumber',
    required => 1,
);

has [
    qw/
        file_creation_date
        /
] => (
    is       => 'ro',
    isa      => 'NAB::Type::StatementDate',
    required => 1,
    coerce   => 1,
);

sub _pack_template {
    return "A2 A10 A20 A6 A9 A8 A6";
}

=head1 METHODS

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Record = Business::NAB::BPAY::Remittance::File::HeaderRecord
        ->new_from_record( $line );

=cut

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $biller_code,
        $biller_short_name,
        $biller_credit_bsb,
        $biller_credit_account,
        $file_creation_date,
        $file_creation_time,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne '00' ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        biller_code           => $biller_code,
        biller_short_name     => $biller_short_name,
        biller_credit_bsb     => $biller_credit_bsb,
        biller_credit_account => $biller_credit_account,
        file_creation_date    => $file_creation_date,
        file_creation_time    => $file_creation_time,
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
        "00",
        $self->biller_code,
        $self->biller_short_name,
        $self->biller_credit_bsb,
        $self->biller_credit_account,
        $self->file_creation_date->ymd( '' ),
        $self->file_creation_time,
    );

    return $record;
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
