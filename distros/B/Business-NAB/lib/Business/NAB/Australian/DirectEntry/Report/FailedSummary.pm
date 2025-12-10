package Business::NAB::Australian::DirectEntry::Report::FailedSummary;
$Business::NAB::Australian::DirectEntry::Report::FailedSummary::VERSION = '0.01';
=head1 NAME

Business::NAB::Australian::DirectEntry::Report::ValueSummary

Extends L<Business::NAB::Australian::DirectEntry::Report::ValueSummary>

=head1 SYNOPSIS

=head1 DESCRIPTION

Class for failed summary record in the Australian Direct Entry Report file

=cut;

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::Australian::DirectEntry::Report::ValueSummary';
no warnings qw/ experimental::signatures /;

use Business::NAB::Types qw/
    add_max_string_attribute
    /;

=head1 ATTRIBUTES

All are Str types, required, except where stated. Extra attributes are
inherited from L<Business::NAB::Australian::DirectEntry::Report::ValueSummary>.

=over

=item failed_item_treatment_option

=item text

=back

=cut

sub _record_type { '62' }

sub _attributes ( $self ) {

    return (
        $self->SUPER::_attributes,
        $self->_extra_attributes,
    );
}

sub _extra_attributes ( $self ) {

    return qw/
        failed_item_treatment_option
        text
        /;
}

foreach my $str_attr (
    'sub_trancode',
    __PACKAGE__->_extra_attributes,
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

__PACKAGE__->meta->make_immutable;
