#
# BioPerl module for Bio::Network::Edge
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::Network::Edge - holds the names of pairs of Nodes

=head1 SYNOPSIS

  use Bio::Network;

  # get a network, somehow, then:
  my @edges = $graph->edges;
  for my $edge (@edges) {
    for my $node ($edge->[0],$edge->[1]) {
      my @proteins = $node->proteins;
      for my $protein (@proteins) {
        print "Sequence is: ", $protein->seq, "\n";
      }
    }  
  }

=head1 DESCRIPTION

This class contains the names of the Nodes in a bi-molecular 
interaction. An Edge object is extremely simple as most of the
experimental or biological detail goes into the Interaction
objects.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists. Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHORS

Brian Osborne bosborne at alum.mit.edu
Richard Adams richard.adams@ed.ac.uk

Maintained by Brian Osborne

=cut

use strict;
package Bio::Network::Edge;
use base 'Bio::Root::Root';

=head2 new

 Name       : new
 Purpose    : Constructor for an Edge object
 Usage      : my $edge = Bio::Network::Edge->new(-nodes => \@nodes);
 Returns    : A new Bio::Network::Edge object 
 Arguments  : -nodes => reference to an array containing a 
              pair of Nodes

=cut

sub new {
	my ($caller,@args) = @_;
	my $class = ref ($caller) || $caller;
	my $self = {};
	bless ($self,$class);

	my ($nodes) = $self->_rearrange([qw( NODES )], @args);
	$self->throw("You must pass 1 or 2 Nodes to Bio::Network::Edge, not ",
	  scalar @$nodes, " nodes") if (scalar @$nodes == 0 || scalar @$nodes > 2);
	for my $node (@$nodes) {
		$self->throw("You must pass Bio::Network::Node objects to Bio::Network::Edge->new, not ",
						ref($node), " objects") unless ($node->isa("Bio::Network::Node"));
	}
	$self->{_nodes} = $nodes; 
	return $self;
}

=head2 nodes

 Name       : nodes
 Purpose    : Get the pair of nodes for an Edge
 Usage      : my $count = $edge->nodes
                       or
              my @nodes = $edge->nodes
 Returns    : Gets an array of 2 Nodes or a count of the number of
              Nodes
 Arguments  :
 Notes      : Getting a count of the number of Nodes in an edge will
              almost always return 2, but there is a formal possibility
              that a Node could interact with itself, returning 1

=cut

sub nodes {
	my $self = shift;
	my @nodes = @{$self->{_nodes}};
	wantarray ? return @nodes : return scalar @nodes;
}

1;

__END__

=head2 next_node

 Name       :
 Purpose    :
 Usage      :
 Returns    :
 Arguments  :

=cut

sub next_node {
	my $self = shift;
}
