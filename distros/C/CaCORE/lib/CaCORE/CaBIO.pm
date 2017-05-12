# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::SNP;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##

$VERSION = '3.2';

@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the SNP object
# returns: a SNP object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new SNP\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this SNP intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":SNP\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# DBSNPID;
	if( defined( $self->getDBSNPID ) ) {
		$tmpstr = "<DBSNPID xsi:type=\"xsd:string\">" . $self->getDBSNPID . "</DBSNPID>";
	} else {
		$tmpstr = "<DBSNPID xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# alleleA;
	if( defined( $self->getAlleleA ) ) {
		$tmpstr = "<alleleA xsi:type=\"xsd:string\">" . $self->getAlleleA . "</alleleA>";
	} else {
		$tmpstr = "<alleleA xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# alleleB;
	if( defined( $self->getAlleleB ) ) {
		$tmpstr = "<alleleB xsi:type=\"xsd:string\">" . $self->getAlleleB . "</alleleB>";
	} else {
		$tmpstr = "<alleleB xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# validationStatus;
	if( defined( $self->getValidationStatus ) ) {
		$tmpstr = "<validationStatus xsi:type=\"xsd:string\">" . $self->getValidationStatus . "</validationStatus>";
	} else {
		$tmpstr = "<validationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of SNP objects
# param: xml doc
# returns: list of SNP objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of SNP objects
# param: xml node
# returns: a list of SNP objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one SNP object
# param: xml node
# returns: one SNP object
sub fromWSXMLNode {
	my $SNPNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $DBSNPID;
		my $alleleA;
		my $alleleB;
		my $bigid;
		my $id;
		my $validationStatus;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($SNPNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "DBSNPID") {
				$DBSNPID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "alleleA") {
				$alleleA=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "alleleB") {
				$alleleB=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "validationStatus") {
				$validationStatus=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::SNP;
	## begin set attr ##
		$newobj->setDBSNPID($DBSNPID);
		$newobj->setAlleleA($alleleA);
		$newobj->setAlleleB($alleleB);
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setValidationStatus($validationStatus);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDBSNPID {
	my $self = shift;
	return $self->{DBSNPID};
}

sub setDBSNPID {
	my $self = shift;
	$self->{DBSNPID} = shift;
}

sub getAlleleA {
	my $self = shift;
	return $self->{alleleA};
}

sub setAlleleA {
	my $self = shift;
	$self->{alleleA} = shift;
}

sub getAlleleB {
	my $self = shift;
	return $self->{alleleB};
}

sub setAlleleB {
	my $self = shift;
	$self->{alleleB} = shift;
}

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getValidationStatus {
	my $self = shift;
	return $self->{validationStatus};
}

sub setValidationStatus {
	my $self = shift;
	$self->{validationStatus} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getDatabaseCrossReferenceCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::DatabaseCrossReference", $self);
	return @results;
}

sub getGeneRelativeLocationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GeneRelativeLocation", $self);
	return @results;
}

sub getLocationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Location", $self);
	return @results;
}

sub getPopulationFrequencyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::PopulationFrequency", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Taxon;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Taxon object
# returns: a Taxon object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Taxon\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Taxon intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Taxon\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# abbreviation;
	if( defined( $self->getAbbreviation ) ) {
		$tmpstr = "<abbreviation xsi:type=\"xsd:string\">" . $self->getAbbreviation . "</abbreviation>";
	} else {
		$tmpstr = "<abbreviation xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# commonName;
	if( defined( $self->getCommonName ) ) {
		$tmpstr = "<commonName xsi:type=\"xsd:string\">" . $self->getCommonName . "</commonName>";
	} else {
		$tmpstr = "<commonName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# ethnicityStrain;
	if( defined( $self->getEthnicityStrain ) ) {
		$tmpstr = "<ethnicityStrain xsi:type=\"xsd:string\">" . $self->getEthnicityStrain . "</ethnicityStrain>";
	} else {
		$tmpstr = "<ethnicityStrain xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# scientificName;
	if( defined( $self->getScientificName ) ) {
		$tmpstr = "<scientificName xsi:type=\"xsd:string\">" . $self->getScientificName . "</scientificName>";
	} else {
		$tmpstr = "<scientificName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Taxon objects
# param: xml doc
# returns: list of Taxon objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Taxon objects
# param: xml node
# returns: a list of Taxon objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Taxon object
# param: xml node
# returns: one Taxon object
sub fromWSXMLNode {
	my $TaxonNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $abbreviation;
		my $bigid;
		my $commonName;
		my $ethnicityStrain;
		my $id;
		my $scientificName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($TaxonNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "abbreviation") {
				$abbreviation=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "commonName") {
				$commonName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "ethnicityStrain") {
				$ethnicityStrain=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "scientificName") {
				$scientificName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Taxon;
	## begin set attr ##
		$newobj->setAbbreviation($abbreviation);
		$newobj->setBigid($bigid);
		$newobj->setCommonName($commonName);
		$newobj->setEthnicityStrain($ethnicityStrain);
		$newobj->setId($id);
		$newobj->setScientificName($scientificName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getAbbreviation {
	my $self = shift;
	return $self->{abbreviation};
}

sub setAbbreviation {
	my $self = shift;
	$self->{abbreviation} = shift;
}

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getCommonName {
	my $self = shift;
	return $self->{commonName};
}

sub setCommonName {
	my $self = shift;
	$self->{commonName} = shift;
}

sub getEthnicityStrain {
	my $self = shift;
	return $self->{ethnicityStrain};
}

sub setEthnicityStrain {
	my $self = shift;
	$self->{ethnicityStrain} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getScientificName {
	my $self = shift;
	return $self->{scientificName};
}

sub setScientificName {
	my $self = shift;
	$self->{scientificName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChromosomeCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Chromosome", $self);
	return @results;
}

sub getCloneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Clone", $self);
	return @results;
}

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getPathwayCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Pathway", $self);
	return @results;
}

sub getProteinCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Protein", $self);
	return @results;
}

sub getTissueCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Tissue", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Chromosome;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Chromosome object
# returns: a Chromosome object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Chromosome\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Chromosome intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Chromosome\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# number;
	if( defined( $self->getNumber ) ) {
		$tmpstr = "<number xsi:type=\"xsd:string\">" . $self->getNumber . "</number>";
	} else {
		$tmpstr = "<number xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Chromosome objects
# param: xml doc
# returns: list of Chromosome objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Chromosome objects
# param: xml node
# returns: a list of Chromosome objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Chromosome object
# param: xml node
# returns: one Chromosome object
sub fromWSXMLNode {
	my $ChromosomeNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $number;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ChromosomeNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "number") {
				$number=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Chromosome;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setNumber($number);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getNumber {
	my $self = shift;
	return $self->{number};
}

sub setNumber {
	my $self = shift;
	$self->{number} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getLocationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Location", $self);
	return @results;
}

sub getTaxon {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Taxon", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Gene;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Gene object
# returns: a Gene object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Gene\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Gene intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Gene\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# clusterId;
	if( defined( $self->getClusterId ) ) {
		$tmpstr = "<clusterId xsi:type=\"xsd:long\">" . $self->getClusterId . "</clusterId>";
	} else {
		$tmpstr = "<clusterId xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# fullName;
	if( defined( $self->getFullName ) ) {
		$tmpstr = "<fullName xsi:type=\"xsd:string\">" . $self->getFullName . "</fullName>";
	} else {
		$tmpstr = "<fullName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# symbol;
	if( defined( $self->getSymbol ) ) {
		$tmpstr = "<symbol xsi:type=\"xsd:string\">" . $self->getSymbol . "</symbol>";
	} else {
		$tmpstr = "<symbol xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Gene objects
# param: xml doc
# returns: list of Gene objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Gene objects
# param: xml node
# returns: a list of Gene objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Gene object
# param: xml node
# returns: one Gene object
sub fromWSXMLNode {
	my $GeneNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $clusterId;
		my $fullName;
		my $id;
		my $symbol;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($GeneNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "clusterId") {
				$clusterId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "fullName") {
				$fullName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "symbol") {
				$symbol=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Gene;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setClusterId($clusterId);
		$newobj->setFullName($fullName);
		$newobj->setId($id);
		$newobj->setSymbol($symbol);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getClusterId {
	my $self = shift;
	return $self->{clusterId};
}

sub setClusterId {
	my $self = shift;
	$self->{clusterId} = shift;
}

sub getFullName {
	my $self = shift;
	return $self->{fullName};
}

sub setFullName {
	my $self = shift;
	$self->{fullName} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getSymbol {
	my $self = shift;
	return $self->{symbol};
}

sub setSymbol {
	my $self = shift;
	$self->{symbol} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChromosome {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Chromosome", $self);
	return $results[0];
}

sub getDatabaseCrossReferenceCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::DatabaseCrossReference", $self);
	return @results;
}

sub getGeneAliasCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GeneAlias", $self);
	return @results;
}

sub getGeneOntologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GeneOntology", $self);
	return @results;
}

sub getGeneRelativeLocationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GeneRelativeLocation", $self);
	return @results;
}

sub getGenericReporterCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GenericReporter", $self);
	return @results;
}

sub getHistopathologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Histopathology", $self);
	return @results;
}

sub getHomologousAssociationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::HomologousAssociation", $self);
	return @results;
}

sub getLibraryCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Library", $self);
	return @results;
}

sub getLocationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Location", $self);
	return @results;
}

sub getNucleicAcidSequenceCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::NucleicAcidSequence", $self);
	return @results;
}

sub getOrganOntologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::OrganOntology", $self);
	return @results;
}

sub getPathwayCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Pathway", $self);
	return @results;
}

sub getProteinCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Protein", $self);
	return @results;
}

sub getTargetCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Target", $self);
	return @results;
}

sub getTaxon {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Taxon", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Protocol;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Protocol object
# returns: a Protocol object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Protocol\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Protocol intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Protocol\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# description;
	if( defined( $self->getDescription ) ) {
		$tmpstr = "<description xsi:type=\"xsd:string\">" . $self->getDescription . "</description>";
	} else {
		$tmpstr = "<description xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Protocol objects
# param: xml doc
# returns: list of Protocol objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Protocol objects
# param: xml node
# returns: a list of Protocol objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Protocol object
# param: xml node
# returns: one Protocol object
sub fromWSXMLNode {
	my $ProtocolNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $description;
		my $id;
		my $name;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ProtocolNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Protocol;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setName($name);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getDescription {
	my $self = shift;
	return $self->{description};
}

sub setDescription {
	my $self = shift;
	$self->{description} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getLibraryCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Library", $self);
	return @results;
}

sub getTissueCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Tissue", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Tissue;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Tissue object
# returns: a Tissue object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Tissue\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Tissue intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Tissue\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# cellLine;
	if( defined( $self->getCellLine ) ) {
		$tmpstr = "<cellLine xsi:type=\"xsd:string\">" . $self->getCellLine . "</cellLine>";
	} else {
		$tmpstr = "<cellLine xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# cellType;
	if( defined( $self->getCellType ) ) {
		$tmpstr = "<cellType xsi:type=\"xsd:string\">" . $self->getCellType . "</cellType>";
	} else {
		$tmpstr = "<cellType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# description;
	if( defined( $self->getDescription ) ) {
		$tmpstr = "<description xsi:type=\"xsd:string\">" . $self->getDescription . "</description>";
	} else {
		$tmpstr = "<description xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# developmentalStage;
	if( defined( $self->getDevelopmentalStage ) ) {
		$tmpstr = "<developmentalStage xsi:type=\"xsd:string\">" . $self->getDevelopmentalStage . "</developmentalStage>";
	} else {
		$tmpstr = "<developmentalStage xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# histology;
	if( defined( $self->getHistology ) ) {
		$tmpstr = "<histology xsi:type=\"xsd:string\">" . $self->getHistology . "</histology>";
	} else {
		$tmpstr = "<histology xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# organ;
	if( defined( $self->getOrgan ) ) {
		$tmpstr = "<organ xsi:type=\"xsd:string\">" . $self->getOrgan . "</organ>";
	} else {
		$tmpstr = "<organ xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sex;
	if( defined( $self->getSex ) ) {
		$tmpstr = "<sex xsi:type=\"xsd:string\">" . $self->getSex . "</sex>";
	} else {
		$tmpstr = "<sex xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# supplier;
	if( defined( $self->getSupplier ) ) {
		$tmpstr = "<supplier xsi:type=\"xsd:string\">" . $self->getSupplier . "</supplier>";
	} else {
		$tmpstr = "<supplier xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Tissue objects
# param: xml doc
# returns: list of Tissue objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Tissue objects
# param: xml node
# returns: a list of Tissue objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Tissue object
# param: xml node
# returns: one Tissue object
sub fromWSXMLNode {
	my $TissueNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $cellLine;
		my $cellType;
		my $description;
		my $developmentalStage;
		my $histology;
		my $id;
		my $name;
		my $organ;
		my $sex;
		my $supplier;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($TissueNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "cellLine") {
				$cellLine=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "cellType") {
				$cellType=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "developmentalStage") {
				$developmentalStage=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "histology") {
				$histology=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "organ") {
				$organ=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sex") {
				$sex=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "supplier") {
				$supplier=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Tissue;
	## begin set attr ##
		$newobj->setCellLine($cellLine);
		$newobj->setCellType($cellType);
		$newobj->setDescription($description);
		$newobj->setDevelopmentalStage($developmentalStage);
		$newobj->setHistology($histology);
		$newobj->setId($id);
		$newobj->setName($name);
		$newobj->setOrgan($organ);
		$newobj->setSex($sex);
		$newobj->setSupplier($supplier);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCellLine {
	my $self = shift;
	return $self->{cellLine};
}

sub setCellLine {
	my $self = shift;
	$self->{cellLine} = shift;
}

sub getCellType {
	my $self = shift;
	return $self->{cellType};
}

sub setCellType {
	my $self = shift;
	$self->{cellType} = shift;
}

sub getDescription {
	my $self = shift;
	return $self->{description};
}

sub setDescription {
	my $self = shift;
	$self->{description} = shift;
}

sub getDevelopmentalStage {
	my $self = shift;
	return $self->{developmentalStage};
}

sub setDevelopmentalStage {
	my $self = shift;
	$self->{developmentalStage} = shift;
}

sub getHistology {
	my $self = shift;
	return $self->{histology};
}

sub setHistology {
	my $self = shift;
	$self->{histology} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getOrgan {
	my $self = shift;
	return $self->{organ};
}

sub setOrgan {
	my $self = shift;
	$self->{organ} = shift;
}

sub getSex {
	my $self = shift;
	return $self->{sex};
}

sub setSex {
	my $self = shift;
	$self->{sex} = shift;
}

sub getSupplier {
	my $self = shift;
	return $self->{supplier};
}

sub setSupplier {
	my $self = shift;
	$self->{supplier} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getLibraryCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Library", $self);
	return @results;
}

sub getProtocol {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Protocol", $self);
	return $results[0];
}

sub getTaxon {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Taxon", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Library;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Library object
# returns: a Library object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Library\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Library intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Library\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# cloneProducer;
	if( defined( $self->getCloneProducer ) ) {
		$tmpstr = "<cloneProducer xsi:type=\"xsd:string\">" . $self->getCloneProducer . "</cloneProducer>";
	} else {
		$tmpstr = "<cloneProducer xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# cloneVector;
	if( defined( $self->getCloneVector ) ) {
		$tmpstr = "<cloneVector xsi:type=\"xsd:string\">" . $self->getCloneVector . "</cloneVector>";
	} else {
		$tmpstr = "<cloneVector xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# cloneVectorType;
	if( defined( $self->getCloneVectorType ) ) {
		$tmpstr = "<cloneVectorType xsi:type=\"xsd:string\">" . $self->getCloneVectorType . "</cloneVectorType>";
	} else {
		$tmpstr = "<cloneVectorType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# clonesToDate;
	if( defined( $self->getClonesToDate ) ) {
		$tmpstr = "<clonesToDate xsi:type=\"xsd:long\">" . $self->getClonesToDate . "</clonesToDate>";
	} else {
		$tmpstr = "<clonesToDate xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# creationDate;
	if( defined( $self->getCreationDate ) ) {
		$tmpstr = "<creationDate xsi:type=\"xsd:dateTime\">" . $self->getCreationDate . "</creationDate>";
	} else {
		$tmpstr = "<creationDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# description;
	if( defined( $self->getDescription ) ) {
		$tmpstr = "<description xsi:type=\"xsd:string\">" . $self->getDescription . "</description>";
	} else {
		$tmpstr = "<description xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# keyword;
	if( defined( $self->getKeyword ) ) {
		$tmpstr = "<keyword xsi:type=\"xsd:string\">" . $self->getKeyword . "</keyword>";
	} else {
		$tmpstr = "<keyword xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# labHost;
	if( defined( $self->getLabHost ) ) {
		$tmpstr = "<labHost xsi:type=\"xsd:string\">" . $self->getLabHost . "</labHost>";
	} else {
		$tmpstr = "<labHost xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# rsite1;
	if( defined( $self->getRsite1 ) ) {
		$tmpstr = "<rsite1 xsi:type=\"xsd:string\">" . $self->getRsite1 . "</rsite1>";
	} else {
		$tmpstr = "<rsite1 xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# rsite2;
	if( defined( $self->getRsite2 ) ) {
		$tmpstr = "<rsite2 xsi:type=\"xsd:string\">" . $self->getRsite2 . "</rsite2>";
	} else {
		$tmpstr = "<rsite2 xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sequencesToDate;
	if( defined( $self->getSequencesToDate ) ) {
		$tmpstr = "<sequencesToDate xsi:type=\"xsd:long\">" . $self->getSequencesToDate . "</sequencesToDate>";
	} else {
		$tmpstr = "<sequencesToDate xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# uniGeneId;
	if( defined( $self->getUniGeneId ) ) {
		$tmpstr = "<uniGeneId xsi:type=\"xsd:long\">" . $self->getUniGeneId . "</uniGeneId>";
	} else {
		$tmpstr = "<uniGeneId xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Library objects
# param: xml doc
# returns: list of Library objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Library objects
# param: xml node
# returns: a list of Library objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Library object
# param: xml node
# returns: one Library object
sub fromWSXMLNode {
	my $LibraryNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $cloneProducer;
		my $cloneVector;
		my $cloneVectorType;
		my $clonesToDate;
		my $creationDate;
		my $description;
		my $id;
		my $keyword;
		my $labHost;
		my $name;
		my $rsite1;
		my $rsite2;
		my $sequencesToDate;
		my $type;
		my $uniGeneId;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($LibraryNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "cloneProducer") {
				$cloneProducer=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "cloneVector") {
				$cloneVector=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "cloneVectorType") {
				$cloneVectorType=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "clonesToDate") {
				$clonesToDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "creationDate") {
				$creationDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "keyword") {
				$keyword=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "labHost") {
				$labHost=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "rsite1") {
				$rsite1=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "rsite2") {
				$rsite2=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sequencesToDate") {
				$sequencesToDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "uniGeneId") {
				$uniGeneId=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Library;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setCloneProducer($cloneProducer);
		$newobj->setCloneVector($cloneVector);
		$newobj->setCloneVectorType($cloneVectorType);
		$newobj->setClonesToDate($clonesToDate);
		$newobj->setCreationDate($creationDate);
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setKeyword($keyword);
		$newobj->setLabHost($labHost);
		$newobj->setName($name);
		$newobj->setRsite1($rsite1);
		$newobj->setRsite2($rsite2);
		$newobj->setSequencesToDate($sequencesToDate);
		$newobj->setType($type);
		$newobj->setUniGeneId($uniGeneId);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getCloneProducer {
	my $self = shift;
	return $self->{cloneProducer};
}

sub setCloneProducer {
	my $self = shift;
	$self->{cloneProducer} = shift;
}

sub getCloneVector {
	my $self = shift;
	return $self->{cloneVector};
}

sub setCloneVector {
	my $self = shift;
	$self->{cloneVector} = shift;
}

sub getCloneVectorType {
	my $self = shift;
	return $self->{cloneVectorType};
}

sub setCloneVectorType {
	my $self = shift;
	$self->{cloneVectorType} = shift;
}

sub getClonesToDate {
	my $self = shift;
	return $self->{clonesToDate};
}

sub setClonesToDate {
	my $self = shift;
	$self->{clonesToDate} = shift;
}

sub getCreationDate {
	my $self = shift;
	return $self->{creationDate};
}

sub setCreationDate {
	my $self = shift;
	$self->{creationDate} = shift;
}

sub getDescription {
	my $self = shift;
	return $self->{description};
}

sub setDescription {
	my $self = shift;
	$self->{description} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getKeyword {
	my $self = shift;
	return $self->{keyword};
}

sub setKeyword {
	my $self = shift;
	$self->{keyword} = shift;
}

sub getLabHost {
	my $self = shift;
	return $self->{labHost};
}

sub setLabHost {
	my $self = shift;
	$self->{labHost} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getRsite1 {
	my $self = shift;
	return $self->{rsite1};
}

sub setRsite1 {
	my $self = shift;
	$self->{rsite1} = shift;
}

sub getRsite2 {
	my $self = shift;
	return $self->{rsite2};
}

sub setRsite2 {
	my $self = shift;
	$self->{rsite2} = shift;
}

sub getSequencesToDate {
	my $self = shift;
	return $self->{sequencesToDate};
}

sub setSequencesToDate {
	my $self = shift;
	$self->{sequencesToDate} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

sub getUniGeneId {
	my $self = shift;
	return $self->{uniGeneId};
}

sub setUniGeneId {
	my $self = shift;
	$self->{uniGeneId} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getCloneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Clone", $self);
	return @results;
}

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getHistopathologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Histopathology", $self);
	return @results;
}

sub getProtocol {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Protocol", $self);
	return $results[0];
}

sub getTissue {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Tissue", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Clone;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Clone object
# returns: a Clone object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Clone\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Clone intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Clone\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# insertSize;
	if( defined( $self->getInsertSize ) ) {
		$tmpstr = "<insertSize xsi:type=\"xsd:long\">" . $self->getInsertSize . "</insertSize>";
	} else {
		$tmpstr = "<insertSize xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Clone objects
# param: xml doc
# returns: list of Clone objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Clone objects
# param: xml node
# returns: a list of Clone objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Clone object
# param: xml node
# returns: one Clone object
sub fromWSXMLNode {
	my $CloneNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $insertSize;
		my $name;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($CloneNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "insertSize") {
				$insertSize=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Clone;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setInsertSize($insertSize);
		$newobj->setName($name);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getInsertSize {
	my $self = shift;
	return $self->{insertSize};
}

sub setInsertSize {
	my $self = shift;
	$self->{insertSize} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getCloneRelativeLocationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::CloneRelativeLocation", $self);
	return @results;
}

sub getLibrary {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Library", $self);
	return $results[0];
}

sub getNucleicAcidSequenceCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::NucleicAcidSequence", $self);
	return @results;
}

sub getTaxonCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Taxon", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::CloneRelativeLocation;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the CloneRelativeLocation object
# returns: a CloneRelativeLocation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new CloneRelativeLocation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this CloneRelativeLocation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":CloneRelativeLocation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of CloneRelativeLocation objects
# param: xml doc
# returns: list of CloneRelativeLocation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of CloneRelativeLocation objects
# param: xml node
# returns: a list of CloneRelativeLocation objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one CloneRelativeLocation object
# param: xml node
# returns: one CloneRelativeLocation object
sub fromWSXMLNode {
	my $CloneRelativeLocationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($CloneRelativeLocationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::CloneRelativeLocation;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getClone {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Clone", $self);
	return $results[0];
}

sub getNucleicAcidSequence {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::NucleicAcidSequence", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::NucleicAcidSequence;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the NucleicAcidSequence object
# returns: a NucleicAcidSequence object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new NucleicAcidSequence\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this NucleicAcidSequence intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":NucleicAcidSequence\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# accessionNumber;
	if( defined( $self->getAccessionNumber ) ) {
		$tmpstr = "<accessionNumber xsi:type=\"xsd:string\">" . $self->getAccessionNumber . "</accessionNumber>";
	} else {
		$tmpstr = "<accessionNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# accessionNumberVersion;
	if( defined( $self->getAccessionNumberVersion ) ) {
		$tmpstr = "<accessionNumberVersion xsi:type=\"xsd:string\">" . $self->getAccessionNumberVersion . "</accessionNumberVersion>";
	} else {
		$tmpstr = "<accessionNumberVersion xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# length;
	if( defined( $self->getLength ) ) {
		$tmpstr = "<length xsi:type=\"xsd:long\">" . $self->getLength . "</length>";
	} else {
		$tmpstr = "<length xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# value;
	if( defined( $self->getValue ) ) {
		$tmpstr = "<value xsi:type=\"xsd:string\">" . $self->getValue . "</value>";
	} else {
		$tmpstr = "<value xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of NucleicAcidSequence objects
# param: xml doc
# returns: list of NucleicAcidSequence objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of NucleicAcidSequence objects
# param: xml node
# returns: a list of NucleicAcidSequence objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one NucleicAcidSequence object
# param: xml node
# returns: one NucleicAcidSequence object
sub fromWSXMLNode {
	my $NucleicAcidSequenceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $accessionNumber;
		my $accessionNumberVersion;
		my $bigid;
		my $id;
		my $length;
		my $type;
		my $value;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($NucleicAcidSequenceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "accessionNumber") {
				$accessionNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "accessionNumberVersion") {
				$accessionNumberVersion=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "length") {
				$length=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "value") {
				$value=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::NucleicAcidSequence;
	## begin set attr ##
		$newobj->setAccessionNumber($accessionNumber);
		$newobj->setAccessionNumberVersion($accessionNumberVersion);
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setLength($length);
		$newobj->setType($type);
		$newobj->setValue($value);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getAccessionNumber {
	my $self = shift;
	return $self->{accessionNumber};
}

sub setAccessionNumber {
	my $self = shift;
	$self->{accessionNumber} = shift;
}

sub getAccessionNumberVersion {
	my $self = shift;
	return $self->{accessionNumberVersion};
}

sub setAccessionNumberVersion {
	my $self = shift;
	$self->{accessionNumberVersion} = shift;
}

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLength {
	my $self = shift;
	return $self->{length};
}

sub setLength {
	my $self = shift;
	$self->{length} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

sub getValue {
	my $self = shift;
	return $self->{value};
}

sub setValue {
	my $self = shift;
	$self->{value} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getCloneRelativeLocation {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::CloneRelativeLocation", $self);
	return $results[0];
}

sub getDatabaseCrossReferenceCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::DatabaseCrossReference", $self);
	return @results;
}

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getLocationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Location", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Location;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Location object
# returns: a Location object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Location\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Location intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Location\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Location objects
# param: xml doc
# returns: list of Location objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Location objects
# param: xml node
# returns: a list of Location objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Location object
# param: xml node
# returns: one Location object
sub fromWSXMLNode {
	my $LocationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($LocationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Location;
	## begin set attr ##
		$newobj->setId($id);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getSNP {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::SNP", $self);
	return $results[0];
}

sub getChromosome {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Chromosome", $self);
	return $results[0];
}

sub getGene {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return $results[0];
}

sub getNucleicAcidSequence {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::NucleicAcidSequence", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::PhysicalLocation;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaBIO::Location);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the PhysicalLocation object
# returns: a PhysicalLocation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new PhysicalLocation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this PhysicalLocation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":PhysicalLocation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# chromosomalEndPosition;
	if( defined( $self->getChromosomalEndPosition ) ) {
		$tmpstr = "<chromosomalEndPosition xsi:type=\"xsd:long\">" . $self->getChromosomalEndPosition . "</chromosomalEndPosition>";
	} else {
		$tmpstr = "<chromosomalEndPosition xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# chromosomalStartPosition;
	if( defined( $self->getChromosomalStartPosition ) ) {
		$tmpstr = "<chromosomalStartPosition xsi:type=\"xsd:long\">" . $self->getChromosomalStartPosition . "</chromosomalStartPosition>";
	} else {
		$tmpstr = "<chromosomalStartPosition xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of PhysicalLocation objects
# param: xml doc
# returns: list of PhysicalLocation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of PhysicalLocation objects
# param: xml node
# returns: a list of PhysicalLocation objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one PhysicalLocation object
# param: xml node
# returns: one PhysicalLocation object
sub fromWSXMLNode {
	my $PhysicalLocationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $chromosomalEndPosition;
		my $chromosomalStartPosition;
		my $id;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($PhysicalLocationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "chromosomalEndPosition") {
				$chromosomalEndPosition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "chromosomalStartPosition") {
				$chromosomalStartPosition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::PhysicalLocation;
	## begin set attr ##
		$newobj->setChromosomalEndPosition($chromosomalEndPosition);
		$newobj->setChromosomalStartPosition($chromosomalStartPosition);
		$newobj->setId($id);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getChromosomalEndPosition {
	my $self = shift;
	return $self->{chromosomalEndPosition};
}

sub setChromosomalEndPosition {
	my $self = shift;
	$self->{chromosomalEndPosition} = shift;
}

sub getChromosomalStartPosition {
	my $self = shift;
	return $self->{chromosomalStartPosition};
}

sub setChromosomalStartPosition {
	my $self = shift;
	$self->{chromosomalStartPosition} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getCytobandCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Cytoband", $self);
	return @results;
}

sub getSNP {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::SNP", $self);
	return $results[0];
}

sub getChromosome {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Chromosome", $self);
	return $results[0];
}

sub getGene {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return $results[0];
}

sub getNucleicAcidSequence {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::NucleicAcidSequence", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::DiseaseOntology;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the DiseaseOntology object
# returns: a DiseaseOntology object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DiseaseOntology\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DiseaseOntology intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DiseaseOntology\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DiseaseOntology objects
# param: xml doc
# returns: list of DiseaseOntology objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DiseaseOntology objects
# param: xml node
# returns: a list of DiseaseOntology objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one DiseaseOntology object
# param: xml node
# returns: one DiseaseOntology object
sub fromWSXMLNode {
	my $DiseaseOntologyNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DiseaseOntologyNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::DiseaseOntology;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildDiseaseOntologyRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::DiseaseOntologyRelationship", $self);
	return @results;
}

sub getClinicalTrialProtocolCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::ClinicalTrialProtocol", $self);
	return @results;
}

sub getHistopathologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Histopathology", $self);
	return @results;
}

sub getParentDiseaseOntologyRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::DiseaseOntologyRelationship", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::GeneRelativeLocation;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the GeneRelativeLocation object
# returns: a GeneRelativeLocation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new GeneRelativeLocation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this GeneRelativeLocation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":GeneRelativeLocation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of GeneRelativeLocation objects
# param: xml doc
# returns: list of GeneRelativeLocation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of GeneRelativeLocation objects
# param: xml node
# returns: a list of GeneRelativeLocation objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one GeneRelativeLocation object
# param: xml node
# returns: one GeneRelativeLocation object
sub fromWSXMLNode {
	my $GeneRelativeLocationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($GeneRelativeLocationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::GeneRelativeLocation;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::PopulationFrequency;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the PopulationFrequency object
# returns: a PopulationFrequency object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new PopulationFrequency\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this PopulationFrequency intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":PopulationFrequency\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# ethnicity;
	if( defined( $self->getEthnicity ) ) {
		$tmpstr = "<ethnicity xsi:type=\"xsd:string\">" . $self->getEthnicity . "</ethnicity>";
	} else {
		$tmpstr = "<ethnicity xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# majorAllele;
	if( defined( $self->getMajorAllele ) ) {
		$tmpstr = "<majorAllele xsi:type=\"xsd:string\">" . $self->getMajorAllele . "</majorAllele>";
	} else {
		$tmpstr = "<majorAllele xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# majorFrequency;
	if( defined( $self->getMajorFrequency ) ) {
		$tmpstr = "<majorFrequency xsi:type=\"xsd:double\">" . $self->getMajorFrequency . "</majorFrequency>";
	} else {
		$tmpstr = "<majorFrequency xsi:type=\"xsd:double\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# minorAllele;
	if( defined( $self->getMinorAllele ) ) {
		$tmpstr = "<minorAllele xsi:type=\"xsd:string\">" . $self->getMinorAllele . "</minorAllele>";
	} else {
		$tmpstr = "<minorAllele xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# minorFrequency;
	if( defined( $self->getMinorFrequency ) ) {
		$tmpstr = "<minorFrequency xsi:type=\"xsd:double\">" . $self->getMinorFrequency . "</minorFrequency>";
	} else {
		$tmpstr = "<minorFrequency xsi:type=\"xsd:double\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of PopulationFrequency objects
# param: xml doc
# returns: list of PopulationFrequency objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of PopulationFrequency objects
# param: xml node
# returns: a list of PopulationFrequency objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one PopulationFrequency object
# param: xml node
# returns: one PopulationFrequency object
sub fromWSXMLNode {
	my $PopulationFrequencyNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $ethnicity;
		my $id;
		my $majorAllele;
		my $majorFrequency;
		my $minorAllele;
		my $minorFrequency;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($PopulationFrequencyNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "ethnicity") {
				$ethnicity=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "majorAllele") {
				$majorAllele=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "majorFrequency") {
				$majorFrequency=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "minorAllele") {
				$minorAllele=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "minorFrequency") {
				$minorFrequency=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::PopulationFrequency;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setEthnicity($ethnicity);
		$newobj->setId($id);
		$newobj->setMajorAllele($majorAllele);
		$newobj->setMajorFrequency($majorFrequency);
		$newobj->setMinorAllele($minorAllele);
		$newobj->setMinorFrequency($minorFrequency);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getEthnicity {
	my $self = shift;
	return $self->{ethnicity};
}

sub setEthnicity {
	my $self = shift;
	$self->{ethnicity} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getMajorAllele {
	my $self = shift;
	return $self->{majorAllele};
}

sub setMajorAllele {
	my $self = shift;
	$self->{majorAllele} = shift;
}

sub getMajorFrequency {
	my $self = shift;
	return $self->{majorFrequency};
}

sub setMajorFrequency {
	my $self = shift;
	$self->{majorFrequency} = shift;
}

sub getMinorAllele {
	my $self = shift;
	return $self->{minorAllele};
}

sub setMinorAllele {
	my $self = shift;
	$self->{minorAllele} = shift;
}

sub getMinorFrequency {
	my $self = shift;
	return $self->{minorFrequency};
}

sub setMinorFrequency {
	my $self = shift;
	$self->{minorFrequency} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getSNP {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::SNP", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::HomologousAssociation;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the HomologousAssociation object
# returns: a HomologousAssociation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new HomologousAssociation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this HomologousAssociation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":HomologousAssociation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# homologousId;
	if( defined( $self->getHomologousId ) ) {
		$tmpstr = "<homologousId xsi:type=\"xsd:long\">" . $self->getHomologousId . "</homologousId>";
	} else {
		$tmpstr = "<homologousId xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# similarityPercentage;
	if( defined( $self->getSimilarityPercentage ) ) {
		$tmpstr = "<similarityPercentage xsi:type=\"xsd:float\">" . $self->getSimilarityPercentage . "</similarityPercentage>";
	} else {
		$tmpstr = "<similarityPercentage xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of HomologousAssociation objects
# param: xml doc
# returns: list of HomologousAssociation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of HomologousAssociation objects
# param: xml node
# returns: a list of HomologousAssociation objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one HomologousAssociation object
# param: xml node
# returns: one HomologousAssociation object
sub fromWSXMLNode {
	my $HomologousAssociationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $homologousId;
		my $id;
		my $similarityPercentage;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($HomologousAssociationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "homologousId") {
				$homologousId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "similarityPercentage") {
				$similarityPercentage=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::HomologousAssociation;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setHomologousId($homologousId);
		$newobj->setId($id);
		$newobj->setSimilarityPercentage($similarityPercentage);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getHomologousId {
	my $self = shift;
	return $self->{homologousId};
}

sub setHomologousId {
	my $self = shift;
	$self->{homologousId} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getSimilarityPercentage {
	my $self = shift;
	return $self->{similarityPercentage};
}

sub setSimilarityPercentage {
	my $self = shift;
	$self->{similarityPercentage} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getHomologousGene {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Cytoband;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Cytoband object
# returns: a Cytoband object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Cytoband\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Cytoband intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Cytoband\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Cytoband objects
# param: xml doc
# returns: list of Cytoband objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Cytoband objects
# param: xml node
# returns: a list of Cytoband objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Cytoband object
# param: xml node
# returns: one Cytoband object
sub fromWSXMLNode {
	my $CytobandNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($CytobandNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Cytoband;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getPhysicalLocation {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::PhysicalLocation", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::GeneOntology;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the GeneOntology object
# returns: a GeneOntology object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new GeneOntology\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this GeneOntology intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":GeneOntology\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of GeneOntology objects
# param: xml doc
# returns: list of GeneOntology objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of GeneOntology objects
# param: xml node
# returns: a list of GeneOntology objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one GeneOntology object
# param: xml node
# returns: one GeneOntology object
sub fromWSXMLNode {
	my $GeneOntologyNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($GeneOntologyNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::GeneOntology;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildGeneOntologyRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GeneOntologyRelationship", $self);
	return @results;
}

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getParentGeneOntologyRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GeneOntologyRelationship", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::OrganOntology;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the OrganOntology object
# returns: a OrganOntology object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new OrganOntology\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this OrganOntology intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":OrganOntology\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of OrganOntology objects
# param: xml doc
# returns: list of OrganOntology objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of OrganOntology objects
# param: xml node
# returns: a list of OrganOntology objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one OrganOntology object
# param: xml node
# returns: one OrganOntology object
sub fromWSXMLNode {
	my $OrganOntologyNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($OrganOntologyNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::OrganOntology;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAnomalyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Anomaly", $self);
	return @results;
}

sub getChildOrganOntologyRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::OrganOntologyRelationship", $self);
	return @results;
}

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getHistopathologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Histopathology", $self);
	return @results;
}

sub getParentOrganOntologyRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::OrganOntologyRelationship", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Histopathology;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Histopathology object
# returns: a Histopathology object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Histopathology\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Histopathology intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Histopathology\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# ageOfOnset;
	if( defined( $self->getAgeOfOnset ) ) {
		$tmpstr = "<ageOfOnset xsi:type=\"xsd:string\">" . $self->getAgeOfOnset . "</ageOfOnset>";
	} else {
		$tmpstr = "<ageOfOnset xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# comments;
	if( defined( $self->getComments ) ) {
		$tmpstr = "<comments xsi:type=\"xsd:string\">" . $self->getComments . "</comments>";
	} else {
		$tmpstr = "<comments xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# grossDescription;
	if( defined( $self->getGrossDescription ) ) {
		$tmpstr = "<grossDescription xsi:type=\"xsd:string\">" . $self->getGrossDescription . "</grossDescription>";
	} else {
		$tmpstr = "<grossDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# microscopicDescription;
	if( defined( $self->getMicroscopicDescription ) ) {
		$tmpstr = "<microscopicDescription xsi:type=\"xsd:string\">" . $self->getMicroscopicDescription . "</microscopicDescription>";
	} else {
		$tmpstr = "<microscopicDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# relationalOperation;
	if( defined( $self->getRelationalOperation ) ) {
		$tmpstr = "<relationalOperation xsi:type=\"xsd:string\">" . $self->getRelationalOperation . "</relationalOperation>";
	} else {
		$tmpstr = "<relationalOperation xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# survivalInfo;
	if( defined( $self->getSurvivalInfo ) ) {
		$tmpstr = "<survivalInfo xsi:type=\"xsd:string\">" . $self->getSurvivalInfo . "</survivalInfo>";
	} else {
		$tmpstr = "<survivalInfo xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# tumorIncidenceRate;
	if( defined( $self->getTumorIncidenceRate ) ) {
		$tmpstr = "<tumorIncidenceRate xsi:type=\"xsd:float\">" . $self->getTumorIncidenceRate . "</tumorIncidenceRate>";
	} else {
		$tmpstr = "<tumorIncidenceRate xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# MetastasisCollection;
	if( defined( $self->getMetastasisCollection ) ) {
		my @assoclist = $self->getMetastasisCollection;
		if( $#assoclist >= 0 ) {
			$result .= "<metastasisCollection>";
			foreach my $node ($self->getMetastasisCollection) {
				$result .= "<metastasisCollection xsi:type=\"xsd:string\"> . $node . </metastasisCollection>";
			}
			$result .= "</metastasisCollection>";
		}
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Histopathology objects
# param: xml doc
# returns: list of Histopathology objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Histopathology objects
# param: xml node
# returns: a list of Histopathology objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Histopathology object
# param: xml node
# returns: one Histopathology object
sub fromWSXMLNode {
	my $HistopathologyNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $ageOfOnset;
		my $comments;
		my $grossDescription;
		my $id;
		my $microscopicDescription;
		my $relationalOperation;
		my $survivalInfo;
		my $tumorIncidenceRate;
		my @metastasis = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($HistopathologyNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "ageOfOnset") {
				$ageOfOnset=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "comments") {
				$comments=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "grossDescription") {
				$grossDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "microscopicDescription") {
				$microscopicDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "relationalOperation") {
				$relationalOperation=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "survivalInfo") {
				$survivalInfo=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "tumorIncidenceRate") {
				$tumorIncidenceRate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "metastasisCollection") {
				for my $node ($childrenNode->getChildNodes) {
					if( $node->getNodeName eq "empty" ){ next; };
					if( ! defined($node->getFirstChild) ){ next; };
					my $txnode = $node->getFirstChild;
					push @metastasis, $txnode->getNodeValue;
				}
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Histopathology;
	## begin set attr ##
		$newobj->setAgeOfOnset($ageOfOnset);
		$newobj->setComments($comments);
		$newobj->setGrossDescription($grossDescription);
		$newobj->setId($id);
		$newobj->setMicroscopicDescription($microscopicDescription);
		$newobj->setRelationalOperation($relationalOperation);
		$newobj->setSurvivalInfo($survivalInfo);
		$newobj->setTumorIncidenceRate($tumorIncidenceRate);
		$newobj->setMetastasisCollection(@metastasis);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getAgeOfOnset {
	my $self = shift;
	return $self->{ageOfOnset};
}

sub setAgeOfOnset {
	my $self = shift;
	$self->{ageOfOnset} = shift;
}

sub getComments {
	my $self = shift;
	return $self->{comments};
}

sub setComments {
	my $self = shift;
	$self->{comments} = shift;
}

sub getGrossDescription {
	my $self = shift;
	return $self->{grossDescription};
}

sub setGrossDescription {
	my $self = shift;
	$self->{grossDescription} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getMicroscopicDescription {
	my $self = shift;
	return $self->{microscopicDescription};
}

sub setMicroscopicDescription {
	my $self = shift;
	$self->{microscopicDescription} = shift;
}

sub getRelationalOperation {
	my $self = shift;
	return $self->{relationalOperation};
}

sub setRelationalOperation {
	my $self = shift;
	$self->{relationalOperation} = shift;
}

sub getSurvivalInfo {
	my $self = shift;
	return $self->{survivalInfo};
}

sub setSurvivalInfo {
	my $self = shift;
	$self->{survivalInfo} = shift;
}

sub getTumorIncidenceRate {
	my $self = shift;
	return $self->{tumorIncidenceRate};
}

sub setTumorIncidenceRate {
	my $self = shift;
	$self->{tumorIncidenceRate} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAnomalyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Anomaly", $self);
	return @results;
}

sub getClinicalTrialProtocolCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::ClinicalTrialProtocol", $self);
	return @results;
}

sub getDiseaseOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::DiseaseOntology", $self);
	return $results[0];
}

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getLibraryCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Library", $self);
	return @results;
}

sub getMetastasisCollection {
	my $self = shift;
	if( defined($self->{metastasis}) ) {
		return @{$self->{metastasis}};
	} else {
		return ();
	}
}

sub setMetastasisCollection {
	my ($self, @set) = @_;
	push @{$self->{metastasis}}, @set;
}

sub getOrganOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::OrganOntology", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::ProteinSequence;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ProteinSequence object
# returns: a ProteinSequence object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ProteinSequence\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ProteinSequence intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ProteinSequence\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# checkSum;
	if( defined( $self->getCheckSum ) ) {
		$tmpstr = "<checkSum xsi:type=\"xsd:string\">" . $self->getCheckSum . "</checkSum>";
	} else {
		$tmpstr = "<checkSum xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# length;
	if( defined( $self->getLength ) ) {
		$tmpstr = "<length xsi:type=\"xsd:long\">" . $self->getLength . "</length>";
	} else {
		$tmpstr = "<length xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# molecularWeightInDaltons;
	if( defined( $self->getMolecularWeightInDaltons ) ) {
		$tmpstr = "<molecularWeightInDaltons xsi:type=\"xsd:double\">" . $self->getMolecularWeightInDaltons . "</molecularWeightInDaltons>";
	} else {
		$tmpstr = "<molecularWeightInDaltons xsi:type=\"xsd:double\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# value;
	if( defined( $self->getValue ) ) {
		$tmpstr = "<value xsi:type=\"xsd:string\">" . $self->getValue . "</value>";
	} else {
		$tmpstr = "<value xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ProteinSequence objects
# param: xml doc
# returns: list of ProteinSequence objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ProteinSequence objects
# param: xml node
# returns: a list of ProteinSequence objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one ProteinSequence object
# param: xml node
# returns: one ProteinSequence object
sub fromWSXMLNode {
	my $ProteinSequenceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $checkSum;
		my $id;
		my $length;
		my $molecularWeightInDaltons;
		my $value;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ProteinSequenceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "checkSum") {
				$checkSum=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "length") {
				$length=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "molecularWeightInDaltons") {
				$molecularWeightInDaltons=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "value") {
				$value=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::ProteinSequence;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setCheckSum($checkSum);
		$newobj->setId($id);
		$newobj->setLength($length);
		$newobj->setMolecularWeightInDaltons($molecularWeightInDaltons);
		$newobj->setValue($value);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getCheckSum {
	my $self = shift;
	return $self->{checkSum};
}

sub setCheckSum {
	my $self = shift;
	$self->{checkSum} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLength {
	my $self = shift;
	return $self->{length};
}

sub setLength {
	my $self = shift;
	$self->{length} = shift;
}

sub getMolecularWeightInDaltons {
	my $self = shift;
	return $self->{molecularWeightInDaltons};
}

sub setMolecularWeightInDaltons {
	my $self = shift;
	$self->{molecularWeightInDaltons} = shift;
}

sub getValue {
	my $self = shift;
	return $self->{value};
}

sub setValue {
	my $self = shift;
	$self->{value} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getProtein {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Protein", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Protein;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Protein object
# returns: a Protein object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Protein\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Protein intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Protein\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# copyrightStatement;
	if( defined( $self->getCopyrightStatement ) ) {
		$tmpstr = "<copyrightStatement xsi:type=\"xsd:string\">" . $self->getCopyrightStatement . "</copyrightStatement>";
	} else {
		$tmpstr = "<copyrightStatement xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# primaryAccession;
	if( defined( $self->getPrimaryAccession ) ) {
		$tmpstr = "<primaryAccession xsi:type=\"xsd:string\">" . $self->getPrimaryAccession . "</primaryAccession>";
	} else {
		$tmpstr = "<primaryAccession xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# uniProtCode;
	if( defined( $self->getUniProtCode ) ) {
		$tmpstr = "<uniProtCode xsi:type=\"xsd:string\">" . $self->getUniProtCode . "</uniProtCode>";
	} else {
		$tmpstr = "<uniProtCode xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# KeywordsCollection;
	if( defined( $self->getKeywordsCollection ) ) {
		my @assoclist = $self->getKeywordsCollection;
		if( $#assoclist >= 0 ) {
			$result .= "<keywordsCollection>";
			foreach my $node ($self->getKeywordsCollection) {
				$result .= "<keywordsCollection xsi:type=\"xsd:string\"> . $node . </keywordsCollection>";
			}
			$result .= "</keywordsCollection>";
		}
	}
	# SecondaryAccessionCollection;
	if( defined( $self->getSecondaryAccessionCollection ) ) {
		my @assoclist = $self->getSecondaryAccessionCollection;
		if( $#assoclist >= 0 ) {
			$result .= "<secondaryAccessionCollection>";
			foreach my $node ($self->getSecondaryAccessionCollection) {
				$result .= "<secondaryAccessionCollection xsi:type=\"xsd:string\"> . $node . </secondaryAccessionCollection>";
			}
			$result .= "</secondaryAccessionCollection>";
		}
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Protein objects
# param: xml doc
# returns: list of Protein objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Protein objects
# param: xml node
# returns: a list of Protein objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Protein object
# param: xml node
# returns: one Protein object
sub fromWSXMLNode {
	my $ProteinNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $copyrightStatement;
		my $id;
		my $name;
		my $primaryAccession;
		my $uniProtCode;
		my @keywords = ();
		my @secondaryAccession = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ProteinNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "copyrightStatement") {
				$copyrightStatement=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "primaryAccession") {
				$primaryAccession=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "uniProtCode") {
				$uniProtCode=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "keywords") {
				for my $node ($childrenNode->getChildNodes) {
					if( $node->getNodeName eq "empty" ){ next; };
					if( ! defined($node->getFirstChild) ){ next; };
					my $txnode = $node->getFirstChild;
					push @keywords, $txnode->getNodeValue;
				}
			}
			elsif ($childrenNode->getNodeName eq "secondaryAccession") {
				for my $node ($childrenNode->getChildNodes) {
					if( $node->getNodeName eq "empty" ){ next; };
					if( ! defined($node->getFirstChild) ){ next; };
					my $txnode = $node->getFirstChild;
					push @secondaryAccession, $txnode->getNodeValue;
				}
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Protein;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setCopyrightStatement($copyrightStatement);
		$newobj->setId($id);
		$newobj->setName($name);
		$newobj->setPrimaryAccession($primaryAccession);
		$newobj->setUniProtCode($uniProtCode);
		$newobj->setKeywordsCollection(@keywords);
		$newobj->setSecondaryAccessionCollection(@secondaryAccession);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getCopyrightStatement {
	my $self = shift;
	return $self->{copyrightStatement};
}

sub setCopyrightStatement {
	my $self = shift;
	$self->{copyrightStatement} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getPrimaryAccession {
	my $self = shift;
	return $self->{primaryAccession};
}

sub setPrimaryAccession {
	my $self = shift;
	$self->{primaryAccession} = shift;
}

sub getUniProtCode {
	my $self = shift;
	return $self->{uniProtCode};
}

sub setUniProtCode {
	my $self = shift;
	$self->{uniProtCode} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getKeywordsCollection {
	my $self = shift;
	if( defined($self->{keywords}) ) {
		return @{$self->{keywords}};
	} else {
		return ();
	}
}

sub setKeywordsCollection {
	my ($self, @set) = @_;
	push @{$self->{keywords}}, @set;
}

sub getProteinAliasCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::ProteinAlias", $self);
	return @results;
}

sub getProteinSequence {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::ProteinSequence", $self);
	return $results[0];
}

sub getSecondaryAccessionCollection {
	my $self = shift;
	if( defined($self->{secondaryAccession}) ) {
		return @{$self->{secondaryAccession}};
	} else {
		return ();
	}
}

sub setSecondaryAccessionCollection {
	my ($self, @set) = @_;
	push @{$self->{secondaryAccession}}, @set;
}

sub getTaxonCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Taxon", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::ProteinAlias;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ProteinAlias object
# returns: a ProteinAlias object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ProteinAlias\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ProteinAlias intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ProteinAlias\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ProteinAlias objects
# param: xml doc
# returns: list of ProteinAlias objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ProteinAlias objects
# param: xml node
# returns: a list of ProteinAlias objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one ProteinAlias object
# param: xml node
# returns: one ProteinAlias object
sub fromWSXMLNode {
	my $ProteinAliasNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ProteinAliasNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::ProteinAlias;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getProteinCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Protein", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Target;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Target object
# returns: a Target object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Target\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Target intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Target\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Target objects
# param: xml doc
# returns: list of Target objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Target objects
# param: xml node
# returns: a list of Target objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Target object
# param: xml node
# returns: one Target object
sub fromWSXMLNode {
	my $TargetNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $name;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($TargetNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Target;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setName($name);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAgentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Agent", $self);
	return @results;
}

sub getAnomalyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Anomaly", $self);
	return @results;
}

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::GeneAlias;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the GeneAlias object
# returns: a GeneAlias object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new GeneAlias\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this GeneAlias intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":GeneAlias\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of GeneAlias objects
# param: xml doc
# returns: list of GeneAlias objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of GeneAlias objects
# param: xml node
# returns: a list of GeneAlias objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one GeneAlias object
# param: xml node
# returns: one GeneAlias object
sub fromWSXMLNode {
	my $GeneAliasNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $name;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($GeneAliasNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::GeneAlias;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setName($name);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::GenericArray;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the GenericArray object
# returns: a GenericArray object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new GenericArray\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this GenericArray intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":GenericArray\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# arrayName;
	if( defined( $self->getArrayName ) ) {
		$tmpstr = "<arrayName xsi:type=\"xsd:string\">" . $self->getArrayName . "</arrayName>";
	} else {
		$tmpstr = "<arrayName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# platform;
	if( defined( $self->getPlatform ) ) {
		$tmpstr = "<platform xsi:type=\"xsd:string\">" . $self->getPlatform . "</platform>";
	} else {
		$tmpstr = "<platform xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of GenericArray objects
# param: xml doc
# returns: list of GenericArray objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of GenericArray objects
# param: xml node
# returns: a list of GenericArray objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one GenericArray object
# param: xml node
# returns: one GenericArray object
sub fromWSXMLNode {
	my $GenericArrayNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $arrayName;
		my $bigid;
		my $id;
		my $platform;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($GenericArrayNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "arrayName") {
				$arrayName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "platform") {
				$platform=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::GenericArray;
	## begin set attr ##
		$newobj->setArrayName($arrayName);
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setPlatform($platform);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getArrayName {
	my $self = shift;
	return $self->{arrayName};
}

sub setArrayName {
	my $self = shift;
	$self->{arrayName} = shift;
}

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getPlatform {
	my $self = shift;
	return $self->{platform};
}

sub setPlatform {
	my $self = shift;
	$self->{platform} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getGenericReporterCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GenericReporter", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Vocabulary;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Vocabulary object
# returns: a Vocabulary object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Vocabulary\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Vocabulary intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Vocabulary\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# coreTerm;
	if( defined( $self->getCoreTerm ) ) {
		$tmpstr = "<coreTerm xsi:type=\"xsd:string\">" . $self->getCoreTerm . "</coreTerm>";
	} else {
		$tmpstr = "<coreTerm xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# generalTerm;
	if( defined( $self->getGeneralTerm ) ) {
		$tmpstr = "<generalTerm xsi:type=\"xsd:string\">" . $self->getGeneralTerm . "</generalTerm>";
	} else {
		$tmpstr = "<generalTerm xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Vocabulary objects
# param: xml doc
# returns: list of Vocabulary objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Vocabulary objects
# param: xml node
# returns: a list of Vocabulary objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Vocabulary object
# param: xml node
# returns: one Vocabulary object
sub fromWSXMLNode {
	my $VocabularyNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $coreTerm;
		my $generalTerm;
		my $id;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($VocabularyNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "coreTerm") {
				$coreTerm=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "generalTerm") {
				$generalTerm=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Vocabulary;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setCoreTerm($coreTerm);
		$newobj->setGeneralTerm($generalTerm);
		$newobj->setId($id);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getCoreTerm {
	my $self = shift;
	return $self->{coreTerm};
}

sub setCoreTerm {
	my $self = shift;
	$self->{coreTerm} = shift;
}

sub getGeneralTerm {
	my $self = shift;
	return $self->{generalTerm};
}

sub setGeneralTerm {
	my $self = shift;
	$self->{generalTerm} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAnomalyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Anomaly", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::OrganOntologyRelationship;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the OrganOntologyRelationship object
# returns: a OrganOntologyRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new OrganOntologyRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this OrganOntologyRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":OrganOntologyRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of OrganOntologyRelationship objects
# param: xml doc
# returns: list of OrganOntologyRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of OrganOntologyRelationship objects
# param: xml node
# returns: a list of OrganOntologyRelationship objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one OrganOntologyRelationship object
# param: xml node
# returns: one OrganOntologyRelationship object
sub fromWSXMLNode {
	my $OrganOntologyRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($OrganOntologyRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::OrganOntologyRelationship;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildOrganOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::OrganOntology", $self);
	return $results[0];
}

sub getParentOrganOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::OrganOntology", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Anomaly;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Anomaly object
# returns: a Anomaly object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Anomaly\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Anomaly intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Anomaly\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# description;
	if( defined( $self->getDescription ) ) {
		$tmpstr = "<description xsi:type=\"xsd:string\">" . $self->getDescription . "</description>";
	} else {
		$tmpstr = "<description xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Anomaly objects
# param: xml doc
# returns: list of Anomaly objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Anomaly objects
# param: xml node
# returns: a list of Anomaly objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Anomaly object
# param: xml node
# returns: one Anomaly object
sub fromWSXMLNode {
	my $AnomalyNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $description;
		my $id;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AnomalyNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Anomaly;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setDescription($description);
		$newobj->setId($id);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getDescription {
	my $self = shift;
	return $self->{description};
}

sub setDescription {
	my $self = shift;
	$self->{description} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getHistopathology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Histopathology", $self);
	return $results[0];
}

sub getOrganOntologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::OrganOntology", $self);
	return @results;
}

sub getVocabularyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Vocabulary", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Agent;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Agent object
# returns: a Agent object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Agent\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Agent intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Agent\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# EVSId;
	if( defined( $self->getEVSId ) ) {
		$tmpstr = "<EVSId xsi:type=\"xsd:string\">" . $self->getEVSId . "</EVSId>";
	} else {
		$tmpstr = "<EVSId xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# NSCNumber;
	if( defined( $self->getNSCNumber ) ) {
		$tmpstr = "<NSCNumber xsi:type=\"xsd:long\">" . $self->getNSCNumber . "</NSCNumber>";
	} else {
		$tmpstr = "<NSCNumber xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# comment;
	if( defined( $self->getComment ) ) {
		$tmpstr = "<comment xsi:type=\"xsd:string\">" . $self->getComment . "</comment>";
	} else {
		$tmpstr = "<comment xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# isCMAPAgent;
	if( defined( $self->getIsCMAPAgent ) ) {
		$tmpstr = "<isCMAPAgent xsi:type=\"xsd:boolean\">" . $self->getIsCMAPAgent . "</isCMAPAgent>";
	} else {
		$tmpstr = "<isCMAPAgent xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# source;
	if( defined( $self->getSource ) ) {
		$tmpstr = "<source xsi:type=\"xsd:string\">" . $self->getSource . "</source>";
	} else {
		$tmpstr = "<source xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Agent objects
# param: xml doc
# returns: list of Agent objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Agent objects
# param: xml node
# returns: a list of Agent objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Agent object
# param: xml node
# returns: one Agent object
sub fromWSXMLNode {
	my $AgentNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $EVSId;
		my $NSCNumber;
		my $bigid;
		my $comment;
		my $id;
		my $isCMAPAgent;
		my $name;
		my $source;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AgentNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "EVSId") {
				$EVSId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "NSCNumber") {
				$NSCNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "comment") {
				$comment=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "isCMAPAgent") {
				$isCMAPAgent=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "source") {
				$source=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Agent;
	## begin set attr ##
		$newobj->setEVSId($EVSId);
		$newobj->setNSCNumber($NSCNumber);
		$newobj->setBigid($bigid);
		$newobj->setComment($comment);
		$newobj->setId($id);
		$newobj->setIsCMAPAgent($isCMAPAgent);
		$newobj->setName($name);
		$newobj->setSource($source);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getEVSId {
	my $self = shift;
	return $self->{EVSId};
}

sub setEVSId {
	my $self = shift;
	$self->{EVSId} = shift;
}

sub getNSCNumber {
	my $self = shift;
	return $self->{NSCNumber};
}

sub setNSCNumber {
	my $self = shift;
	$self->{NSCNumber} = shift;
}

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getComment {
	my $self = shift;
	return $self->{comment};
}

sub setComment {
	my $self = shift;
	$self->{comment} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getIsCMAPAgent {
	my $self = shift;
	return $self->{isCMAPAgent};
}

sub setIsCMAPAgent {
	my $self = shift;
	$self->{isCMAPAgent} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getSource {
	my $self = shift;
	return $self->{source};
}

sub setSource {
	my $self = shift;
	$self->{source} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getClinicalTrialProtocolCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::ClinicalTrialProtocol", $self);
	return @results;
}

sub getTargetCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Target", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::ClinicalTrialProtocol;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ClinicalTrialProtocol object
# returns: a ClinicalTrialProtocol object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ClinicalTrialProtocol\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ClinicalTrialProtocol intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ClinicalTrialProtocol\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# NIHAdminCode;
	if( defined( $self->getNIHAdminCode ) ) {
		$tmpstr = "<NIHAdminCode xsi:type=\"xsd:string\">" . $self->getNIHAdminCode . "</NIHAdminCode>";
	} else {
		$tmpstr = "<NIHAdminCode xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# PDQIdentifier;
	if( defined( $self->getPDQIdentifier ) ) {
		$tmpstr = "<PDQIdentifier xsi:type=\"xsd:string\">" . $self->getPDQIdentifier . "</PDQIdentifier>";
	} else {
		$tmpstr = "<PDQIdentifier xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# PIName;
	if( defined( $self->getPIName ) ) {
		$tmpstr = "<PIName xsi:type=\"xsd:string\">" . $self->getPIName . "</PIName>";
	} else {
		$tmpstr = "<PIName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# currentStatus;
	if( defined( $self->getCurrentStatus ) ) {
		$tmpstr = "<currentStatus xsi:type=\"xsd:string\">" . $self->getCurrentStatus . "</currentStatus>";
	} else {
		$tmpstr = "<currentStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# currentStatusDate;
	if( defined( $self->getCurrentStatusDate ) ) {
		$tmpstr = "<currentStatusDate xsi:type=\"xsd:dateTime\">" . $self->getCurrentStatusDate . "</currentStatusDate>";
	} else {
		$tmpstr = "<currentStatusDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# documentNumber;
	if( defined( $self->getDocumentNumber ) ) {
		$tmpstr = "<documentNumber xsi:type=\"xsd:string\">" . $self->getDocumentNumber . "</documentNumber>";
	} else {
		$tmpstr = "<documentNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# leadOrganizationId;
	if( defined( $self->getLeadOrganizationId ) ) {
		$tmpstr = "<leadOrganizationId xsi:type=\"xsd:string\">" . $self->getLeadOrganizationId . "</leadOrganizationId>";
	} else {
		$tmpstr = "<leadOrganizationId xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# leadOrganizationName;
	if( defined( $self->getLeadOrganizationName ) ) {
		$tmpstr = "<leadOrganizationName xsi:type=\"xsd:string\">" . $self->getLeadOrganizationName . "</leadOrganizationName>";
	} else {
		$tmpstr = "<leadOrganizationName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# participationType;
	if( defined( $self->getParticipationType ) ) {
		$tmpstr = "<participationType xsi:type=\"xsd:string\">" . $self->getParticipationType . "</participationType>";
	} else {
		$tmpstr = "<participationType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# phase;
	if( defined( $self->getPhase ) ) {
		$tmpstr = "<phase xsi:type=\"xsd:string\">" . $self->getPhase . "</phase>";
	} else {
		$tmpstr = "<phase xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# title;
	if( defined( $self->getTitle ) ) {
		$tmpstr = "<title xsi:type=\"xsd:string\">" . $self->getTitle . "</title>";
	} else {
		$tmpstr = "<title xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# treatmentFlag;
	if( defined( $self->getTreatmentFlag ) ) {
		$tmpstr = "<treatmentFlag xsi:type=\"xsd:string\">" . $self->getTreatmentFlag . "</treatmentFlag>";
	} else {
		$tmpstr = "<treatmentFlag xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ClinicalTrialProtocol objects
# param: xml doc
# returns: list of ClinicalTrialProtocol objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ClinicalTrialProtocol objects
# param: xml node
# returns: a list of ClinicalTrialProtocol objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one ClinicalTrialProtocol object
# param: xml node
# returns: one ClinicalTrialProtocol object
sub fromWSXMLNode {
	my $ClinicalTrialProtocolNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $NIHAdminCode;
		my $PDQIdentifier;
		my $PIName;
		my $bigid;
		my $currentStatus;
		my $currentStatusDate;
		my $documentNumber;
		my $id;
		my $leadOrganizationId;
		my $leadOrganizationName;
		my $participationType;
		my $phase;
		my $title;
		my $treatmentFlag;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ClinicalTrialProtocolNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "NIHAdminCode") {
				$NIHAdminCode=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "PDQIdentifier") {
				$PDQIdentifier=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "PIName") {
				$PIName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "currentStatus") {
				$currentStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "currentStatusDate") {
				$currentStatusDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "documentNumber") {
				$documentNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "leadOrganizationId") {
				$leadOrganizationId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "leadOrganizationName") {
				$leadOrganizationName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "participationType") {
				$participationType=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "phase") {
				$phase=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "title") {
				$title=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "treatmentFlag") {
				$treatmentFlag=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::ClinicalTrialProtocol;
	## begin set attr ##
		$newobj->setNIHAdminCode($NIHAdminCode);
		$newobj->setPDQIdentifier($PDQIdentifier);
		$newobj->setPIName($PIName);
		$newobj->setBigid($bigid);
		$newobj->setCurrentStatus($currentStatus);
		$newobj->setCurrentStatusDate($currentStatusDate);
		$newobj->setDocumentNumber($documentNumber);
		$newobj->setId($id);
		$newobj->setLeadOrganizationId($leadOrganizationId);
		$newobj->setLeadOrganizationName($leadOrganizationName);
		$newobj->setParticipationType($participationType);
		$newobj->setPhase($phase);
		$newobj->setTitle($title);
		$newobj->setTreatmentFlag($treatmentFlag);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getNIHAdminCode {
	my $self = shift;
	return $self->{NIHAdminCode};
}

sub setNIHAdminCode {
	my $self = shift;
	$self->{NIHAdminCode} = shift;
}

sub getPDQIdentifier {
	my $self = shift;
	return $self->{PDQIdentifier};
}

sub setPDQIdentifier {
	my $self = shift;
	$self->{PDQIdentifier} = shift;
}

sub getPIName {
	my $self = shift;
	return $self->{PIName};
}

sub setPIName {
	my $self = shift;
	$self->{PIName} = shift;
}

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getCurrentStatus {
	my $self = shift;
	return $self->{currentStatus};
}

sub setCurrentStatus {
	my $self = shift;
	$self->{currentStatus} = shift;
}

sub getCurrentStatusDate {
	my $self = shift;
	return $self->{currentStatusDate};
}

sub setCurrentStatusDate {
	my $self = shift;
	$self->{currentStatusDate} = shift;
}

sub getDocumentNumber {
	my $self = shift;
	return $self->{documentNumber};
}

sub setDocumentNumber {
	my $self = shift;
	$self->{documentNumber} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLeadOrganizationId {
	my $self = shift;
	return $self->{leadOrganizationId};
}

sub setLeadOrganizationId {
	my $self = shift;
	$self->{leadOrganizationId} = shift;
}

sub getLeadOrganizationName {
	my $self = shift;
	return $self->{leadOrganizationName};
}

sub setLeadOrganizationName {
	my $self = shift;
	$self->{leadOrganizationName} = shift;
}

sub getParticipationType {
	my $self = shift;
	return $self->{participationType};
}

sub setParticipationType {
	my $self = shift;
	$self->{participationType} = shift;
}

sub getPhase {
	my $self = shift;
	return $self->{phase};
}

sub setPhase {
	my $self = shift;
	$self->{phase} = shift;
}

sub getTitle {
	my $self = shift;
	return $self->{title};
}

sub setTitle {
	my $self = shift;
	$self->{title} = shift;
}

sub getTreatmentFlag {
	my $self = shift;
	return $self->{treatmentFlag};
}

sub setTreatmentFlag {
	my $self = shift;
	$self->{treatmentFlag} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAgentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Agent", $self);
	return @results;
}

sub getDiseaseOntologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::DiseaseOntology", $self);
	return @results;
}

sub getHistopathologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Histopathology", $self);
	return @results;
}

sub getProtocolAssociationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::ProtocolAssociation", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::ProtocolAssociation;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ProtocolAssociation object
# returns: a ProtocolAssociation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ProtocolAssociation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ProtocolAssociation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ProtocolAssociation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# CTEPNAME;
	if( defined( $self->getCTEPNAME ) ) {
		$tmpstr = "<CTEPNAME xsi:type=\"xsd:string\">" . $self->getCTEPNAME . "</CTEPNAME>";
	} else {
		$tmpstr = "<CTEPNAME xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# IMTCODE;
	if( defined( $self->getIMTCODE ) ) {
		$tmpstr = "<IMTCODE xsi:type=\"xsd:long\">" . $self->getIMTCODE . "</IMTCODE>";
	} else {
		$tmpstr = "<IMTCODE xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# diseaseCategory;
	if( defined( $self->getDiseaseCategory ) ) {
		$tmpstr = "<diseaseCategory xsi:type=\"xsd:string\">" . $self->getDiseaseCategory . "</diseaseCategory>";
	} else {
		$tmpstr = "<diseaseCategory xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# diseaseSubCategory;
	if( defined( $self->getDiseaseSubCategory ) ) {
		$tmpstr = "<diseaseSubCategory xsi:type=\"xsd:string\">" . $self->getDiseaseSubCategory . "</diseaseSubCategory>";
	} else {
		$tmpstr = "<diseaseSubCategory xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ProtocolAssociation objects
# param: xml doc
# returns: list of ProtocolAssociation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ProtocolAssociation objects
# param: xml node
# returns: a list of ProtocolAssociation objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one ProtocolAssociation object
# param: xml node
# returns: one ProtocolAssociation object
sub fromWSXMLNode {
	my $ProtocolAssociationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $CTEPNAME;
		my $IMTCODE;
		my $bigid;
		my $diseaseCategory;
		my $diseaseSubCategory;
		my $id;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ProtocolAssociationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "CTEPNAME") {
				$CTEPNAME=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "IMTCODE") {
				$IMTCODE=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "diseaseCategory") {
				$diseaseCategory=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "diseaseSubCategory") {
				$diseaseSubCategory=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::ProtocolAssociation;
	## begin set attr ##
		$newobj->setCTEPNAME($CTEPNAME);
		$newobj->setIMTCODE($IMTCODE);
		$newobj->setBigid($bigid);
		$newobj->setDiseaseCategory($diseaseCategory);
		$newobj->setDiseaseSubCategory($diseaseSubCategory);
		$newobj->setId($id);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCTEPNAME {
	my $self = shift;
	return $self->{CTEPNAME};
}

sub setCTEPNAME {
	my $self = shift;
	$self->{CTEPNAME} = shift;
}

sub getIMTCODE {
	my $self = shift;
	return $self->{IMTCODE};
}

sub setIMTCODE {
	my $self = shift;
	$self->{IMTCODE} = shift;
}

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getDiseaseCategory {
	my $self = shift;
	return $self->{diseaseCategory};
}

sub setDiseaseCategory {
	my $self = shift;
	$self->{diseaseCategory} = shift;
}

sub getDiseaseSubCategory {
	my $self = shift;
	return $self->{diseaseSubCategory};
}

sub setDiseaseSubCategory {
	my $self = shift;
	$self->{diseaseSubCategory} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getClinicalTrialProtocol {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::ClinicalTrialProtocol", $self);
	return $results[0];
}

sub getDiseaseOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::DiseaseOntology", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::GeneOntologyRelationship;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the GeneOntologyRelationship object
# returns: a GeneOntologyRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new GeneOntologyRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this GeneOntologyRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":GeneOntologyRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# relationshipType;
	if( defined( $self->getRelationshipType ) ) {
		$tmpstr = "<relationshipType xsi:type=\"xsd:string\">" . $self->getRelationshipType . "</relationshipType>";
	} else {
		$tmpstr = "<relationshipType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of GeneOntologyRelationship objects
# param: xml doc
# returns: list of GeneOntologyRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of GeneOntologyRelationship objects
# param: xml node
# returns: a list of GeneOntologyRelationship objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one GeneOntologyRelationship object
# param: xml node
# returns: one GeneOntologyRelationship object
sub fromWSXMLNode {
	my $GeneOntologyRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $relationshipType;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($GeneOntologyRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "relationshipType") {
				$relationshipType=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::GeneOntologyRelationship;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setRelationshipType($relationshipType);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getRelationshipType {
	my $self = shift;
	return $self->{relationshipType};
}

sub setRelationshipType {
	my $self = shift;
	$self->{relationshipType} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildGeneOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GeneOntology", $self);
	return $results[0];
}

sub getParentGeneOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GeneOntology", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::GenericReporter;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the GenericReporter object
# returns: a GenericReporter object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new GenericReporter\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this GenericReporter intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":GenericReporter\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of GenericReporter objects
# param: xml doc
# returns: list of GenericReporter objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of GenericReporter objects
# param: xml node
# returns: a list of GenericReporter objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one GenericReporter object
# param: xml node
# returns: one GenericReporter object
sub fromWSXMLNode {
	my $GenericReporterNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $name;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($GenericReporterNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::GenericReporter;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setName($name);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getGene {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return $results[0];
}

sub getGenericArrayCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::GenericArray", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::Pathway;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Pathway object
# returns: a Pathway object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Pathway\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Pathway intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Pathway\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# description;
	if( defined( $self->getDescription ) ) {
		$tmpstr = "<description xsi:type=\"xsd:string\">" . $self->getDescription . "</description>";
	} else {
		$tmpstr = "<description xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# diagram;
	if( defined( $self->getDiagram ) ) {
		$tmpstr = "<diagram xsi:type=\"xsd:string\">" . $self->getDiagram . "</diagram>";
	} else {
		$tmpstr = "<diagram xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# displayValue;
	if( defined( $self->getDisplayValue ) ) {
		$tmpstr = "<displayValue xsi:type=\"xsd:string\">" . $self->getDisplayValue . "</displayValue>";
	} else {
		$tmpstr = "<displayValue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Pathway objects
# param: xml doc
# returns: list of Pathway objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Pathway objects
# param: xml node
# returns: a list of Pathway objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one Pathway object
# param: xml node
# returns: one Pathway object
sub fromWSXMLNode {
	my $PathwayNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $description;
		my $diagram;
		my $displayValue;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($PathwayNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "diagram") {
				$diagram=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "displayValue") {
				$displayValue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::Pathway;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setDescription($description);
		$newobj->setDiagram($diagram);
		$newobj->setDisplayValue($displayValue);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getDescription {
	my $self = shift;
	return $self->{description};
}

sub setDescription {
	my $self = shift;
	$self->{description} = shift;
}

sub getDiagram {
	my $self = shift;
	return $self->{diagram};
}

sub setDiagram {
	my $self = shift;
	$self->{diagram} = shift;
}

sub getDisplayValue {
	my $self = shift;
	return $self->{displayValue};
}

sub setDisplayValue {
	my $self = shift;
	$self->{displayValue} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getGeneCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return @results;
}

sub getHistopathologyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Histopathology", $self);
	return @results;
}

sub getTaxon {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Taxon", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::DiseaseOntologyRelationship;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::DomainObjectI);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the DiseaseOntologyRelationship object
# returns: a DiseaseOntologyRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DiseaseOntologyRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DiseaseOntologyRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DiseaseOntologyRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DiseaseOntologyRelationship objects
# param: xml doc
# returns: list of DiseaseOntologyRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DiseaseOntologyRelationship objects
# param: xml node
# returns: a list of DiseaseOntologyRelationship objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one DiseaseOntologyRelationship object
# param: xml node
# returns: one DiseaseOntologyRelationship object
sub fromWSXMLNode {
	my $DiseaseOntologyRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $id;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DiseaseOntologyRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::DiseaseOntologyRelationship;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setId($id);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildDiseaseOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::DiseaseOntology", $self);
	return $results[0];
}

sub getParentDiseaseOntology {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::DiseaseOntology", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaBIO::CytogeneticLocation;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaBIO::Location);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the CytogeneticLocation object
# returns: a CytogeneticLocation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new CytogeneticLocation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this CytogeneticLocation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":CytogeneticLocation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cabio.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# bigid;
	if( defined( $self->getBigid ) ) {
		$tmpstr = "<bigid xsi:type=\"xsd:string\">" . $self->getBigid . "</bigid>";
	} else {
		$tmpstr = "<bigid xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endCytobandLocId;
	if( defined( $self->getEndCytobandLocId ) ) {
		$tmpstr = "<endCytobandLocId xsi:type=\"xsd:long\">" . $self->getEndCytobandLocId . "</endCytobandLocId>";
	} else {
		$tmpstr = "<endCytobandLocId xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# startCytobandLocId;
	if( defined( $self->getStartCytobandLocId ) ) {
		$tmpstr = "<startCytobandLocId xsi:type=\"xsd:long\">" . $self->getStartCytobandLocId . "</startCytobandLocId>";
	} else {
		$tmpstr = "<startCytobandLocId xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of CytogeneticLocation objects
# param: xml doc
# returns: list of CytogeneticLocation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of CytogeneticLocation objects
# param: xml node
# returns: a list of CytogeneticLocation objects
sub fromWSXMLListNode {
	my $self = shift;
	my $listNode = shift;
	my @obj_list = ();
	
	# get all children for this node
	for my $childrenNode ($listNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		my $newobj = $self->fromWSXMLNode($childrenNode);
		push @obj_list, $newobj;
	    }
	}
	
	return @obj_list;
}

# parse a given xml node, construct one CytogeneticLocation object
# param: xml node
# returns: one CytogeneticLocation object
sub fromWSXMLNode {
	my $CytogeneticLocationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $bigid;
		my $endCytobandLocId;
		my $startCytobandLocId;
		my $id;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($CytogeneticLocationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "bigid") {
				$bigid=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endCytobandLocId") {
				$endCytobandLocId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "startCytobandLocId") {
				$startCytobandLocId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaBIO::CytogeneticLocation;
	## begin set attr ##
		$newobj->setBigid($bigid);
		$newobj->setEndCytobandLocId($endCytobandLocId);
		$newobj->setStartCytobandLocId($startCytobandLocId);
		$newobj->setId($id);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBigid {
	my $self = shift;
	return $self->{bigid};
}

sub setBigid {
	my $self = shift;
	$self->{bigid} = shift;
}

sub getEndCytobandLocId {
	my $self = shift;
	return $self->{endCytobandLocId};
}

sub setEndCytobandLocId {
	my $self = shift;
	$self->{endCytobandLocId} = shift;
}

sub getStartCytobandLocId {
	my $self = shift;
	return $self->{startCytobandLocId};
}

sub setStartCytobandLocId {
	my $self = shift;
	$self->{startCytobandLocId} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getEndCytoband {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Cytoband", $self);
	return $results[0];
}

sub getStartCytoband {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Cytoband", $self);
	return $results[0];
}

sub getSNP {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::SNP", $self);
	return $results[0];
}

sub getChromosome {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Chromosome", $self);
	return $results[0];
}

sub getGene {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::Gene", $self);
	return $results[0];
}

sub getNucleicAcidSequence {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaBIO::NucleicAcidSequence", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# Below is module documentation for Agent

=pod

=head1 Agent

CaCORE::CaBIO::Agent - Perl extension for Agent.

=head2 ABSTRACT

The CaCORE::CaBIO::Agent is a Perl object representation of the
CaCORE Agent object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Agent

The following are all the attributes of the Agent object and their data types:

=over 4

=item EVSId

data type: C<string>

=item NSCNumber

data type: C<long>

=item bigid

data type: C<string>

=item comment

data type: C<string>

=item id

data type: C<long>

=item isCMAPAgent

data type: C<boolean>

=item name

data type: C<string>

=item source

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Agent

The following are all the objects that are associated with the Agent:

=over 4

=item Instance of L</ClinicalTrialProtocol>:

One to many assoication, use C<getClinicalTrialProtocolCollection> to get a collection of associated ClinicalTrialProtocol.

=item Instance of L</Target>:

One to many assoication, use C<getTargetCollection> to get a collection of associated Target.


=back

=cut

# Below is module documentation for Anomaly

=pod

=head1 Anomaly

CaCORE::CaBIO::Anomaly - Perl extension for Anomaly.

=head2 ABSTRACT

The CaCORE::CaBIO::Anomaly is a Perl object representation of the
CaCORE Anomaly object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Anomaly

The following are all the attributes of the Anomaly object and their data types:

=over 4

=item bigid

data type: C<string>

=item description

data type: C<string>

=item id

data type: C<long>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Anomaly

The following are all the objects that are associated with the Anomaly:

=over 4

=item Collection of L</Histopathology>:

Many to one assoication, use C<getHistopathology> to get the associated Histopathology.

=item Instance of L</OrganOntology>:

One to many assoication, use C<getOrganOntologyCollection> to get a collection of associated OrganOntology.

=item Instance of L</Vocabulary>:

One to many assoication, use C<getVocabularyCollection> to get a collection of associated Vocabulary.


=back

=cut

# Below is module documentation for Chromosome

=pod

=head1 Chromosome

CaCORE::CaBIO::Chromosome - Perl extension for Chromosome.

=head2 ABSTRACT

The CaCORE::CaBIO::Chromosome is a Perl object representation of the
CaCORE Chromosome object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Chromosome

The following are all the attributes of the Chromosome object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item number

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Chromosome

The following are all the objects that are associated with the Chromosome:

=over 4

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</Location>:

One to many assoication, use C<getLocationCollection> to get a collection of associated Location.

=item Collection of L</Taxon>:

Many to one assoication, use C<getTaxon> to get the associated Taxon.


=back

=cut

# Below is module documentation for ClinicalTrialProtocol

=pod

=head1 ClinicalTrialProtocol

CaCORE::CaBIO::ClinicalTrialProtocol - Perl extension for ClinicalTrialProtocol.

=head2 ABSTRACT

The CaCORE::CaBIO::ClinicalTrialProtocol is a Perl object representation of the
CaCORE ClinicalTrialProtocol object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ClinicalTrialProtocol

The following are all the attributes of the ClinicalTrialProtocol object and their data types:

=over 4

=item NIHAdminCode

data type: C<string>

=item PDQIdentifier

data type: C<string>

=item PIName

data type: C<string>

=item bigid

data type: C<string>

=item currentStatus

data type: C<string>

=item currentStatusDate

data type: C<dateTime>

=item documentNumber

data type: C<string>

=item id

data type: C<long>

=item leadOrganizationId

data type: C<string>

=item leadOrganizationName

data type: C<string>

=item participationType

data type: C<string>

=item phase

data type: C<string>

=item title

data type: C<string>

=item treatmentFlag

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ClinicalTrialProtocol

The following are all the objects that are associated with the ClinicalTrialProtocol:

=over 4

=item Instance of L</Agent>:

One to many assoication, use C<getAgentCollection> to get a collection of associated Agent.

=item Instance of L</DiseaseOntology>:

One to many assoication, use C<getDiseaseOntologyCollection> to get a collection of associated DiseaseOntology.

=item Instance of L</Histopathology>:

One to many assoication, use C<getHistopathologyCollection> to get a collection of associated Histopathology.

=item Instance of L</ProtocolAssociation>:

One to many assoication, use C<getProtocolAssociationCollection> to get a collection of associated ProtocolAssociation.


=back

=cut

# Below is module documentation for Clone

=pod

=head1 Clone

CaCORE::CaBIO::Clone - Perl extension for Clone.

=head2 ABSTRACT

The CaCORE::CaBIO::Clone is a Perl object representation of the
CaCORE Clone object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Clone

The following are all the attributes of the Clone object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item insertSize

data type: C<long>

=item name

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Clone

The following are all the objects that are associated with the Clone:

=over 4

=item Instance of L</CloneRelativeLocation>:

One to many assoication, use C<getCloneRelativeLocationCollection> to get a collection of associated CloneRelativeLocation.

=item Collection of L</Library>:

Many to one assoication, use C<getLibrary> to get the associated Library.

=item Instance of L</NucleicAcidSequence>:

One to many assoication, use C<getNucleicAcidSequenceCollection> to get a collection of associated NucleicAcidSequence.

=item Instance of L</Taxon>:

One to many assoication, use C<getTaxonCollection> to get a collection of associated Taxon.


=back

=cut

# Below is module documentation for CloneRelativeLocation

=pod

=head1 CloneRelativeLocation

CaCORE::CaBIO::CloneRelativeLocation - Perl extension for CloneRelativeLocation.

=head2 ABSTRACT

The CaCORE::CaBIO::CloneRelativeLocation is a Perl object representation of the
CaCORE CloneRelativeLocation object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of CloneRelativeLocation

The following are all the attributes of the CloneRelativeLocation object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of CloneRelativeLocation

The following are all the objects that are associated with the CloneRelativeLocation:

=over 4

=item Collection of L</Clone>:

Many to one assoication, use C<getClone> to get the associated Clone.

=item Collection of L</NucleicAcidSequence>:

Many to one assoication, use C<getNucleicAcidSequence> to get the associated NucleicAcidSequence.


=back

=cut

# Below is module documentation for Cytoband

=pod

=head1 Cytoband

CaCORE::CaBIO::Cytoband - Perl extension for Cytoband.

=head2 ABSTRACT

The CaCORE::CaBIO::Cytoband is a Perl object representation of the
CaCORE Cytoband object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Cytoband

The following are all the attributes of the Cytoband object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Cytoband

The following are all the objects that are associated with the Cytoband:

=over 4

=item Collection of L</PhysicalLocation>:

Many to one assoication, use C<getPhysicalLocation> to get the associated PhysicalLocation.


=back

=cut

# Below is module documentation for CytogeneticLocation

=pod

=head1 CytogeneticLocation

CaCORE::CaBIO::CytogeneticLocation - Perl extension for CytogeneticLocation.

=head2 ABSTRACT

The CaCORE::CaBIO::CytogeneticLocation is a Perl object representation of the
CaCORE CytogeneticLocation object.

CytogeneticLocation extends from domain object L<"Location">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of CytogeneticLocation

The following are all the attributes of the CytogeneticLocation object and their data types:

=over 4

=item bigid

data type: C<string>

=item endCytobandLocId

data type: C<long>

=item startCytobandLocId

data type: C<long>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of CytogeneticLocation

The following are all the objects that are associated with the CytogeneticLocation:

=over 4

=item Collection of L</EndCytoband>:

Many to one assoication, use C<getEndCytoband> to get the associated EndCytoband.

=item Collection of L</StartCytoband>:

Many to one assoication, use C<getStartCytoband> to get the associated StartCytoband.


=back

=cut

# Below is module documentation for DiseaseOntology

=pod

=head1 DiseaseOntology

CaCORE::CaBIO::DiseaseOntology - Perl extension for DiseaseOntology.

=head2 ABSTRACT

The CaCORE::CaBIO::DiseaseOntology is a Perl object representation of the
CaCORE DiseaseOntology object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DiseaseOntology

The following are all the attributes of the DiseaseOntology object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DiseaseOntology

The following are all the objects that are associated with the DiseaseOntology:

=over 4

=item Instance of L</ChildDiseaseOntologyRelationship>:

One to many assoication, use C<getChildDiseaseOntologyRelationshipCollection> to get a collection of associated ChildDiseaseOntologyRelationship.

=item Instance of L</ClinicalTrialProtocol>:

One to many assoication, use C<getClinicalTrialProtocolCollection> to get a collection of associated ClinicalTrialProtocol.

=item Instance of L</Histopathology>:

One to many assoication, use C<getHistopathologyCollection> to get a collection of associated Histopathology.

=item Instance of L</ParentDiseaseOntologyRelationship>:

One to many assoication, use C<getParentDiseaseOntologyRelationshipCollection> to get a collection of associated ParentDiseaseOntologyRelationship.


=back

=cut

# Below is module documentation for DiseaseOntologyRelationship

=pod

=head1 DiseaseOntologyRelationship

CaCORE::CaBIO::DiseaseOntologyRelationship - Perl extension for DiseaseOntologyRelationship.

=head2 ABSTRACT

The CaCORE::CaBIO::DiseaseOntologyRelationship is a Perl object representation of the
CaCORE DiseaseOntologyRelationship object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DiseaseOntologyRelationship

The following are all the attributes of the DiseaseOntologyRelationship object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DiseaseOntologyRelationship

The following are all the objects that are associated with the DiseaseOntologyRelationship:

=over 4

=item Collection of L</ChildDiseaseOntology>:

Many to one assoication, use C<getChildDiseaseOntology> to get the associated ChildDiseaseOntology.

=item Collection of L</ParentDiseaseOntology>:

Many to one assoication, use C<getParentDiseaseOntology> to get the associated ParentDiseaseOntology.


=back

=cut

# Below is module documentation for Gene

=pod

=head1 Gene

CaCORE::CaBIO::Gene - Perl extension for Gene.

=head2 ABSTRACT

The CaCORE::CaBIO::Gene is a Perl object representation of the
CaCORE Gene object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Gene

The following are all the attributes of the Gene object and their data types:

=over 4

=item bigid

data type: C<string>

=item clusterId

data type: C<long>

=item fullName

data type: C<string>

=item id

data type: C<long>

=item symbol

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Gene

The following are all the objects that are associated with the Gene:

=over 4

=item Collection of L</Chromosome>:

Many to one assoication, use C<getChromosome> to get the associated Chromosome.

=item Instance of L</DatabaseCrossReference>:

One to many assoication, use C<getDatabaseCrossReferenceCollection> to get a collection of associated DatabaseCrossReference.

=item Instance of L</GeneAlias>:

One to many assoication, use C<getGeneAliasCollection> to get a collection of associated GeneAlias.

=item Instance of L</GeneOntology>:

One to many assoication, use C<getGeneOntologyCollection> to get a collection of associated GeneOntology.

=item Instance of L</GeneRelativeLocation>:

One to many assoication, use C<getGeneRelativeLocationCollection> to get a collection of associated GeneRelativeLocation.

=item Instance of L</GenericReporter>:

One to many assoication, use C<getGenericReporterCollection> to get a collection of associated GenericReporter.

=item Instance of L</Histopathology>:

One to many assoication, use C<getHistopathologyCollection> to get a collection of associated Histopathology.

=item Instance of L</HomologousAssociation>:

One to many assoication, use C<getHomologousAssociationCollection> to get a collection of associated HomologousAssociation.

=item Instance of L</Library>:

One to many assoication, use C<getLibraryCollection> to get a collection of associated Library.

=item Instance of L</Location>:

One to many assoication, use C<getLocationCollection> to get a collection of associated Location.

=item Instance of L</NucleicAcidSequence>:

One to many assoication, use C<getNucleicAcidSequenceCollection> to get a collection of associated NucleicAcidSequence.

=item Instance of L</OrganOntology>:

One to many assoication, use C<getOrganOntologyCollection> to get a collection of associated OrganOntology.

=item Instance of L</Pathway>:

One to many assoication, use C<getPathwayCollection> to get a collection of associated Pathway.

=item Instance of L</Protein>:

One to many assoication, use C<getProteinCollection> to get a collection of associated Protein.

=item Instance of L</Target>:

One to many assoication, use C<getTargetCollection> to get a collection of associated Target.

=item Collection of L</Taxon>:

Many to one assoication, use C<getTaxon> to get the associated Taxon.


=back

=cut

# Below is module documentation for GeneAlias

=pod

=head1 GeneAlias

CaCORE::CaBIO::GeneAlias - Perl extension for GeneAlias.

=head2 ABSTRACT

The CaCORE::CaBIO::GeneAlias is a Perl object representation of the
CaCORE GeneAlias object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of GeneAlias

The following are all the attributes of the GeneAlias object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of GeneAlias

The following are all the objects that are associated with the GeneAlias:

=over 4

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.


=back

=cut

# Below is module documentation for GeneOntology

=pod

=head1 GeneOntology

CaCORE::CaBIO::GeneOntology - Perl extension for GeneOntology.

=head2 ABSTRACT

The CaCORE::CaBIO::GeneOntology is a Perl object representation of the
CaCORE GeneOntology object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of GeneOntology

The following are all the attributes of the GeneOntology object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of GeneOntology

The following are all the objects that are associated with the GeneOntology:

=over 4

=item Instance of L</ChildGeneOntologyRelationship>:

One to many assoication, use C<getChildGeneOntologyRelationshipCollection> to get a collection of associated ChildGeneOntologyRelationship.

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</ParentGeneOntologyRelationship>:

One to many assoication, use C<getParentGeneOntologyRelationshipCollection> to get a collection of associated ParentGeneOntologyRelationship.


=back

=cut

# Below is module documentation for GeneOntologyRelationship

=pod

=head1 GeneOntologyRelationship

CaCORE::CaBIO::GeneOntologyRelationship - Perl extension for GeneOntologyRelationship.

=head2 ABSTRACT

The CaCORE::CaBIO::GeneOntologyRelationship is a Perl object representation of the
CaCORE GeneOntologyRelationship object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of GeneOntologyRelationship

The following are all the attributes of the GeneOntologyRelationship object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item relationshipType

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of GeneOntologyRelationship

The following are all the objects that are associated with the GeneOntologyRelationship:

=over 4

=item Collection of L</ChildGeneOntology>:

Many to one assoication, use C<getChildGeneOntology> to get the associated ChildGeneOntology.

=item Collection of L</ParentGeneOntology>:

Many to one assoication, use C<getParentGeneOntology> to get the associated ParentGeneOntology.


=back

=cut

# Below is module documentation for GeneRelativeLocation

=pod

=head1 GeneRelativeLocation

CaCORE::CaBIO::GeneRelativeLocation - Perl extension for GeneRelativeLocation.

=head2 ABSTRACT

The CaCORE::CaBIO::GeneRelativeLocation is a Perl object representation of the
CaCORE GeneRelativeLocation object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of GeneRelativeLocation

The following are all the attributes of the GeneRelativeLocation object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of GeneRelativeLocation

The following are all the objects that are associated with the GeneRelativeLocation:

=over 4


=back

=cut

# Below is module documentation for GenericArray

=pod

=head1 GenericArray

CaCORE::CaBIO::GenericArray - Perl extension for GenericArray.

=head2 ABSTRACT

The CaCORE::CaBIO::GenericArray is a Perl object representation of the
CaCORE GenericArray object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of GenericArray

The following are all the attributes of the GenericArray object and their data types:

=over 4

=item arrayName

data type: C<string>

=item bigid

data type: C<string>

=item id

data type: C<long>

=item platform

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of GenericArray

The following are all the objects that are associated with the GenericArray:

=over 4

=item Instance of L</GenericReporter>:

One to many assoication, use C<getGenericReporterCollection> to get a collection of associated GenericReporter.


=back

=cut

# Below is module documentation for GenericReporter

=pod

=head1 GenericReporter

CaCORE::CaBIO::GenericReporter - Perl extension for GenericReporter.

=head2 ABSTRACT

The CaCORE::CaBIO::GenericReporter is a Perl object representation of the
CaCORE GenericReporter object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of GenericReporter

The following are all the attributes of the GenericReporter object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of GenericReporter

The following are all the objects that are associated with the GenericReporter:

=over 4

=item Collection of L</Gene>:

Many to one assoication, use C<getGene> to get the associated Gene.

=item Instance of L</GenericArray>:

One to many assoication, use C<getGenericArrayCollection> to get a collection of associated GenericArray.


=back

=cut

# Below is module documentation for Histopathology

=pod

=head1 Histopathology

CaCORE::CaBIO::Histopathology - Perl extension for Histopathology.

=head2 ABSTRACT

The CaCORE::CaBIO::Histopathology is a Perl object representation of the
CaCORE Histopathology object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Histopathology

The following are all the attributes of the Histopathology object and their data types:

=over 4

=item ageOfOnset

data type: C<string>

=item comments

data type: C<string>

=item grossDescription

data type: C<string>

=item id

data type: C<long>

=item microscopicDescription

data type: C<string>

=item relationalOperation

data type: C<string>

=item survivalInfo

data type: C<string>

=item tumorIncidenceRate

data type: C<float>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Histopathology

The following are all the objects that are associated with the Histopathology:

=over 4

=item Instance of L</Anomaly>:

One to many assoication, use C<getAnomalyCollection> to get a collection of associated Anomaly.

=item Instance of L</ClinicalTrialProtocol>:

One to many assoication, use C<getClinicalTrialProtocolCollection> to get a collection of associated ClinicalTrialProtocol.

=item Collection of L</DiseaseOntology>:

Many to one assoication, use C<getDiseaseOntology> to get the associated DiseaseOntology.

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</Library>:

One to many assoication, use C<getLibraryCollection> to get a collection of associated Library.

=item Instance of L</Metastasis>:

One to many assoication, use C<getMetastasisCollection> to get a collection of associated Metastasis.

=item Collection of L</OrganOntology>:

Many to one assoication, use C<getOrganOntology> to get the associated OrganOntology.


=back

=cut

# Below is module documentation for HomologousAssociation

=pod

=head1 HomologousAssociation

CaCORE::CaBIO::HomologousAssociation - Perl extension for HomologousAssociation.

=head2 ABSTRACT

The CaCORE::CaBIO::HomologousAssociation is a Perl object representation of the
CaCORE HomologousAssociation object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of HomologousAssociation

The following are all the attributes of the HomologousAssociation object and their data types:

=over 4

=item bigid

data type: C<string>

=item homologousId

data type: C<long>

=item id

data type: C<long>

=item similarityPercentage

data type: C<float>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of HomologousAssociation

The following are all the objects that are associated with the HomologousAssociation:

=over 4

=item Collection of L</HomologousGene>:

Many to one assoication, use C<getHomologousGene> to get the associated HomologousGene.


=back

=cut

# Below is module documentation for Library

=pod

=head1 Library

CaCORE::CaBIO::Library - Perl extension for Library.

=head2 ABSTRACT

The CaCORE::CaBIO::Library is a Perl object representation of the
CaCORE Library object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Library

The following are all the attributes of the Library object and their data types:

=over 4

=item bigid

data type: C<string>

=item cloneProducer

data type: C<string>

=item cloneVector

data type: C<string>

=item cloneVectorType

data type: C<string>

=item clonesToDate

data type: C<long>

=item creationDate

data type: C<dateTime>

=item description

data type: C<string>

=item id

data type: C<long>

=item keyword

data type: C<string>

=item labHost

data type: C<string>

=item name

data type: C<string>

=item rsite1

data type: C<string>

=item rsite2

data type: C<string>

=item sequencesToDate

data type: C<long>

=item type

data type: C<string>

=item uniGeneId

data type: C<long>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Library

The following are all the objects that are associated with the Library:

=over 4

=item Instance of L</Clone>:

One to many assoication, use C<getCloneCollection> to get a collection of associated Clone.

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</Histopathology>:

One to many assoication, use C<getHistopathologyCollection> to get a collection of associated Histopathology.

=item Collection of L</Protocol>:

Many to one assoication, use C<getProtocol> to get the associated Protocol.

=item Collection of L</Tissue>:

Many to one assoication, use C<getTissue> to get the associated Tissue.


=back

=cut

# Below is module documentation for Location

=pod

=head1 Location

CaCORE::CaBIO::Location - Perl extension for Location.

=head2 ABSTRACT

The CaCORE::CaBIO::Location is a Perl object representation of the
CaCORE Location object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Location

The following are all the attributes of the Location object and their data types:

=over 4

=item id

data type: C<long>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Location

The following are all the objects that are associated with the Location:

=over 4

=item Collection of L</SNP>:

Many to one assoication, use C<getSNP> to get the associated SNP.

=item Collection of L</Chromosome>:

Many to one assoication, use C<getChromosome> to get the associated Chromosome.

=item Collection of L</Gene>:

Many to one assoication, use C<getGene> to get the associated Gene.

=item Collection of L</NucleicAcidSequence>:

Many to one assoication, use C<getNucleicAcidSequence> to get the associated NucleicAcidSequence.


=back

=cut

# Below is module documentation for NucleicAcidSequence

=pod

=head1 NucleicAcidSequence

CaCORE::CaBIO::NucleicAcidSequence - Perl extension for NucleicAcidSequence.

=head2 ABSTRACT

The CaCORE::CaBIO::NucleicAcidSequence is a Perl object representation of the
CaCORE NucleicAcidSequence object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of NucleicAcidSequence

The following are all the attributes of the NucleicAcidSequence object and their data types:

=over 4

=item accessionNumber

data type: C<string>

=item accessionNumberVersion

data type: C<string>

=item bigid

data type: C<string>

=item id

data type: C<long>

=item length

data type: C<long>

=item type

data type: C<string>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of NucleicAcidSequence

The following are all the objects that are associated with the NucleicAcidSequence:

=over 4

=item Collection of L</CloneRelativeLocation>:

Many to one assoication, use C<getCloneRelativeLocation> to get the associated CloneRelativeLocation.

=item Instance of L</DatabaseCrossReference>:

One to many assoication, use C<getDatabaseCrossReferenceCollection> to get a collection of associated DatabaseCrossReference.

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</Location>:

One to many assoication, use C<getLocationCollection> to get a collection of associated Location.


=back

=cut

# Below is module documentation for OrganOntology

=pod

=head1 OrganOntology

CaCORE::CaBIO::OrganOntology - Perl extension for OrganOntology.

=head2 ABSTRACT

The CaCORE::CaBIO::OrganOntology is a Perl object representation of the
CaCORE OrganOntology object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of OrganOntology

The following are all the attributes of the OrganOntology object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of OrganOntology

The following are all the objects that are associated with the OrganOntology:

=over 4

=item Instance of L</Anomaly>:

One to many assoication, use C<getAnomalyCollection> to get a collection of associated Anomaly.

=item Instance of L</ChildOrganOntologyRelationship>:

One to many assoication, use C<getChildOrganOntologyRelationshipCollection> to get a collection of associated ChildOrganOntologyRelationship.

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</Histopathology>:

One to many assoication, use C<getHistopathologyCollection> to get a collection of associated Histopathology.

=item Instance of L</ParentOrganOntologyRelationship>:

One to many assoication, use C<getParentOrganOntologyRelationshipCollection> to get a collection of associated ParentOrganOntologyRelationship.


=back

=cut

# Below is module documentation for OrganOntologyRelationship

=pod

=head1 OrganOntologyRelationship

CaCORE::CaBIO::OrganOntologyRelationship - Perl extension for OrganOntologyRelationship.

=head2 ABSTRACT

The CaCORE::CaBIO::OrganOntologyRelationship is a Perl object representation of the
CaCORE OrganOntologyRelationship object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of OrganOntologyRelationship

The following are all the attributes of the OrganOntologyRelationship object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of OrganOntologyRelationship

The following are all the objects that are associated with the OrganOntologyRelationship:

=over 4

=item Collection of L</ChildOrganOntology>:

Many to one assoication, use C<getChildOrganOntology> to get the associated ChildOrganOntology.

=item Collection of L</ParentOrganOntology>:

Many to one assoication, use C<getParentOrganOntology> to get the associated ParentOrganOntology.


=back

=cut

# Below is module documentation for Pathway

=pod

=head1 Pathway

CaCORE::CaBIO::Pathway - Perl extension for Pathway.

=head2 ABSTRACT

The CaCORE::CaBIO::Pathway is a Perl object representation of the
CaCORE Pathway object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Pathway

The following are all the attributes of the Pathway object and their data types:

=over 4

=item bigid

data type: C<string>

=item description

data type: C<string>

=item diagram

data type: C<string>

=item displayValue

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Pathway

The following are all the objects that are associated with the Pathway:

=over 4

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</Histopathology>:

One to many assoication, use C<getHistopathologyCollection> to get a collection of associated Histopathology.

=item Collection of L</Taxon>:

Many to one assoication, use C<getTaxon> to get the associated Taxon.


=back

=cut

# Below is module documentation for PhysicalLocation

=pod

=head1 PhysicalLocation

CaCORE::CaBIO::PhysicalLocation - Perl extension for PhysicalLocation.

=head2 ABSTRACT

The CaCORE::CaBIO::PhysicalLocation is a Perl object representation of the
CaCORE PhysicalLocation object.

PhysicalLocation extends from domain object L<"Location">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of PhysicalLocation

The following are all the attributes of the PhysicalLocation object and their data types:

=over 4

=item chromosomalEndPosition

data type: C<long>

=item chromosomalStartPosition

data type: C<long>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of PhysicalLocation

The following are all the objects that are associated with the PhysicalLocation:

=over 4

=item Instance of L</Cytoband>:

One to many assoication, use C<getCytobandCollection> to get a collection of associated Cytoband.


=back

=cut

# Below is module documentation for PopulationFrequency

=pod

=head1 PopulationFrequency

CaCORE::CaBIO::PopulationFrequency - Perl extension for PopulationFrequency.

=head2 ABSTRACT

The CaCORE::CaBIO::PopulationFrequency is a Perl object representation of the
CaCORE PopulationFrequency object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of PopulationFrequency

The following are all the attributes of the PopulationFrequency object and their data types:

=over 4

=item bigid

data type: C<string>

=item ethnicity

data type: C<string>

=item id

data type: C<long>

=item majorAllele

data type: C<string>

=item majorFrequency

data type: C<double>

=item minorAllele

data type: C<string>

=item minorFrequency

data type: C<double>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of PopulationFrequency

The following are all the objects that are associated with the PopulationFrequency:

=over 4

=item Collection of L</SNP>:

Many to one assoication, use C<getSNP> to get the associated SNP.


=back

=cut

# Below is module documentation for Protein

=pod

=head1 Protein

CaCORE::CaBIO::Protein - Perl extension for Protein.

=head2 ABSTRACT

The CaCORE::CaBIO::Protein is a Perl object representation of the
CaCORE Protein object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Protein

The following are all the attributes of the Protein object and their data types:

=over 4

=item bigid

data type: C<string>

=item copyrightStatement

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>

=item primaryAccession

data type: C<string>

=item uniProtCode

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Protein

The following are all the objects that are associated with the Protein:

=over 4

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</Keywords>:

One to many assoication, use C<getKeywordsCollection> to get a collection of associated Keywords.

=item Instance of L</ProteinAlias>:

One to many assoication, use C<getProteinAliasCollection> to get a collection of associated ProteinAlias.

=item Collection of L</ProteinSequence>:

Many to one assoication, use C<getProteinSequence> to get the associated ProteinSequence.

=item Instance of L</SecondaryAccession>:

One to many assoication, use C<getSecondaryAccessionCollection> to get a collection of associated SecondaryAccession.

=item Instance of L</Taxon>:

One to many assoication, use C<getTaxonCollection> to get a collection of associated Taxon.


=back

=cut

# Below is module documentation for ProteinAlias

=pod

=head1 ProteinAlias

CaCORE::CaBIO::ProteinAlias - Perl extension for ProteinAlias.

=head2 ABSTRACT

The CaCORE::CaBIO::ProteinAlias is a Perl object representation of the
CaCORE ProteinAlias object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ProteinAlias

The following are all the attributes of the ProteinAlias object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ProteinAlias

The following are all the objects that are associated with the ProteinAlias:

=over 4

=item Instance of L</Protein>:

One to many assoication, use C<getProteinCollection> to get a collection of associated Protein.


=back

=cut

# Below is module documentation for ProteinSequence

=pod

=head1 ProteinSequence

CaCORE::CaBIO::ProteinSequence - Perl extension for ProteinSequence.

=head2 ABSTRACT

The CaCORE::CaBIO::ProteinSequence is a Perl object representation of the
CaCORE ProteinSequence object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ProteinSequence

The following are all the attributes of the ProteinSequence object and their data types:

=over 4

=item bigid

data type: C<string>

=item checkSum

data type: C<string>

=item id

data type: C<long>

=item length

data type: C<long>

=item molecularWeightInDaltons

data type: C<double>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ProteinSequence

The following are all the objects that are associated with the ProteinSequence:

=over 4

=item Collection of L</Protein>:

Many to one assoication, use C<getProtein> to get the associated Protein.


=back

=cut

# Below is module documentation for Protocol

=pod

=head1 Protocol

CaCORE::CaBIO::Protocol - Perl extension for Protocol.

=head2 ABSTRACT

The CaCORE::CaBIO::Protocol is a Perl object representation of the
CaCORE Protocol object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Protocol

The following are all the attributes of the Protocol object and their data types:

=over 4

=item bigid

data type: C<string>

=item description

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Protocol

The following are all the objects that are associated with the Protocol:

=over 4

=item Instance of L</Library>:

One to many assoication, use C<getLibraryCollection> to get a collection of associated Library.

=item Instance of L</Tissue>:

One to many assoication, use C<getTissueCollection> to get a collection of associated Tissue.


=back

=cut

# Below is module documentation for ProtocolAssociation

=pod

=head1 ProtocolAssociation

CaCORE::CaBIO::ProtocolAssociation - Perl extension for ProtocolAssociation.

=head2 ABSTRACT

The CaCORE::CaBIO::ProtocolAssociation is a Perl object representation of the
CaCORE ProtocolAssociation object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ProtocolAssociation

The following are all the attributes of the ProtocolAssociation object and their data types:

=over 4

=item CTEPNAME

data type: C<string>

=item IMTCODE

data type: C<long>

=item bigid

data type: C<string>

=item diseaseCategory

data type: C<string>

=item diseaseSubCategory

data type: C<string>

=item id

data type: C<long>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ProtocolAssociation

The following are all the objects that are associated with the ProtocolAssociation:

=over 4

=item Collection of L</ClinicalTrialProtocol>:

Many to one assoication, use C<getClinicalTrialProtocol> to get the associated ClinicalTrialProtocol.

=item Collection of L</DiseaseOntology>:

Many to one assoication, use C<getDiseaseOntology> to get the associated DiseaseOntology.


=back

=cut

# Below is module documentation for SNP

=pod

=head1 SNP

CaCORE::CaBIO::SNP - Perl extension for SNP.

=head2 ABSTRACT

The CaCORE::CaBIO::SNP is a Perl object representation of the
CaCORE SNP object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of SNP

The following are all the attributes of the SNP object and their data types:

=over 4

=item DBSNPID

data type: C<string>

=item alleleA

data type: C<string>

=item alleleB

data type: C<string>

=item bigid

data type: C<string>

=item id

data type: C<long>

=item validationStatus

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of SNP

The following are all the objects that are associated with the SNP:

=over 4

=item Instance of L</DatabaseCrossReference>:

One to many assoication, use C<getDatabaseCrossReferenceCollection> to get a collection of associated DatabaseCrossReference.

=item Instance of L</GeneRelativeLocation>:

One to many assoication, use C<getGeneRelativeLocationCollection> to get a collection of associated GeneRelativeLocation.

=item Instance of L</Location>:

One to many assoication, use C<getLocationCollection> to get a collection of associated Location.

=item Instance of L</PopulationFrequency>:

One to many assoication, use C<getPopulationFrequencyCollection> to get a collection of associated PopulationFrequency.


=back

=cut

# Below is module documentation for Target

=pod

=head1 Target

CaCORE::CaBIO::Target - Perl extension for Target.

=head2 ABSTRACT

The CaCORE::CaBIO::Target is a Perl object representation of the
CaCORE Target object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Target

The following are all the attributes of the Target object and their data types:

=over 4

=item bigid

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Target

The following are all the objects that are associated with the Target:

=over 4

=item Instance of L</Agent>:

One to many assoication, use C<getAgentCollection> to get a collection of associated Agent.

=item Instance of L</Anomaly>:

One to many assoication, use C<getAnomalyCollection> to get a collection of associated Anomaly.

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.


=back

=cut

# Below is module documentation for Taxon

=pod

=head1 Taxon

CaCORE::CaBIO::Taxon - Perl extension for Taxon.

=head2 ABSTRACT

The CaCORE::CaBIO::Taxon is a Perl object representation of the
CaCORE Taxon object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Taxon

The following are all the attributes of the Taxon object and their data types:

=over 4

=item abbreviation

data type: C<string>

=item bigid

data type: C<string>

=item commonName

data type: C<string>

=item ethnicityStrain

data type: C<string>

=item id

data type: C<long>

=item scientificName

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Taxon

The following are all the objects that are associated with the Taxon:

=over 4

=item Instance of L</Chromosome>:

One to many assoication, use C<getChromosomeCollection> to get a collection of associated Chromosome.

=item Instance of L</Clone>:

One to many assoication, use C<getCloneCollection> to get a collection of associated Clone.

=item Instance of L</Gene>:

One to many assoication, use C<getGeneCollection> to get a collection of associated Gene.

=item Instance of L</Pathway>:

One to many assoication, use C<getPathwayCollection> to get a collection of associated Pathway.

=item Instance of L</Protein>:

One to many assoication, use C<getProteinCollection> to get a collection of associated Protein.

=item Instance of L</Tissue>:

One to many assoication, use C<getTissueCollection> to get a collection of associated Tissue.


=back

=cut

# Below is module documentation for Tissue

=pod

=head1 Tissue

CaCORE::CaBIO::Tissue - Perl extension for Tissue.

=head2 ABSTRACT

The CaCORE::CaBIO::Tissue is a Perl object representation of the
CaCORE Tissue object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Tissue

The following are all the attributes of the Tissue object and their data types:

=over 4

=item cellLine

data type: C<string>

=item cellType

data type: C<string>

=item description

data type: C<string>

=item developmentalStage

data type: C<string>

=item histology

data type: C<string>

=item id

data type: C<long>

=item name

data type: C<string>

=item organ

data type: C<string>

=item sex

data type: C<string>

=item supplier

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Tissue

The following are all the objects that are associated with the Tissue:

=over 4

=item Instance of L</Library>:

One to many assoication, use C<getLibraryCollection> to get a collection of associated Library.

=item Collection of L</Protocol>:

Many to one assoication, use C<getProtocol> to get the associated Protocol.

=item Collection of L</Taxon>:

Many to one assoication, use C<getTaxon> to get the associated Taxon.


=back

=cut

# Below is module documentation for Vocabulary

=pod

=head1 Vocabulary

CaCORE::CaBIO::Vocabulary - Perl extension for Vocabulary.

=head2 ABSTRACT

The CaCORE::CaBIO::Vocabulary is a Perl object representation of the
CaCORE Vocabulary object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Vocabulary

The following are all the attributes of the Vocabulary object and their data types:

=over 4

=item bigid

data type: C<string>

=item coreTerm

data type: C<string>

=item generalTerm

data type: C<string>

=item id

data type: C<long>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Vocabulary

The following are all the objects that are associated with the Vocabulary:

=over 4

=item Instance of L</Anomaly>:

One to many assoication, use C<getAnomalyCollection> to get a collection of associated Anomaly.


=back

=cut


=pod

=head1 SUPPORT

Please do not contact author directly. Send email to ncicb@pop.nci.nih.gov to request
support or report a bug.

=head1 AUTHOR

Shan Jiang <jiangs@mail.nih.gov>

=head1 COPYRIGHT AND LICENSE

The CaCORE Software License, Version 1.0

Copyright 2001-2005 SAIC. This software was developed in conjunction with the National Cancer Institute, and so to the extent government employees are co-authors, any rights in such works shall be subject to Title 17 of the United States Code, section 105. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

=over 1

=item 1

Redistributions of source code must retain the above copyright notice, this list of conditions and the disclaimer of Article 5, below. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the disclaimer of Article 5 in the documentation and/or other materials provided with the distribution.

=item 2

The end-user documentation included with the redistribution, if any, must include the following acknowledgment: "This product includes software developed by SAIC and the National Cancer Institute." If no such end-user documentation is to be included, this acknowledgment shall appear in the software itself, wherever such third-party acknowledgments normally appear.

=item 3

The names "The National Cancer Institute", "NCI" and "SAIC" must not be used to endorse or promote products derived from this software. This license does not authorize the licensee to use any trademarks owned by either NCI or SAIC.

=item 4

This license does not authorize or prohibit the incorporation of this software into any third party proprietary programs. Licensee is expressly made responsible for obtaining any permission required to incorporate this software into third party proprietary programs and for informing licensee's end-users of their obligation to secure any required permissions before incorporating this software into third party proprietary software programs.

=item 5

THIS SOFTWARE IS PROVIDED "AS IS," AND ANY EXPRESSED OR IMPLIED WARRANTIES, (INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE) ARE DISCLAIMED. IN NO EVENT SHALL THE NATIONAL CANCER INSTITUTE, SAIC, OR THEIR AFFILIATES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=back

=cut


