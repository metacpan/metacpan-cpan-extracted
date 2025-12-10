package Business::NAB::BPAY::Remittance::File;
$Business::NAB::BPAY::Remittance::File::VERSION = '0.01';
=head1 NAME

Business::NAB::BPAY::Remittance::File

=head1 SYNOPSIS

    use Business::NAB::BPAY::Remittance::File;

    my $File = Business::NAB::BPAY::Remittance::File->new_from_file(
        "/path/to/bpay/payments/batch/file-brf.txt",
    );

    # parse
    my $Header = $File->header_record->[0];

    foreach my $File ( $File->detail_record->@* ) {
        ...
    }

    my $Trailer = $File->trailer_record->[0];

    # create
    $File->to_file(
        "/path/to/bpay/remittance/file_output.brf",
        $separator, # defaults to "\r\n"
    );

=head1 DESCRIPTION

Class for parsing / creating a NAB BPAY remittance/reporting file

=cut;

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

use Business::NAB::BPAY::Remittance::File;

# we have long namespaces and use them multiple times so have
# normalised them out into the $parent and @subclasses below
my $parent = 'Business::NAB::BPAY::Remittance::File';

my @subclasses = (
    qw/
        HeaderRecord
        DetailRecord
        TrailerRecord
        /
);

=head1 ATTRIBUTES

All attributes are ArrayRef[Obj] where Obj are of the Business::NAB::BPAY*
namespace:

    HeaderRecord
    DetailRecord
    TrailerRecord

Convenience methods are available for trivial addition of new elements
to the arrays:

    $File->add_header_record( $HeaderRecord );
    $File->add_detail_record( $DetailRecord );
    $File->add_trailer_record( $TrailerRecord );

=over

=item header_record (ArrayRef[Obj])

=item detail_record (ArrayRef[Obj])

=item trailer_record (ArrayRef[Obj])

=back

=cut

__PACKAGE__->load_attributes( $parent, @subclasses );

=head1 METHODS

=head2 new_from_file

Returns a new instance of the class with attributes populated from
the result of parsing the passed file

    my $File = Business::NAB::BPAY::Remittance::File
        ->new_from_file( $file_path );

=cut

sub new_from_file (
    $class,
    $file,
    $class_parent = $parent,    # undocumented as called by subclasses
) {

    my %sub_class_map = (
        0 => 'HeaderRecord',
        5 => 'DetailRecord',
        9 => 'TrailerRecord',
    );

    my $self = ref( $class ) ? $class : $class->new;

    return $self->SUPER::new_from_file(
        $class_parent, $file, \%sub_class_map
    );
}

=head2 to_file

Writes the file content to the passed file path:

    $File->to_file(
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
    print $fh $_->to_record . $sep foreach $self->detail_record->@*;

    if ( my $TrailerRecord = $self->trailer_record->[ 0 ] ) {
        print $fh $TrailerRecord->to_record . $sep;
    } else {

        my (
            $number_of_error_corrections,
            $amount_of_error_corrections,
            $number_of_payments,
            $amount_of_payments,
            $number_of_reversals,
            $amount_of_reversals,
        ) = ( 0 ) x 6;

        foreach my $detail ( $self->detail_record->@* ) {

            if ( $detail->is_payment ) {
                $number_of_payments++;
                $amount_of_payments += $detail->amount;

            } elsif ( $detail->is_correction ) {
                $number_of_error_corrections++;
                $amount_of_error_corrections += $detail->amount;

            } elsif ( $detail->is_reversal ) {
                $number_of_reversals++;
                $amount_of_reversals += $detail->amount;

            } else {
                croak(
                    "Unrecognised payment_instruction_type: "
                        . $detail->payment_instruction_type
                );
            }
        }

        my $TrailerRecord = Business::NAB::BPAY::Remittance::File::TrailerRecord->new( {
            'number_of_error_corrections' => $number_of_error_corrections,
            'amount_of_error_corrections' => $amount_of_error_corrections,

            'number_of_payments' => $number_of_payments,
            'amount_of_payments' => $amount_of_payments,

            'number_of_reversals' => $number_of_reversals,
            'amount_of_reversals' => $amount_of_reversals,

            'biller_code' => $self->header_record->[ 0 ]->biller_code,

            'settlement_amount' => $amount_of_payments
                - $amount_of_error_corrections
                - $amount_of_reversals,
        } );

        print $fh $TrailerRecord->to_record . $sep;
    }

    close( $fh );

    return 1;
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::BPAY::Remittance::File::HeaderRecord>

L<Business::NAB::BPAY::Remittance::File::DetailRecord>

L<Business::NAB::BPAY::Remittance::File::TrailerRecord>

=cut

__PACKAGE__->meta->make_immutable;
