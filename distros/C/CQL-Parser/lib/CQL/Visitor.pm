package CQL::Visitor;

use strict;
use warnings;

=head1 NAME

CQL::Visitor - visit nodes in a CQL parse tree

=head1 SYNOPSIS

    package MyVisitor;
    use base qw( CQL::Visitor );

    sub term {
        my ($self,$node) = @_;
        # do something to the node
    }

    # later on
   
    my $parser = CQL::Parser->new();
    my $root = $parser->parse($cql);

    my $visitor = MyVisitor->new();
    $vistor->visit($root);

=head1 DESCRIPTION

CQL::Visitor provides a simple interface for visiting nodes in your parse tree.
It could be useful if you want to do something like change a query like this:

    dc.title=foo and dc.creator=bar 

    into

    title=foo and creator=bar

Or some similar procedure. You simply create a new subclass of CQL::Visitor
and override the appropriate method, such as term(). Every term that is
encountered during the traversal will be handed off to your term() method.

Note: at the moment only term() is supported because that's what was needed, but
if you need other ones feel free to add them, or ask for them.

=head1 METHODS

=head2 new()

=cut

sub new {
    my $class = shift;
    return bless {}, ref($class) || $class;
}

=head2 visit()

Call this to traverse your parse tree, starting at the root.

=cut

sub visit {
    my ($self,$node) = @_;
    if ( $node->isa( 'CQL::BooleanNode' ) ) { 
        $self->visit( $node->left() );
        $self->visit( $node->right() );
    }
    elsif ( $node->isa( 'CQL::TermNode' ) ) {
        $self->term( $node );
    }
}

=head2 term()

Your subclass should override this, and do something meaningful with the
CQL::TermNode object.

=cut

sub term {
    # subclasses should subclass
}

1;
