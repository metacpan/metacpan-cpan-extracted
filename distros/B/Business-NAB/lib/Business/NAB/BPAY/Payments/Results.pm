package Business::NAB::BPAY::Payments::Results;
$Business::NAB::BPAY::Payments::Results::VERSION = '0.01';
=head1 NAME

Business::NAB::BPAY::Payments::Results

=head1 SYNOPSIS

    use Business::NAB::BPAY::Payments::Results;

    my $Payments = Business::NAB::BPAY::Payments::Results->new_from_file(
        "/path/to/bpay/payments/batch/file_response.bpb",
    );

    # parse
    my $Header = $Payments->header_record->[0];

    foreach my $Payment ( $Payments->detail_record->@* ) {
        ...
    }

    my $Trailer = $Payments->trailer_record->[0];

    # create
    $Payments->to_file(
        "/path/to/bpay/payments/batch/file_output_results.bpb",
        $separator, # defaults to "\r\n"
    );


=head1 DESCRIPTION

Class for parsing / creating a NAB BPAY batch payments response files

All methods and attributes are inherited from
L<Business::NAB::BPAY::Payments>

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::BPAY::Payments';
no warnings qw/ experimental::signatures /;

use Business::NAB::BPAY::Payments::Results::TrailerRecord;

# we have long namespaces and use them multiple times so have
# normalised them out into the $parent and @subclasses below
my $parent = 'Business::NAB::BPAY::Payments::Results';

my @subclasses = (
    qw/
        HeaderRecord
        DetailRecord
        TrailerRecord
        /
);

__PACKAGE__->load_attributes( $parent, @subclasses );

sub new_from_file ( $class, $file ) {

    my $self = $class->new;

    return $self->SUPER::new_from_file(
        $file, $parent
    );
}

sub to_file ( $self, $file, $sep = "\r\n" ) {

    if ( !$self->trailer_record->[ 0 ] ) {

        my (
            $total_value, $total_value_success, $total_value_failed,
            $total_count, $total_count_success, $total_count_failed,
        ) = ( 0, 0, 0, 0, 0, 0 );

        foreach my $Detail ( $self->detail_record->@* ) {
            $total_value += $Detail->amount;
            $total_count++;

            if ( $Detail->is_successful ) {
                $total_value_success += $Detail->amount;
                $total_count_success++;
            } else {
                $total_value_failed += $Detail->amount;
                $total_count_failed++;
            }
        }

        my $TrailerRecord = Business::NAB::BPAY::Payments::Results::TrailerRecord->new(
            total_value_of_payments             => $total_value,
            total_number_of_payments            => $total_count,
            total_value_of_successful_payments  => $total_value_success,
            total_number_of_successful_payments => $total_count_success,
            total_value_of_declined_payments    => $total_value_failed,
            total_number_of_declined_payments   => $total_count_failed,
        );

        $self->add_trailer_record( $TrailerRecord );
    }

    return $self->SUPER::to_file( $file, $sep );
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::BPAY::Payments>

L<Business::NAB::BPAY::Payments::Results::HeaderRecord>

L<Business::NAB::BPAY::Payments::Results::DetailRecord>

L<Business::NAB::BPAY::Payments::Results::TrailerRecord>

=cut

__PACKAGE__->meta->make_immutable;
