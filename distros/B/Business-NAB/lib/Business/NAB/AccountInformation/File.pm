package Business::NAB::AccountInformation::File;
$Business::NAB::AccountInformation::File::VERSION = '0.02';
=head1 NAME

Business::NAB::AccountInformation::File

=head1 SYNOPSIS

    use Business::NAB::AccountInformation::File;

    # parse
    my $AccountInfo = Business::NAB::AccountInformation::File
        ->new_from_file( $file_path );

    foreach my $Group ( $AccountInfo->groups->@* ) {

        foreach my $Account ( $Group->accounts->@* ) {

            foreach my $Transaction ( $Account->transactions->@* ) {

                ...
            }
        }
    }

=head1 DESCRIPTION

Class for parsing a NAB "Account Information File (NAI/BAI2)" file

=cut

use strict;
use warnings;
use feature qw/ signatures /;
use autodie qw/ :all /;
use Carp    qw/ croak /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;

use Module::Load;
use Text::CSV_XS         qw/ csv /;
use Business::NAB::Types qw/
    add_max_string_attribute
    /;

# we have long namespaces and use them multiple times so have
# normalised them out into the $parent and @subclasses below
my $parent = 'Business::NAB::AccountInformation';

my @subclasses = (
    qw/
        Transaction
        Group
        Account
        /
);

load( $parent . "::$_" ) for @subclasses;

=head1 ATTRIBUTES

=over

=item sender_identification (Str, max length 8)

=item receiver_identification (Str, max length 4096)

=item file_creation_date (DateTime)

=item file_creation_time (Str, max length 4)

=item file_sequence_number (NAB::Type::PositiveInt)

=item physical_record_length (NAB::Type::PositiveIntOrZero)

=item blocking_factor (NAB::Type::PositiveIntOrZero)

=item version_number (NAB::Type::PositiveInt)

=item control_total_a (Int)

=item number_of_groups (Int)

=item number_of_records (Int)

=item control_total_b (Int)

=item groups (ArrayRef[Business::NAB::AccountInformation::Group])

=back

=cut

