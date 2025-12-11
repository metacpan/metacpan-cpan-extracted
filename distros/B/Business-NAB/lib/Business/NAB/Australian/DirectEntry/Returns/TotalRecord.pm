package Business::NAB::Australian::DirectEntry::Returns::TotalRecord;
$Business::NAB::Australian::DirectEntry::Returns::TotalRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Return::TotalRecord;

=head1 DESCRIPTION

Class for total record in the "Australian Direct Entry Payments"
returns file. Inherits all logic/attributes from
L<Business::NAB::Australian::DirectEntry::Payments::TotalRecord>.

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::Australian::DirectEntry::Payments::TotalRecord';
no warnings qw/ experimental::signatures /;

sub record_type { 7 }

__PACKAGE__->meta->make_immutable;
