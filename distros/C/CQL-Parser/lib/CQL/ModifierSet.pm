package CQL::ModifierSet;

use strict;
use warnings;
use CQL::Utils qw( indent xq );
use Carp qw( croak );

=head1 NAME

CQL::ModifierSet - represents a base string and modifier strings 

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is used as a delegate by both CQLRelation and
CQLProxNode - two functionally very separate classes that happen to
require similar data structures and functionality.

A ModifierSet consists of a ``base'' string together with a set of
zero or more type=value pairs, where both type and value are strings.
Types may be null, values may not.
       
=head1 METHODS

=head2 new()

Creates a new modifier set with the specified base. 

=cut 

sub new {
    my ($class,$base) = @_;
    my $self = { base => $base, modifiers => [] };
    return bless $self, ref($class) || $class;
}

=head2 getBase()

Returns the base string with which the modifier set was created.

=cut

sub getBase {
    return shift->{base};
}

=head2 addModifier() 

Adds a modifier of the specified type and value to a modifier set.

=cut

sub addModifier {
    my ($self,$type,$value) = @_;
    push( @{ $self->{modifiers} }, [ $type => $value ] );
}

=head2 modifier()

Returns a modifier with a given type, or null if a modifier of that
type isn't present.

=cut

sub modifier {
    my ($self,$type) = @_;
    foreach my $pair ( @{ $self->{modifiers} } ) { 
        if ( $pair->[0] eq $type ) { return $pair->[1]; }
    }
    return undef;
}

=head2 getModifiers()

Returns a list of modifiers each represented by a 2 element array ref.

=cut

sub getModifiers {
    my $self = shift;
    return @{ $self->{modifiers} };
}

=head2 toCQL()

=cut

sub toCQL {
    my $self = shift;
    my $cql = $self->{base};
    foreach ( @{ $self->{modifiers} } ) { 
        $cql .= "/" . $_->[1];
    }
    return $cql;
}

=head2 toSwish()

=cut

sub toSwish {
    my $self = shift;
    croak( "Swish does not support relational modifiers" )
        if @{ $self->{modifiers} } > 0;
    my $base = $self->getBase();
    return $base if $base eq "=" or $base eq "not"; 
    croak( "Swish doesn't support relations other than = and not" );
}

=head2 toXCQL()

=cut

sub toXCQL {
    my ($self, $level, $topLevelElement) = @_;
    my $buffer = 
        indent($level).'<'.$topLevelElement.">\n". 
        indent($level+1)."<value>".xq($self->{base})."</value>\n";
    my @modifiers = $self->getModifiers();
    if ( @modifiers > 0 ) { 
        $buffer .= indent($level+1)."<modifiers>\n";
        foreach my $m ( @modifiers ) { 
            $buffer .= indent($level+2)."<modifier>";
            $buffer .= "<type>".xq($m->[0])."</type>" if $m->[0];
            $buffer .= "<value>".xq($m->[1])."</value></modifier>\n"
        }
        $buffer .= indent($level+1)."</modifiers>\n";
    }
    $buffer .= indent($level).'</'.$topLevelElement.">\n";
    return $buffer;
}

1;
