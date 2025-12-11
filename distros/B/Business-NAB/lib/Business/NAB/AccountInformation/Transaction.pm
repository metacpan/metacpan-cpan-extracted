package Business::NAB::AccountInformation::Transaction;
$Business::NAB::AccountInformation::Transaction::VERSION = '0.02';
=head1 NAME

Business::NAB::AccountInformation::Transaction

=head1 SYNOPSIS

    use Business::NAB::AccountInformation::Transaction;

    my $Transaction = Business::NAB::AccountInformation::Transaction->new(
        transaction_code => $trans_code,
        amount_minor_units => $amount,
        funds_type => $funds_type,
        reference_number => $ref_number,
        text => $text,
    );

=head1 DESCRIPTION

Class for parsing a NAB "Account Information File (NAI/BAI2)" transaction
line (type C<16>).

=cut

use strict;
use warnings;
use feature qw/ signatures state /;
use Carp    qw/ croak /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;

use Text::CSV_XS         qw/ csv /;
use Business::NAB::Types qw/
    add_max_string_attribute
    /;

=head1 ATTRIBUTES

=over

=item transaction_code (Str, max length 3)

=item funds_type (Str, max length 1)

=item bank_reference (Str, max length 4096)

=item customer_reference (Str, max length 4096)

=item text (Str, max length 4096)

=item amount_minor_units (NAB::Type::PositiveIntOrZero)

=back

=cut

foreach my $str_attr (
    'transaction_code[3]',
    'funds_type[1]',
    'bank_reference[4096]',
    'customer_reference[4096]',
    'text[4096]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

has [ qw/ amount_minor_units / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveIntOrZero',
    required => 1,
);

=head1 METHODS

=head2 new_from_raw_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Transaction = Business::NAB::AccountInformation::Transaction
        ::Payments::DescriptiveRecord->new_from_raw_record( $line );

=cut

sub new_from_raw_record ( $class, $line ) {

    my $aoa = csv( in => \$line )
        or croak( Text::CSV->error_diag );

    return $class->new_from_record( $aoa->[ 0 ]->@* );
}

=head2 new_from_record

Returns a new instance of the class with attributes populated from
the result of parsing the already parsed line:

    my $Transaction = Business::NAB::AccountInformation::Transaction
        ::Payments::DescriptiveRecord->new_from_record( @record );

=cut

sub new_from_record ( $class, @record ) {

    my ( $record_type, $trans_code, $amount, $funds_type, $bank_ref, $cust_ref, @text )
        = @record;

    if ( $record_type ne '16' ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        transaction_code   => $trans_code,
        amount_minor_units => $amount,
        funds_type         => $funds_type,
        bank_reference     => $bank_ref,
        customer_reference => $cust_ref,
        text               => join( " ", @text ),
    );
}

=head2 is_debit

=head2 is_credit

Boolean check on the transaction type

    if ( $Transaction->is_credit ) {
        ...
    }

=cut

sub is_debit ( $self ) {
    return $self->_raw_description->[ 0 ] eq 'DR';
}

sub is_credit ( $self ) {
    return $self->_raw_description->[ 0 ] eq 'CR';
}

=head2 description

Returns a descriptive string for the transaction type

    my $description = $Transaction->description;

=cut

sub description ( $self ) {
    return $self->_raw_description->[ 1 ];
}

sub _raw_description ( $self ) {

    state %transaction_details_codes = (
        175 => [ 'CR', 'Cheques' ],
        195 => [ 'CR', 'Transfer credits' ],
        238 => [ 'CR', 'Dividend' ],
        252 => [ 'CR', 'Reversal Entry' ],
        357 => [ 'CR', 'Credit adjustment' ],
        399 => [ 'CR', 'Miscellaneous credits' ],
        475 => [ 'DR', 'Cheques (paid)' ],
        495 => [ 'DR', 'Transfer debits' ],
        501 => [ 'DR', 'Automatic drawings' ],
        512 => [ 'DR', 'Documentary L/C Drawings/Fees' ],
        555 => [ 'DR', 'Dishonoured cheques' ],
        564 => [ 'DR', 'Loan fees' ],
        595 => [ 'DR', 'FlexiPay' ],
        631 => [ 'DR', 'Debit adjustment' ],
        654 => [ 'DR', 'Debit Interest' ],
        699 => [ 'DR', 'Miscellaneous debits' ],
        905 => [ 'CR', 'Credit Interest' ],
        906 => [ 'CR', 'National nominees credits' ],
        910 => [ 'CR', 'Cash' ],
        911 => [ 'CR', 'Cash/cheques' ],
        915 => [ 'CR', 'Agent Credits' ],
        920 => [ 'CR', 'Inter-bank credits' ],
        925 => [ 'CR', 'Bankcard credits' ],
        930 => [ 'CR', 'Credit balance transfer' ],
        935 => [ 'CR', 'Credits summarised' ],
        936 => [ 'CR', 'EFTPOS' ],
        938 => [ 'CR', 'NFCA credit transactions' ],
        950 => [ 'DR', 'Loan establishment fees' ],
        951 => [ 'DR', 'Account keeping fees' ],
        952 => [ 'DR', 'Unused limit fees' ],
        953 => [ 'DR', 'Security fees' ],
        955 => [ 'DR', 'Charges' ],
        956 => [ 'DR', 'National nominee debits' ],
        960 => [ 'DR', 'Stamp duty-cheque book' ],
        961 => [ 'DR', 'Stamp duty' ],
        962 => [ 'DR', 'Stamp duty-security' ],
        970 => [ 'DR', 'State government tax' ],
        971 => [ 'DR', 'Federal government tax' ],
        975 => [ 'DR', 'Bankcards' ],
        980 => [ 'DR', 'Debit balance transfers' ],
        985 => [ 'DR', 'Debits summarised' ],
        986 => [ 'DR', 'Cheques summarised' ],
        987 => [ 'DR', 'Non-cheques summarised' ],
        988 => [ 'DR', 'NFCA debit transaction' ],
    );

    return $transaction_details_codes{ $self->transaction_code };
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
