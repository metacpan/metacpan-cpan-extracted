package Chloro::Trait::Class;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose::Role;

with 'Chloro::Role::Trait::HasFormComponents';

sub fields {
    my $self = shift;

    return $self->_unique_items('local_fields');
}

sub groups {
    my $self = shift;

    return $self->_unique_items('local_groups');
}

sub _unique_items {
    my $self = shift;
    my $meth = shift;

    my %seen;
    my @items;

    for my $class ( $self->linearized_isa() ) {
        my $meta = Class::MOP::class_of($class);

        next unless $meta && $meta->can($meth);

        for my $item ( $meta->$meth() ) {
            next if $seen{ $item->name() };

            push @items, $item;

            $seen{ $item->name() } = 1;
        }
    }

    return @items;
}

1;
