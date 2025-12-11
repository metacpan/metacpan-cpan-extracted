package Business::NAB::Australian::DirectEntry::Returns::DescriptiveRecord;
$Business::NAB::Australian::DirectEntry::Returns::DescriptiveRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Return::DescriptiveRecord;

=head1 DESCRIPTION

Class for descriptive record in the "Australian Direct Entry Payments"
returns file. Inherits all logic/attributes from
L<Business::NAB::Australian::DirectEntry::Payments::DescriptiveRecord>.

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::Australian::DirectEntry::Payments::DescriptiveRecord';
no warnings qw/ experimental::signatures /;

__PACKAGE__->meta->make_immutable;
