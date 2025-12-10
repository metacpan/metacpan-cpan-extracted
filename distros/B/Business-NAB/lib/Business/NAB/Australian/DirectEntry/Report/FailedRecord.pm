package Business::NAB::Australian::DirectEntry::Report::FailedRecord;
$Business::NAB::Australian::DirectEntry::Report::FailedRecord::VERSION = '0.01';
=head1 NAME

Business::NAB::Australian::DirectEntry::Report::FailedRecord

=head1 SYNOPSIS

=head1 DESCRIPTION

Class for failed record in the Australian Direct Entry Report file.

Extends L<Business::NAB::Australian::DirectEntry::Report::PaymentRecord>.

=cut;

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::Australian::DirectEntry::Report::PaymentRecord';
no warnings qw/ experimental::signatures /;

use Business::NAB::Types qw/
    add_max_string_attribute
    /;

=head1 ATTRIBUTES

All are Str types, required, except where stated. Extra attributes are
inherited from L<Business::NAB::Australian::DirectEntry::Report::PaymentRecord>.

=over

=item failed_reason_code

=item reason_for_rejection

=back

=cut

sub _record_type ( $self ) { '61' }

sub _attributes ( $self ) {

    return (
        qw/ sub_trancode /,
        $self->SUPER::_attributes,
        $self->_extra_attributes,
    );
}

sub _extra_attributes ( $self ) {

    return qw/
        failed_reason_code
        reason_for_rejection
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
