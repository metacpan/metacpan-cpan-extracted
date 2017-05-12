#
# BioPerl module for Bio::Network::IO::psi25
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::Network::IO::psi25

=head1 SYNOPSIS

Do not use this module directly, use Bio::Network::IO:

  my $io = Bio::Network::IO->new(-format => 'psi25',
                                 -file   => 'data.xml');

  my $network = $io->next_network;

=head1 DESCRIPTION

PSI MI (Protein Standards Initiative Molecular Interaction) XML is a 
format to describe protein-protein interactions and interaction 
networks. This module parses version 2.5 of PSI MI.

=head2 Databases

The following databases provide their data as PSI MI XML:

=over 3

=item *

DIP L<http://dip.doe-mbi.ucla.edu/>

=item *

HPRD L<http://www.hprd.org>

=item *

IntAct L<http://www.ebi.ac.uk/intact>

=item *

MINT L<http://cbm.bio.uniroma2.it/mint/>

=back

Each of these databases will call PSI format by some different name.
for example, PSI MI from DIP comes in files with the suffix "mif"
whereas PSI MI from IntAct or MINT has the "xml" suffix.

Documentation for PSI XML can be found at L<http://www.psidev.info>.

=head2 Version

This module supports a subset of the fields described in PSI MI version 
2.5. (L<http://www.psidev.info/index.php?q=node/60>). The DATA IN THE NODE
section below describes which fields are currently parsed into 
ProteinNet networks.

=head2 Notes

See the Bio::Network::IO::psi_xml page in the Bioperl Wiki 
(L<http://bioperl.open-bio.org/wiki/Bio::Network::IO::psi_xml>)
for notes on PSI XML from various databases.

When using this parser recall that some PSI MI fields, or classes,
are populated by values taken from an ontology created for the PSI MI
format. This ontology is an OBO ontology and can be browsed at
L<http://www.ebi.ac.uk/ontology-lookup/browse.do?ontName=MI>.

=head1 METHODS

The naming system is analagous to the SeqIO system, although usually
next_network() will be called only once per file.

=head1 DATA IN THE NODE

The Node (protein or protein complex) is roughly equivalent to the PSI MI 
B<interactor> (entrySet/entry/interactorList/interactor). The following are 
subclasses of B<interactor> whose values are accessible through the Node
object.

=over 3

=item *

interactor/names/shortLabel

L<Bio::Annotation::SimpleValue|Bio::Annotation::SimpleValue>

=item *

interactor/names/fullName

L<Bio::Annotation::SimpleValue|Bio::Annotation::SimpleValue>

=item *

interactor/xref/primaryRef

L<Bio::Annotation::DBLink|Bio::Annotation::DBLink>

=item *

interactor/xref/secondaryRef

L<Bio::Annotation::DBLink|Bio::Annotation::DBLink>

L<Bio::Species|Bio::Species> object

=item *

interactor/organism/names/alias

L<Bio::Species|Bio::Species> object

=item *

interactor/organism/names/fullName

L<Bio::Species|Bio::Species> object

=item *

interactor/organism/names/shortLabel

L<Bio::Species|Bio::Species> object

=back

=head1 DATA NOT YET AVAILABLE

The following are subclasses of B<interactor> whose values are currently not
accessible through the Node object.

=over 3

=item *

interactor/names/alias

L<Bio::Annotation::SimpleValue|Bio::Annotation::SimpleValue>

=item *

interactor/sequence

=item *

interactor/interactorType/names

Controlled vocabulary maintained by PSI MI
L<http://www.ebi.ac.uk/ontology-lookup/browse.do?ontName=MI>.
Example: "protein".

L<Bio::Annotation::OntologyTerm|Bio::Annotation::OntologyTerm>

=item *

interactor/interactorType/xref

L<Bio::Annotation::DBLink|Bio::Annotation::DBLink>

=item *

interactor/organism/cellType

L<Bio::Annotation::OntologyTerm|Bio::Annotation::OntologyTerm>

=item *

interactor/organism/compartment

L<Bio::Annotation::OntologyTerm|Bio::Annotation::OntologyTerm>

=item *

interactor/organism/tissue

L<Bio::Annotation::OntologyTerm|Bio::Annotation::OntologyTerm>

=back

=head1 INTERACTION DATA

The Interaction object is roughly equivalent to the PSI MI B<interaction>
(entrySet/entry/interactionList/interaction) and B<experimentDescription>
(entrySet/entry/experimentList/experimentDescription). The following are
subclasses of B<interaction> and B<experimentDescription> whose values are 
NOT yet accessible through the Interaction object.

=over 3

=item *

interaction/xref/primaryRef

L<Bio::Annotation::DBLink|Bio::Annotation::DBLink>

=item *

interaction/xref/secondaryRef

L<Bio::Annotation::DBLink|Bio::Annotation::DBLink>

=item *

interaction/organism/names/shortLabel

L<Bio::Species|Bio::Species> object

=item *

interaction/organism/names/alias

L<Bio::Species|Bio::Species> object

=item *

interaction/organism/names/fullName

L<Bio::Species|Bio::Species> object

=item *

interaction/modelled

L<Bio::Annotation::SimpleValue|Bio::Annotation::SimpleValue>

=item *

interaction/intraMolecular

L<Bio::Annotation::SimpleValue|Bio::Annotation::SimpleValue>

=item *

interaction/negative

L<Bio::Annotation::SimpleValue|Bio::Annotation::SimpleValue>

=item *

interaction/interactionType

Controlled vocabulary maintained by PSI MI
L<http://www.ebi.ac.uk/ontology-lookup/browse.do?ontName=MI>.
Example: "phosphorylation reaction".

L<Bio::Annotation::OntologyTerm|Bio::Annotation::OntologyTerm>

=item *

interaction/confidenceList

L<Bio::Annotation::SimpleValue|Bio::Annotation::SimpleValue>

=item *

experimentDescription/confidenceList

L<Bio::Annotation::SimpleValue|Bio::Annotation::SimpleValue>

=item *

experimentDescription/interactionDetectionMethod

Controlled vocabulary maintained by PSI MI
L<http://www.ebi.ac.uk/ontology-lookup/browse.do?ontName=MI>.
Example: "two hybrid array".

L<Bio::Annotation::OntologyTerm|Bio::Annotation::OntologyTerm>

=item *

featureElementType/featureType

Controlled vocabulary maintained by PSI MI
L<http://www.ebi.ac.uk/ontology-lookup/browse.do?ontName=MI>. 
The featureType includes data on post-translational modification.
Example: "phospho-histidine".

L<Bio::Annotation::OntologyTerm|Bio::Annotation::OntologyTerm>

=back

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

=cut

package Bio::Network::IO::psi25;
use strict;
use base qw(Bio::Network::IO Bio::Root::Root);
use XML::Twig;
use Bio::Root::Root;
use Bio::Seq::SeqFactory;
use Bio::Network::ProteinNet;
use Bio::Network::Interaction;
use Bio::Network::IO;
use Bio::Network::Node;
use Bio::Species;
use Bio::Annotation::DBLink;
use Bio::Annotation::Collection;
#use Bio::Annotation::Comment;
#use Bio::Annotation::Reference;
#use Bio::Annotation::SimpleValue;
#use Bio::Network::IO::psi::intact;
#use Bio::Annotation::OntologyTerm;

use vars qw( %species $net $fac $verbose );

BEGIN {
	$fac = Bio::Seq::SeqFactory->new(-type => 'Bio::Seq::RichSeq');
}

=head2 next_network

 Name       : next_network
 Purpose    : Constructs a protein interaction graph from PSI XML data
 Usage      : my $net = $io->next_network()
 Arguments  :
 Returns    : A Bio::Network::ProteinNet object

=cut

sub next_network {
	my $self = shift;
	$net = Bio::Network::ProteinNet->new(refvertexed => 1);
	$verbose = $self->verbose;
	# the tag in the handler is an XML field, the value is
	# the function called when that field is encountered 
	my $t = XML::Twig->new(TwigHandlers => {
								  interactor 	=> \&_addInteractor,
								  interaction 	=> \&_addInteraction
														});
	$t->parsefile($self->file);
	$net;
}

=head2 _addInteractor

 Name      : _addInteractor
 Purpose   : Parses protein information into Bio::Seq::RichSeq objects
 Returns   :
 Usage     : Internally called by next_network()
 Arguments : None
 Notes     : Interactors without organism data get their Bio::Species
             fields set to -1
=cut

sub _addInteractor {
	my ($twig, $pi) = @_;

	my ($prot, $acc, $sp, $desc, $sp_obj, $taxid, $common, $full);
	my $nullVal = "-1";
	
	my $org = $pi->first_child('organism');

	eval { $taxid = $org->att('ncbiTaxId'); };
	if ($@) {
		print "No organism for interactor " . 
		  $pi->first_child('names')->first_child('fullName')->text . "\n" if $verbose;
		$common = $full = $taxid = $nullVal;
	} elsif ( !exists($species{$taxid}) ) {
		# Make new species object if doesn't already exist
		$common = $org->first_child('names')->first_child('shortLabel')->text;

		# some PSI MI files have entries with species lacking "fullName"
		eval {
			$full = $org->first_child('names')->first_child('fullName')->text;
		};
		$full = $common if $@;

		eval {
			$sp_obj = Bio::Species->new(-ncbi_taxid  => $taxid,
												 -name        => $full,
												 -common_name => $common
												); };
		$species{$taxid} = $sp_obj;
	}

	# Extract sequence identifiers
	my @ids        = $pi->first_child('xref')->children();
	my %ids        = map {$_->att('db'), $_->att('id')} @ids;
	$ids{'psixml'} = $pi->att('id');

	my $prim_id = defined ($ids{'GI'}) ?  $ids{'GI'} : '';
	# needs to be done by reference to an actual ontology:
	$acc = $ids{'RefSeq'} || 
	       $ids{'SWP'} ||               # DIP's name for Swissprot
			 $ids{'Swiss-Prot'} ||        # db name from HPRD
			 $ids{'Ref-Seq'} ||           # db name from HPRD
          $ids{'uniprotkb'} ||         # db name from MINT
			 $ids{'GI'} || 
			 $ids{'PIR'} ||
			 $ids{'intact'} ||            # db name from IntAct
			 $ids{'psi-mi'} ||            # db name from IntAct
			 $ids{'DIP'} ||               # DIP node name
          $ids{'ensembl'} ||           # db name from MINT
          $ids{'flybase'} ||           # db name from MINT
          $ids{'wormbase'} ||          # db name from MINT
          $ids{'sgd'} ||               # db name from MINT
          $ids{'ddbj/embl/genbank'} || # db name from MINT
          $ids{'mint'};                # db name from MINT

	# Get description line - certain files, like PSI XML from HPRD,
	# have "shortLabel" but no "fullName"
	eval {
		$desc = $pi->first_child('names')->first_child('fullName')->text; 
	};
	if ($@) {
		print "No fullName for interactor " .
		  $pi->first_child('names')->first_child('shortLabel')->text . "\n" if $verbose;
		$desc = $pi->first_child('names')->first_child('shortLabel')->text;
	}

	# Use ids other than accession_no or primary_id for DBLink annotations
	my $ac = Bio::Annotation::Collection->new();	
	for my $db (keys %ids) {
		next if $ids{$db} eq $acc;
		next if $ids{$db} eq $prim_id;
		my $an = Bio::Annotation::DBLink->new( -database   => $db,
															-primary_id => $ids{$db},
											);
		$ac->add_Annotation('dblink',$an);
	}

	# Make sequence object
	eval {
 	$prot = $fac->create(
						-accession_number => $acc,
						-desc             => $desc,
						-display_id       => $acc,
						-primary_id       => $prim_id,
						-species          => $species{$taxid},
						-annotation       => $ac);
	};

	# Add node to network
	my $node = Bio::Network::Node->new(-protein => [($prot)]);
	$net->add_node($node);

	# Add primary identifier and acc to internal id <-> node mapping hash
	$net->add_id_to_node($ids{'psixml'},$node);
	$net->add_id_to_node($prot->primary_id,$node);
	$net->add_id_to_node($prot->accession_number,$node);

	# Add secondary identifiers to internal id <-> node mapping hash
	$ac = $prot->annotation();
	for my $an ($ac->get_Annotations('dblink')) {
		$net->add_id_to_node($an->primary_id,$node);
	}

	$twig->purge();
}

=head2 _addInteraction

 Name     : _addInteraction
 Purpose  : Adds a new Interaction to a graph
 Usage    : Do not call, called internally by next_network()
 Returns  :
 Notes    : All interactions are made of 2 nodes - if there are more
            or less than 2 then no Interaction object is created
=cut

sub _addInteraction {
	my ($twig, $i) = @_;

	my @ints = $i->first_child('participantList')->children;
	print "Interaction " . $i->first_child('xref')->first_child('primaryRef')->att('id') .
	  " has " . scalar @ints . " interactors\n" if $verbose;

	# 2 nodes are required
	if ( scalar @ints == 2 ) {
		my @nodeids = map {$_->first_child('interactorRef')->text} @ints;
		my $interx_id = $i->first_child('xref')->first_child('primaryRef')->att('id');

		my $node1 = $net->get_nodes_by_id($nodeids[0]);
		my $node2 = $net->get_nodes_by_id($nodeids[1]);

		my $interx = Bio::Network::Interaction->new(-id => $interx_id);
		$net->add_interaction(-nodes => [($node1,$node2)],
									 -interaction => $interx );
		$net->add_id_to_interaction($interx_id,$interx);

		$twig->purge();
	}
}

1;

__END__
