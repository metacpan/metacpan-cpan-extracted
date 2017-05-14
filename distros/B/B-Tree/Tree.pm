package B::Tree;

use strict;
our $VERSION = "0.02";

use GraphViz;
use B qw(main_root walkoptree_slow);

my $g;

sub compile {
    return sub { 
        $g = new GraphViz;
        walkoptree_slow(main_root, "visit");
        print $g->as_dot;
    };
}

sub B::LISTOP::visit {
    my $self = shift;
    $g->add_node({name => $$self, label => $self->name});
    my $node = $self->first;
    $g->add_edge({from => $$self, to => $$node});
    sibvisit($self, $node);
}

sub B::BINOP::visit {
    my $self = shift;
    my $first = $self->first;
    my $last = $self->last;
    $g->add_node({name => $$self, label => $self->name});
    $g->add_edge({from => $$self, to => $$first});
    $g->add_edge({from => $$self, to => $$last});
}

sub B::UNOP::visit {
    my $self = shift;
    my $first = $self->first;
    $g->add_node({name => $$self, label => $self->name});
    $g->add_edge({from => $$self, to => $$first});
    B::Tree::sibvisit($self, $first); # For nulls.
}

sub B::LOOP::visit {
    my $self = shift;
    if ($self->children) {
        B::LISTOP::visit($self);
    } else {
    $g->add_node({name => $$self, label => $self->name});
    }
}

sub B::OP::visit {
    my $self = shift;
    $g->add_node({name => $$self, label => $self->name});
}

sub B::PMOP::visit { # PMOPs think they're unary, but they aren't.
    my $self = shift;
    $g->add_node({name => $$self, label => $self->name});
}

sub sibvisit {
    my ($parent, $child) = @_;
    while ($child->can("sibling") and ${$child->sibling}) {
        $child = $child->sibling;
        $g->add_edge({from => $$parent, to => $$child});
    }
}
1;

=head1 NAME

B::Tree - Simplified version of B::Graph for demonstration

=head1 SYNOPSIS

    perl -MO=Tree program | dot -Tps > tree.ps

=head1 DESCRIPTION

This is a very cut-down version of C<B::Graph>; it generates minimalist
tree graphs of the op tree of a Perl program, merely connecting the op
nodes and labelling each node with the type of op.

It was written as an example of how to write compiler modules for
"Professional Perl", but I've found it extremely useful for creating
simple op tree graphs for use in presentations on Perl internals.

It requires the CPAN C<GraphViz> module and the GraphViz package from
C<http://www.research.att.com/sw/tools/graphviz/>. It takes no
options.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<GraphViz>, L<B::Graph>
