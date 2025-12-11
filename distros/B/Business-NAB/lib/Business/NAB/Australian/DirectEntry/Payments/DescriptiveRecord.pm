package Business::NAB::Australian::DirectEntry::Payments::DescriptiveRecord;
$Business::NAB::Australian::DirectEntry::Payments::DescriptiveRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Payments::DescriptiveRecord

=head1 SYNOPSIS

    use Business::NAB::Australian::DirectEntry::Payments::DescriptiveRecord;

    # parse
    my $Record = Business::NAB::Australian::DirectEntry
        ::Payments::DescriptiveRecord->new_from_record( $line );

    # create
    my $Record = Business::NAB::Australian::DirectEntry
        ::Payments::DescriptiveRecord->new(
            reel_sequence_number => '01',
            institution_name => 'NAB',
            user_name => 'NAB TEST',
            user_number => 123456,
            description => 'DrDebit',
            process_date => DateTime->now,
    );

    my $line = $Record->to_record;

=head1 DESCRIPTION

Class for descriptive record in the "Australian Direct Entry Payments and
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

=item process_date (NAB::Type::Date, coerced from Str)

=item reel_sequence_number (Int, max 99)

=item institution_name (Str, max length 3)

=item user_name (Str, max length 26)

=item user_number (Str, max length 6)

=item description (Str, max length 12)

=back

=cut

has [
    qw/
        process_date
        /
] => (
    is       => 'ro',
    isa      => 'NAB::Type::Date',
    required => 1,
    coerce   => 1,
);

foreach my $str_attr (
    'reel_sequence_number[2:trim_leading_zeros]',
    'institution_name[3]',
    'user_name[26]',
    'user_number[6]',
    'description[12]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

sub _pack_template {
    return "A1 A17 A2 A3 A7 A26 A6 A12 A6 A40";
}

sub record_type { 0 }

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
        undef,
        $reel_sequence_number,
        $institution_name,
        undef,
        $user_name,
        $user_number,
        $description,
        $date,
        undef,
    ) = unpack( $class->_pack_template(), $line );

    if ( $record_type ne $class->record_type ) {
        croak( "unsupported record type ($record_type)" );
    }

    return $class->new(
        reel_sequence_number => $reel_sequence_number,
        institution_name     => $institution_name,
        user_name            => $user_name,
        user_number          => $user_number,
        description          => $description,
        process_date         => $date,
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
        "",
        sprintf( "%02s", $self->reel_sequence_number ),
        $self->institution_name,
        "",
        $self->user_name,
        sprintf( "%06s", $self->user_number ),
        $self->description,
        $self->process_date->strftime( '%d%m%y' ),
        "",
    );

    return $record;
}

=head1 SEE ALSO

L<Business::NAB::Types>

=cut

__PACKAGE__->meta->make_immutable;
