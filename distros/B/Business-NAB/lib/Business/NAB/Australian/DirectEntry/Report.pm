package Business::NAB::Australian::DirectEntry::Report;
$Business::NAB::Australian::DirectEntry::Report::VERSION = '0.01';
=head1 NAME

Business::NAB::Australian::DirectEntry::Report

=head1 SYNOPSIS

    use Business::NAB::Australian::DirectEntry::Report;

    # parse;
    my $Report = Business::NAB::Australian::DirectEntry::Report
        ->new_from_file( $file_path );

    foreach my $Credit (
        grep { $_->is_credit } $Report->payment_record->@*
    ) {
        ...
    }

    # build
    my $Report = Business::NAB::Australian::DirectEntry::Report->new;

    $Report->add_header_record(
        .. # Business::NAB:: ... HeaderRecord object
    );

    $Report->add_payment_record(
        .. # Business::NAB:: ... PaymentRecord object
    ) for ( @payments );

    $Report->to_file(
        $file_path,
        $separator, # defaults to "\r\n"
    );

=head1 DESCRIPTION

Class for building/parsing a Australian Direct Entry Reports file

=cut

use strict;
use warnings;
use feature qw/ signatures /;
use autodie qw/ :all /;
use Carp    qw/ croak /;

use Moose;
with 'Business::NAB::Role::AttributeContainer';
extends 'Business::NAB::FileContainer';

use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;

use List::Util qw/ sum0 /;

# we have long namespaces and use them multiple times so have
# normalised them out into the $parent and @subclasses below
my $parent = 'Business::NAB::Australian::DirectEntry::Report';

my @subclasses = (
    qw/
        HeaderRecord
        PaymentRecord
        ValueSummary
        FailedRecord
        FailedSummary
        TrailerRecord
        DisclaimerRecord
        /
);

=head1 ATTRIBUTES

All attributes are ArrayRef[Obj] where Obj are of the Business::NAB::Australian::DirectEntry::Report::* namespace:

    HeaderRecord
    PaymentRecord
    ValueSummary
    FailedRecord
    FailedSummary
    TrailerRecord
    DisclaimerRecord

Convenience methods are available for trivial addition of new elements
to the arrays:

    $Report->add_header_record( $HeaderRecord );
    $Report->add_payment_record( $PaymentRecord );
    $Report->add_value_summary( $ValueSummary );
    $Report->add_failed_record( $FailedRecord );
    $Report->add_failed_summary( $FailedSummary );
    $Report->add_trailer_record( $TrailerRecord );
    $Report->add_disclaimer_record( $DisclaimerRecord );

=over

=item header_record (ArrayRef[Obj])

=item payment_record (ArrayRef[Obj])

=item value_summary (ArrayRef[Obj])

=item failed_record (ArrayRef[Obj])

=item failed_summary (ArrayRef[Obj])

=item trailer_record (ArrayRef[Obj])

=item disclaimer_record (ArrayRef[Obj])

=back

=cut

__PACKAGE__->load_attributes( $parent, @subclasses );

=head1 METHODS

=head2 new_from_file

Returns a new instance of the class with attributes populated from
the result of parsing the passed file

    my $Payments = Business::NAB::Australian::DirectEntry::Report
        ->new_from_file( $file_path );

=cut

sub new_from_file ( $class, $file ) {

    my %sub_class_map = (
        '00'  => 'HeaderRecord',
        '53'  => 'PaymentRecord',
        '54'  => 'ValueSummary',
        '57'  => 'PaymentRecord',
        '58'  => 'ValueSummary',
        '61'  => 'FailedRecord',
        '62'  => 'FailedSummary',
        '99'  => 'TrailerRecord',
        '100' => 'DisclaimerRecord',
    );

    my $self = $class->new;

    return $self->SUPER::new_from_file(
        $parent, $file, \%sub_class_map, ','
    );
}

=head2 to_file

Writes the file content to the passed file path:

    $Report->to_file(
        $file_path,
        $separator, # defaults to "\r\n"
    );

=cut

sub to_file (
    $self,
    $file,
    $sep = "\r\n",
) {
    open( my $fh, '>', $file );

    print $fh $self->header_record->[ 0 ]->to_record . $sep;

    my $class = "Business::NAB::Australian::DirectEntry::Report::ValueSummary";
    my @records;

    foreach my $type ( qw/ credit debit / ) {

        my $check    = "is_${type}";
        my @payments = grep { $_->$check } $self->payment_record->@*;
        print $fh $_->to_record . $sep foreach ( @payments );

        my ( $ValueSummary ) = grep { $_->$check } $self->value_summary->@*;

        $ValueSummary //= $class->new(
            record_type     => $type eq 'credit' ? '54' : '58',
            sub_trancode    => 'UVD',
            number_of_items => scalar( @payments ),
            total_of_items  => sum0 map { $_->amount } @payments,
        );

        print $fh $ValueSummary->to_record . $sep;

        push( @records, @payments );
    }

    $class = "Business::NAB::Australian::DirectEntry::Report::FailedSummary";

    if ( my @failed = $self->failed_record->@* ) {

        print $fh $_->to_record . $sep foreach ( @failed );

        my ( $FailedSummary ) = $self->failed_summary->@*;

        $FailedSummary //= $class->new(
            sub_trancode                 => 'UXS',
            number_of_items              => scalar( @failed ),
            failed_item_treatment_option => 1,
            text                         => 'Failed items will be returned as individual '
                . 'items to your trace account.',
            total_of_items => sum0 map { $_->amount } @failed,
        );

        print $fh $FailedSummary->to_record . $sep;

        push( @records, @failed );
    }

    if ( my ( $TrailerRecord ) = $self->trailer_record->@* ) {
        print $fh $TrailerRecord->to_record . $sep;
    } else {

        my $credit_total = sum0 map { $_->amount } grep { $_->is_credit }
            @records;

        my $debit_total = sum0 map { $_->amount } grep { $_->is_debit }
            @records;

        $class         = "Business::NAB::Australian::DirectEntry::Report::TrailerRecord";
        $TrailerRecord = $class->new(
            net_file_total          => $credit_total - $debit_total,
            credit_file_total       => $credit_total,
            debit_file_total        => $debit_total,
            total_number_of_records => scalar( @records ),
        );

        print $fh $TrailerRecord->to_record . $sep;
    }

    $class = "Business::NAB::Australian::DirectEntry::Report::DisclaimerRecord";
    my ( $DisclaimerRecord ) = $self->disclaimer_record->@*;
    $DisclaimerRecord //= $class->new(
        text => "(c) 2012 National Australia Bank Limit ABN 12 004 044 937",
    );

    print $fh $DisclaimerRecord->to_record . $sep;

    close( $fh );

    return;
}

=head2 original_filename

An alias for the header_record C<import_file_name>

=cut

sub original_filename ( $self ) {
    $self->header_record->[ 0 ]->import_file_name;
}

=head2 status

Hardcoded to "PROCESSED" - as per NAB's documentation that states
"This report assists with confirming the processing of your payment
file..."

=cut

sub status ( $self ) { 'PROCESSED' }

=head1 SEE ALSO

L<Business::NAB::Australian::DirectEntry::Report::PaymentRecord>

L<Business::NAB::Australian::DirectEntry::Report::ValueSummary>

L<Business::NAB::Australian::DirectEntry::Report::FailedRecord>

L<Business::NAB::Australian::DirectEntry::Report::FailedSummary>

=cut

__PACKAGE__->meta->make_immutable;
