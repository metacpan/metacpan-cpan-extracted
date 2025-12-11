package Business::NAB::BPAY::Payments::Results::HeaderRecord;
$Business::NAB::BPAY::Payments::Results::HeaderRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::BPAY::Payments::Results::HeaderRecord

=head1 SYNOPSIS

    use Business::NAB::BPAY::Payments::HeaderRecord;

    # parse
    my $Header = Business::NAB::BPAY::Payments::HeaderRecord
        ->new_from_record( $line );

    # create
    my $Header = Business::NAB::BPAY::Payments::Results::HeaderRecord->new(
        bpay_batch_user_id => '01',
        customer_short_name => 'NAB',
        processing_date => DateTime->now,
    );

    my $line = $Header->to_record;

=head1 DESCRIPTION

Class for header record in the "BPAY Batch User Guide" responses

All methods and attributes are inherited from
L<Business::NAB::BPAY::Payments::HeaderRecord>

=cut

use strict;
use warnings;

use Moose;
extends 'Business::NAB::BPAY::Payments::HeaderRecord';

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::BPAY::Payments::Results::HeaderRecord>

=cut

__PACKAGE__->meta->make_immutable;
