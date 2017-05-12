package CQL::ProxModifierSet;

use strict;
use warnings;
use base qw( CQL::ModifierSet );
use CQL::Utils qw( indent xq );
use Carp qw( croak );
use CQL::ModifierSet;

=head1 NAME

CQL::ProxModifierSet - represents a base string and modifier strings 

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is used as a delegate by CQLProxNode based on ModifierSet
data structure.

=head1 METHODS

=head2 toCQL()

=cut

sub toCQL {
    my $self = shift;
    my $cql = $self->{base};

    my $distance = $self->modifier("distance");
    my $relation = $self->modifier("relation");
    my $unit = $self->modifier("unit");
    my $ordering = $self->modifier("ordering");

    $cql .= "/distance$relation$distance"
	if defined $distance and defined $relation;
    $cql .= "/unit=$unit" if defined $unit;
    $cql .= "/$ordering" if defined $ordering;

    return $cql;
}

1;
