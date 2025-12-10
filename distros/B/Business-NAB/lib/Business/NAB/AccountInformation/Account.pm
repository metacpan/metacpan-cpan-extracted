package Business::NAB::AccountInformation::Account;
$Business::NAB::AccountInformation::Account::VERSION = '0.01';
=head1 NAME

Business::NAB::AccountInformation::Account

=head1 SYNOPSIS

    use Business::NAB::AccountInformation::Account;

    my $Account = Business::NAB::AccountInformation::Account->new(
        commercial_account_number => $commercial_account_number,
        currency_code => $currency_code,
        transaction_code_values => $transaction_code_values,
        control_total_a => $total_a,
        control_total_b => $total_b,
    );

=head1 DESCRIPTION

Class for parsing a NAB "Account Information File (NAI/BAI2)" account
identifier line (type C<03>).

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

=item commercial_account_number (Str, max length 4096)

=item currency_code (Str, max length 3)

=item transaction_code_values (HashRef)

=item control_total_a (Int)

=item control_total_b (Int)

=item number_of_records (Int)

=item transactions (ArrayRef[Business::NAB::AccountInformation::Transaction])

=back

=cut

foreach my $str_attr (
    'commercial_account_number[4096]',
    'currency_code[3]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

has 'transaction_code_values' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
);

has [
    qw/
        control_total_a
        control_total_b
        number_of_records
        /
] => (
    isa => 'Int',
    is  => 'rw',
);

subtype "Transactions"
    => as "ArrayRef[Business::NAB::AccountInformation::Transaction]";

has 'transactions' => (
    traits  => [ 'Array' ],
    is      => 'rw',
    isa     => 'Transactions',
    default => sub { [] },
    handles => {
        "add_transaction" => 'push',
    },
);

=head1 METHODS

=head2 new_from_raw_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Account = Business::NAB::AccountInformation::Account
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

    my $Account = Business::NAB::AccountInformation::Account
        ::Payments::DescriptiveRecord->new_from_record( @record );

=cut

sub new_from_record ( $class, @record ) {

    my (
        $record_type,
        $commercial_account_number,
        $currency_code,
        @transaction_code_values,
    ) = @record;

    if ( $record_type ne '03' ) {
        croak( "unsupported record type ($record_type)" );
    }

    my $transaction_code_values = {};
    my %account_summary_codes   = $class->_account_summary_codes;

    # the record fields are different depending on if the file
    # is the NAI or BAI2 type - the *easiest* way to deal with
    # this is to just strip out the empty fields, as even though
    # they are present for BAI2 the spec says they are "Empty"
    @transaction_code_values = grep { $_ ne "" } @transaction_code_values;

    while ( my @tc_pair = splice( @transaction_code_values, 0, 2 ) ) {
        my ( $transaction_code, $amount_or_count ) = @tc_pair;

        $transaction_code_values->{ $transaction_code }
            = $amount_or_count;
    }

    return $class->new(
        commercial_account_number => $commercial_account_number,
        currency_code             => $currency_code,
        transaction_code_values   => $transaction_code_values,
    );
}

=head2 validate_totals

Checks if the control_total_a and control_total_b values match the
expected totals of the contained transaction items and transaction
code values

    $Account->validate_totals( my $is_bai2 = 0 );

Will throw an exception if any total doesn't match the expected value.

Takes an optional boolean param to stipulate if the file type is BAI2
(defaults to false).

=cut

sub validate_totals ( $self, $is_bai2 = 0 ) {

    my ( $trans_total, $excl_tax_interest ) = ( 0, 0 );

    foreach my $Transaction ( $self->transactions->@* ) {
        $trans_total       += $Transaction->amount_minor_units;
        $excl_tax_interest += $Transaction->amount_minor_units;
    }

    my $tc_values = $self->transaction_code_values;
    TC: foreach my $transaction_code ( sort keys $tc_values->%* ) {
        $trans_total += int( $tc_values->{ $transaction_code } );

        # control_total_b excludes tax and interest
        next TC if grep { $_ eq $transaction_code } 965 .. 969;
        $excl_tax_interest += int( $tc_values->{ $transaction_code } );
    }

    croak(
        "calculated sum ($trans_total) != control_total_a "
            . "(@{[$self->control_total_a]})"
    ) if $trans_total != $self->control_total_a;

    if ( !$is_bai2 ) {
        croak(
            "calculated sum ($excl_tax_interest) != control_total_b "
                . "(@{[$self->control_total_b]})"
        ) if $excl_tax_interest != $self->control_total_b;
    }

    return 1;
}

sub _account_summary_codes ( $self ) {

    state %account_summary_codes = (
        '001' => 'Customer number',
        '003' => 'Number of segments for the account',
        '010' => 'Opening Balance',
        '015' => 'Closing balance',
        '100' => 'Total credits',
        '102' => 'Number of credit transactions',
        '400' => 'Total debits',
        '402' => 'Number of debit transactions',
        '500' => 'Accrued (unposted) credit interest',
        '501' => 'Accrued (unposted) debit interest',
        '502' => 'Account limit',
        '503' => 'Available limit',
        '965' => 'Effective Debit interest rate',
        '966' => 'Effective Credit interest rate',
        '967' => 'Accrued State Government Duty',
        '968' => 'Accrued Government Credit Tax',
        '969' => 'Accrued Government Debit Tax',
    );

    return %account_summary_codes;
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::AccountInformation::Transaction>

=cut

__PACKAGE__->meta->make_immutable;
