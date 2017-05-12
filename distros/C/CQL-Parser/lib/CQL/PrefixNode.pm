package CQL::PrefixNode;

use strict;
use warnings;
use base qw( CQL::Node );
use CQL::Prefix;
use Carp qw( croak );

=head1 NAME

CQL::PrefixNode - represents a prefix node in a CQL parse tree

=head1 SYNOPSIS

    use CQL::PrefixNode;
    my $prefix = CQL::PrefixNode->new(
        name        => '',
        identifier  => '',
        subtree     => $node
    );

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

Creates a new CQL::PrefixNode inducing a mapping from the
specified qualifier-set name to the specified identifier across
the specified subtree. 

=cut 

sub new {
    my ($class,%opts) = @_;
    croak( 'must supply name' ) if ! exists $opts{name};
    croak( 'must supply identifier' ) if ! exists $opts{identifier};
    croak( 'must supply subtree' ) if ! exists $opts{subtree};
    my $prefix = CQL::Prefix->new(
        name        => $opts{name},
        identifier  => $opts{identifier}
    );
    my $self = { 
        prefix      => $prefix, 
        subtree     => $opts{subtree} 
    };
    return bless $self, ref($class) || $class;
}

=head2 getPrefix()

=cut

sub getPrefix {
    return shift->{prefix};
}

=head2 getSubtree()

=cut

sub getSubtree {
    return shift->{subtree};
}

=head2 toCQL()

=cut

sub toCQL {
    my $self = shift;
    my $prefix = $self->getPrefix();
    my $subtree = $self->getSubtree();
    return ">" . $prefix->getName() . '="' . $prefix->getIdentifier() . '" ' .
        '(' . $subtree->toCQL() . ')';
}

=head2 toXCQL()

=cut

sub toXCQL {
    my ($self,$level,@prefixes) = @_;
    $level = 0 if ! $level;
    push( @prefixes, $self->getPrefix() );
    my $xml = $self->getSubtree()->toXCQL( $level, @prefixes );
    return $self->addNamespace( $level, $xml );
}

1;
