#
# BioPerl module for Bio::Network::IO::dip_tab
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::Network::IO::dip_tab - class for parsing interaction data in DIP
tab-delimited format

=head1 SYNOPSIS

Do not use this module directly, use Bio::Network::IO. For example:

  my $io = Bio::Network::IO->new(-format => 'dip_tab',
                                 -file   => 'data.dip');

  my $network = $io->next_network;

=head1 DESCRIPTION

The Database of Interacting Proteins (DIP) is a protein interaction
database (see L<http://dip.doe-mbi.ucla.edu/dip/Main.cgi>).
The species-specific subsets of the DIP database are provided in
a simple, tab-delimited format. The tab-separated columns are:

   edge     DIP id 
   node A   DIP id 
	node A   optional id
   node A   SwissProt id
   node A   PIR id
   node A   GenBank GI id
   node B   DIP id 
	node B   optional id
   node B   SwissProt id
   node B   PIR id
   node B   GenBank GI id

The source or namespace of the optional id in columns 3 and 8 varies 
from species to species, and optional ids are frequently absent. 

=head2 Versions

The first version of this format prepended the identifier with a 
database name, e.g.:

  DIP:4305E  DIP:3048N     PIR:B64526  SWP:P23487  GI:2313123  ...

The version as of 1/2006 has no database identifiers:

  DIP:4305E  DIP:3048N     B64526  P23487  2313123  ...

This module parses both versions.

=head1 METHODS

The naming system is analagous to the SeqIO system, although usually
next_network() will be called only once per file.

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

=cut

package Bio::Network::IO::dip_tab;
use strict;
use vars qw(@ISA $FAC);
use Bio::Network::IO;
use Bio::Network::ProteinNet;
use Bio::Network::Node;
use Bio::Seq::SeqFactory;
use Bio::Annotation::DBLink;
use Bio::Annotation::Collection;
use Bio::Network::Interaction;

@ISA = qw(Bio::Network::IO Bio::Network::ProteinNet);

BEGIN {
	$FAC = Bio::Seq::SeqFactory->new(-type => 'Bio::Seq::RichSeq');
}

=head2 next_network

  Name        : next_network
  Purpose     : parses a DIP file and returns a Bio::Network::ProteinNet 
                object
  Usage       : my $g = $graph_io->next_network();
  Arguments   : none
  Returns     : a Bio::Network::ProteinNet object

=cut

sub next_network {
	my $self = shift;
	my $graph = Bio::Network::ProteinNet->new(refvertexed => 1);

	while (my $l = $self->_readline() ) {
		chomp $l;
		## get line, only gi and node_id always defined
		my ($interx_id, $node_id1, $o1, $s1, $p1, $g1, 
                    $node_id2, $o2, $s2, $p2, $g2, $score) = split '\t', $l;
		last unless ($interx_id && $g2);

		## concatenate correct database name with id 
		($g1,$g2) = $self->_fix_id("GI",$g1,$g2);
		($s1,$s2) = $self->_fix_id("SWP",$s1,$s2);
		($p1,$p2) = $self->_fix_id("PIR",$p1,$p2);
		# ($node_id1,$node_id2) = $self->_fix_id("DIP",$node_id1,$node_id2);

		## skip if score is below threshold
		if ($self->threshold && defined($score)) {
			next unless $score >= $self->threshold;
		}

	   ## build node object if it's a new node, use DIP id
	   my ($node1, $node2);

	   unless ( $node1 = $graph->get_nodes_by_id($node_id1) ) {
			my $acc = $s1 || $p1 || $g1;
			my $ac = $self->_add_db_links($acc, $s1, $p1, $node_id1, $g1);
			my $prot1 = $FAC->create(-accession_number => $acc,
											 -primary_id       => $g1,
											 -display_id		 => $acc,
											 -annotation       => $ac,
										);		
			$node1 = Bio::Network::Node->new(-protein => [($prot1)]);
			$graph->add_node($node1);
			my @ids = ($g1, $p1, $s1, $node_id1);
			$graph->add_id_to_node(\@ids,$node1);
		}

		unless ( $node2 = $graph->get_nodes_by_id($node_id2) ) {
			my $acc = $s2 || $p2 || $g2;
			my $ac = $self->_add_db_links($acc, $s2, $p2, $node_id2, $g2);
			my $prot2 = $FAC->create(-accession_number => $acc,
											 -primary_id       => $g2,
											 -display_id		 => $acc,
											 -annotation       => $ac,
										 );		
			$node2 = Bio::Network::Node->new(-protein => [($prot2)]);
			$graph->add_node($node2);
			my @ids = ($g2, $p2, $s2, $node_id2);
			$graph->add_id_to_node(\@ids,$node2);
		}

		## create new Interaction object based on DIP id, weight
		my $interx = Bio::Network::Interaction->new(-weight => $score,
													         -id     => $interx_id);

		$graph->add_interaction(-interaction => $interx,
									   -nodes => [($node1,$node2)]);
		$graph->add_id_to_interaction($interx_id,$interx);
	}  
	$graph;
}

=head2 write_network

 Name     : write_network
 Purpose  : write graph out in dip format
 Arguments: a Bio::Network::ProteinNet object
 Returns  : void
 Usage    : $out->write_network($gr);

=cut

sub write_network {
	my ($self, $gr) = @_;
	if ( !$gr || !$gr->isa('Bio::Network::ProteinNet') ) {
		$self->throw("I need a Bio::Network::ProteinNet, not a [".
						 ref($gr) . "]");
	}

	# Need to have all ids as annotations with database ids as well,
	# the idea is to be able to round trip, to write it in same way as 
	# for each edge

	for my $ref ($gr->edges) {
		my ($interx,$str,$weight);

		my $atts = $gr->get_edge_attributes(@$ref);
		# there should be only one Interaction if the network is from DIP
		for my $interx (keys %$atts) {
			# add DIP edge id
			$str = $interx . "\t"; 
			$weight = $atts->{$interx}->weight();
		}

		# add node ids to string
		for my $node (@$ref){
			# print out nodes in dip_tab order
			my %ids = $gr->get_ids_by_node($node); # need to modify this in graph()
			# add second tab since we won't write out an optional id
			$str .= "DIP:" . $ids{DIP} . "\t\t"; 
			for my $name ( qw(UniProt PIR GenBank) ) {
				$str .= $ids{$name} if (defined $ids{$name});
				$str .= "\t"; 
			}
		}

		# add weight if defined
		$str .= $weight . "\t" if $weight;
		$str =~ s/\t$/\n/;
		$self->_print($str);
	}
	$self->flush();
}

=head2 _add_db_links

 Name     : _add_db_links
 Purpose  : create DBLink annotations, add to an Annotation
            Collection object
 Arguments: an array of ids
 Returns  : an Annotation::Collection object
 Usage    :

=cut

sub _add_db_links {
	my $self = shift;
	my @ids = @_;
	my %seen;
	my $ac = Bio::Annotation::Collection->new();
	for my $id (@ids) {
		next unless $id;
		next if $seen{$id};
		$id =~ /^([^:]+):([^:]+)/;
		my $an = Bio::Annotation::DBLink->new( 
                         -database   => $1,
								 -primary_id => $2 );
		$ac->add_Annotation('dblink', $an);
		$seen{$id}++;
	}
	return $ac;
}

=head2 _fix_id

 Name     : _fix_id
 Purpose  : 
 Arguments: 
 Returns  : 
 Usage    :

=cut

sub _fix_id {
	my $self = shift;
	my $str = shift;
	my @ids = @_;
	my $name = $self->_get_standard_name($str);
	for my $id (@ids) {
		next unless $id;
		$id =~ /([^:]+)$/;
		$id = $name . ":" . $1;
	}
	@ids;
}

1;

__END__
