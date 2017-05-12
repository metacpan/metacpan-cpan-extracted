#
# BioPerl module for Bio::Network::Node
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::Network::Node - describe a Node, either a protein or protein 
complex

=head1 SYNOPSIS

  use Bio::Network::Node;

  my $node = Bio::Network::Node->new(-protein => [($seq1,$seq2)]);

  # or get nodes from a network:
  my @nodes = $graph->nodes;
  for my $node (@nodes) {
     my @proteins = $node->proteins
     for my $protein (@proteins) {
        print "Sequence is ", $protein->seq;
     }
  }  

=head1 DESCRIPTION

This class describes nodes in a network of interactions. A node is either
a protein, a Sequence object, or a protein complex, which is a collection
of Sequence objects. 

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

Maintained by Brian Osborne

=cut

use strict;
package Bio::Network::Node;
use base 'Bio::Root::Root';

=head2 new

 Name       : new
 Purpose    : Constructor for an Node object
 Usage      : my $node = Bio::Network::Node->new(-protein => $seqobj)   
                                   or
              my $node = Bio::Network::Node->new(-protein => [($seqobj1,$seqobj2)])  
                                   or
              my $node = Bio::Network::Node->new(-protein => 
                                               [ [(2, $seqobj1)],
																 [(1, $seqobj2)],
                                                 [(3, $seqobj3)] ];
 Returns    : A new Bio::Network::Node object 
 Arguments  : -protein => 1 Sequence object    
                             or
				  -protein => Reference to an array containing 1 or more
                          Sequence objects       
                             or
              -protein => Reference to an array of arrays where the elements are 
                          arrays containing a number denoting the number of subunits of 
                          a protein in the protein complex and a Sequence object
 Notes      :

=cut

sub new {
	my ($caller,@args) = @_;
	my $class = ref ($caller) || $caller;
	my $self = {};
	bless ($self,$class);
	my $count = 1;

	# Defaults
	$self->{_is_complex} = 0; # 1 protein, not a protein complex

	my ($protein) = $self->_rearrange([qw( PROTEIN )], @args); 
	$self->throw("No proteins specified when making a Node")
	  unless defined($protein); 
	
	if ( ref($protein) eq "ARRAY" ) {
		$self->throw("No Sequence objects passed to Bio::Network::Node::new")
		  if scalar @$protein == 0;
		# If an array of arrays is passed...
		if (ref($$protein[0]) eq "ARRAY") {
			for my $ref (@{$protein}) {
				$self->throw("Must pass a Sequence object to Bio::Network::Node::new")
				  unless $ref->[0]->isa("Bio::Seq");
				$self->{_protein}->{$count}->{_subunit} = $ref->[0];
				$self->{_protein}->{$count}->{_number} = $ref->[1] if $ref->[1];
				$self->{_is_complex} = 1 if ($ref->[1] && $ref->[1] > 2);
				$count++;
			}
			$self->{_is_complex} = 1 if ($count > 2);
		} else {		
			# If an array of Sequence objects is passed...
			for my $protein (@{$protein}) {
				$self->throw("Must pass a Sequence object to Bio::Network::Node::new")
				  unless $protein->isa("Bio::Seq");
				# Seq object must be value, not key
				$self->{_protein}->{$count}->{_subunit} = $protein;
				$self->{_protein}->{$count}->{_number} = undef;
				$count++;
			}
			$self->{_is_complex} = 1 if ($count > 2);
		}
	} else {
		# A single Sequence object is passed
		$self->throw("Must pass a Sequence object to Bio::Network::Node::new")
		  unless $protein->isa("Bio::Seq");
		# Seq object must be value, not key
		$self->{_protein}->{$count}->{_subunit} = $protein;		
		$self->{_protein}->{$count}->{_number} = undef;		
	}
	$self;
}

=head2 proteins

 Name       : proteins
 Purpose    : Get the proteins in a Node or get a count of proteins in the Node
 Usage      : my $count = $node->proteins   
                          or
              my @proteins = $node->proteins 
 Returns    : Gets an array of Sequence objects or a count of 
              the number of Sequence objects
 Arguments  : None

=cut

sub proteins {
	my $self = shift;
	$self->throw("Only a Node object can call the Node::proteins() method")
	  unless $self->isa("Bio::Network::Node");
	if (wantarray) {
		my @proteins;
		for my $count (keys %{$self->{_protein}}) {
			push @proteins,$self->{_protein}->{$count}->{_subunit};
		}
		return @proteins;
	}
	scalar keys %{$self->{_protein}};
}

=head2 next_protein

 Name       :
 Purpose    :
 Usage      :
 Returns    :
 Arguments  :

=cut

sub next_protein {
	my $self = shift;
	$self->throw("Only a Node object can call the Node::next_protein() method")
	  unless $self->isa("Bio::Network::Node");


}

=head2 is_complex

 Name       : is_complex
 Purpose    : Get or set whether a node is a protein or a protein complex
 Usage      : if ($node->is_complex){ ... }
                           or
              $node->is_complex(1)
 Returns    : 1 if the Node has more than 1 proteins, 0 if not
 Arguments  : None

=cut

sub is_complex {
	my ($self,$arg) = @_;
	$self->throw("Only a Node object can call the Node::is_complex() method")
	  unless $self->isa("Bio::Network::Node");
	if (defined $arg) {
		if ($arg == 1) {
			$self->{_is_complex} = 1;
		} elsif ($arg == 0) {
			$self->{_is_complex} = 0;
		} 
	} else {
		return 1 if ($self->{_is_complex});
		return 0;
	}
}

=head2 subunit_number

 Name       : subunit_number
 Purpose    : Get or set the number of a given protein in a protein
              complex.
 Usage      : $num = $node->subunit_number($protein)    
                            or
              $node->subunit_number($protein,$number)
 Returns    : A number, whether get or set
 Arguments  : None or a Sequence object in a given Node

=cut

sub subunit_number {
	my ($self,$protein,$num) = @_;
	$self->throw("Only a Node object can call the Node::subunit_number() method")
	  unless $self->isa("Bio::Network::Node");
	if ($protein && $num) {
		for my $key (keys %{$self->{_protein}}) {
			if ($self->{_protein}->{$key}->{_subunit} == $protein) {	
				$self->{_protein}->{$key}->{_number} = $num; 
				return $num;
			}
		}
		$self->throw("Protein ",$protein," not found, cannot set subunit_number");
	} else {
		for my $key (keys %{$self->{_protein}}) {
			return $self->{_protein}->{$key}->{_number}
			  if $self->{_protein}->{$key}->{_subunit} eq $protein;
		}
	}
}

1;

__END__
