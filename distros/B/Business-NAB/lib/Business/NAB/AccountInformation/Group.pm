package Business::NAB::AccountInformation::Group;
$Business::NAB::AccountInformation::Group::VERSION = '0.01';
=head1 NAME

Business::NAB::AccountInformation::Group

=head1 SYNOPSIS

    use Business::NAB::AccountInformation::Group;

    my $Group = Business::NAB::AccountInformation::Group->new(
    	ultimate_receiver_identification => $ult_receiver_id,
    	originator_identification => $org_id,
        as_of_date => $as_of_date,
    	additional_field => $additional_field,
        control_total_a => $total_a,
        number_of_accounts => $number_of_accounts,
        control_total_b => $total_b,
    );

=head1 DESCRIPTION

Class for parsing a NAB "Account Information File (NAI/BAI2)" group
line (type C<02>).

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

=item ultimate_receiver_identification (Str, max length 4096)

=item originator_identification (Str, max length 8)

=item as_of_date (DateTime)

=item additional_field

=item control_total_a (Int)

=item number_of_accounts (Int)

=item control_total_b (Int)

=item number_of_records (Int)

=item accounts (ArrayRef[Business::NAB::AccountInformation::Account])

=back

=cut

foreach my $str_attr (
    'ultimate_receiver_identification[4096]',
    'originator_identification[8]',
    'additional_field[4096]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

has 'as_of_date' => (
    isa      => 'NAB::Type::StatementDate',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

has [
    qw/
        control_total_a
        number_of_accounts
        control_total_b
        number_of_records
        /
] => (
    isa => 'Int',
    is  => 'rw',
);

subtype "Accounts"
    => as "ArrayRef[Business::NAB::AccountInformation::Account]";

has 'accounts' => (
    traits  => [ 'Array' ],
    is      => 'rw',
    isa     => 'Accounts',
    default => sub { [] },
    handles => {
        "add_account" => 'push',
    },
);

=head1 METHODS

=head2 new_from_raw_record

Returns a new instance of the class with attributes populated from
the result of parsing the passed line:

    my $Group = Business::NAB::AccountInformation::Group
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

    my $Group = Business::NAB::AccountInformation::Group
        ::Payments::DescriptiveRecord->new_from_record( @record );

=cut

sub new_from_record ( $class, @record ) {

    my (
        $record_type,
        $ult_receiver_id,
        $org_id,
        undef,    # group status
        $as_of_date,
        undef,    # as of time
        $additional_field,
    ) = @record;

    if ( $record_type ne '02' ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        ultimate_receiver_identification => $ult_receiver_id,
        originator_identification        => $org_id,
        as_of_date                       => $as_of_date,
        additional_field                 => $additional_field,
    );
}

=head2 validate_totals

Checks if the control_total_a and control_total_b values match the
expected totals of the contained accounts:

    $Group->validate_totals( my $is_bai2 = 0 );

Will throw an exception if any total doesn't match the expected value.

Takes an optional boolean param to stipulate if the file type is BAI2
(defaults to false).

=cut

sub validate_totals ( $self, $is_bai2 = 0 ) {

    my $num_accounts = scalar( $self->accounts->@* );
    croak(
        "number of nested accounts ($num_accounts) != number_of_accounts "
            . "(@{[ $self->number_of_accounts ]})"
    ) if $num_accounts != $self->number_of_accounts;

    my ( $account_total_a, $account_total_b ) = ( 0, 0 );

    foreach my $Account ( $self->accounts->@* ) {
        $account_total_a += $Account->control_total_a;

        if ( !$is_bai2 ) {
            $account_total_b += $Account->control_total_b;
        }
    }

    croak(
        "calculated sum ($account_total_a) != control_total_a "
            . "(@{[$self->control_total_a]})"
    ) if $account_total_a != $self->control_total_a;

    if ( !$is_bai2 ) {
        croak(
            "calculated sum ($account_total_b) != control_total_b "
                . "(@{[$self->control_total_b]})"
        ) if $account_total_b != $self->control_total_b;
    }

    return 1;
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::AccountInformation::Account>

L<Business::NAB::AccountInformation::Transaction>

=cut

__PACKAGE__->meta->make_immutable;
