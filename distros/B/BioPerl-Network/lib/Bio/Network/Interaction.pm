#
# BioPerl module for Bio::Network::Interaction
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::Network::Interaction - describes a protein-protein interaction

=head1 SYNOPSIS

  # Add an interaction with some attributes
  use Bio::Network::Interaction;

  my $interx = Bio::Network::Interaction->new(-weight => $score,
                                            -id => $id);
  $gr->add_interaction(-nodes => [($node1,$node2)],
                       -interaction => $interx);

  # Retrieve an interaction using an identifier
  my $interaction = $gr->get_interaction_by_id($id);

  my $id = $interaction->primary_id;
  my $wt = $interaction->weight;
  my @nodes = $interaction->nodes;

=head1 DESCRIPTION

This class contains information about a bi-molecular interaction.
At present it just contains data about a weight (optional) and an 
identifier. Subclasses could hold more specific information. A pair 
of nodes can have more than one Interaction object associated with it.

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
package Bio::Network::Interaction;
use base qw(Bio::Root::Root Bio::AnnotatableI Bio::Annotation::Collection);


=head2 new

 Name       : new
 Purpose    : Constructor for an Interaction object
 Usage      : my $interx = Bio::Network::Interaction->new(-id => $id);
 Returns    : A new Bio::Network::Interaction object 
 Arguments  : -id                => interaction id
              -weight (optional) => weight score

=cut

sub new {
	my ($caller,@args) = @_;
	my $class = ref ($caller) || $caller;
	my $self = {};
	bless ($self, $class);

	my ($weight,$id) = $self->_rearrange([qw( WEIGHT ID )], @args);
	$self->{_weight} = defined($weight) ? $weight : undef; 
	$self->{_id} = defined($id) ? $id : undef; 
	return $self;
}

=head2 weight

 Name      : weight
 Purpose   : Get or set a weight or score
 Usage     : my $weight = $interx->weight()
                     or
             $interx->weight(3)
 Returns   : a number
 Arguments : Nothing or a number

=cut

sub weight {
	my $self = shift;
	$self->{_weight} = shift if @_;
	return defined($self->{_weight}) ? $self->{_weight} : undef;
}

=head2 primary_id

 Name      : primary_id
 Purpose   : Get or set the primary_id
 Usage     : my $id = $interx->primary_id()
                       or
             $interx->primary_id("SIB4")
 Returns   : A string identifier
 Arguments : Nothing or an identifier 

=cut

sub primary_id {
	my $self = shift;
	if (@_) {
		my $v  = shift;
		$self->throw ("Primary interaction ID must be a text value, not a [" . 
						  ref($v). "].") if (ref ($v));
		$self->{_id} = $v;
	}
	return defined($self->{_id}) ? $self->{_id} : undef;
}

=head2 nodes

 Name       : nodes
 Purpose    : Get the pair of nodes for an Interaction
 Usage      : my $count = $interx->nodes
                       or
              my @nodes = $interx->nodes
 Returns    : Gets an array of 2 Nodes or a count of the number of
              Nodes
 Arguments  :
 Notes      : Getting a count of the number of Nodes in an Interaction 
              will almost always return 2, but there is a formal possibility
              that a Node could interact with itself, returning 1

=cut

sub nodes {
	my $self = shift;
	my @nodes = @{$self->{_nodes}};
	wantarray ? return @nodes : return scalar @nodes;
}

=head2 annotation

 Title   : annotation
 Usage   : my $annotation = $ix->annotation 
                   or 
           $ix->annotation($annotation)
 Function: Gets or sets the annotation
 Returns : Bio::AnnotationCollectionI object
 Args    : None or Bio::AnnotationCollectionI object

See L<Bio::AnnotationCollectionI> and L<Bio::Annotation::Collection>
for more information

=cut

sub annotation {
	my ($obj,$value) = @_;
	if ( defined $value ) {
		$obj->throw("Object of class " . ref($value) . " does not implement ".
						"Bio::AnnotationCollectionI.")
		  unless $value->isa("Bio::AnnotationCollectionI");
		$obj->{'_annotation'} = $value;
	} elsif( ! defined $obj->{'_annotation'}) {
		$obj->{'_annotation'} = Bio::Annotation::Collection->new();
	}
	return $obj->{'_annotation'};
}

=head2 object_id

 Name      : object_id
 Purpose   : Alias to primary_id
 Usage     : my $id = $edge->object_id()
 Notes     : Deprecated

=cut

sub object_id {
	my ($self,$id) = @_;
	$id ? $self->primary_id($id) : return $self->primary_id;
}

1;

__END__
