package Business::NAB::Australian::DirectEntry::Payments::DetailRecord;
$Business::NAB::Australian::DirectEntry::Payments::DetailRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Payments::DetailRecord

=head1 SYNOPSIS

    use Business::NAB::Australian::DirectEntry::Payments::DetailRecord;

    # parse
    my $Record = Business::NAB::Australian::DirectEntry
        ::Payments::DetailRecord->new_from_record( $line );

    # create
    my $Record = Business::NAB::Australian::DirectEntry
        ::Payments::DetailRecord->new(
            bsb_number => '083-047',
            account_number => '111111111',
            transaction_code => '13',
            amount => 1,
            title_of_account => ' Beneficiary 1',
            lodgement_reference => 'FOR DEMONSTRATION',
            bsb_number_trace => '083-047',
            account_number_trace => '123456789',
            remitter_name => 'NAB SAMPLE  TEST',
            withholding_tax => '00000000',
    );

    my $line = $Record->to_record;

=head1 DESCRIPTION

Class for detail record in the "Australian Direct Entry Payments and
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

=item bsb_number_trace (NAB::Type::BSBNumber)

=item account_number (NAB::Type::AccountNumber)

=item account_number_trace (NAB::Type::AccountNumber)

=item indicator (NAB::Type::Indicator)

=item amount (NAB::Type::PositiveInt)

=item withholding_tax (NAB::Type::PositiveIntOrZero)

=item transaction_code (Str, max length 2)

=item title_of_account (Str, max length 32)

=item lodgement_reference (Str, max length 18)

=item remitter_name (Str, max length 16)

=back

=cut

has [ qw/ bsb_number bsb_number_trace / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::BSBNumber',
    required => 1,
    coerce   => 1,
);

has [ qw/ account_number account_number_trace / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::AccountNumber',
    required => 1,
);

has [ qw/ indicator / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::Indicator',
    required => 0,
    default  => sub { ' ' },
);

has [ qw/ amount / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveInt',
    required => 1,
);

has [ qw/ withholding_tax / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveIntOrZero',
    required => 0,
);

foreach my $str_attr (
    'transaction_code[2]',
    'title_of_account[32]',
    'lodgement_reference[18]',
    'remitter_name[16]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => $str_attr =~ /original/ ? 0 : 1,
    );
}

sub _pack_template {
    return "A1 A7 A9 A1 A2 A10 A32 A18 A7 A9 A16 A8";
}

sub record_type { 1 }

=head1 METHODS

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Record = Business::NAB::Australian::DirectEntry
        ::Payments::DescriptiveRecord->new_from_record( $line );

=cut

sub new_from_record ( $class, $line ) {

    # undef being "this space intentionally left blank"
    my (
        $record_type,
        $bsb_number,
        $account_number,
        $indicator,
        $transaction_code,
        $amount,
        $title_of_account,
        $lodgement_reference,
        $bsb_number_trace,
        $account_number_trace,
        $remitter_name,
        $withholding_tax,
        $rest,
    ) = unpack( $class->_pack_template(), $line );

    my ( $return_code, $orig_day, $orig_user_id );

    if ( $record_type ne $class->record_type ) {
        croak( "unsupported record type ($record_type)" );
    }

    if ( $class->record_type eq '1' ) {

        # payments descriptive record
    } elsif ( $class->record_type eq '2' ) {

        # returns descriptive record
        $return_code  = $indicator;
        $orig_day     = $withholding_tax;
        $orig_user_id = $rest;
    }

    return $class->new(
        bsb_number           => $bsb_number,
        account_number       => $account_number,
        transaction_code     => $transaction_code,
        amount               => $amount,
        title_of_account     => $title_of_account,
        lodgement_reference  => $lodgement_reference,
        bsb_number_trace     => $bsb_number_trace,
        account_number_trace => $account_number_trace,
        remitter_name        => $remitter_name,

        (
            $class->record_type eq '1'
            ? (
                indicator       => $indicator || ' ',
                withholding_tax => $withholding_tax,
                )
            : ()
        ),

        (
            $class->record_type eq '2'
            ? (
                return_code                => $return_code,
                original_day_of_processing => $orig_day,
                original_user_id_number    => $orig_user_id,
                )
            : ()
        ),
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
        $self->account_number,

        $self->record_type eq '1'
        ? $self->indicator
        : $self->return_code,

        $self->transaction_code,
        sprintf( "%010s", $self->amount ),
        $self->title_of_account,
        $self->lodgement_reference,
        $self->bsb_number_trace,
        $self->account_number_trace,
        $self->remitter_name,

        $self->record_type eq '1'
        ? ( $self->withholding_tax )
        : (
            $self->original_day_of_processing,
            $self->original_user_id_number,
        ),
    );

    return $record;
}

=head2 is_debit

=head2 is_credit

Boolean check on the transaction type

    if ( $Record->is_credit ) {
        ...
    }

=cut

sub is_credit ( $self ) {
    return !$self->is_debit;
}

sub is_debit ( $self ) {

    # there's only one debit transaction type code so
    # this is pretty straightforward
    return $self->transaction_code eq '13' ? 1 : 0;
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
