package Business::NAB::Australian::DirectEntry::Report::ValueSummary;
$Business::NAB::Australian::DirectEntry::Report::ValueSummary::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Report::ValueSummary

=head1 SYNOPSIS

=head1 DESCRIPTION

Class for summary record in the Australian Direct Entry Report file

=cut;

use strict;
use warnings;
use feature qw/ signatures /;
use Carp    qw/ croak /;

use Moose;
extends 'Business::NAB::CSV';
no warnings qw/ experimental::signatures /;

use Business::NAB::Types qw/
    add_max_string_attribute
    /;

=head1 ATTRIBUTES

All are NAB::Type::PositiveInt types, required, except where stated

=over

=item sub_trancode (Str)

=item number_of_items

=item total_of_items

=back

=cut

sub BUILD {
    my ( $self ) = @_;

    croak( "unsupported record type (@{[ $self->record_type ]})" )
        if ( $self->record_type !~ /^5(4|8)|62$/ );
}

sub _record_type ( $self ) { return $self->record_type }

has [ qw/ record_type / ] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => sub {
        '54',;
    },
);

sub _attributes {
    return qw/
        sub_trancode
        number_of_items
        total_of_items
        /;
}

has [
    qw/
        number_of_items
        total_of_items
        /
] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveIntOrZero',
    required => 1,
);

foreach my $str_attr (
    grep { $_ !~ /items/ } __PACKAGE__->_attributes
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

sub is_credit ( $self ) { return $self->record_type eq '54' }
sub is_debit  ( $self ) { return $self->record_type eq '58' }
sub is_failed ( $self ) { return $self->record_type eq '62' }

__PACKAGE__->meta->make_immutable;
