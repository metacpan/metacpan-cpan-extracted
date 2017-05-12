package CQL::ProxNode;

use strict;
use warnings;
use base qw( CQL::BooleanNode );
use CQL::ProxModifierSet;

=head1 NAME

CQL::ProxNode - represents a PROX node in a CQL parse tree

=head1 SYNOPSIS

    use CQL::ProxNode;
    my $node = CQL::ProxNode->new( left => $left );
    $node->addSecondTerm( $right );

=head1 DESCRIPTION

=head1 METHODS

=head1 new()

Creates a new, incomplete, proximity node with the
specified left-hand side.  No right-hand side is specified at
this stage: that must be specified later, using the
addSecondSubterm() method.  (That may seem odd, but
it's just easier to write the parser that way.)

Proximity paramaters may be added at any time,
before or after the right-hand-side sub-tree is added.
    
    my $prox = CQL::ProxNode->new( $term );

=cut

sub new {
    my ($class,$left) = @_;
    my $self = $class->SUPER::new( left => $left, right => undef );
    $self->{modifierSet} = CQL::ProxModifierSet->new( 'prox' );
    return $self;
}

=head2 addSecondTerm()

=cut

sub addSecondTerm {
    my ($self,$term) = @_;
    $self->{right} = $term;
}

=head2 addModifier()

=cut

sub addModifier {
    my ($self,$type,$value) = @_;
    $self->{modifierSet}->addModifier( $type, $value );
}

=head2 getModifiers()

=cut

sub getModifiers {
    return shift->{modifierSet}->getModifiers();
}

=head2 op()

=cut

sub op { 
    return shift->{modifierSet}->toCQL(); 
}

=head2 opXCQL()

=cut

sub opXCQL {
    my ($self,$level) = @_;
    return $self->{modifierSet}->toXCQL( $level, 'boolean' );
}

1;
