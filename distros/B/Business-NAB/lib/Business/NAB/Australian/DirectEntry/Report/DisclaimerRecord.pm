package Business::NAB::Australian::DirectEntry::Report::DisclaimerRecord;
$Business::NAB::Australian::DirectEntry::Report::DisclaimerRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Report::DisclaimerRecord

=head1 SYNOPSIS

=head1 DESCRIPTION

Class for disclaimer record in the Australian Direct Entry Report file

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

All are Str types, required, except where stated

=over

=item text

=back

=cut

sub _record_type { '100' }

sub _attributes {

    return qw/
        text
        /;
}

foreach my $str_attr (
    __PACKAGE__->_attributes
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

__PACKAGE__->meta->make_immutable;
