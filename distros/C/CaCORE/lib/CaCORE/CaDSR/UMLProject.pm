# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::UMLGeneralizationMetadata;

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

# create an instance of the UMLGeneralizationMetadata object
# returns: a UMLGeneralizationMetadata object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new UMLGeneralizationMetadata\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this UMLGeneralizationMetadata intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":UMLGeneralizationMetadata\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of UMLGeneralizationMetadata objects
# param: xml doc
# returns: list of UMLGeneralizationMetadata objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of UMLGeneralizationMetadata objects
# param: xml node
# returns: a list of UMLGeneralizationMetadata objects
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

# parse a given xml node, construct one UMLGeneralizationMetadata object
# param: xml node
# returns: one UMLGeneralizationMetadata object
sub fromWSXMLNode {
	my $UMLGeneralizationMetadataNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($UMLGeneralizationMetadataNode->getChildNodes) {
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
	my $newobj = new CaCORE::CaDSR::UMLProject::UMLGeneralizationMetadata;
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

sub getObjectClassRelationship {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClassRelationship", $self);
	return $results[0];
}

sub getSuperUMLClassMetadata {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLClassMetadata", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::Project;

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

# create an instance of the Project object
# returns: a Project object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Project\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Project intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Project\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# shortName;
	if( defined( $self->getShortName ) ) {
		$tmpstr = "<shortName xsi:type=\"xsd:string\">" . $self->getShortName . "</shortName>";
	} else {
		$tmpstr = "<shortName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:string\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Project objects
# param: xml doc
# returns: list of Project objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Project objects
# param: xml node
# returns: a list of Project objects
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

# parse a given xml node, construct one Project object
# param: xml node
# returns: one Project object
sub fromWSXMLNode {
	my $ProjectNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $description;
		my $id;
		my $longName;
		my $shortName;
		my $version;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ProjectNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "shortName") {
				$shortName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::UMLProject::Project;
	## begin set attr ##
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setLongName($longName);
		$newobj->setShortName($shortName);
		$newobj->setVersion($version);
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

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getShortName {
	my $self = shift;
	return $self->{shortName};
}

sub setShortName {
	my $self = shift;
	$self->{shortName} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getUMLAssociationMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLAssociationMetadata", $self);
	return @results;
}

sub getUMLAttributeMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLAttributeMetadata", $self);
	return @results;
}

sub getUMLClassMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLClassMetadata", $self);
	return @results;
}

sub getUMLPackageMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLPackageMetadata", $self);
	return @results;
}

sub getClassificationScheme {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationScheme", $self);
	return $results[0];
}

sub getSubProjectCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::SubProject", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::SubProject;

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

# create an instance of the SubProject object
# returns: a SubProject object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new SubProject\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this SubProject intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":SubProject\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

# parse a given webservice response xml, construct a list of SubProject objects
# param: xml doc
# returns: list of SubProject objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of SubProject objects
# param: xml node
# returns: a list of SubProject objects
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

# parse a given xml node, construct one SubProject object
# param: xml node
# returns: one SubProject object
sub fromWSXMLNode {
	my $SubProjectNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $description;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($SubProjectNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::UMLProject::SubProject;
	## begin set attr ##
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setName($name);
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

sub getUMLPackageMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLPackageMetadata", $self);
	return @results;
}

sub getClassSchemeClassSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return $results[0];
}

sub getProject {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::Project", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::UMLPackageMetadata;

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

# create an instance of the UMLPackageMetadata object
# returns: a UMLPackageMetadata object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new UMLPackageMetadata\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this UMLPackageMetadata intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":UMLPackageMetadata\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

# parse a given webservice response xml, construct a list of UMLPackageMetadata objects
# param: xml doc
# returns: list of UMLPackageMetadata objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of UMLPackageMetadata objects
# param: xml node
# returns: a list of UMLPackageMetadata objects
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

# parse a given xml node, construct one UMLPackageMetadata object
# param: xml node
# returns: one UMLPackageMetadata object
sub fromWSXMLNode {
	my $UMLPackageMetadataNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $description;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($UMLPackageMetadataNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::UMLProject::UMLPackageMetadata;
	## begin set attr ##
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setName($name);
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

sub getUMLClassMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLClassMetadata", $self);
	return @results;
}

sub getClassSchemeClassSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return $results[0];
}

sub getProject {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::Project", $self);
	return $results[0];
}

sub getSubProject {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::SubProject", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::UMLClassMetadata;

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

# create an instance of the UMLClassMetadata object
# returns: a UMLClassMetadata object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new UMLClassMetadata\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this UMLClassMetadata intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":UMLClassMetadata\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

	# fullyQualifiedName;
	if( defined( $self->getFullyQualifiedName ) ) {
		$tmpstr = "<fullyQualifiedName xsi:type=\"xsd:string\">" . $self->getFullyQualifiedName . "</fullyQualifiedName>";
	} else {
		$tmpstr = "<fullyQualifiedName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

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

# parse a given webservice response xml, construct a list of UMLClassMetadata objects
# param: xml doc
# returns: list of UMLClassMetadata objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of UMLClassMetadata objects
# param: xml node
# returns: a list of UMLClassMetadata objects
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

# parse a given xml node, construct one UMLClassMetadata object
# param: xml node
# returns: one UMLClassMetadata object
sub fromWSXMLNode {
	my $UMLClassMetadataNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $description;
		my $fullyQualifiedName;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($UMLClassMetadataNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "fullyQualifiedName") {
				$fullyQualifiedName=$textNode->getNodeValue;
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
	my $newobj = new CaCORE::CaDSR::UMLProject::UMLClassMetadata;
	## begin set attr ##
		$newobj->setDescription($description);
		$newobj->setFullyQualifiedName($fullyQualifiedName);
		$newobj->setId($id);
		$newobj->setName($name);
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

sub getFullyQualifiedName {
	my $self = shift;
	return $self->{fullyQualifiedName};
}

sub setFullyQualifiedName {
	my $self = shift;
	$self->{fullyQualifiedName} = shift;
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

sub getUMLAssociationMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLAssociationMetadata", $self);
	return @results;
}

sub getUMLAttributeMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLAttributeMetadata", $self);
	return @results;
}

sub getUMLGeneralizationMetadata {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLGeneralizationMetadata", $self);
	return $results[0];
}

sub getUMLPackageMetadata {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLPackageMetadata", $self);
	return $results[0];
}

sub getObjectClass {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClass", $self);
	return $results[0];
}

sub getProject {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::Project", $self);
	return $results[0];
}

sub getSemanticMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::SemanticMetadata", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::AttributeTypeMetadata;

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

# create an instance of the AttributeTypeMetadata object
# returns: a AttributeTypeMetadata object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new AttributeTypeMetadata\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this AttributeTypeMetadata intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":AttributeTypeMetadata\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

	# valueDomainDataType;
	if( defined( $self->getValueDomainDataType ) ) {
		$tmpstr = "<valueDomainDataType xsi:type=\"xsd:string\">" . $self->getValueDomainDataType . "</valueDomainDataType>";
	} else {
		$tmpstr = "<valueDomainDataType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# valueDomainLongName;
	if( defined( $self->getValueDomainLongName ) ) {
		$tmpstr = "<valueDomainLongName xsi:type=\"xsd:string\">" . $self->getValueDomainLongName . "</valueDomainLongName>";
	} else {
		$tmpstr = "<valueDomainLongName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of AttributeTypeMetadata objects
# param: xml doc
# returns: list of AttributeTypeMetadata objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of AttributeTypeMetadata objects
# param: xml node
# returns: a list of AttributeTypeMetadata objects
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

# parse a given xml node, construct one AttributeTypeMetadata object
# param: xml node
# returns: one AttributeTypeMetadata object
sub fromWSXMLNode {
	my $AttributeTypeMetadataNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
		my $valueDomainDataType;
		my $valueDomainLongName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AttributeTypeMetadataNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "valueDomainDataType") {
				$valueDomainDataType=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "valueDomainLongName") {
				$valueDomainLongName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::UMLProject::AttributeTypeMetadata;
	## begin set attr ##
		$newobj->setId($id);
		$newobj->setValueDomainDataType($valueDomainDataType);
		$newobj->setValueDomainLongName($valueDomainLongName);
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

sub getValueDomainDataType {
	my $self = shift;
	return $self->{valueDomainDataType};
}

sub setValueDomainDataType {
	my $self = shift;
	$self->{valueDomainDataType} = shift;
}

sub getValueDomainLongName {
	my $self = shift;
	return $self->{valueDomainLongName};
}

sub setValueDomainLongName {
	my $self = shift;
	$self->{valueDomainLongName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getSemanticMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::SemanticMetadata", $self);
	return @results;
}

sub getTypeEnumerationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::TypeEnumerationMetadata", $self);
	return @results;
}

sub getValueDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomain", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::UMLAttributeMetadata;

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

# create an instance of the UMLAttributeMetadata object
# returns: a UMLAttributeMetadata object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new UMLAttributeMetadata\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this UMLAttributeMetadata intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":UMLAttributeMetadata\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

	# fullyQualifiedName;
	if( defined( $self->getFullyQualifiedName ) ) {
		$tmpstr = "<fullyQualifiedName xsi:type=\"xsd:string\">" . $self->getFullyQualifiedName . "</fullyQualifiedName>";
	} else {
		$tmpstr = "<fullyQualifiedName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

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

# parse a given webservice response xml, construct a list of UMLAttributeMetadata objects
# param: xml doc
# returns: list of UMLAttributeMetadata objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of UMLAttributeMetadata objects
# param: xml node
# returns: a list of UMLAttributeMetadata objects
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

# parse a given xml node, construct one UMLAttributeMetadata object
# param: xml node
# returns: one UMLAttributeMetadata object
sub fromWSXMLNode {
	my $UMLAttributeMetadataNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $description;
		my $fullyQualifiedName;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($UMLAttributeMetadataNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "fullyQualifiedName") {
				$fullyQualifiedName=$textNode->getNodeValue;
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
	my $newobj = new CaCORE::CaDSR::UMLProject::UMLAttributeMetadata;
	## begin set attr ##
		$newobj->setDescription($description);
		$newobj->setFullyQualifiedName($fullyQualifiedName);
		$newobj->setId($id);
		$newobj->setName($name);
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

sub getFullyQualifiedName {
	my $self = shift;
	return $self->{fullyQualifiedName};
}

sub setFullyQualifiedName {
	my $self = shift;
	$self->{fullyQualifiedName} = shift;
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

sub getUMLClassMetadata {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLClassMetadata", $self);
	return $results[0];
}

sub getAttributeTypeMetadata {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::AttributeTypeMetadata", $self);
	return $results[0];
}

sub getDataElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return $results[0];
}

sub getProject {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::Project", $self);
	return $results[0];
}

sub getSemanticMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::SemanticMetadata", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::UMLAssociationMetadata;

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

# create an instance of the UMLAssociationMetadata object
# returns: a UMLAssociationMetadata object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new UMLAssociationMetadata\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this UMLAssociationMetadata intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":UMLAssociationMetadata\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

	# isBidirectional;
	if( defined( $self->getIsBidirectional ) ) {
		$tmpstr = "<isBidirectional xsi:type=\"xsd:boolean\">" . $self->getIsBidirectional . "</isBidirectional>";
	} else {
		$tmpstr = "<isBidirectional xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceHighCardinality;
	if( defined( $self->getSourceHighCardinality ) ) {
		$tmpstr = "<sourceHighCardinality xsi:type=\"xsd:int\">" . $self->getSourceHighCardinality . "</sourceHighCardinality>";
	} else {
		$tmpstr = "<sourceHighCardinality xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceLowCardinality;
	if( defined( $self->getSourceLowCardinality ) ) {
		$tmpstr = "<sourceLowCardinality xsi:type=\"xsd:int\">" . $self->getSourceLowCardinality . "</sourceLowCardinality>";
	} else {
		$tmpstr = "<sourceLowCardinality xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceRoleName;
	if( defined( $self->getSourceRoleName ) ) {
		$tmpstr = "<sourceRoleName xsi:type=\"xsd:string\">" . $self->getSourceRoleName . "</sourceRoleName>";
	} else {
		$tmpstr = "<sourceRoleName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# targetHighCardinality;
	if( defined( $self->getTargetHighCardinality ) ) {
		$tmpstr = "<targetHighCardinality xsi:type=\"xsd:int\">" . $self->getTargetHighCardinality . "</targetHighCardinality>";
	} else {
		$tmpstr = "<targetHighCardinality xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# targetLowCardinality;
	if( defined( $self->getTargetLowCardinality ) ) {
		$tmpstr = "<targetLowCardinality xsi:type=\"xsd:int\">" . $self->getTargetLowCardinality . "</targetLowCardinality>";
	} else {
		$tmpstr = "<targetLowCardinality xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# targetRoleName;
	if( defined( $self->getTargetRoleName ) ) {
		$tmpstr = "<targetRoleName xsi:type=\"xsd:string\">" . $self->getTargetRoleName . "</targetRoleName>";
	} else {
		$tmpstr = "<targetRoleName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of UMLAssociationMetadata objects
# param: xml doc
# returns: list of UMLAssociationMetadata objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of UMLAssociationMetadata objects
# param: xml node
# returns: a list of UMLAssociationMetadata objects
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

# parse a given xml node, construct one UMLAssociationMetadata object
# param: xml node
# returns: one UMLAssociationMetadata object
sub fromWSXMLNode {
	my $UMLAssociationMetadataNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
		my $isBidirectional;
		my $sourceHighCardinality;
		my $sourceLowCardinality;
		my $sourceRoleName;
		my $targetHighCardinality;
		my $targetLowCardinality;
		my $targetRoleName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($UMLAssociationMetadataNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "isBidirectional") {
				$isBidirectional=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceHighCardinality") {
				$sourceHighCardinality=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceLowCardinality") {
				$sourceLowCardinality=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceRoleName") {
				$sourceRoleName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "targetHighCardinality") {
				$targetHighCardinality=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "targetLowCardinality") {
				$targetLowCardinality=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "targetRoleName") {
				$targetRoleName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::UMLProject::UMLAssociationMetadata;
	## begin set attr ##
		$newobj->setId($id);
		$newobj->setIsBidirectional($isBidirectional);
		$newobj->setSourceHighCardinality($sourceHighCardinality);
		$newobj->setSourceLowCardinality($sourceLowCardinality);
		$newobj->setSourceRoleName($sourceRoleName);
		$newobj->setTargetHighCardinality($targetHighCardinality);
		$newobj->setTargetLowCardinality($targetLowCardinality);
		$newobj->setTargetRoleName($targetRoleName);
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

sub getIsBidirectional {
	my $self = shift;
	return $self->{isBidirectional};
}

sub setIsBidirectional {
	my $self = shift;
	$self->{isBidirectional} = shift;
}

sub getSourceHighCardinality {
	my $self = shift;
	return $self->{sourceHighCardinality};
}

sub setSourceHighCardinality {
	my $self = shift;
	$self->{sourceHighCardinality} = shift;
}

sub getSourceLowCardinality {
	my $self = shift;
	return $self->{sourceLowCardinality};
}

sub setSourceLowCardinality {
	my $self = shift;
	$self->{sourceLowCardinality} = shift;
}

sub getSourceRoleName {
	my $self = shift;
	return $self->{sourceRoleName};
}

sub setSourceRoleName {
	my $self = shift;
	$self->{sourceRoleName} = shift;
}

sub getTargetHighCardinality {
	my $self = shift;
	return $self->{targetHighCardinality};
}

sub setTargetHighCardinality {
	my $self = shift;
	$self->{targetHighCardinality} = shift;
}

sub getTargetLowCardinality {
	my $self = shift;
	return $self->{targetLowCardinality};
}

sub setTargetLowCardinality {
	my $self = shift;
	$self->{targetLowCardinality} = shift;
}

sub getTargetRoleName {
	my $self = shift;
	return $self->{targetRoleName};
}

sub setTargetRoleName {
	my $self = shift;
	$self->{targetRoleName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getObjectClassRelationship {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClassRelationship", $self);
	return $results[0];
}

sub getProject {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::Project", $self);
	return $results[0];
}

sub getSemanticMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::SemanticMetadata", $self);
	return @results;
}

sub getSourceUMLClassMetadata {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLClassMetadata", $self);
	return $results[0];
}

sub getTargetUMLClassMetadata {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::UMLClassMetadata", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::SemanticMetadata;

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

# create an instance of the SemanticMetadata object
# returns: a SemanticMetadata object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new SemanticMetadata\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this SemanticMetadata intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":SemanticMetadata\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# conceptCode;
	if( defined( $self->getConceptCode ) ) {
		$tmpstr = "<conceptCode xsi:type=\"xsd:string\">" . $self->getConceptCode . "</conceptCode>";
	} else {
		$tmpstr = "<conceptCode xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# conceptDefinition;
	if( defined( $self->getConceptDefinition ) ) {
		$tmpstr = "<conceptDefinition xsi:type=\"xsd:string\">" . $self->getConceptDefinition . "</conceptDefinition>";
	} else {
		$tmpstr = "<conceptDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# conceptName;
	if( defined( $self->getConceptName ) ) {
		$tmpstr = "<conceptName xsi:type=\"xsd:string\">" . $self->getConceptName . "</conceptName>";
	} else {
		$tmpstr = "<conceptName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# isPrimaryConcept;
	if( defined( $self->getIsPrimaryConcept ) ) {
		$tmpstr = "<isPrimaryConcept xsi:type=\"xsd:boolean\">" . $self->getIsPrimaryConcept . "</isPrimaryConcept>";
	} else {
		$tmpstr = "<isPrimaryConcept xsi:type=\"xsd:boolean\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# order;
	if( defined( $self->getOrder ) ) {
		$tmpstr = "<order xsi:type=\"xsd:int\">" . $self->getOrder . "</order>";
	} else {
		$tmpstr = "<order xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# orderLevel;
	if( defined( $self->getOrderLevel ) ) {
		$tmpstr = "<orderLevel xsi:type=\"xsd:int\">" . $self->getOrderLevel . "</orderLevel>";
	} else {
		$tmpstr = "<orderLevel xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of SemanticMetadata objects
# param: xml doc
# returns: list of SemanticMetadata objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of SemanticMetadata objects
# param: xml node
# returns: a list of SemanticMetadata objects
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

# parse a given xml node, construct one SemanticMetadata object
# param: xml node
# returns: one SemanticMetadata object
sub fromWSXMLNode {
	my $SemanticMetadataNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $conceptCode;
		my $conceptDefinition;
		my $conceptName;
		my $id;
		my $isPrimaryConcept;
		my $order;
		my $orderLevel;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($SemanticMetadataNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "conceptCode") {
				$conceptCode=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "conceptDefinition") {
				$conceptDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "conceptName") {
				$conceptName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "isPrimaryConcept") {
				$isPrimaryConcept=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "order") {
				$order=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "orderLevel") {
				$orderLevel=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::UMLProject::SemanticMetadata;
	## begin set attr ##
		$newobj->setConceptCode($conceptCode);
		$newobj->setConceptDefinition($conceptDefinition);
		$newobj->setConceptName($conceptName);
		$newobj->setId($id);
		$newobj->setIsPrimaryConcept($isPrimaryConcept);
		$newobj->setOrder($order);
		$newobj->setOrderLevel($orderLevel);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getConceptCode {
	my $self = shift;
	return $self->{conceptCode};
}

sub setConceptCode {
	my $self = shift;
	$self->{conceptCode} = shift;
}

sub getConceptDefinition {
	my $self = shift;
	return $self->{conceptDefinition};
}

sub setConceptDefinition {
	my $self = shift;
	$self->{conceptDefinition} = shift;
}

sub getConceptName {
	my $self = shift;
	return $self->{conceptName};
}

sub setConceptName {
	my $self = shift;
	$self->{conceptName} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getIsPrimaryConcept {
	my $self = shift;
	return $self->{isPrimaryConcept};
}

sub setIsPrimaryConcept {
	my $self = shift;
	$self->{isPrimaryConcept} = shift;
}

sub getOrder {
	my $self = shift;
	return $self->{order};
}

sub setOrder {
	my $self = shift;
	$self->{order} = shift;
}

sub getOrderLevel {
	my $self = shift;
	return $self->{orderLevel};
}

sub setOrderLevel {
	my $self = shift;
	$self->{orderLevel} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getConcept {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Concept", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::UMLProject::TypeEnumerationMetadata;

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

# create an instance of the TypeEnumerationMetadata object
# returns: a TypeEnumerationMetadata object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new TypeEnumerationMetadata\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this TypeEnumerationMetadata intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":TypeEnumerationMetadata\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.umlproject.cadsr.nci.nih.gov\">";
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

	# permissibleValue;
	if( defined( $self->getPermissibleValue ) ) {
		$tmpstr = "<permissibleValue xsi:type=\"xsd:string\">" . $self->getPermissibleValue . "</permissibleValue>";
	} else {
		$tmpstr = "<permissibleValue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# valueMeaning;
	if( defined( $self->getValueMeaning ) ) {
		$tmpstr = "<valueMeaning xsi:type=\"xsd:string\">" . $self->getValueMeaning . "</valueMeaning>";
	} else {
		$tmpstr = "<valueMeaning xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of TypeEnumerationMetadata objects
# param: xml doc
# returns: list of TypeEnumerationMetadata objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of TypeEnumerationMetadata objects
# param: xml node
# returns: a list of TypeEnumerationMetadata objects
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

# parse a given xml node, construct one TypeEnumerationMetadata object
# param: xml node
# returns: one TypeEnumerationMetadata object
sub fromWSXMLNode {
	my $TypeEnumerationMetadataNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
		my $permissibleValue;
		my $valueMeaning;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($TypeEnumerationMetadataNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "permissibleValue") {
				$permissibleValue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "valueMeaning") {
				$valueMeaning=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::UMLProject::TypeEnumerationMetadata;
	## begin set attr ##
		$newobj->setId($id);
		$newobj->setPermissibleValue($permissibleValue);
		$newobj->setValueMeaning($valueMeaning);
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

sub getPermissibleValue {
	my $self = shift;
	return $self->{permissibleValue};
}

sub setPermissibleValue {
	my $self = shift;
	$self->{permissibleValue} = shift;
}

sub getValueMeaning {
	my $self = shift;
	return $self->{valueMeaning};
}

sub setValueMeaning {
	my $self = shift;
	$self->{valueMeaning} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getSemanticMetadataCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::UMLProject::SemanticMetadata", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# Below is module documentation for AttributeTypeMetadata

=pod

=head1 AttributeTypeMetadata

CaCORE::CaDSR::UMLProject::AttributeTypeMetadata - Perl extension for AttributeTypeMetadata.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::AttributeTypeMetadata is a Perl object representation of the
CaCORE AttributeTypeMetadata object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of AttributeTypeMetadata

The following are all the attributes of the AttributeTypeMetadata object and their data types:

=over 4

=item id

data type: C<string>

=item valueDomainDataType

data type: C<string>

=item valueDomainLongName

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of AttributeTypeMetadata

The following are all the objects that are associated with the AttributeTypeMetadata:

=over 4

=item Instance of L</SemanticMetadata>:

One to many assoication, use C<getSemanticMetadataCollection> to get a collection of associated SemanticMetadata.

=item Instance of L</TypeEnumeration>:

One to many assoication, use C<getTypeEnumerationCollection> to get a collection of associated TypeEnumeration.

=item Collection of L</ValueDomain>:

Many to one assoication, use C<getValueDomain> to get the associated ValueDomain.


=back

=cut

# Below is module documentation for Project

=pod

=head1 Project

CaCORE::CaDSR::UMLProject::Project - Perl extension for Project.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::Project is a Perl object representation of the
CaCORE Project object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Project

The following are all the attributes of the Project object and their data types:

=over 4

=item description

data type: C<string>

=item id

data type: C<string>

=item longName

data type: C<string>

=item shortName

data type: C<string>

=item version

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Project

The following are all the objects that are associated with the Project:

=over 4

=item Instance of L</UMLAssociationMetadata>:

One to many assoication, use C<getUMLAssociationMetadataCollection> to get a collection of associated UMLAssociationMetadata.

=item Instance of L</UMLAttributeMetadata>:

One to many assoication, use C<getUMLAttributeMetadataCollection> to get a collection of associated UMLAttributeMetadata.

=item Instance of L</UMLClassMetadata>:

One to many assoication, use C<getUMLClassMetadataCollection> to get a collection of associated UMLClassMetadata.

=item Instance of L</UMLPackageMetadata>:

One to many assoication, use C<getUMLPackageMetadataCollection> to get a collection of associated UMLPackageMetadata.

=item Collection of L</ClassificationScheme>:

Many to one assoication, use C<getClassificationScheme> to get the associated ClassificationScheme.

=item Instance of L</SubProject>:

One to many assoication, use C<getSubProjectCollection> to get a collection of associated SubProject.


=back

=cut

# Below is module documentation for SemanticMetadata

=pod

=head1 SemanticMetadata

CaCORE::CaDSR::UMLProject::SemanticMetadata - Perl extension for SemanticMetadata.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::SemanticMetadata is a Perl object representation of the
CaCORE SemanticMetadata object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of SemanticMetadata

The following are all the attributes of the SemanticMetadata object and their data types:

=over 4

=item conceptCode

data type: C<string>

=item conceptDefinition

data type: C<string>

=item conceptName

data type: C<string>

=item id

data type: C<string>

=item isPrimaryConcept

data type: C<boolean>

=item order

data type: C<int>

=item orderLevel

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of SemanticMetadata

The following are all the objects that are associated with the SemanticMetadata:

=over 4

=item Collection of L</Concept>:

Many to one assoication, use C<getConcept> to get the associated Concept.


=back

=cut

# Below is module documentation for SubProject

=pod

=head1 SubProject

CaCORE::CaDSR::UMLProject::SubProject - Perl extension for SubProject.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::SubProject is a Perl object representation of the
CaCORE SubProject object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of SubProject

The following are all the attributes of the SubProject object and their data types:

=over 4

=item description

data type: C<string>

=item id

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of SubProject

The following are all the objects that are associated with the SubProject:

=over 4

=item Instance of L</UMLPackageMetadata>:

One to many assoication, use C<getUMLPackageMetadataCollection> to get a collection of associated UMLPackageMetadata.

=item Collection of L</ClassSchemeClassSchemeItem>:

Many to one assoication, use C<getClassSchemeClassSchemeItem> to get the associated ClassSchemeClassSchemeItem.

=item Collection of L</Project>:

Many to one assoication, use C<getProject> to get the associated Project.


=back

=cut

# Below is module documentation for TypeEnumerationMetadata

=pod

=head1 TypeEnumerationMetadata

CaCORE::CaDSR::UMLProject::TypeEnumerationMetadata - Perl extension for TypeEnumerationMetadata.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::TypeEnumerationMetadata is a Perl object representation of the
CaCORE TypeEnumerationMetadata object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of TypeEnumerationMetadata

The following are all the attributes of the TypeEnumerationMetadata object and their data types:

=over 4

=item id

data type: C<string>

=item permissibleValue

data type: C<string>

=item valueMeaning

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of TypeEnumerationMetadata

The following are all the objects that are associated with the TypeEnumerationMetadata:

=over 4

=item Instance of L</SemanticMetadata>:

One to many assoication, use C<getSemanticMetadataCollection> to get a collection of associated SemanticMetadata.


=back

=cut

# Below is module documentation for UMLAssociationMetadata

=pod

=head1 UMLAssociationMetadata

CaCORE::CaDSR::UMLProject::UMLAssociationMetadata - Perl extension for UMLAssociationMetadata.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::UMLAssociationMetadata is a Perl object representation of the
CaCORE UMLAssociationMetadata object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of UMLAssociationMetadata

The following are all the attributes of the UMLAssociationMetadata object and their data types:

=over 4

=item id

data type: C<string>

=item isBidirectional

data type: C<boolean>

=item sourceHighCardinality

data type: C<int>

=item sourceLowCardinality

data type: C<int>

=item sourceRoleName

data type: C<string>

=item targetHighCardinality

data type: C<int>

=item targetLowCardinality

data type: C<int>

=item targetRoleName

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of UMLAssociationMetadata

The following are all the objects that are associated with the UMLAssociationMetadata:

=over 4

=item Collection of L</ObjectClassRelationship>:

Many to one assoication, use C<getObjectClassRelationship> to get the associated ObjectClassRelationship.

=item Collection of L</Project>:

Many to one assoication, use C<getProject> to get the associated Project.

=item Instance of L</SemanticMetadata>:

One to many assoication, use C<getSemanticMetadataCollection> to get a collection of associated SemanticMetadata.

=item Collection of L</SourceUMLClassMetadata>:

Many to one assoication, use C<getSourceUMLClassMetadata> to get the associated SourceUMLClassMetadata.

=item Collection of L</TargetUMLClassMetadata>:

Many to one assoication, use C<getTargetUMLClassMetadata> to get the associated TargetUMLClassMetadata.


=back

=cut

# Below is module documentation for UMLAttributeMetadata

=pod

=head1 UMLAttributeMetadata

CaCORE::CaDSR::UMLProject::UMLAttributeMetadata - Perl extension for UMLAttributeMetadata.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::UMLAttributeMetadata is a Perl object representation of the
CaCORE UMLAttributeMetadata object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of UMLAttributeMetadata

The following are all the attributes of the UMLAttributeMetadata object and their data types:

=over 4

=item description

data type: C<string>

=item fullyQualifiedName

data type: C<string>

=item id

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of UMLAttributeMetadata

The following are all the objects that are associated with the UMLAttributeMetadata:

=over 4

=item Collection of L</UMLClassMetadata>:

Many to one assoication, use C<getUMLClassMetadata> to get the associated UMLClassMetadata.

=item Collection of L</AttributeTypeMetadata>:

Many to one assoication, use C<getAttributeTypeMetadata> to get the associated AttributeTypeMetadata.

=item Collection of L</DataElement>:

Many to one assoication, use C<getDataElement> to get the associated DataElement.

=item Collection of L</Project>:

Many to one assoication, use C<getProject> to get the associated Project.

=item Instance of L</SemanticMetadata>:

One to many assoication, use C<getSemanticMetadataCollection> to get a collection of associated SemanticMetadata.


=back

=cut

# Below is module documentation for UMLClassMetadata

=pod

=head1 UMLClassMetadata

CaCORE::CaDSR::UMLProject::UMLClassMetadata - Perl extension for UMLClassMetadata.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::UMLClassMetadata is a Perl object representation of the
CaCORE UMLClassMetadata object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of UMLClassMetadata

The following are all the attributes of the UMLClassMetadata object and their data types:

=over 4

=item description

data type: C<string>

=item fullyQualifiedName

data type: C<string>

=item id

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of UMLClassMetadata

The following are all the objects that are associated with the UMLClassMetadata:

=over 4

=item Instance of L</UMLAssociationMetadata>:

One to many assoication, use C<getUMLAssociationMetadataCollection> to get a collection of associated UMLAssociationMetadata.

=item Instance of L</UMLAttributeMetadata>:

One to many assoication, use C<getUMLAttributeMetadataCollection> to get a collection of associated UMLAttributeMetadata.

=item Collection of L</UMLGeneralizationMetadata>:

Many to one assoication, use C<getUMLGeneralizationMetadata> to get the associated UMLGeneralizationMetadata.

=item Collection of L</UMLPackageMetadata>:

Many to one assoication, use C<getUMLPackageMetadata> to get the associated UMLPackageMetadata.

=item Collection of L</ObjectClass>:

Many to one assoication, use C<getObjectClass> to get the associated ObjectClass.

=item Collection of L</Project>:

Many to one assoication, use C<getProject> to get the associated Project.

=item Instance of L</SemanticMetadata>:

One to many assoication, use C<getSemanticMetadataCollection> to get a collection of associated SemanticMetadata.


=back

=cut

# Below is module documentation for UMLGeneralizationMetadata

=pod

=head1 UMLGeneralizationMetadata

CaCORE::CaDSR::UMLProject::UMLGeneralizationMetadata - Perl extension for UMLGeneralizationMetadata.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::UMLGeneralizationMetadata is a Perl object representation of the
CaCORE UMLGeneralizationMetadata object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of UMLGeneralizationMetadata

The following are all the attributes of the UMLGeneralizationMetadata object and their data types:

=over 4

=item id

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of UMLGeneralizationMetadata

The following are all the objects that are associated with the UMLGeneralizationMetadata:

=over 4

=item Collection of L</ObjectClassRelationship>:

Many to one assoication, use C<getObjectClassRelationship> to get the associated ObjectClassRelationship.

=item Collection of L</SuperUMLClassMetadata>:

Many to one assoication, use C<getSuperUMLClassMetadata> to get the associated SuperUMLClassMetadata.


=back

=cut

# Below is module documentation for UMLPackageMetadata

=pod

=head1 UMLPackageMetadata

CaCORE::CaDSR::UMLProject::UMLPackageMetadata - Perl extension for UMLPackageMetadata.

=head2 ABSTRACT

The CaCORE::CaDSR::UMLProject::UMLPackageMetadata is a Perl object representation of the
CaCORE UMLPackageMetadata object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of UMLPackageMetadata

The following are all the attributes of the UMLPackageMetadata object and their data types:

=over 4

=item description

data type: C<string>

=item id

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of UMLPackageMetadata

The following are all the objects that are associated with the UMLPackageMetadata:

=over 4

=item Instance of L</UMLClassMetadata>:

One to many assoication, use C<getUMLClassMetadataCollection> to get a collection of associated UMLClassMetadata.

=item Collection of L</ClassSchemeClassSchemeItem>:

Many to one assoication, use C<getClassSchemeClassSchemeItem> to get the associated ClassSchemeClassSchemeItem.

=item Collection of L</Project>:

Many to one assoication, use C<getProject> to get the associated Project.

=item Collection of L</SubProject>:

Many to one assoication, use C<getSubProject> to get the associated SubProject.


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


