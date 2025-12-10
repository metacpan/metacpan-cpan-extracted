package Business::NAB::Australian::DirectEntry::Payments;
$Business::NAB::Australian::DirectEntry::Payments::VERSION = '0.01';
=head1 NAME

Business::NAB::Australian::DirectEntry::Payments

=head1 SYNOPSIS

    use Business::NAB::Australian::DirectEntry::Payments;

    # parse:
    my $Payments = Business::NAB::Australian::DirectEntry::Payments
        ->new_from_file( $file_path );

    foreach my $DetailRecord ( $Payments->detail_record->@* ) {
        ...
    }

    # build:
    my $Payments = Business::NAB::Australian::DirectEntry::Payments->new;

    $Payments->add_descriptive_record(
        .. # Business::NAB:: ... DescriptiveRecord object
    );

    $Payments->add_detail_record(
        .. # Business::NAB:: ... DetailRecord object
    ) for ( @payments );

    # optional:
    $Payments->add_total_record(
        .. # Business::NAB:: ... TotalRecord object
    );

    $Payments->to_file(
        $file_path,
        $bsb_number, # if TotalRecord is not set
        $separator, # defaults to "\r\n"
    );

=head1 DESCRIPTION

Class for building/parsing a "Australian Direct Entry Payments" file

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
my $parent = 'Business::NAB::Australian::DirectEntry::Payments';

my @subclasses = (
    qw/
        DescriptiveRecord
        DetailRecord
        TotalRecord
        /
);

=head1 ATTRIBUTES

All attributes are ArrayRef[Obj] where Obj are of the Business::NAB::Australian::DirectEntry::Payments::* namespace:

    DescriptiveRecord
    DetailRecord
    TotalRecord

Convenience methods are available for trivial addition of new elements
to the arrays:

    $Payments->add_descriptive_record( $DescriptiveRecord );
    $Payments->add_detail_record( $DetailRecord );
    $Payments->add_total_record( $TotalRecord );

=over

=item descriptive_record (ArrayRef[Obj])

=item detail_record (ArrayRef[Obj])

=item total_record (ArrayRef[Obj])

=back

=cut

__PACKAGE__->load_attributes( $parent, @subclasses );

=head1 METHODS

=head2 new_from_file

Returns a new instance of the class with attributes populated from
the result of parsing the passed file

    my $Payments = Business::NAB::Australian::DirectEntry::Payments
        ->new_from_file( $file_path );

=cut

sub new_from_file (
    $class, $file, $class_map = undef, $sub_parent = undef
) {

    my %sub_class_map = (
        0 => 'DescriptiveRecord',
        1 => 'DetailRecord',
        7 => 'TotalRecord',
    );

    my $self = $class->new;

    return $self->SUPER::new_from_file(
        ( $sub_parent // $parent ),
        $file,
        ( $class_map // \%sub_class_map ),
    );
}

=head2 to_file

Writes the file content to the passed file path:

    $Payments->to_file(
        $file_path,
        $bsb_number, # if TotalRecord is not set, defaults to 999-999
        $separator, # defaults to "\r\n"
    );

This also does some validation on the totals in the records.

=cut

sub to_file (
    $self,
    $file,
    $bsb_number = "999-999",
    $sep = "\r\n",
) {

    open( my $fh, '>', $file );

    print $fh $self->descriptive_record->[ 0 ]->to_record . $sep;
    print $fh $_->to_record . $sep foreach $self->detail_record->@*;

    my $record_count = scalar( $self->detail_record->@* );

    my $credit_total = sum0 map { $_->amount }
        grep { $_->is_credit } $self->detail_record->@*;
    my $debit_total = sum0 map { $_->amount }
        grep { $_->is_debit } $self->detail_record->@*;

    my $net_total = abs( $credit_total - $debit_total );

    # net total should be zero as it is the net of credit - debit records
    # and there should always be a record that nets off the other record
    # type totals (to describe where funds go to/from). however if this is
    # a returns file then this check does not apply
    if (
        $net_total != 0
        && $self->blessed !~ /::Returns$/
    ) {
        croak(
            "Net total not equal to zero ($net_total) file detail records do"
                . " not balance, you have debits missing a credit or vice-versa"
        );
    }

    if ( my $TotalRecord = $self->total_record->[ 0 ] ) {
        print $fh $TotalRecord->to_record . $sep;
    } else {
        croak( "BSB number is required if total_record is not set" )
            if !$bsb_number;

        my $TotalRecord = Business::NAB::Australian::DirectEntry::Payments::TotalRecord->new(
            bsb_number          => $bsb_number,
            net_total_amount    => $net_total,
            credit_total_amount => $credit_total,
            debit_total_amount  => $debit_total,
            record_count        => $record_count,
        );

        print $fh $TotalRecord->to_record . $sep;
    }

    close( $fh );

    return 1;
}

=head1 SEE ALSO

L<Business::NAB::Australian::DirectEntry::Payments::DescriptiveRecord>

L<Business::NAB::Australian::DirectEntry::Payments::DetailRecord>

L<Business::NAB::Australian::DirectEntry::Payments::TotalRecord>

=cut

__PACKAGE__->meta->make_immutable;
