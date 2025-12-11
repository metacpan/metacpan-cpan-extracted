package Business::NAB::Australian::DirectEntry::Report::PaymentRecord;
$Business::NAB::Australian::DirectEntry::Report::PaymentRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Report::PaymentRecord

=head1 SYNOPSIS

=head1 DESCRIPTION

Class for payment record in the Australian Direct Entry Report file

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

=item payment_type

=item lodgement_ref

=item amount (NAB::Type::PositiveInt)

=item currency

=item credit_debit

=item title_of_account

=item bsb_number (NAB::Type::BSBNumber)

=item account_number (NAB::Type::AccountNumber)

=back

=cut

sub _record_type ( $self ) { $self->is_credit ? '53' : '57' }

sub _attributes {
    return qw/
        payment_type
        lodgement_ref
        amount
        currency
        credit_debit
        title_of_account
        bsb_number
        account_number
        /;
}

has [ qw/ amount / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveInt',
    required => 1,
);

has [ qw/ bsb_number / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::BSBNumber',
    required => 1,
    coerce   => 1,
);

has [ qw/ account_number / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::AccountNumber',
    required => 1,
);

foreach my $str_attr (
    grep { $_ !~ /bsb|amount|account_number/ } __PACKAGE__->_attributes
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

sub is_credit ( $self ) { return $self->credit_debit eq 'CR' }
sub is_debit  ( $self ) { return $self->credit_debit eq 'DR' }

__PACKAGE__->meta->make_immutable;
