package Business::NAB::Australian::DirectEntry::Report::TrailerRecord;
$Business::NAB::Australian::DirectEntry::Report::TrailerRecord::VERSION = '0.01';
=head1 NAME

Business::NAB::Australian::DirectEntry::Report::TrailerRecord

=head1 SYNOPSIS

=head1 DESCRIPTION

Class for trailer record in the Australian Direct Entry Report file

=cut;

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::CSV';
no warnings qw/ experimental::signatures /;

use Business::NAB::Types qw/
    add_max_string_attribute
    /;

=head1 ATTRIBUTES

All are NAB::Type::PositiveIntOrZero types, required, except where stated

=over

=item net_file_total

=item credit_file_total

=item debit_file_total

=item total_number_of_records

=back

=cut

sub _record_type { '99' }

sub _attributes {

    return qw/
        net_file_total
        credit_file_total
        debit_file_total
        total_number_of_records
        /;
}

has [ __PACKAGE__->_attributes ] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveIntOrZero',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
