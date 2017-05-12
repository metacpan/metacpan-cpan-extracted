# ------------------------------------------------------------------------------------------
package CaCORE::EVS::HashSet;

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

# create an instance of the HashSet object
# returns: a HashSet object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new HashSet\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this HashSet intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":HashSet\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of HashSet objects
# param: xml doc
# returns: list of HashSet objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of HashSet objects
# param: xml node
# returns: a list of HashSet objects
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

# parse a given xml node, construct one HashSet object
# param: xml node
# returns: one HashSet object
sub fromWSXMLNode {
	my $HashSetNode = $_[1];
	
	## begin ELEMENT_NODE children ##
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($HashSetNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::HashSet;
	## begin set attr ##
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

## end getters and setters ##

## begin bean association methods ##

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::EdgeProperties;

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

# create an instance of the EdgeProperties object
# returns: a EdgeProperties object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new EdgeProperties\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this EdgeProperties intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":EdgeProperties\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# isA;
	if( defined( $self->getIsA ) ) {
		$tmpstr = "<isA xsi:type=\"xsd:boolean\">" . $self->getIsA . "</isA>";
	} else {
		$tmpstr = "<isA xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# traverseDown;
	if( defined( $self->getTraverseDown ) ) {
		$tmpstr = "<traverseDown xsi:type=\"xsd:boolean\">" . $self->getTraverseDown . "</traverseDown>";
	} else {
		$tmpstr = "<traverseDown xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# LinksCollection;
	if( defined( $self->getLinksCollection ) ) {
		my @assoclist = $self->getLinksCollection;
		if( $#assoclist >= 0 ) {
			$result .= "<linksCollection>";
			foreach my $node ($self->getLinksCollection) {
				$result .= "<linksCollection xsi:type=\"xsd:string\"> . $node . </linksCollection>";
			}
			$result .= "</linksCollection>";
		}
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of EdgeProperties objects
# param: xml doc
# returns: list of EdgeProperties objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of EdgeProperties objects
# param: xml node
# returns: a list of EdgeProperties objects
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

# parse a given xml node, construct one EdgeProperties object
# param: xml node
# returns: one EdgeProperties object
sub fromWSXMLNode {
	my $EdgePropertiesNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $isA;
		my $name;
		my $traverseDown;
		my @links = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($EdgePropertiesNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "isA") {
				$isA=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "traverseDown") {
				$traverseDown=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "links") {
				for my $node ($childrenNode->getChildNodes) {
					if( $node->getNodeName eq "empty" ){ next; };
					if( ! defined($node->getFirstChild) ){ next; };
					my $txnode = $node->getFirstChild;
					push @links, $txnode->getNodeValue;
				}
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::EdgeProperties;
	## begin set attr ##
		$newobj->setIsA($isA);
		$newobj->setName($name);
		$newobj->setTraverseDown($traverseDown);
		$newobj->setLinksCollection(@links);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getIsA {
	my $self = shift;
	return $self->{isA};
}

sub setIsA {
	my $self = shift;
	$self->{isA} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getTraverseDown {
	my $self = shift;
	return $self->{traverseDown};
}

sub setTraverseDown {
	my $self = shift;
	$self->{traverseDown} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getLinksCollection {
	my $self = shift;
	if( defined($self->{links}) ) {
		return @{$self->{links}};
	} else {
		return ();
	}
}

sub setLinksCollection {
	my ($self, @set) = @_;
	push @{$self->{links}}, @set;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::TreeNode;

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

# create an instance of the TreeNode object
# returns: a TreeNode object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new TreeNode\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this TreeNode intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":TreeNode\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# isA;
	if( defined( $self->getIsA ) ) {
		$tmpstr = "<isA xsi:type=\"xsd:boolean\">" . $self->getIsA . "</isA>";
	} else {
		$tmpstr = "<isA xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# traverseDown;
	if( defined( $self->getTraverseDown ) ) {
		$tmpstr = "<traverseDown xsi:type=\"xsd:boolean\">" . $self->getTraverseDown . "</traverseDown>";
	} else {
		$tmpstr = "<traverseDown xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# LinksCollection;
	if( defined( $self->getLinksCollection ) ) {
		my @assoclist = $self->getLinksCollection;
		if( $#assoclist >= 0 ) {
			$result .= "<linksCollection>";
			foreach my $node ($self->getLinksCollection) {
				$result .= "<linksCollection xsi:type=\"xsd:string\"> . $node . </linksCollection>";
			}
			$result .= "</linksCollection>";
		}
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of TreeNode objects
# param: xml doc
# returns: list of TreeNode objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of TreeNode objects
# param: xml node
# returns: a list of TreeNode objects
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

# parse a given xml node, construct one TreeNode object
# param: xml node
# returns: one TreeNode object
sub fromWSXMLNode {
	my $TreeNodeNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $isA;
		my $name;
		my $traverseDown;
		my @links = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($TreeNodeNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "isA") {
				$isA=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "traverseDown") {
				$traverseDown=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "links") {
				for my $node ($childrenNode->getChildNodes) {
					if( $node->getNodeName eq "empty" ){ next; };
					if( ! defined($node->getFirstChild) ){ next; };
					my $txnode = $node->getFirstChild;
					push @links, $txnode->getNodeValue;
				}
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::TreeNode;
	## begin set attr ##
		$newobj->setIsA($isA);
		$newobj->setName($name);
		$newobj->setTraverseDown($traverseDown);
		$newobj->setLinksCollection(@links);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getIsA {
	my $self = shift;
	return $self->{isA};
}

sub setIsA {
	my $self = shift;
	$self->{isA} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getTraverseDown {
	my $self = shift;
	return $self->{traverseDown};
}

sub setTraverseDown {
	my $self = shift;
	$self->{traverseDown} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getLinksCollection {
	my $self = shift;
	if( defined($self->{links}) ) {
		return @{$self->{links}};
	} else {
		return ();
	}
}

sub setLinksCollection {
	my ($self, @set) = @_;
	push @{$self->{links}}, @set;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Vocabulary;

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
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Vocabulary\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# description;
	if( defined( $self->getDescription ) ) {
		$tmpstr = "<description xsi:type=\"xsd:string\">" . $self->getDescription . "</description>";
	} else {
		$tmpstr = "<description xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# namespaceId;
	if( defined( $self->getNamespaceId ) ) {
		$tmpstr = "<namespaceId xsi:type=\"xsd:int\">" . $self->getNamespaceId . "</namespaceId>";
	} else {
		$tmpstr = "<namespaceId xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# SecurityToken;
	if( defined( $self->getSecurityToken ) ) {
		$result .= "<securityToken href=\"\#id" . $current_id . "\"/>";
		$worklist{$current_id} = $self->getSecurityToken;
		$current_id ++;
	}
	# SiloCollection;
	if( defined( $self->getSiloCollection ) ) {
		my @assoclist = $self->getSiloCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<siloCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getSiloCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</siloCollection>";
	}
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
		my $description;
		my $name;
		my $namespaceId;
		my $securityToken;
		my @silo = ();
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
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "namespaceId") {
				$namespaceId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "securityToken") {
				my $doi = new CaCORE::EVS::SecurityToken;
				$securityToken=$doi->fromWSXMLNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "siloCollection") {
				my $doi = new CaCORE::EVS::Silo;
				@silo=$doi->fromWSXMLListNode($childrenNode);
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Vocabulary;
	## begin set attr ##
		$newobj->setDescription($description);
		$newobj->setName($name);
		$newobj->setNamespaceId($namespaceId);
		$newobj->setSecurityToken($securityToken);
		$newobj->setSiloCollection(@silo);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDescription {
	my $self = shift;
	return $self->{description};
}

sub setDescription {
	my $self = shift;
	$self->{description} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getNamespaceId {
	my $self = shift;
	return $self->{namespaceId};
}

sub setNamespaceId {
	my $self = shift;
	$self->{namespaceId} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getSecurityToken {
	my $self = shift;
	return $self->{securityToken};
}

sub setSecurityToken {
	my $self = shift;
	$self->{securityToken} = shift;
}

sub getSiloCollection {
	my $self = shift;
	if( defined($self->{silo}) ) {
		return @{$self->{silo}};
	} else {
		return ();
	}
}

sub setSiloCollection {
	my ($self, @set) = @_;
	push @{$self->{silo}}, @set;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::DescLogicConcept;

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

# create an instance of the DescLogicConcept object
# returns: a DescLogicConcept object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DescLogicConcept\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DescLogicConcept intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DescLogicConcept\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# code;
	if( defined( $self->getCode ) ) {
		$tmpstr = "<code xsi:type=\"xsd:string\">" . $self->getCode . "</code>";
	} else {
		$tmpstr = "<code xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# hasChildren;
	if( defined( $self->getHasChildren ) ) {
		$tmpstr = "<hasChildren xsi:type=\"xsd:boolean\">" . $self->getHasChildren . "</hasChildren>";
	} else {
		$tmpstr = "<hasChildren xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# hasParents;
	if( defined( $self->getHasParents ) ) {
		$tmpstr = "<hasParents xsi:type=\"xsd:boolean\">" . $self->getHasParents . "</hasParents>";
	} else {
		$tmpstr = "<hasParents xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# isRetired;
	if( defined( $self->getIsRetired ) ) {
		$tmpstr = "<isRetired xsi:type=\"xsd:boolean\">" . $self->getIsRetired . "</isRetired>";
	} else {
		$tmpstr = "<isRetired xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# namespaceId;
	if( defined( $self->getNamespaceId ) ) {
		$tmpstr = "<namespaceId xsi:type=\"xsd:int\">" . $self->getNamespaceId . "</namespaceId>";
	} else {
		$tmpstr = "<namespaceId xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# vocabularyName;
	if( defined( $self->getVocabularyName ) ) {
		$tmpstr = "<vocabularyName xsi:type=\"xsd:string\">" . $self->getVocabularyName . "</vocabularyName>";
	} else {
		$tmpstr = "<vocabularyName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# AssociationCollection;
	if( defined( $self->getAssociationCollection ) ) {
		my @assoclist = $self->getAssociationCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<associationCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getAssociationCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</associationCollection>";
	}
	# EdgeProperties;
	if( defined( $self->getEdgeProperties ) ) {
		$result .= "<edgeProperties href=\"\#id" . $current_id . "\"/>";
		$worklist{$current_id} = $self->getEdgeProperties;
		$current_id ++;
	}
	# InverseAssociationCollection;
	if( defined( $self->getInverseAssociationCollection ) ) {
		my @assoclist = $self->getInverseAssociationCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<inverseAssociationCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getInverseAssociationCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</inverseAssociationCollection>";
	}
	# InverseRoleCollection;
	if( defined( $self->getInverseRoleCollection ) ) {
		my @assoclist = $self->getInverseRoleCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<inverseRoleCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getInverseRoleCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</inverseRoleCollection>";
	}
	# PropertyCollection;
	if( defined( $self->getPropertyCollection ) ) {
		my @assoclist = $self->getPropertyCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<propertyCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getPropertyCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</propertyCollection>";
	}
	# RoleCollection;
	if( defined( $self->getRoleCollection ) ) {
		my @assoclist = $self->getRoleCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<roleCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getRoleCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</roleCollection>";
	}
	# SemanticTypeVectorCollection;
	if( defined( $self->getSemanticTypeVectorCollection ) ) {
		my @assoclist = $self->getSemanticTypeVectorCollection;
		if( $#assoclist >= 0 ) {
			$result .= "<semanticTypeVectorCollection>";
			foreach my $node ($self->getSemanticTypeVectorCollection) {
				$result .= "<semanticTypeVectorCollection xsi:type=\"xsd:string\"> . $node . </semanticTypeVectorCollection>";
			}
			$result .= "</semanticTypeVectorCollection>";
		}
	}
	# TreeNode;
	if( defined( $self->getTreeNode ) ) {
		$result .= "<treeNode href=\"\#id" . $current_id . "\"/>";
		$worklist{$current_id} = $self->getTreeNode;
		$current_id ++;
	}
	# Vocabulary;
	if( defined( $self->getVocabulary ) ) {
		$result .= "<vocabulary href=\"\#id" . $current_id . "\"/>";
		$worklist{$current_id} = $self->getVocabulary;
		$current_id ++;
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DescLogicConcept objects
# param: xml doc
# returns: list of DescLogicConcept objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DescLogicConcept objects
# param: xml node
# returns: a list of DescLogicConcept objects
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

# parse a given xml node, construct one DescLogicConcept object
# param: xml node
# returns: one DescLogicConcept object
sub fromWSXMLNode {
	my $DescLogicConceptNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $code;
		my $hasChildren;
		my $hasParents;
		my $isRetired;
		my $name;
		my $namespaceId;
		my $vocabularyName;
		my @association = ();
		my $edgeProperties;
		my @inverseAssociation = ();
		my @inverseRole = ();
		my @property = ();
		my @role = ();
		my @semanticTypeVector = ();
		my $treeNode;
		my $vocabulary;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DescLogicConceptNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "code") {
				$code=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "hasChildren") {
				$hasChildren=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "hasParents") {
				$hasParents=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "isRetired") {
				$isRetired=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "namespaceId") {
				$namespaceId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "vocabularyName") {
				$vocabularyName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "associationCollection") {
				my $doi = new CaCORE::EVS::Association;
				@association=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "edgeProperties") {
				my $doi = new CaCORE::EVS::EdgeProperties;
				$edgeProperties=$doi->fromWSXMLNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "inverseAssociationCollection") {
				my $doi = new CaCORE::EVS::Association;
				@inverseAssociation=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "inverseRoleCollection") {
				my $doi = new CaCORE::EVS::Role;
				@inverseRole=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "propertyCollection") {
				my $doi = new CaCORE::EVS::Property;
				@property=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "roleCollection") {
				my $doi = new CaCORE::EVS::Role;
				@role=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "semanticTypeVector") {
				for my $node ($childrenNode->getChildNodes) {
					if( $node->getNodeName eq "empty" ){ next; };
					if( ! defined($node->getFirstChild) ){ next; };
					my $txnode = $node->getFirstChild;
					push @semanticTypeVector, $txnode->getNodeValue;
				}
			}
			elsif ($childrenNode->getNodeName eq "treeNode") {
				my $doi = new CaCORE::EVS::TreeNode;
				$treeNode=$doi->fromWSXMLNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "vocabulary") {
				my $doi = new CaCORE::EVS::Vocabulary;
				$vocabulary=$doi->fromWSXMLNode($childrenNode);
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::DescLogicConcept;
	## begin set attr ##
		$newobj->setCode($code);
		$newobj->setHasChildren($hasChildren);
		$newobj->setHasParents($hasParents);
		$newobj->setIsRetired($isRetired);
		$newobj->setName($name);
		$newobj->setNamespaceId($namespaceId);
		$newobj->setVocabularyName($vocabularyName);
		$newobj->setAssociationCollection(@association);
		$newobj->setEdgeProperties($edgeProperties);
		$newobj->setInverseAssociationCollection(@inverseAssociation);
		$newobj->setInverseRoleCollection(@inverseRole);
		$newobj->setPropertyCollection(@property);
		$newobj->setRoleCollection(@role);
		$newobj->setSemanticTypeVectorCollection(@semanticTypeVector);
		$newobj->setTreeNode($treeNode);
		$newobj->setVocabulary($vocabulary);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCode {
	my $self = shift;
	return $self->{code};
}

sub setCode {
	my $self = shift;
	$self->{code} = shift;
}

sub getHasChildren {
	my $self = shift;
	return $self->{hasChildren};
}

sub setHasChildren {
	my $self = shift;
	$self->{hasChildren} = shift;
}

sub getHasParents {
	my $self = shift;
	return $self->{hasParents};
}

sub setHasParents {
	my $self = shift;
	$self->{hasParents} = shift;
}

sub getIsRetired {
	my $self = shift;
	return $self->{isRetired};
}

sub setIsRetired {
	my $self = shift;
	$self->{isRetired} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getNamespaceId {
	my $self = shift;
	return $self->{namespaceId};
}

sub setNamespaceId {
	my $self = shift;
	$self->{namespaceId} = shift;
}

sub getVocabularyName {
	my $self = shift;
	return $self->{vocabularyName};
}

sub setVocabularyName {
	my $self = shift;
	$self->{vocabularyName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAssociationCollection {
	my $self = shift;
	if( defined($self->{association}) ) {
		return @{$self->{association}};
	} else {
		return ();
	}
}

sub setAssociationCollection {
	my ($self, @set) = @_;
	push @{$self->{association}}, @set;
}

sub getEdgeProperties {
	my $self = shift;
	return $self->{edgeProperties};
}

sub setEdgeProperties {
	my $self = shift;
	$self->{edgeProperties} = shift;
}

sub getInverseAssociationCollection {
	my $self = shift;
	if( defined($self->{inverseAssociation}) ) {
		return @{$self->{inverseAssociation}};
	} else {
		return ();
	}
}

sub setInverseAssociationCollection {
	my ($self, @set) = @_;
	push @{$self->{inverseAssociation}}, @set;
}

sub getInverseRoleCollection {
	my $self = shift;
	if( defined($self->{inverseRole}) ) {
		return @{$self->{inverseRole}};
	} else {
		return ();
	}
}

sub setInverseRoleCollection {
	my ($self, @set) = @_;
	push @{$self->{inverseRole}}, @set;
}

sub getPropertyCollection {
	my $self = shift;
	if( defined($self->{property}) ) {
		return @{$self->{property}};
	} else {
		return ();
	}
}

sub setPropertyCollection {
	my ($self, @set) = @_;
	push @{$self->{property}}, @set;
}

sub getRoleCollection {
	my $self = shift;
	if( defined($self->{role}) ) {
		return @{$self->{role}};
	} else {
		return ();
	}
}

sub setRoleCollection {
	my ($self, @set) = @_;
	push @{$self->{role}}, @set;
}

sub getSemanticTypeVectorCollection {
	my $self = shift;
	if( defined($self->{semanticTypeVector}) ) {
		return @{$self->{semanticTypeVector}};
	} else {
		return ();
	}
}

sub setSemanticTypeVectorCollection {
	my ($self, @set) = @_;
	push @{$self->{semanticTypeVector}}, @set;
}

sub getTreeNode {
	my $self = shift;
	return $self->{treeNode};
}

sub setTreeNode {
	my $self = shift;
	$self->{treeNode} = shift;
}

sub getVocabulary {
	my $self = shift;
	return $self->{vocabulary};
}

sub setVocabulary {
	my $self = shift;
	$self->{vocabulary} = shift;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Silo;

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

# create an instance of the Silo object
# returns: a Silo object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Silo\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Silo intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Silo\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:int\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of Silo objects
# param: xml doc
# returns: list of Silo objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Silo objects
# param: xml node
# returns: a list of Silo objects
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

# parse a given xml node, construct one Silo object
# param: xml node
# returns: one Silo object
sub fromWSXMLNode {
	my $SiloNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($SiloNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Silo;
	## begin set attr ##
		$newobj->setId($id);
		$newobj->setName($name);
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

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::SemanticType;

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

# create an instance of the SemanticType object
# returns: a SemanticType object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new SemanticType\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this SemanticType intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":SemanticType\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of SemanticType objects
# param: xml doc
# returns: list of SemanticType objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of SemanticType objects
# param: xml node
# returns: a list of SemanticType objects
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

# parse a given xml node, construct one SemanticType object
# param: xml node
# returns: one SemanticType object
sub fromWSXMLNode {
	my $SemanticTypeNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($SemanticTypeNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::SemanticType;
	## begin set attr ##
		$newobj->setId($id);
		$newobj->setName($name);
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

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::MetaThesaurusConcept;

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

# create an instance of the MetaThesaurusConcept object
# returns: a MetaThesaurusConcept object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new MetaThesaurusConcept\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this MetaThesaurusConcept intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":MetaThesaurusConcept\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# cui;
	if( defined( $self->getCui ) ) {
		$tmpstr = "<cui xsi:type=\"xsd:string\">" . $self->getCui . "</cui>";
	} else {
		$tmpstr = "<cui xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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
	# AtomCollection;
	if( defined( $self->getAtomCollection ) ) {
		my @assoclist = $self->getAtomCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<atomCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getAtomCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</atomCollection>";
	}
	# DefinitionCollection;
	if( defined( $self->getDefinitionCollection ) ) {
		my @assoclist = $self->getDefinitionCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<definitionCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getDefinitionCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</definitionCollection>";
	}
	# SemanticTypeCollection;
	if( defined( $self->getSemanticTypeCollection ) ) {
		my @assoclist = $self->getSemanticTypeCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<semanticTypeCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getSemanticTypeCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</semanticTypeCollection>";
	}
	# SourceCollection;
	if( defined( $self->getSourceCollection ) ) {
		my @assoclist = $self->getSourceCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<sourceCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getSourceCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</sourceCollection>";
	}
	# SynonymCollection;
	if( defined( $self->getSynonymCollection ) ) {
		my @assoclist = $self->getSynonymCollection;
		if( $#assoclist >= 0 ) {
			$result .= "<synonymCollection>";
			foreach my $node ($self->getSynonymCollection) {
				$result .= "<synonymCollection xsi:type=\"xsd:string\"> . $node . </synonymCollection>";
			}
			$result .= "</synonymCollection>";
		}
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of MetaThesaurusConcept objects
# param: xml doc
# returns: list of MetaThesaurusConcept objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of MetaThesaurusConcept objects
# param: xml node
# returns: a list of MetaThesaurusConcept objects
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

# parse a given xml node, construct one MetaThesaurusConcept object
# param: xml node
# returns: one MetaThesaurusConcept object
sub fromWSXMLNode {
	my $MetaThesaurusConceptNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $cui;
		my $name;
		my @atom = ();
		my @definition = ();
		my @semanticType = ();
		my @source = ();
		my @synonym = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($MetaThesaurusConceptNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "cui") {
				$cui=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "atomCollection") {
				my $doi = new CaCORE::EVS::Atom;
				@atom=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "definitionCollection") {
				my $doi = new CaCORE::EVS::Definition;
				@definition=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "semanticTypeCollection") {
				my $doi = new CaCORE::EVS::SemanticType;
				@semanticType=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "sourceCollection") {
				my $doi = new CaCORE::EVS::Source;
				@source=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "synonymCollection") {
				for my $node ($childrenNode->getChildNodes) {
					if( $node->getNodeName eq "empty" ){ next; };
					if( ! defined($node->getFirstChild) ){ next; };
					my $txnode = $node->getFirstChild;
					push @synonym, $txnode->getNodeValue;
				}
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::MetaThesaurusConcept;
	## begin set attr ##
		$newobj->setCui($cui);
		$newobj->setName($name);
		$newobj->setAtomCollection(@atom);
		$newobj->setDefinitionCollection(@definition);
		$newobj->setSemanticTypeCollection(@semanticType);
		$newobj->setSourceCollection(@source);
		$newobj->setSynonymCollection(@synonym);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCui {
	my $self = shift;
	return $self->{cui};
}

sub setCui {
	my $self = shift;
	$self->{cui} = shift;
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

sub getAtomCollection {
	my $self = shift;
	if( defined($self->{atom}) ) {
		return @{$self->{atom}};
	} else {
		return ();
	}
}

sub setAtomCollection {
	my ($self, @set) = @_;
	push @{$self->{atom}}, @set;
}

sub getDefinitionCollection {
	my $self = shift;
	if( defined($self->{definition}) ) {
		return @{$self->{definition}};
	} else {
		return ();
	}
}

sub setDefinitionCollection {
	my ($self, @set) = @_;
	push @{$self->{definition}}, @set;
}

sub getSemanticTypeCollection {
	my $self = shift;
	if( defined($self->{semanticType}) ) {
		return @{$self->{semanticType}};
	} else {
		return ();
	}
}

sub setSemanticTypeCollection {
	my ($self, @set) = @_;
	push @{$self->{semanticType}}, @set;
}

sub getSourceCollection {
	my $self = shift;
	if( defined($self->{source}) ) {
		return @{$self->{source}};
	} else {
		return ();
	}
}

sub setSourceCollection {
	my ($self, @set) = @_;
	push @{$self->{source}}, @set;
}

sub getSynonymCollection {
	my $self = shift;
	if( defined($self->{synonym}) ) {
		return @{$self->{synonym}};
	} else {
		return ();
	}
}

sub setSynonymCollection {
	my ($self, @set) = @_;
	push @{$self->{synonym}}, @set;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::AttributeSetDescriptor;

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

# create an instance of the AttributeSetDescriptor object
# returns: a AttributeSetDescriptor object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new AttributeSetDescriptor\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this AttributeSetDescriptor intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":AttributeSetDescriptor\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# PropertyCollection;
	if( defined( $self->getPropertyCollection ) ) {
		my @assoclist = $self->getPropertyCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<propertyCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getPropertyCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</propertyCollection>";
	}
	# RoleCollection;
	if( defined( $self->getRoleCollection ) ) {
		my @assoclist = $self->getRoleCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<roleCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getRoleCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</roleCollection>";
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of AttributeSetDescriptor objects
# param: xml doc
# returns: list of AttributeSetDescriptor objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of AttributeSetDescriptor objects
# param: xml node
# returns: a list of AttributeSetDescriptor objects
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

# parse a given xml node, construct one AttributeSetDescriptor object
# param: xml node
# returns: one AttributeSetDescriptor object
sub fromWSXMLNode {
	my $AttributeSetDescriptorNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $name;
		my @property = ();
		my @role = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AttributeSetDescriptorNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "propertyCollection") {
				my $doi = new CaCORE::EVS::Property;
				@property=$doi->fromWSXMLListNode($childrenNode);
			}
			elsif ($childrenNode->getNodeName eq "roleCollection") {
				my $doi = new CaCORE::EVS::Role;
				@role=$doi->fromWSXMLListNode($childrenNode);
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::AttributeSetDescriptor;
	## begin set attr ##
		$newobj->setName($name);
		$newobj->setPropertyCollection(@property);
		$newobj->setRoleCollection(@role);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

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

sub getPropertyCollection {
	my $self = shift;
	if( defined($self->{property}) ) {
		return @{$self->{property}};
	} else {
		return ();
	}
}

sub setPropertyCollection {
	my ($self, @set) = @_;
	push @{$self->{property}}, @set;
}

sub getRoleCollection {
	my $self = shift;
	if( defined($self->{role}) ) {
		return @{$self->{role}};
	} else {
		return ();
	}
}

sub setRoleCollection {
	my ($self, @set) = @_;
	push @{$self->{role}}, @set;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Source;

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

# create an instance of the Source object
# returns: a Source object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Source\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Source intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Source\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
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

	# code;
	if( defined( $self->getCode ) ) {
		$tmpstr = "<code xsi:type=\"xsd:string\">" . $self->getCode . "</code>";
	} else {
		$tmpstr = "<code xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# description;
	if( defined( $self->getDescription ) ) {
		$tmpstr = "<description xsi:type=\"xsd:string\">" . $self->getDescription . "</description>";
	} else {
		$tmpstr = "<description xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Source objects
# param: xml doc
# returns: list of Source objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Source objects
# param: xml node
# returns: a list of Source objects
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

# parse a given xml node, construct one Source object
# param: xml node
# returns: one Source object
sub fromWSXMLNode {
	my $SourceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $abbreviation;
		my $code;
		my $description;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($SourceNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "code") {
				$code=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Source;
	## begin set attr ##
		$newobj->setAbbreviation($abbreviation);
		$newobj->setCode($code);
		$newobj->setDescription($description);
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

sub getCode {
	my $self = shift;
	return $self->{code};
}

sub setCode {
	my $self = shift;
	$self->{code} = shift;
}

sub getDescription {
	my $self = shift;
	return $self->{description};
}

sub setDescription {
	my $self = shift;
	$self->{description} = shift;
}

## end getters and setters ##

## begin bean association methods ##

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Definition;

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

# create an instance of the Definition object
# returns: a Definition object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Definition\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Definition intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Definition\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# definition;
	if( defined( $self->getDefinition ) ) {
		$tmpstr = "<definition xsi:type=\"xsd:string\">" . $self->getDefinition . "</definition>";
	} else {
		$tmpstr = "<definition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# Source;
	if( defined( $self->getSource ) ) {
		$result .= "<source href=\"\#id" . $current_id . "\"/>";
		$worklist{$current_id} = $self->getSource;
		$current_id ++;
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Definition objects
# param: xml doc
# returns: list of Definition objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Definition objects
# param: xml node
# returns: a list of Definition objects
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

# parse a given xml node, construct one Definition object
# param: xml node
# returns: one Definition object
sub fromWSXMLNode {
	my $DefinitionNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $definition;
		my $source;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DefinitionNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "definition") {
				$definition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "source") {
				my $doi = new CaCORE::EVS::Source;
				$source=$doi->fromWSXMLNode($childrenNode);
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Definition;
	## begin set attr ##
		$newobj->setDefinition($definition);
		$newobj->setSource($source);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDefinition {
	my $self = shift;
	return $self->{definition};
}

sub setDefinition {
	my $self = shift;
	$self->{definition} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getSource {
	my $self = shift;
	return $self->{source};
}

sub setSource {
	my $self = shift;
	$self->{source} = shift;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Property;

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

# create an instance of the Property object
# returns: a Property object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Property\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Property intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Property\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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
	# QualifierCollection;
	if( defined( $self->getQualifierCollection ) ) {
		my @assoclist = $self->getQualifierCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<qualifierCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getQualifierCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</qualifierCollection>";
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Property objects
# param: xml doc
# returns: list of Property objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Property objects
# param: xml node
# returns: a list of Property objects
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

# parse a given xml node, construct one Property object
# param: xml node
# returns: one Property object
sub fromWSXMLNode {
	my $PropertyNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $name;
		my $value;
		my @qualifier = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($PropertyNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "value") {
				$value=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "qualifierCollection") {
				my $doi = new CaCORE::EVS::Qualifier;
				@qualifier=$doi->fromWSXMLListNode($childrenNode);
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Property;
	## begin set attr ##
		$newobj->setName($name);
		$newobj->setValue($value);
		$newobj->setQualifierCollection(@qualifier);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
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

sub getQualifierCollection {
	my $self = shift;
	if( defined($self->{qualifier}) ) {
		return @{$self->{qualifier}};
	} else {
		return ();
	}
}

sub setQualifierCollection {
	my ($self, @set) = @_;
	push @{$self->{qualifier}}, @set;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::History;

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

# create an instance of the History object
# returns: a History object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new History\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this History intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":History\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# editAction;
	if( defined( $self->getEditAction ) ) {
		$tmpstr = "<editAction xsi:type=\"xsd:string\">" . $self->getEditAction . "</editAction>";
	} else {
		$tmpstr = "<editAction xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# editActionDate;
	if( defined( $self->getEditActionDate ) ) {
		$tmpstr = "<editActionDate xsi:type=\"xsd:dateTime\">" . $self->getEditActionDate . "</editActionDate>";
	} else {
		$tmpstr = "<editActionDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# namespaceId;
	if( defined( $self->getNamespaceId ) ) {
		$tmpstr = "<namespaceId xsi:type=\"xsd:int\">" . $self->getNamespaceId . "</namespaceId>";
	} else {
		$tmpstr = "<namespaceId xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# referenceCode;
	if( defined( $self->getReferenceCode ) ) {
		$tmpstr = "<referenceCode xsi:type=\"xsd:string\">" . $self->getReferenceCode . "</referenceCode>";
	} else {
		$tmpstr = "<referenceCode xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of History objects
# param: xml doc
# returns: list of History objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of History objects
# param: xml node
# returns: a list of History objects
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

# parse a given xml node, construct one History object
# param: xml node
# returns: one History object
sub fromWSXMLNode {
	my $HistoryNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $editAction;
		my $editActionDate;
		my $namespaceId;
		my $referenceCode;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($HistoryNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "editAction") {
				$editAction=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "editActionDate") {
				$editActionDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "namespaceId") {
				$namespaceId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "referenceCode") {
				$referenceCode=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::History;
	## begin set attr ##
		$newobj->setEditAction($editAction);
		$newobj->setEditActionDate($editActionDate);
		$newobj->setNamespaceId($namespaceId);
		$newobj->setReferenceCode($referenceCode);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getEditAction {
	my $self = shift;
	return $self->{editAction};
}

sub setEditAction {
	my $self = shift;
	$self->{editAction} = shift;
}

sub getEditActionDate {
	my $self = shift;
	return $self->{editActionDate};
}

sub setEditActionDate {
	my $self = shift;
	$self->{editActionDate} = shift;
}

sub getNamespaceId {
	my $self = shift;
	return $self->{namespaceId};
}

sub setNamespaceId {
	my $self = shift;
	$self->{namespaceId} = shift;
}

sub getReferenceCode {
	my $self = shift;
	return $self->{referenceCode};
}

sub setReferenceCode {
	my $self = shift;
	$self->{referenceCode} = shift;
}

## end getters and setters ##

## begin bean association methods ##

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::HistoryRecord;

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

# create an instance of the HistoryRecord object
# returns: a HistoryRecord object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new HistoryRecord\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this HistoryRecord intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":HistoryRecord\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# descLogicConceptCode;
	if( defined( $self->getDescLogicConceptCode ) ) {
		$tmpstr = "<descLogicConceptCode xsi:type=\"xsd:string\">" . $self->getDescLogicConceptCode . "</descLogicConceptCode>";
	} else {
		$tmpstr = "<descLogicConceptCode xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# HistoryCollection;
	if( defined( $self->getHistoryCollection ) ) {
		my @assoclist = $self->getHistoryCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<historyCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getHistoryCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</historyCollection>";
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of HistoryRecord objects
# param: xml doc
# returns: list of HistoryRecord objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of HistoryRecord objects
# param: xml node
# returns: a list of HistoryRecord objects
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

# parse a given xml node, construct one HistoryRecord object
# param: xml node
# returns: one HistoryRecord object
sub fromWSXMLNode {
	my $HistoryRecordNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $descLogicConceptCode;
		my @history = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($HistoryRecordNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "descLogicConceptCode") {
				$descLogicConceptCode=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "historyCollection") {
				my $doi = new CaCORE::EVS::History;
				@history=$doi->fromWSXMLListNode($childrenNode);
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::HistoryRecord;
	## begin set attr ##
		$newobj->setDescLogicConceptCode($descLogicConceptCode);
		$newobj->setHistoryCollection(@history);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDescLogicConceptCode {
	my $self = shift;
	return $self->{descLogicConceptCode};
}

sub setDescLogicConceptCode {
	my $self = shift;
	$self->{descLogicConceptCode} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getHistoryCollection {
	my $self = shift;
	if( defined($self->{history}) ) {
		return @{$self->{history}};
	} else {
		return ();
	}
}

sub setHistoryCollection {
	my ($self, @set) = @_;
	push @{$self->{history}}, @set;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Association;

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

# create an instance of the Association object
# returns: a Association object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Association\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Association intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Association\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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
	# QualifierCollection;
	if( defined( $self->getQualifierCollection ) ) {
		my @assoclist = $self->getQualifierCollection;
		my $listsize = $#assoclist + 1;
		$result .= "<qualifierCollection soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" soapenc:arrayType=\"xsd:anyType[" . $listsize . "]\" xsi:type=\"soapenc:Array\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\">";
		foreach my $node ($self->getQualifierCollection) {
			$result .= "<multiRef href=\"\#id" . $current_id . "\"/>";
			$worklist{$current_id} = $node;
			$current_id ++;
		}
		$result .= "</qualifierCollection>";
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Association objects
# param: xml doc
# returns: list of Association objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Association objects
# param: xml node
# returns: a list of Association objects
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

# parse a given xml node, construct one Association object
# param: xml node
# returns: one Association object
sub fromWSXMLNode {
	my $AssociationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $name;
		my $value;
		my @qualifier = ();
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AssociationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "value") {
				$value=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "qualifierCollection") {
				my $doi = new CaCORE::EVS::Qualifier;
				@qualifier=$doi->fromWSXMLListNode($childrenNode);
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Association;
	## begin set attr ##
		$newobj->setName($name);
		$newobj->setValue($value);
		$newobj->setQualifierCollection(@qualifier);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
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

sub getQualifierCollection {
	my $self = shift;
	if( defined($self->{qualifier}) ) {
		return @{$self->{qualifier}};
	} else {
		return ();
	}
}

sub setQualifierCollection {
	my ($self, @set) = @_;
	push @{$self->{qualifier}}, @set;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::EditActionDate;

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

# create an instance of the EditActionDate object
# returns: a EditActionDate object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new EditActionDate\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this EditActionDate intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":EditActionDate\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# action;
	if( defined( $self->getAction ) ) {
		$tmpstr = "<action xsi:type=\"xsd:int\">" . $self->getAction . "</action>";
	} else {
		$tmpstr = "<action xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# editDate;
	if( defined( $self->getEditDate ) ) {
		$tmpstr = "<editDate xsi:type=\"xsd:dateTime\">" . $self->getEditDate . "</editDate>";
	} else {
		$tmpstr = "<editDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of EditActionDate objects
# param: xml doc
# returns: list of EditActionDate objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of EditActionDate objects
# param: xml node
# returns: a list of EditActionDate objects
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

# parse a given xml node, construct one EditActionDate object
# param: xml node
# returns: one EditActionDate object
sub fromWSXMLNode {
	my $EditActionDateNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $action;
		my $editDate;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($EditActionDateNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "action") {
				$action=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "editDate") {
				$editDate=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::EditActionDate;
	## begin set attr ##
		$newobj->setAction($action);
		$newobj->setEditDate($editDate);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getAction {
	my $self = shift;
	return $self->{action};
}

sub setAction {
	my $self = shift;
	$self->{action} = shift;
}

sub getEditDate {
	my $self = shift;
	return $self->{editDate};
}

sub setEditDate {
	my $self = shift;
	$self->{editDate} = shift;
}

## end getters and setters ##

## begin bean association methods ##

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Role;

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

# create an instance of the Role object
# returns: a Role object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Role\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Role intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Role\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of Role objects
# param: xml doc
# returns: list of Role objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Role objects
# param: xml node
# returns: a list of Role objects
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

# parse a given xml node, construct one Role object
# param: xml node
# returns: one Role object
sub fromWSXMLNode {
	my $RoleNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $name;
		my $value;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($RoleNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "value") {
				$value=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Role;
	## begin set attr ##
		$newobj->setName($name);
		$newobj->setValue($value);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
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

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Atom;

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

# create an instance of the Atom object
# returns: a Atom object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Atom\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Atom intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Atom\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# code;
	if( defined( $self->getCode ) ) {
		$tmpstr = "<code xsi:type=\"xsd:string\">" . $self->getCode . "</code>";
	} else {
		$tmpstr = "<code xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# lui;
	if( defined( $self->getLui ) ) {
		$tmpstr = "<lui xsi:type=\"xsd:string\">" . $self->getLui . "</lui>";
	} else {
		$tmpstr = "<lui xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	# Source;
	if( defined( $self->getSource ) ) {
		$result .= "<source href=\"\#id" . $current_id . "\"/>";
		$worklist{$current_id} = $self->getSource;
		$current_id ++;
	}
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Atom objects
# param: xml doc
# returns: list of Atom objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Atom objects
# param: xml node
# returns: a list of Atom objects
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

# parse a given xml node, construct one Atom object
# param: xml node
# returns: one Atom object
sub fromWSXMLNode {
	my $AtomNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $code;
		my $lui;
		my $name;
		my $origin;
		my $source;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AtomNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "code") {
				$code=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "lui") {
				$lui=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "source") {
				my $doi = new CaCORE::EVS::Source;
				$source=$doi->fromWSXMLNode($childrenNode);
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Atom;
	## begin set attr ##
		$newobj->setCode($code);
		$newobj->setLui($lui);
		$newobj->setName($name);
		$newobj->setOrigin($origin);
		$newobj->setSource($source);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCode {
	my $self = shift;
	return $self->{code};
}

sub setCode {
	my $self = shift;
	$self->{code} = shift;
}

sub getLui {
	my $self = shift;
	return $self->{lui};
}

sub setLui {
	my $self = shift;
	$self->{lui} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getSource {
	my $self = shift;
	return $self->{source};
}

sub setSource {
	my $self = shift;
	$self->{source} = shift;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::EVS::Qualifier;

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

# create an instance of the Qualifier object
# returns: a Qualifier object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Qualifier\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Qualifier intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Qualifier\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.evs.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of Qualifier objects
# param: xml doc
# returns: list of Qualifier objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Qualifier objects
# param: xml node
# returns: a list of Qualifier objects
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

# parse a given xml node, construct one Qualifier object
# param: xml node
# returns: one Qualifier object
sub fromWSXMLNode {
	my $QualifierNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $name;
		my $value;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($QualifierNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "value") {
				$value=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::EVS::Qualifier;
	## begin set attr ##
		$newobj->setName($name);
		$newobj->setValue($value);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
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

## end bean association methods ##

1;
#end
# Below is module documentation for Association

=pod

=head1 Association

CaCORE::EVS::Association - Perl extension for Association.

=head2 ABSTRACT

The CaCORE::EVS::Association is a Perl object representation of the
CaCORE Association object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Association

The following are all the attributes of the Association object and their data types:

=over 4

=item name

data type: C<string>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Association

The following are all the objects that are associated with the Association:

=over 4

=item Instance of L</Qualifier>:

One to many assoication, use C<getQualifierCollection> to get a collection of associated Qualifier.


=back

=cut

# Below is module documentation for Atom

=pod

=head1 Atom

CaCORE::EVS::Atom - Perl extension for Atom.

=head2 ABSTRACT

The CaCORE::EVS::Atom is a Perl object representation of the
CaCORE Atom object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Atom

The following are all the attributes of the Atom object and their data types:

=over 4

=item code

data type: C<string>

=item lui

data type: C<string>

=item name

data type: C<string>

=item origin

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Atom

The following are all the objects that are associated with the Atom:

=over 4

=item Collection of L</Source>:

Many to one assoication, use C<getSource> to get the associated Source.


=back

=cut

# Below is module documentation for AttributeSetDescriptor

=pod

=head1 AttributeSetDescriptor

CaCORE::EVS::AttributeSetDescriptor - Perl extension for AttributeSetDescriptor.

=head2 ABSTRACT

The CaCORE::EVS::AttributeSetDescriptor is a Perl object representation of the
CaCORE AttributeSetDescriptor object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of AttributeSetDescriptor

The following are all the attributes of the AttributeSetDescriptor object and their data types:

=over 4

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of AttributeSetDescriptor

The following are all the objects that are associated with the AttributeSetDescriptor:

=over 4

=item Instance of L</Property>:

One to many assoication, use C<getPropertyCollection> to get a collection of associated Property.

=item Instance of L</Role>:

One to many assoication, use C<getRoleCollection> to get a collection of associated Role.


=back

=cut

# Below is module documentation for Definition

=pod

=head1 Definition

CaCORE::EVS::Definition - Perl extension for Definition.

=head2 ABSTRACT

The CaCORE::EVS::Definition is a Perl object representation of the
CaCORE Definition object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Definition

The following are all the attributes of the Definition object and their data types:

=over 4

=item definition

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Definition

The following are all the objects that are associated with the Definition:

=over 4

=item Collection of L</Source>:

Many to one assoication, use C<getSource> to get the associated Source.


=back

=cut

# Below is module documentation for DescLogicConcept

=pod

=head1 DescLogicConcept

CaCORE::EVS::DescLogicConcept - Perl extension for DescLogicConcept.

=head2 ABSTRACT

The CaCORE::EVS::DescLogicConcept is a Perl object representation of the
CaCORE DescLogicConcept object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DescLogicConcept

The following are all the attributes of the DescLogicConcept object and their data types:

=over 4

=item code

data type: C<string>

=item hasChildren

data type: C<boolean>

=item hasParents

data type: C<boolean>

=item isRetired

data type: C<boolean>

=item name

data type: C<string>

=item namespaceId

data type: C<int>

=item vocabularyName

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DescLogicConcept

The following are all the objects that are associated with the DescLogicConcept:

=over 4

=item Instance of L</Association>:

One to many assoication, use C<getAssociationCollection> to get a collection of associated Association.

=item Collection of L</EdgeProperties>:

Many to one assoication, use C<getEdgeProperties> to get the associated EdgeProperties.

=item Instance of L</InverseAssociation>:

One to many assoication, use C<getInverseAssociationCollection> to get a collection of associated InverseAssociation.

=item Instance of L</InverseRole>:

One to many assoication, use C<getInverseRoleCollection> to get a collection of associated InverseRole.

=item Instance of L</Property>:

One to many assoication, use C<getPropertyCollection> to get a collection of associated Property.

=item Instance of L</Role>:

One to many assoication, use C<getRoleCollection> to get a collection of associated Role.

=item Instance of L</SemanticTypeVector>:

One to many assoication, use C<getSemanticTypeVectorCollection> to get a collection of associated SemanticTypeVector.

=item Collection of L</TreeNode>:

Many to one assoication, use C<getTreeNode> to get the associated TreeNode.

=item Collection of L</Vocabulary>:

Many to one assoication, use C<getVocabulary> to get the associated Vocabulary.


=back

=cut

# Below is module documentation for EdgeProperties

=pod

=head1 EdgeProperties

CaCORE::EVS::EdgeProperties - Perl extension for EdgeProperties.

=head2 ABSTRACT

The CaCORE::EVS::EdgeProperties is a Perl object representation of the
CaCORE EdgeProperties object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of EdgeProperties

The following are all the attributes of the EdgeProperties object and their data types:

=over 4

=item isA

data type: C<boolean>

=item name

data type: C<string>

=item traverseDown

data type: C<boolean>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of EdgeProperties

The following are all the objects that are associated with the EdgeProperties:

=over 4

=item Instance of L</Links>:

One to many assoication, use C<getLinksCollection> to get a collection of associated Links.


=back

=cut

# Below is module documentation for EditActionDate

=pod

=head1 EditActionDate

CaCORE::EVS::EditActionDate - Perl extension for EditActionDate.

=head2 ABSTRACT

The CaCORE::EVS::EditActionDate is a Perl object representation of the
CaCORE EditActionDate object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of EditActionDate

The following are all the attributes of the EditActionDate object and their data types:

=over 4

=item action

data type: C<int>

=item editDate

data type: C<dateTime>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of EditActionDate

The following are all the objects that are associated with the EditActionDate:

=over 4


=back

=cut

# Below is module documentation for HashSet

=pod

=head1 HashSet

CaCORE::EVS::HashSet - Perl extension for HashSet.

=head2 ABSTRACT

The CaCORE::EVS::HashSet is a Perl object representation of the
CaCORE HashSet object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of HashSet

The following are all the attributes of the HashSet object and their data types:

=over 4


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of HashSet

The following are all the objects that are associated with the HashSet:

=over 4


=back

=cut

# Below is module documentation for History

=pod

=head1 History

CaCORE::EVS::History - Perl extension for History.

=head2 ABSTRACT

The CaCORE::EVS::History is a Perl object representation of the
CaCORE History object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of History

The following are all the attributes of the History object and their data types:

=over 4

=item editAction

data type: C<string>

=item editActionDate

data type: C<dateTime>

=item namespaceId

data type: C<int>

=item referenceCode

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of History

The following are all the objects that are associated with the History:

=over 4


=back

=cut

# Below is module documentation for HistoryRecord

=pod

=head1 HistoryRecord

CaCORE::EVS::HistoryRecord - Perl extension for HistoryRecord.

=head2 ABSTRACT

The CaCORE::EVS::HistoryRecord is a Perl object representation of the
CaCORE HistoryRecord object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of HistoryRecord

The following are all the attributes of the HistoryRecord object and their data types:

=over 4

=item descLogicConceptCode

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of HistoryRecord

The following are all the objects that are associated with the HistoryRecord:

=over 4

=item Instance of L</History>:

One to many assoication, use C<getHistoryCollection> to get a collection of associated History.


=back

=cut

# Below is module documentation for MetaThesaurusConcept

=pod

=head1 MetaThesaurusConcept

CaCORE::EVS::MetaThesaurusConcept - Perl extension for MetaThesaurusConcept.

=head2 ABSTRACT

The CaCORE::EVS::MetaThesaurusConcept is a Perl object representation of the
CaCORE MetaThesaurusConcept object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of MetaThesaurusConcept

The following are all the attributes of the MetaThesaurusConcept object and their data types:

=over 4

=item cui

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of MetaThesaurusConcept

The following are all the objects that are associated with the MetaThesaurusConcept:

=over 4

=item Instance of L</Atom>:

One to many assoication, use C<getAtomCollection> to get a collection of associated Atom.

=item Instance of L</Definition>:

One to many assoication, use C<getDefinitionCollection> to get a collection of associated Definition.

=item Instance of L</SemanticType>:

One to many assoication, use C<getSemanticTypeCollection> to get a collection of associated SemanticType.

=item Instance of L</Source>:

One to many assoication, use C<getSourceCollection> to get a collection of associated Source.

=item Instance of L</Synonym>:

One to many assoication, use C<getSynonymCollection> to get a collection of associated Synonym.


=back

=cut

# Below is module documentation for Property

=pod

=head1 Property

CaCORE::EVS::Property - Perl extension for Property.

=head2 ABSTRACT

The CaCORE::EVS::Property is a Perl object representation of the
CaCORE Property object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Property

The following are all the attributes of the Property object and their data types:

=over 4

=item name

data type: C<string>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Property

The following are all the objects that are associated with the Property:

=over 4

=item Instance of L</Qualifier>:

One to many assoication, use C<getQualifierCollection> to get a collection of associated Qualifier.


=back

=cut

# Below is module documentation for Qualifier

=pod

=head1 Qualifier

CaCORE::EVS::Qualifier - Perl extension for Qualifier.

=head2 ABSTRACT

The CaCORE::EVS::Qualifier is a Perl object representation of the
CaCORE Qualifier object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Qualifier

The following are all the attributes of the Qualifier object and their data types:

=over 4

=item name

data type: C<string>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Qualifier

The following are all the objects that are associated with the Qualifier:

=over 4


=back

=cut

# Below is module documentation for Role

=pod

=head1 Role

CaCORE::EVS::Role - Perl extension for Role.

=head2 ABSTRACT

The CaCORE::EVS::Role is a Perl object representation of the
CaCORE Role object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Role

The following are all the attributes of the Role object and their data types:

=over 4

=item name

data type: C<string>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Role

The following are all the objects that are associated with the Role:

=over 4


=back

=cut

# Below is module documentation for SemanticType

=pod

=head1 SemanticType

CaCORE::EVS::SemanticType - Perl extension for SemanticType.

=head2 ABSTRACT

The CaCORE::EVS::SemanticType is a Perl object representation of the
CaCORE SemanticType object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of SemanticType

The following are all the attributes of the SemanticType object and their data types:

=over 4

=item id

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of SemanticType

The following are all the objects that are associated with the SemanticType:

=over 4


=back

=cut

# Below is module documentation for Silo

=pod

=head1 Silo

CaCORE::EVS::Silo - Perl extension for Silo.

=head2 ABSTRACT

The CaCORE::EVS::Silo is a Perl object representation of the
CaCORE Silo object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Silo

The following are all the attributes of the Silo object and their data types:

=over 4

=item id

data type: C<int>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Silo

The following are all the objects that are associated with the Silo:

=over 4


=back

=cut

# Below is module documentation for Source

=pod

=head1 Source

CaCORE::EVS::Source - Perl extension for Source.

=head2 ABSTRACT

The CaCORE::EVS::Source is a Perl object representation of the
CaCORE Source object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Source

The following are all the attributes of the Source object and their data types:

=over 4

=item abbreviation

data type: C<string>

=item code

data type: C<string>

=item description

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Source

The following are all the objects that are associated with the Source:

=over 4


=back

=cut

# Below is module documentation for TreeNode

=pod

=head1 TreeNode

CaCORE::EVS::TreeNode - Perl extension for TreeNode.

=head2 ABSTRACT

The CaCORE::EVS::TreeNode is a Perl object representation of the
CaCORE TreeNode object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of TreeNode

The following are all the attributes of the TreeNode object and their data types:

=over 4

=item isA

data type: C<boolean>

=item name

data type: C<string>

=item traverseDown

data type: C<boolean>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of TreeNode

The following are all the objects that are associated with the TreeNode:

=over 4

=item Instance of L</Links>:

One to many assoication, use C<getLinksCollection> to get a collection of associated Links.


=back

=cut

# Below is module documentation for Vocabulary

=pod

=head1 Vocabulary

CaCORE::EVS::Vocabulary - Perl extension for Vocabulary.

=head2 ABSTRACT

The CaCORE::EVS::Vocabulary is a Perl object representation of the
CaCORE Vocabulary object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Vocabulary

The following are all the attributes of the Vocabulary object and their data types:

=over 4

=item description

data type: C<string>

=item name

data type: C<string>

=item namespaceId

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Vocabulary

The following are all the objects that are associated with the Vocabulary:

=over 4

=item Collection of L</SecurityToken>:

Many to one assoication, use C<getSecurityToken> to get the associated SecurityToken.

=item Instance of L</Silo>:

One to many assoication, use C<getSiloCollection> to get a collection of associated Silo.


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