foreach my $str_attr (
    'sender_identification[8]',
    'receiver_identification[4096]',
    'file_creation_time[4]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

has 'file_creation_date' => (
    isa      => 'NAB::Type::StatementDate',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

has [
    qw/
        file_sequence_number
        blocking_factor
        /
] => (
    isa      => 'NAB::Type::PositiveIntOrZero',
    is       => 'ro',
    required => 1,
);

has [
    qw/
        version_number
        /
] => (
    isa      => 'NAB::Type::PositiveInt',
    is       => 'ro',
    required => 0,
    default  => sub { 1 },
);

has [
    qw/
        physical_record_length
        /
] => (
    isa       => 'Maybe[Str]',
    is        => 'ro',
    required  => 0,
    predicate => '_has_physical_record_length',
);

has [
    qw/
        control_total_a
        number_of_groups
        number_of_records
        control_total_b
        _raw_record_count
        /
] => (
    isa => 'Int',
    is  => 'rw',
);

subtype "Groups"
    => as "ArrayRef[${parent}::Group]";

has 'groups' => (
    traits  => [ 'Array' ],
    is      => 'rw',
    isa     => 'Groups',
    default => sub { [] },
    handles => {
        "add_group" => 'push',
    },
);

=head1 METHODS

=head2 new_from_file

Returns a new instance of the class with attributes populated from
the result of parsing the passed file

    my $Payments = Business::NAB::AccountInformation::File
        ->new_from_file( $file_path );

=cut

sub new_from_file ( $class, $file ) {

    my $reconstructed_records = $class->reconstruct_file_records( $file );

    my ( $File, $Group, $Account );

    foreach my $record ( $reconstructed_records->{ records }->@* ) {

        my ( $record_type, @rest ) = $record->@*;

        if ( $record_type eq '01' ) {
            $File = _file_header( $class, @rest );
        }

        if ( $record_type eq '02' ) {
            $Group = Business::NAB::AccountInformation::Group
                ->new_from_record( $record_type, @rest );

            $File->add_group( $Group );
        }

        if ( $record_type eq '03' ) {
            $Account = Business::NAB::AccountInformation::Account
                ->new_from_record( $record_type, @rest );

            $Group->add_account( $Account );
        }

        if ( $record_type eq '16' ) {
            my $Transaction = Business::NAB::AccountInformation::Transaction
                ->new_from_record( $record_type, @rest );

            $Account->add_transaction( $Transaction );
        }

        if ( $record_type eq '49' ) {
            $Account->control_total_a( $rest[ 0 ] );

            $File->is_bai2
                ? $Account->number_of_records( $rest[ 1 ] )
                : $Account->control_total_b( $rest[ 1 ] );

            $Account->validate_totals( $File->is_bai2 );
        }

        if ( $record_type eq '98' ) {
            $Group->control_total_a( $rest[ 0 ] );
            $Group->number_of_accounts( $rest[ 1 ] );

            $File->is_bai2
                ? $Group->number_of_records( $rest[ 2 ] )
                : $Group->control_total_b( $rest[ 2 ] );

            $Group->validate_totals( $File->is_bai2 );
        }

        if ( $record_type eq '99' ) {
            $File->control_total_a( $rest[ 0 ] );
            $File->number_of_groups( $rest[ 1 ] );
            $File->number_of_records( $rest[ 2 ] );
            $File->control_total_b( $rest[ 3 ] )
                if !$File->is_bai2;
            $File->_raw_record_count(
                $reconstructed_records->{ raw_record_count }
            );

            $File->validate_totals;
        }

    }

    return $File;
}

=head2 validate_totals

Checks if the control_total_a and control_total_b values match the
expected totals of the contained group items:

    $File->validate_totals;

Will throw an exception if any total doesn't match the expected value.

=cut

sub validate_totals ( $self ) {

    my $num_groups = scalar( $self->groups->@* );
    croak(
        "number of nested groups ($num_groups) != number_of_groups "
            . "(@{[ $self->number_of_groups ]})"
    ) if $num_groups != $self->number_of_groups;

    my $num_raw_records = $self->_raw_record_count;
    croak(
        "number of records ($num_raw_records) != number_of_records "
            . "(@{[ $self->number_of_records ]})"
    ) if $num_raw_records != $self->number_of_records;

    my ( $group_total_a, $group_total_b ) = ( 0, 0 );

    foreach my $Group ( $self->groups->@* ) {
        $group_total_a += $Group->control_total_a;

        if ( !$self->is_bai2 ) {
            $group_total_b += $Group->control_total_b;
        }
    }

    croak(
        "calculated sum ($group_total_a) != control_total_a "
            . "(@{[$self->control_total_a]})"
    ) if $group_total_a != $self->control_total_a;

    if ( !$self->is_bai2 ) {
        croak(
            "calculated sum ($group_total_b) != control_total_b "
                . "(@{[$self->control_total_b]})"
        ) if $group_total_b != $self->control_total_b;
    }

    return 1;
}

=head1 reconstruct_file_records

Returns the file contents as a hashref, having reconstructed the various
records within it, for easier parsing:

    my $records = Business::NAB::AccountInformation::File
        ->reconstruct_file_records( $file );

This is due to the file format being somewhat baroque and, essentially, a
CSV of fixed width meaning some lines get truncated and continued on the
next line or multiple lines.

The returned hashref is of the form:

    {
        records => @records,
        raw_record_count => $raw_record_count,
    }

=cut

sub reconstruct_file_records ( $self, $file ) {

    open( my $fh, '<', $file );

    my ( $field_continues, @records, $raw_record_count );

    while ( my $line = <$fh> ) {

        my $aoa = csv( in => \$line )
            or croak( Text::CSV->error_diag );

        my ( $record_type, @rest ) = $aoa->[ 0 ]->@*;

        # a trailing / means the last field of the record is complete,
        # otherwise it continues on the next line (which should be a
        # Continuation record (88)
        if ( $rest[ -1 ] =~ m!/$! ) {
            chop( $rest[ -1 ] );
            $field_continues = 0;
        } else {
            $field_continues = 1;
        }

        if ( $record_type eq '88' ) {

            # continuation of the previous record, this is a little
            # bit messy depending on the previous record type

            if (
                $records[ -1 ][ 0 ] eq '16'

                # the previous record was complete, append to the
                # last field in that record
                && scalar( $records[ -1 ]->@* ) == 7
            ) {
                $records[ -1 ][ -1 ] .= ' ' . join( ' ', @rest );
            } else {

                # the previous record was incomplete, complete it
                $records[ -1 ] = [ @{ $records[ -1 ] }, @rest ];
            }
        } else {
            push( @records, [ $record_type, @rest ] );
        }

        $raw_record_count++;
    }

    return {
        records          => \@records,
        raw_record_count => $raw_record_count,
    };
}

=head1 is_bai2

Boolean check on the file type

    if ( $File->is_bai2 ) {
        ...
    } else {
        # it's an NAI file
        ...
    }

=cut

sub is_bai2 ( $self ) {
    return $self->version_number == 2;
}

sub _file_header ( $class, @fields ) {

    return $class->new(
        sender_identification   => $fields[ 0 ],
        receiver_identification => $fields[ 1 ],
        file_creation_date      => $fields[ 2 ],
        file_creation_time      => $fields[ 3 ],
        file_sequence_number    => $fields[ 4 ],
        physical_record_length  => $fields[ 5 ] || 0,
        blocking_factor         => $fields[ 6 ] || 0,

        ( scalar( @fields ) == 8 )
        ? ( version_number => $fields[ 7 ] )
        : (),
    );
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::AccountInformation::Group>

L<Business::NAB::AccountInformation::Account>

L<Business::NAB::AccountInformation::Transaction>

=cut

__PACKAGE__->meta->make_immutable;
