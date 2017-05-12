# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Context;

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

# create an instance of the Context object
# returns: a Context object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Context\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Context intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Context\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
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
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# languageName;
	if( defined( $self->getLanguageName ) ) {
		$tmpstr = "<languageName xsi:type=\"xsd:string\">" . $self->getLanguageName . "</languageName>";
	} else {
		$tmpstr = "<languageName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Context objects
# param: xml doc
# returns: list of Context objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Context objects
# param: xml node
# returns: a list of Context objects
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

# parse a given xml node, construct one Context object
# param: xml node
# returns: one Context object
sub fromWSXMLNode {
	my $ContextNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $description;
		my $id;
		my $languageName;
		my $modifiedBy;
		my $name;
		my $version;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ContextNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "languageName") {
				$languageName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Context;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setLanguageName($languageName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
		$newobj->setVersion($version);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
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

sub getLanguageName {
	my $self = shift;
	return $self->{languageName};
}

sub setLanguageName {
	my $self = shift;
	$self->{languageName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
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

sub getAdministeredComponentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponent", $self);
	return @results;
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::AdministeredComponent;

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

# create an instance of the AdministeredComponent object
# returns: a AdministeredComponent object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new AdministeredComponent\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this AdministeredComponent intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":AdministeredComponent\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of AdministeredComponent objects
# param: xml doc
# returns: list of AdministeredComponent objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of AdministeredComponent objects
# param: xml node
# returns: a list of AdministeredComponent objects
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

# parse a given xml node, construct one AdministeredComponent object
# param: xml node
# returns: one AdministeredComponent object
sub fromWSXMLNode {
	my $AdministeredComponentNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AdministeredComponentNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::AdministeredComponent;
	## begin set attr ##
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DerivationType;

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

# create an instance of the DerivationType object
# returns: a DerivationType object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DerivationType\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DerivationType intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DerivationType\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
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
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of DerivationType objects
# param: xml doc
# returns: list of DerivationType objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DerivationType objects
# param: xml node
# returns: a list of DerivationType objects
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

# parse a given xml node, construct one DerivationType object
# param: xml node
# returns: one DerivationType object
sub fromWSXMLNode {
	my $DerivationTypeNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $description;
		my $id;
		my $modifiedBy;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DerivationTypeNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DerivationType;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
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

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getConceptDerivationRuleCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return @results;
}

sub getDerivedDataElementCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DerivedDataElement", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ConceptDerivationRule;

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

# create an instance of the ConceptDerivationRule object
# returns: a ConceptDerivationRule object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ConceptDerivationRule\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ConceptDerivationRule intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ConceptDerivationRule\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ConceptDerivationRule objects
# param: xml doc
# returns: list of ConceptDerivationRule objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ConceptDerivationRule objects
# param: xml node
# returns: a list of ConceptDerivationRule objects
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

# parse a given xml node, construct one ConceptDerivationRule object
# param: xml node
# returns: one ConceptDerivationRule object
sub fromWSXMLNode {
	my $ConceptDerivationRuleNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ConceptDerivationRuleNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ConceptDerivationRule;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getClassificationSchemeCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationScheme", $self);
	return @results;
}

sub getClassificationSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeItem", $self);
	return @results;
}

sub getComponentConceptCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ComponentConcept", $self);
	return @results;
}

sub getConceptualDomainCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptualDomain", $self);
	return @results;
}

sub getDerivationType {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DerivationType", $self);
	return $results[0];
}

sub getObjectClassCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClass", $self);
	return @results;
}

sub getObjectClassRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClassRelationship", $self);
	return @results;
}

sub getPropertyCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Property", $self);
	return @results;
}

sub getRepresentationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Representation", $self);
	return @results;
}

sub getSourceRoleConceptCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Concept", $self);
	return @results;
}

sub getTargetRoleConceptCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Concept", $self);
	return @results;
}

sub getValueDomainCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomain", $self);
	return @results;
}

sub getValueMeaningCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueMeaning", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ConceptualDomain;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ConceptualDomain object
# returns: a ConceptualDomain object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ConceptualDomain\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ConceptualDomain intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ConceptualDomain\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# dimensionality;
	if( defined( $self->getDimensionality ) ) {
		$tmpstr = "<dimensionality xsi:type=\"xsd:string\">" . $self->getDimensionality . "</dimensionality>";
	} else {
		$tmpstr = "<dimensionality xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ConceptualDomain objects
# param: xml doc
# returns: list of ConceptualDomain objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ConceptualDomain objects
# param: xml node
# returns: a list of ConceptualDomain objects
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

# parse a given xml node, construct one ConceptualDomain object
# param: xml node
# returns: one ConceptualDomain object
sub fromWSXMLNode {
	my $ConceptualDomainNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $dimensionality;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ConceptualDomainNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "dimensionality") {
				$dimensionality=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ConceptualDomain;
	## begin set attr ##
		$newobj->setDimensionality($dimensionality);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDimensionality {
	my $self = shift;
	return $self->{dimensionality};
}

sub setDimensionality {
	my $self = shift;
	$self->{dimensionality} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getDataElementConceptCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementConcept", $self);
	return @results;
}

sub getValueDomainCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomain", $self);
	return @results;
}

sub getValueMeaningCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueMeaning", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ObjectClass;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ObjectClass object
# returns: a ObjectClass object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ObjectClass\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ObjectClass intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ObjectClass\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# definitionSource;
	if( defined( $self->getDefinitionSource ) ) {
		$tmpstr = "<definitionSource xsi:type=\"xsd:string\">" . $self->getDefinitionSource . "</definitionSource>";
	} else {
		$tmpstr = "<definitionSource xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ObjectClass objects
# param: xml doc
# returns: list of ObjectClass objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ObjectClass objects
# param: xml node
# returns: a list of ObjectClass objects
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

# parse a given xml node, construct one ObjectClass object
# param: xml node
# returns: one ObjectClass object
sub fromWSXMLNode {
	my $ObjectClassNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $definitionSource;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ObjectClassNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "definitionSource") {
				$definitionSource=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ObjectClass;
	## begin set attr ##
		$newobj->setDefinitionSource($definitionSource);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDefinitionSource {
	my $self = shift;
	return $self->{definitionSource};
}

sub setDefinitionSource {
	my $self = shift;
	$self->{definitionSource} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getDataElementConceptCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementConcept", $self);
	return @results;
}

sub getSourcObjectClassRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClassRelationship", $self);
	return @results;
}

sub getTargetObjectClassRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClassRelationship", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Property;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
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
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Property\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# definitionSource;
	if( defined( $self->getDefinitionSource ) ) {
		$tmpstr = "<definitionSource xsi:type=\"xsd:string\">" . $self->getDefinitionSource . "</definitionSource>";
	} else {
		$tmpstr = "<definitionSource xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
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
		my $definitionSource;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
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
			elsif ($childrenNode->getNodeName eq "definitionSource") {
				$definitionSource=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Property;
	## begin set attr ##
		$newobj->setDefinitionSource($definitionSource);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDefinitionSource {
	my $self = shift;
	return $self->{definitionSource};
}

sub setDefinitionSource {
	my $self = shift;
	$self->{definitionSource} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getDataElementConceptCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementConcept", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DataElementConcept;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the DataElementConcept object
# returns: a DataElementConcept object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DataElementConcept\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DataElementConcept intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DataElementConcept\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DataElementConcept objects
# param: xml doc
# returns: list of DataElementConcept objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DataElementConcept objects
# param: xml node
# returns: a list of DataElementConcept objects
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

# parse a given xml node, construct one DataElementConcept object
# param: xml node
# returns: one DataElementConcept object
sub fromWSXMLNode {
	my $DataElementConceptNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DataElementConceptNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DataElementConcept;
	## begin set attr ##
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildDataElementConceptRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementConceptRelationship", $self);
	return @results;
}

sub getConceptualDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptualDomain", $self);
	return $results[0];
}

sub getDataElementCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return @results;
}

sub getObjectClass {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClass", $self);
	return $results[0];
}

sub getParentDataElementConceptRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementConceptRelationship", $self);
	return @results;
}

sub getProperty {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Property", $self);
	return $results[0];
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Representation;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Representation object
# returns: a Representation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Representation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Representation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Representation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# definitionSource;
	if( defined( $self->getDefinitionSource ) ) {
		$tmpstr = "<definitionSource xsi:type=\"xsd:string\">" . $self->getDefinitionSource . "</definitionSource>";
	} else {
		$tmpstr = "<definitionSource xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Representation objects
# param: xml doc
# returns: list of Representation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Representation objects
# param: xml node
# returns: a list of Representation objects
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

# parse a given xml node, construct one Representation object
# param: xml node
# returns: one Representation object
sub fromWSXMLNode {
	my $RepresentationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $definitionSource;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($RepresentationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "definitionSource") {
				$definitionSource=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Representation;
	## begin set attr ##
		$newobj->setDefinitionSource($definitionSource);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDefinitionSource {
	my $self = shift;
	return $self->{definitionSource};
}

sub setDefinitionSource {
	my $self = shift;
	$self->{definitionSource} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getValueDomainCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomain", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ValueDomain;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ValueDomain object
# returns: a ValueDomain object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ValueDomain\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ValueDomain intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ValueDomain\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# UOMName;
	if( defined( $self->getUOMName ) ) {
		$tmpstr = "<UOMName xsi:type=\"xsd:string\">" . $self->getUOMName . "</UOMName>";
	} else {
		$tmpstr = "<UOMName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# characterSetName;
	if( defined( $self->getCharacterSetName ) ) {
		$tmpstr = "<characterSetName xsi:type=\"xsd:string\">" . $self->getCharacterSetName . "</characterSetName>";
	} else {
		$tmpstr = "<characterSetName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeAnnotation;
	if( defined( $self->getDatatypeAnnotation ) ) {
		$tmpstr = "<datatypeAnnotation xsi:type=\"xsd:string\">" . $self->getDatatypeAnnotation . "</datatypeAnnotation>";
	} else {
		$tmpstr = "<datatypeAnnotation xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeDescription;
	if( defined( $self->getDatatypeDescription ) ) {
		$tmpstr = "<datatypeDescription xsi:type=\"xsd:string\">" . $self->getDatatypeDescription . "</datatypeDescription>";
	} else {
		$tmpstr = "<datatypeDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeIsCodegenCompatible;
	if( defined( $self->getDatatypeIsCodegenCompatible ) ) {
		$tmpstr = "<datatypeIsCodegenCompatible xsi:type=\"xsd:string\">" . $self->getDatatypeIsCodegenCompatible . "</datatypeIsCodegenCompatible>";
	} else {
		$tmpstr = "<datatypeIsCodegenCompatible xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeName;
	if( defined( $self->getDatatypeName ) ) {
		$tmpstr = "<datatypeName xsi:type=\"xsd:string\">" . $self->getDatatypeName . "</datatypeName>";
	} else {
		$tmpstr = "<datatypeName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeSchemeReference;
	if( defined( $self->getDatatypeSchemeReference ) ) {
		$tmpstr = "<datatypeSchemeReference xsi:type=\"xsd:string\">" . $self->getDatatypeSchemeReference . "</datatypeSchemeReference>";
	} else {
		$tmpstr = "<datatypeSchemeReference xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# decimalPlace;
	if( defined( $self->getDecimalPlace ) ) {
		$tmpstr = "<decimalPlace xsi:type=\"xsd:int\">" . $self->getDecimalPlace . "</decimalPlace>";
	} else {
		$tmpstr = "<decimalPlace xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# formatName;
	if( defined( $self->getFormatName ) ) {
		$tmpstr = "<formatName xsi:type=\"xsd:string\">" . $self->getFormatName . "</formatName>";
	} else {
		$tmpstr = "<formatName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# highValueNumber;
	if( defined( $self->getHighValueNumber ) ) {
		$tmpstr = "<highValueNumber xsi:type=\"xsd:string\">" . $self->getHighValueNumber . "</highValueNumber>";
	} else {
		$tmpstr = "<highValueNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# lowValueNumber;
	if( defined( $self->getLowValueNumber ) ) {
		$tmpstr = "<lowValueNumber xsi:type=\"xsd:string\">" . $self->getLowValueNumber . "</lowValueNumber>";
	} else {
		$tmpstr = "<lowValueNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# maximumLengthNumber;
	if( defined( $self->getMaximumLengthNumber ) ) {
		$tmpstr = "<maximumLengthNumber xsi:type=\"xsd:int\">" . $self->getMaximumLengthNumber . "</maximumLengthNumber>";
	} else {
		$tmpstr = "<maximumLengthNumber xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# minimumLengthNumber;
	if( defined( $self->getMinimumLengthNumber ) ) {
		$tmpstr = "<minimumLengthNumber xsi:type=\"xsd:int\">" . $self->getMinimumLengthNumber . "</minimumLengthNumber>";
	} else {
		$tmpstr = "<minimumLengthNumber xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ValueDomain objects
# param: xml doc
# returns: list of ValueDomain objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ValueDomain objects
# param: xml node
# returns: a list of ValueDomain objects
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

# parse a given xml node, construct one ValueDomain object
# param: xml node
# returns: one ValueDomain object
sub fromWSXMLNode {
	my $ValueDomainNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $UOMName;
		my $characterSetName;
		my $datatypeAnnotation;
		my $datatypeDescription;
		my $datatypeIsCodegenCompatible;
		my $datatypeName;
		my $datatypeSchemeReference;
		my $decimalPlace;
		my $formatName;
		my $highValueNumber;
		my $lowValueNumber;
		my $maximumLengthNumber;
		my $minimumLengthNumber;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ValueDomainNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "UOMName") {
				$UOMName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "characterSetName") {
				$characterSetName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeAnnotation") {
				$datatypeAnnotation=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeDescription") {
				$datatypeDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeIsCodegenCompatible") {
				$datatypeIsCodegenCompatible=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeName") {
				$datatypeName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeSchemeReference") {
				$datatypeSchemeReference=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "decimalPlace") {
				$decimalPlace=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "formatName") {
				$formatName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "highValueNumber") {
				$highValueNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "lowValueNumber") {
				$lowValueNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "maximumLengthNumber") {
				$maximumLengthNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "minimumLengthNumber") {
				$minimumLengthNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ValueDomain;
	## begin set attr ##
		$newobj->setUOMName($UOMName);
		$newobj->setCharacterSetName($characterSetName);
		$newobj->setDatatypeAnnotation($datatypeAnnotation);
		$newobj->setDatatypeDescription($datatypeDescription);
		$newobj->setDatatypeIsCodegenCompatible($datatypeIsCodegenCompatible);
		$newobj->setDatatypeName($datatypeName);
		$newobj->setDatatypeSchemeReference($datatypeSchemeReference);
		$newobj->setDecimalPlace($decimalPlace);
		$newobj->setFormatName($formatName);
		$newobj->setHighValueNumber($highValueNumber);
		$newobj->setLowValueNumber($lowValueNumber);
		$newobj->setMaximumLengthNumber($maximumLengthNumber);
		$newobj->setMinimumLengthNumber($minimumLengthNumber);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getUOMName {
	my $self = shift;
	return $self->{UOMName};
}

sub setUOMName {
	my $self = shift;
	$self->{UOMName} = shift;
}

sub getCharacterSetName {
	my $self = shift;
	return $self->{characterSetName};
}

sub setCharacterSetName {
	my $self = shift;
	$self->{characterSetName} = shift;
}

sub getDatatypeAnnotation {
	my $self = shift;
	return $self->{datatypeAnnotation};
}

sub setDatatypeAnnotation {
	my $self = shift;
	$self->{datatypeAnnotation} = shift;
}

sub getDatatypeDescription {
	my $self = shift;
	return $self->{datatypeDescription};
}

sub setDatatypeDescription {
	my $self = shift;
	$self->{datatypeDescription} = shift;
}

sub getDatatypeIsCodegenCompatible {
	my $self = shift;
	return $self->{datatypeIsCodegenCompatible};
}

sub setDatatypeIsCodegenCompatible {
	my $self = shift;
	$self->{datatypeIsCodegenCompatible} = shift;
}

sub getDatatypeName {
	my $self = shift;
	return $self->{datatypeName};
}

sub setDatatypeName {
	my $self = shift;
	$self->{datatypeName} = shift;
}

sub getDatatypeSchemeReference {
	my $self = shift;
	return $self->{datatypeSchemeReference};
}

sub setDatatypeSchemeReference {
	my $self = shift;
	$self->{datatypeSchemeReference} = shift;
}

sub getDecimalPlace {
	my $self = shift;
	return $self->{decimalPlace};
}

sub setDecimalPlace {
	my $self = shift;
	$self->{decimalPlace} = shift;
}

sub getFormatName {
	my $self = shift;
	return $self->{formatName};
}

sub setFormatName {
	my $self = shift;
	$self->{formatName} = shift;
}

sub getHighValueNumber {
	my $self = shift;
	return $self->{highValueNumber};
}

sub setHighValueNumber {
	my $self = shift;
	$self->{highValueNumber} = shift;
}

sub getLowValueNumber {
	my $self = shift;
	return $self->{lowValueNumber};
}

sub setLowValueNumber {
	my $self = shift;
	$self->{lowValueNumber} = shift;
}

sub getMaximumLengthNumber {
	my $self = shift;
	return $self->{maximumLengthNumber};
}

sub setMaximumLengthNumber {
	my $self = shift;
	$self->{maximumLengthNumber} = shift;
}

sub getMinimumLengthNumber {
	my $self = shift;
	return $self->{minimumLengthNumber};
}

sub setMinimumLengthNumber {
	my $self = shift;
	$self->{minimumLengthNumber} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildValueDomainRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainRelationship", $self);
	return @results;
}

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getConceptualDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptualDomain", $self);
	return $results[0];
}

sub getDataElementCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return @results;
}

sub getParentValueDomainRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainRelationship", $self);
	return @results;
}

sub getQuestionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return @results;
}

sub getRepresention {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Representation", $self);
	return $results[0];
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::EnumeratedValueDomain;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::ValueDomain);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the EnumeratedValueDomain object
# returns: a EnumeratedValueDomain object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new EnumeratedValueDomain\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this EnumeratedValueDomain intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":EnumeratedValueDomain\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# UOMName;
	if( defined( $self->getUOMName ) ) {
		$tmpstr = "<UOMName xsi:type=\"xsd:string\">" . $self->getUOMName . "</UOMName>";
	} else {
		$tmpstr = "<UOMName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# characterSetName;
	if( defined( $self->getCharacterSetName ) ) {
		$tmpstr = "<characterSetName xsi:type=\"xsd:string\">" . $self->getCharacterSetName . "</characterSetName>";
	} else {
		$tmpstr = "<characterSetName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeAnnotation;
	if( defined( $self->getDatatypeAnnotation ) ) {
		$tmpstr = "<datatypeAnnotation xsi:type=\"xsd:string\">" . $self->getDatatypeAnnotation . "</datatypeAnnotation>";
	} else {
		$tmpstr = "<datatypeAnnotation xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeDescription;
	if( defined( $self->getDatatypeDescription ) ) {
		$tmpstr = "<datatypeDescription xsi:type=\"xsd:string\">" . $self->getDatatypeDescription . "</datatypeDescription>";
	} else {
		$tmpstr = "<datatypeDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeIsCodegenCompatible;
	if( defined( $self->getDatatypeIsCodegenCompatible ) ) {
		$tmpstr = "<datatypeIsCodegenCompatible xsi:type=\"xsd:string\">" . $self->getDatatypeIsCodegenCompatible . "</datatypeIsCodegenCompatible>";
	} else {
		$tmpstr = "<datatypeIsCodegenCompatible xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeName;
	if( defined( $self->getDatatypeName ) ) {
		$tmpstr = "<datatypeName xsi:type=\"xsd:string\">" . $self->getDatatypeName . "</datatypeName>";
	} else {
		$tmpstr = "<datatypeName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeSchemeReference;
	if( defined( $self->getDatatypeSchemeReference ) ) {
		$tmpstr = "<datatypeSchemeReference xsi:type=\"xsd:string\">" . $self->getDatatypeSchemeReference . "</datatypeSchemeReference>";
	} else {
		$tmpstr = "<datatypeSchemeReference xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# decimalPlace;
	if( defined( $self->getDecimalPlace ) ) {
		$tmpstr = "<decimalPlace xsi:type=\"xsd:int\">" . $self->getDecimalPlace . "</decimalPlace>";
	} else {
		$tmpstr = "<decimalPlace xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# formatName;
	if( defined( $self->getFormatName ) ) {
		$tmpstr = "<formatName xsi:type=\"xsd:string\">" . $self->getFormatName . "</formatName>";
	} else {
		$tmpstr = "<formatName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# highValueNumber;
	if( defined( $self->getHighValueNumber ) ) {
		$tmpstr = "<highValueNumber xsi:type=\"xsd:string\">" . $self->getHighValueNumber . "</highValueNumber>";
	} else {
		$tmpstr = "<highValueNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# lowValueNumber;
	if( defined( $self->getLowValueNumber ) ) {
		$tmpstr = "<lowValueNumber xsi:type=\"xsd:string\">" . $self->getLowValueNumber . "</lowValueNumber>";
	} else {
		$tmpstr = "<lowValueNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# maximumLengthNumber;
	if( defined( $self->getMaximumLengthNumber ) ) {
		$tmpstr = "<maximumLengthNumber xsi:type=\"xsd:int\">" . $self->getMaximumLengthNumber . "</maximumLengthNumber>";
	} else {
		$tmpstr = "<maximumLengthNumber xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# minimumLengthNumber;
	if( defined( $self->getMinimumLengthNumber ) ) {
		$tmpstr = "<minimumLengthNumber xsi:type=\"xsd:int\">" . $self->getMinimumLengthNumber . "</minimumLengthNumber>";
	} else {
		$tmpstr = "<minimumLengthNumber xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of EnumeratedValueDomain objects
# param: xml doc
# returns: list of EnumeratedValueDomain objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of EnumeratedValueDomain objects
# param: xml node
# returns: a list of EnumeratedValueDomain objects
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

# parse a given xml node, construct one EnumeratedValueDomain object
# param: xml node
# returns: one EnumeratedValueDomain object
sub fromWSXMLNode {
	my $EnumeratedValueDomainNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $UOMName;
		my $characterSetName;
		my $datatypeAnnotation;
		my $datatypeDescription;
		my $datatypeIsCodegenCompatible;
		my $datatypeName;
		my $datatypeSchemeReference;
		my $decimalPlace;
		my $formatName;
		my $highValueNumber;
		my $lowValueNumber;
		my $maximumLengthNumber;
		my $minimumLengthNumber;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($EnumeratedValueDomainNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "UOMName") {
				$UOMName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "characterSetName") {
				$characterSetName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeAnnotation") {
				$datatypeAnnotation=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeDescription") {
				$datatypeDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeIsCodegenCompatible") {
				$datatypeIsCodegenCompatible=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeName") {
				$datatypeName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeSchemeReference") {
				$datatypeSchemeReference=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "decimalPlace") {
				$decimalPlace=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "formatName") {
				$formatName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "highValueNumber") {
				$highValueNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "lowValueNumber") {
				$lowValueNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "maximumLengthNumber") {
				$maximumLengthNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "minimumLengthNumber") {
				$minimumLengthNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::EnumeratedValueDomain;
	## begin set attr ##
		$newobj->setUOMName($UOMName);
		$newobj->setCharacterSetName($characterSetName);
		$newobj->setDatatypeAnnotation($datatypeAnnotation);
		$newobj->setDatatypeDescription($datatypeDescription);
		$newobj->setDatatypeIsCodegenCompatible($datatypeIsCodegenCompatible);
		$newobj->setDatatypeName($datatypeName);
		$newobj->setDatatypeSchemeReference($datatypeSchemeReference);
		$newobj->setDecimalPlace($decimalPlace);
		$newobj->setFormatName($formatName);
		$newobj->setHighValueNumber($highValueNumber);
		$newobj->setLowValueNumber($lowValueNumber);
		$newobj->setMaximumLengthNumber($maximumLengthNumber);
		$newobj->setMinimumLengthNumber($minimumLengthNumber);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getUOMName {
	my $self = shift;
	return $self->{UOMName};
}

sub setUOMName {
	my $self = shift;
	$self->{UOMName} = shift;
}

sub getCharacterSetName {
	my $self = shift;
	return $self->{characterSetName};
}

sub setCharacterSetName {
	my $self = shift;
	$self->{characterSetName} = shift;
}

sub getDatatypeAnnotation {
	my $self = shift;
	return $self->{datatypeAnnotation};
}

sub setDatatypeAnnotation {
	my $self = shift;
	$self->{datatypeAnnotation} = shift;
}

sub getDatatypeDescription {
	my $self = shift;
	return $self->{datatypeDescription};
}

sub setDatatypeDescription {
	my $self = shift;
	$self->{datatypeDescription} = shift;
}

sub getDatatypeIsCodegenCompatible {
	my $self = shift;
	return $self->{datatypeIsCodegenCompatible};
}

sub setDatatypeIsCodegenCompatible {
	my $self = shift;
	$self->{datatypeIsCodegenCompatible} = shift;
}

sub getDatatypeName {
	my $self = shift;
	return $self->{datatypeName};
}

sub setDatatypeName {
	my $self = shift;
	$self->{datatypeName} = shift;
}

sub getDatatypeSchemeReference {
	my $self = shift;
	return $self->{datatypeSchemeReference};
}

sub setDatatypeSchemeReference {
	my $self = shift;
	$self->{datatypeSchemeReference} = shift;
}

sub getDecimalPlace {
	my $self = shift;
	return $self->{decimalPlace};
}

sub setDecimalPlace {
	my $self = shift;
	$self->{decimalPlace} = shift;
}

sub getFormatName {
	my $self = shift;
	return $self->{formatName};
}

sub setFormatName {
	my $self = shift;
	$self->{formatName} = shift;
}

sub getHighValueNumber {
	my $self = shift;
	return $self->{highValueNumber};
}

sub setHighValueNumber {
	my $self = shift;
	$self->{highValueNumber} = shift;
}

sub getLowValueNumber {
	my $self = shift;
	return $self->{lowValueNumber};
}

sub setLowValueNumber {
	my $self = shift;
	$self->{lowValueNumber} = shift;
}

sub getMaximumLengthNumber {
	my $self = shift;
	return $self->{maximumLengthNumber};
}

sub setMaximumLengthNumber {
	my $self = shift;
	$self->{maximumLengthNumber} = shift;
}

sub getMinimumLengthNumber {
	my $self = shift;
	return $self->{minimumLengthNumber};
}

sub setMinimumLengthNumber {
	my $self = shift;
	$self->{minimumLengthNumber} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getValueDomainPermissibleValueCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainPermissibleValue", $self);
	return @results;
}

sub getChildValueDomainRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainRelationship", $self);
	return @results;
}

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getConceptualDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptualDomain", $self);
	return $results[0];
}

sub getDataElementCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return @results;
}

sub getParentValueDomainRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainRelationship", $self);
	return @results;
}

sub getQuestionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return @results;
}

sub getRepresention {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Representation", $self);
	return $results[0];
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::NonenumeratedValueDomain;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::ValueDomain);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the NonenumeratedValueDomain object
# returns: a NonenumeratedValueDomain object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new NonenumeratedValueDomain\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this NonenumeratedValueDomain intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":NonenumeratedValueDomain\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# UOMName;
	if( defined( $self->getUOMName ) ) {
		$tmpstr = "<UOMName xsi:type=\"xsd:string\">" . $self->getUOMName . "</UOMName>";
	} else {
		$tmpstr = "<UOMName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# characterSetName;
	if( defined( $self->getCharacterSetName ) ) {
		$tmpstr = "<characterSetName xsi:type=\"xsd:string\">" . $self->getCharacterSetName . "</characterSetName>";
	} else {
		$tmpstr = "<characterSetName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeAnnotation;
	if( defined( $self->getDatatypeAnnotation ) ) {
		$tmpstr = "<datatypeAnnotation xsi:type=\"xsd:string\">" . $self->getDatatypeAnnotation . "</datatypeAnnotation>";
	} else {
		$tmpstr = "<datatypeAnnotation xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeDescription;
	if( defined( $self->getDatatypeDescription ) ) {
		$tmpstr = "<datatypeDescription xsi:type=\"xsd:string\">" . $self->getDatatypeDescription . "</datatypeDescription>";
	} else {
		$tmpstr = "<datatypeDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeIsCodegenCompatible;
	if( defined( $self->getDatatypeIsCodegenCompatible ) ) {
		$tmpstr = "<datatypeIsCodegenCompatible xsi:type=\"xsd:string\">" . $self->getDatatypeIsCodegenCompatible . "</datatypeIsCodegenCompatible>";
	} else {
		$tmpstr = "<datatypeIsCodegenCompatible xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeName;
	if( defined( $self->getDatatypeName ) ) {
		$tmpstr = "<datatypeName xsi:type=\"xsd:string\">" . $self->getDatatypeName . "</datatypeName>";
	} else {
		$tmpstr = "<datatypeName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# datatypeSchemeReference;
	if( defined( $self->getDatatypeSchemeReference ) ) {
		$tmpstr = "<datatypeSchemeReference xsi:type=\"xsd:string\">" . $self->getDatatypeSchemeReference . "</datatypeSchemeReference>";
	} else {
		$tmpstr = "<datatypeSchemeReference xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# decimalPlace;
	if( defined( $self->getDecimalPlace ) ) {
		$tmpstr = "<decimalPlace xsi:type=\"xsd:int\">" . $self->getDecimalPlace . "</decimalPlace>";
	} else {
		$tmpstr = "<decimalPlace xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# formatName;
	if( defined( $self->getFormatName ) ) {
		$tmpstr = "<formatName xsi:type=\"xsd:string\">" . $self->getFormatName . "</formatName>";
	} else {
		$tmpstr = "<formatName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# highValueNumber;
	if( defined( $self->getHighValueNumber ) ) {
		$tmpstr = "<highValueNumber xsi:type=\"xsd:string\">" . $self->getHighValueNumber . "</highValueNumber>";
	} else {
		$tmpstr = "<highValueNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# lowValueNumber;
	if( defined( $self->getLowValueNumber ) ) {
		$tmpstr = "<lowValueNumber xsi:type=\"xsd:string\">" . $self->getLowValueNumber . "</lowValueNumber>";
	} else {
		$tmpstr = "<lowValueNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# maximumLengthNumber;
	if( defined( $self->getMaximumLengthNumber ) ) {
		$tmpstr = "<maximumLengthNumber xsi:type=\"xsd:int\">" . $self->getMaximumLengthNumber . "</maximumLengthNumber>";
	} else {
		$tmpstr = "<maximumLengthNumber xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# minimumLengthNumber;
	if( defined( $self->getMinimumLengthNumber ) ) {
		$tmpstr = "<minimumLengthNumber xsi:type=\"xsd:int\">" . $self->getMinimumLengthNumber . "</minimumLengthNumber>";
	} else {
		$tmpstr = "<minimumLengthNumber xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of NonenumeratedValueDomain objects
# param: xml doc
# returns: list of NonenumeratedValueDomain objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of NonenumeratedValueDomain objects
# param: xml node
# returns: a list of NonenumeratedValueDomain objects
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

# parse a given xml node, construct one NonenumeratedValueDomain object
# param: xml node
# returns: one NonenumeratedValueDomain object
sub fromWSXMLNode {
	my $NonenumeratedValueDomainNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $UOMName;
		my $characterSetName;
		my $datatypeAnnotation;
		my $datatypeDescription;
		my $datatypeIsCodegenCompatible;
		my $datatypeName;
		my $datatypeSchemeReference;
		my $decimalPlace;
		my $formatName;
		my $highValueNumber;
		my $lowValueNumber;
		my $maximumLengthNumber;
		my $minimumLengthNumber;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($NonenumeratedValueDomainNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "UOMName") {
				$UOMName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "characterSetName") {
				$characterSetName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeAnnotation") {
				$datatypeAnnotation=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeDescription") {
				$datatypeDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeIsCodegenCompatible") {
				$datatypeIsCodegenCompatible=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeName") {
				$datatypeName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "datatypeSchemeReference") {
				$datatypeSchemeReference=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "decimalPlace") {
				$decimalPlace=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "formatName") {
				$formatName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "highValueNumber") {
				$highValueNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "lowValueNumber") {
				$lowValueNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "maximumLengthNumber") {
				$maximumLengthNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "minimumLengthNumber") {
				$minimumLengthNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::NonenumeratedValueDomain;
	## begin set attr ##
		$newobj->setUOMName($UOMName);
		$newobj->setCharacterSetName($characterSetName);
		$newobj->setDatatypeAnnotation($datatypeAnnotation);
		$newobj->setDatatypeDescription($datatypeDescription);
		$newobj->setDatatypeIsCodegenCompatible($datatypeIsCodegenCompatible);
		$newobj->setDatatypeName($datatypeName);
		$newobj->setDatatypeSchemeReference($datatypeSchemeReference);
		$newobj->setDecimalPlace($decimalPlace);
		$newobj->setFormatName($formatName);
		$newobj->setHighValueNumber($highValueNumber);
		$newobj->setLowValueNumber($lowValueNumber);
		$newobj->setMaximumLengthNumber($maximumLengthNumber);
		$newobj->setMinimumLengthNumber($minimumLengthNumber);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getUOMName {
	my $self = shift;
	return $self->{UOMName};
}

sub setUOMName {
	my $self = shift;
	$self->{UOMName} = shift;
}

sub getCharacterSetName {
	my $self = shift;
	return $self->{characterSetName};
}

sub setCharacterSetName {
	my $self = shift;
	$self->{characterSetName} = shift;
}

sub getDatatypeAnnotation {
	my $self = shift;
	return $self->{datatypeAnnotation};
}

sub setDatatypeAnnotation {
	my $self = shift;
	$self->{datatypeAnnotation} = shift;
}

sub getDatatypeDescription {
	my $self = shift;
	return $self->{datatypeDescription};
}

sub setDatatypeDescription {
	my $self = shift;
	$self->{datatypeDescription} = shift;
}

sub getDatatypeIsCodegenCompatible {
	my $self = shift;
	return $self->{datatypeIsCodegenCompatible};
}

sub setDatatypeIsCodegenCompatible {
	my $self = shift;
	$self->{datatypeIsCodegenCompatible} = shift;
}

sub getDatatypeName {
	my $self = shift;
	return $self->{datatypeName};
}

sub setDatatypeName {
	my $self = shift;
	$self->{datatypeName} = shift;
}

sub getDatatypeSchemeReference {
	my $self = shift;
	return $self->{datatypeSchemeReference};
}

sub setDatatypeSchemeReference {
	my $self = shift;
	$self->{datatypeSchemeReference} = shift;
}

sub getDecimalPlace {
	my $self = shift;
	return $self->{decimalPlace};
}

sub setDecimalPlace {
	my $self = shift;
	$self->{decimalPlace} = shift;
}

sub getFormatName {
	my $self = shift;
	return $self->{formatName};
}

sub setFormatName {
	my $self = shift;
	$self->{formatName} = shift;
}

sub getHighValueNumber {
	my $self = shift;
	return $self->{highValueNumber};
}

sub setHighValueNumber {
	my $self = shift;
	$self->{highValueNumber} = shift;
}

sub getLowValueNumber {
	my $self = shift;
	return $self->{lowValueNumber};
}

sub setLowValueNumber {
	my $self = shift;
	$self->{lowValueNumber} = shift;
}

sub getMaximumLengthNumber {
	my $self = shift;
	return $self->{maximumLengthNumber};
}

sub setMaximumLengthNumber {
	my $self = shift;
	$self->{maximumLengthNumber} = shift;
}

sub getMinimumLengthNumber {
	my $self = shift;
	return $self->{minimumLengthNumber};
}

sub setMinimumLengthNumber {
	my $self = shift;
	$self->{minimumLengthNumber} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildValueDomainRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainRelationship", $self);
	return @results;
}

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getConceptualDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptualDomain", $self);
	return $results[0];
}

sub getDataElementCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return @results;
}

sub getParentValueDomainRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainRelationship", $self);
	return @results;
}

sub getQuestionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return @results;
}

sub getRepresention {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Representation", $self);
	return $results[0];
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DataElement;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the DataElement object
# returns: a DataElement object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DataElement\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DataElement intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DataElement\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DataElement objects
# param: xml doc
# returns: list of DataElement objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DataElement objects
# param: xml node
# returns: a list of DataElement objects
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

# parse a given xml node, construct one DataElement object
# param: xml node
# returns: one DataElement object
sub fromWSXMLNode {
	my $DataElementNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DataElementNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DataElement;
	## begin set attr ##
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildDataElementRelationshipsCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementRelationship", $self);
	return @results;
}

sub getDataElementConcept {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementConcept", $self);
	return $results[0];
}

sub getDataElementDerivationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementDerivation", $self);
	return @results;
}

sub getDerivedDataElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DerivedDataElement", $self);
	return $results[0];
}

sub getParentDataElementRelationshipsCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementRelationship", $self);
	return @results;
}

sub getQuestionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return @results;
}

sub getValueDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomain", $self);
	return $results[0];
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DerivedDataElement;

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

# create an instance of the DerivedDataElement object
# returns: a DerivedDataElement object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DerivedDataElement\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DerivedDataElement intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DerivedDataElement\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# concatenationCharacter;
	if( defined( $self->getConcatenationCharacter ) ) {
		$tmpstr = "<concatenationCharacter xsi:type=\"xsd:string\">" . $self->getConcatenationCharacter . "</concatenationCharacter>";
	} else {
		$tmpstr = "<concatenationCharacter xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# methods;
	if( defined( $self->getMethods ) ) {
		$tmpstr = "<methods xsi:type=\"xsd:string\">" . $self->getMethods . "</methods>";
	} else {
		$tmpstr = "<methods xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# rule;
	if( defined( $self->getRule ) ) {
		$tmpstr = "<rule xsi:type=\"xsd:string\">" . $self->getRule . "</rule>";
	} else {
		$tmpstr = "<rule xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DerivedDataElement objects
# param: xml doc
# returns: list of DerivedDataElement objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DerivedDataElement objects
# param: xml node
# returns: a list of DerivedDataElement objects
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

# parse a given xml node, construct one DerivedDataElement object
# param: xml node
# returns: one DerivedDataElement object
sub fromWSXMLNode {
	my $DerivedDataElementNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $concatenationCharacter;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $methods;
		my $modifiedBy;
		my $rule;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DerivedDataElementNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "concatenationCharacter") {
				$concatenationCharacter=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "methods") {
				$methods=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "rule") {
				$rule=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DerivedDataElement;
	## begin set attr ##
		$newobj->setConcatenationCharacter($concatenationCharacter);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setMethods($methods);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setRule($rule);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getConcatenationCharacter {
	my $self = shift;
	return $self->{concatenationCharacter};
}

sub setConcatenationCharacter {
	my $self = shift;
	$self->{concatenationCharacter} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getMethods {
	my $self = shift;
	return $self->{methods};
}

sub setMethods {
	my $self = shift;
	$self->{methods} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getRule {
	my $self = shift;
	return $self->{rule};
}

sub setRule {
	my $self = shift;
	$self->{rule} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getDataElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return $results[0];
}

sub getDataElementDerivationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementDerivation", $self);
	return @results;
}

sub getDerivationType {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DerivationType", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::FormElement;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the FormElement object
# returns: a FormElement object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new FormElement\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this FormElement intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":FormElement\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of FormElement objects
# param: xml doc
# returns: list of FormElement objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of FormElement objects
# param: xml node
# returns: a list of FormElement objects
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

# parse a given xml node, construct one FormElement object
# param: xml node
# returns: one FormElement object
sub fromWSXMLNode {
	my $FormElementNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($FormElementNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::FormElement;
	## begin set attr ##
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getInstructionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Instruction", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Form;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::FormElement);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Form object
# returns: a Form object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Form\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Form intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Form\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# displayName;
	if( defined( $self->getDisplayName ) ) {
		$tmpstr = "<displayName xsi:type=\"xsd:string\">" . $self->getDisplayName . "</displayName>";
	} else {
		$tmpstr = "<displayName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Form objects
# param: xml doc
# returns: list of Form objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Form objects
# param: xml node
# returns: a list of Form objects
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

# parse a given xml node, construct one Form object
# param: xml node
# returns: one Form object
sub fromWSXMLNode {
	my $FormNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $displayName;
		my $type;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($FormNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "displayName") {
				$displayName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Form;
	## begin set attr ##
		$newobj->setDisplayName($displayName);
		$newobj->setType($type);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDisplayName {
	my $self = shift;
	return $self->{displayName};
}

sub setDisplayName {
	my $self = shift;
	$self->{displayName} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getModuleCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Module", $self);
	return @results;
}

sub getProtocolCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Protocol", $self);
	return @results;
}

sub getInstructionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Instruction", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Module;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::FormElement);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Module object
# returns: a Module object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Module\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Module intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Module\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# maximumQuestionRepeat;
	if( defined( $self->getMaximumQuestionRepeat ) ) {
		$tmpstr = "<maximumQuestionRepeat xsi:type=\"xsd:int\">" . $self->getMaximumQuestionRepeat . "</maximumQuestionRepeat>";
	} else {
		$tmpstr = "<maximumQuestionRepeat xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Module objects
# param: xml doc
# returns: list of Module objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Module objects
# param: xml node
# returns: a list of Module objects
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

# parse a given xml node, construct one Module object
# param: xml node
# returns: one Module object
sub fromWSXMLNode {
	my $ModuleNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $displayOrder;
		my $maximumQuestionRepeat;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ModuleNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "maximumQuestionRepeat") {
				$maximumQuestionRepeat=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Module;
	## begin set attr ##
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setMaximumQuestionRepeat($maximumQuestionRepeat);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getMaximumQuestionRepeat {
	my $self = shift;
	return $self->{maximumQuestionRepeat};
}

sub setMaximumQuestionRepeat {
	my $self = shift;
	$self->{maximumQuestionRepeat} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getForm {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Form", $self);
	return $results[0];
}

sub getQuestionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return @results;
}

sub getInstructionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Instruction", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::QuestionCondition;

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

# create an instance of the QuestionCondition object
# returns: a QuestionCondition object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new QuestionCondition\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this QuestionCondition intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":QuestionCondition\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
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

# parse a given webservice response xml, construct a list of QuestionCondition objects
# param: xml doc
# returns: list of QuestionCondition objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of QuestionCondition objects
# param: xml node
# returns: a list of QuestionCondition objects
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

# parse a given xml node, construct one QuestionCondition object
# param: xml node
# returns: one QuestionCondition object
sub fromWSXMLNode {
	my $QuestionConditionNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($QuestionConditionNode->getChildNodes) {
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
	my $newobj = new CaCORE::CaDSR::QuestionCondition;
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

sub getConditionComponentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return @results;
}

sub getCondtionMessageCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConditionMessage", $self);
	return @results;
}

sub getForcedConditionTriggeredActionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::TriggerAction", $self);
	return @results;
}

sub getQuestionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return @results;
}

sub getQuestionConditionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return @results;
}

sub getTriggeredActionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::TriggerAction", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Question;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::FormElement);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Question object
# returns: a Question object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Question\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Question intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Question\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# defaultValidValueId;
	if( defined( $self->getDefaultValidValueId ) ) {
		$tmpstr = "<defaultValidValueId xsi:type=\"xsd:string\">" . $self->getDefaultValidValueId . "</defaultValidValueId>";
	} else {
		$tmpstr = "<defaultValidValueId xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# defaultValue;
	if( defined( $self->getDefaultValue ) ) {
		$tmpstr = "<defaultValue xsi:type=\"xsd:string\">" . $self->getDefaultValue . "</defaultValue>";
	} else {
		$tmpstr = "<defaultValue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# isEditable;
	if( defined( $self->getIsEditable ) ) {
		$tmpstr = "<isEditable xsi:type=\"xsd:string\">" . $self->getIsEditable . "</isEditable>";
	} else {
		$tmpstr = "<isEditable xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# isMandatory;
	if( defined( $self->getIsMandatory ) ) {
		$tmpstr = "<isMandatory xsi:type=\"xsd:string\">" . $self->getIsMandatory . "</isMandatory>";
	} else {
		$tmpstr = "<isMandatory xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Question objects
# param: xml doc
# returns: list of Question objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Question objects
# param: xml node
# returns: a list of Question objects
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

# parse a given xml node, construct one Question object
# param: xml node
# returns: one Question object
sub fromWSXMLNode {
	my $QuestionNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $defaultValidValueId;
		my $defaultValue;
		my $displayOrder;
		my $isEditable;
		my $isMandatory;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($QuestionNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "defaultValidValueId") {
				$defaultValidValueId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "defaultValue") {
				$defaultValue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "isEditable") {
				$isEditable=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "isMandatory") {
				$isMandatory=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Question;
	## begin set attr ##
		$newobj->setDefaultValidValueId($defaultValidValueId);
		$newobj->setDefaultValue($defaultValue);
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setIsEditable($isEditable);
		$newobj->setIsMandatory($isMandatory);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDefaultValidValueId {
	my $self = shift;
	return $self->{defaultValidValueId};
}

sub setDefaultValidValueId {
	my $self = shift;
	$self->{defaultValidValueId} = shift;
}

sub getDefaultValue {
	my $self = shift;
	return $self->{defaultValue};
}

sub setDefaultValue {
	my $self = shift;
	$self->{defaultValue} = shift;
}

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getIsEditable {
	my $self = shift;
	return $self->{isEditable};
}

sub setIsEditable {
	my $self = shift;
	$self->{isEditable} = shift;
}

sub getIsMandatory {
	my $self = shift;
	return $self->{isMandatory};
}

sub setIsMandatory {
	my $self = shift;
	$self->{isMandatory} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getDataElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return $results[0];
}

sub getModule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Module", $self);
	return $results[0];
}

sub getQuestionComponentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return @results;
}

sub getQuestionCondition {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return $results[0];
}

sub getQuestionRepetitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionRepetition", $self);
	return @results;
}

sub getValidValueCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValidValue", $self);
	return @results;
}

sub getValueDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomain", $self);
	return $results[0];
}

sub getInstructionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Instruction", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Concept;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Concept object
# returns: a Concept object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Concept\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Concept intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Concept\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# definitionSource;
	if( defined( $self->getDefinitionSource ) ) {
		$tmpstr = "<definitionSource xsi:type=\"xsd:string\">" . $self->getDefinitionSource . "</definitionSource>";
	} else {
		$tmpstr = "<definitionSource xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# evsSource;
	if( defined( $self->getEvsSource ) ) {
		$tmpstr = "<evsSource xsi:type=\"xsd:string\">" . $self->getEvsSource . "</evsSource>";
	} else {
		$tmpstr = "<evsSource xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Concept objects
# param: xml doc
# returns: list of Concept objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Concept objects
# param: xml node
# returns: a list of Concept objects
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

# parse a given xml node, construct one Concept object
# param: xml node
# returns: one Concept object
sub fromWSXMLNode {
	my $ConceptNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $definitionSource;
		my $evsSource;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ConceptNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "definitionSource") {
				$definitionSource=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "evsSource") {
				$evsSource=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Concept;
	## begin set attr ##
		$newobj->setDefinitionSource($definitionSource);
		$newobj->setEvsSource($evsSource);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDefinitionSource {
	my $self = shift;
	return $self->{definitionSource};
}

sub setDefinitionSource {
	my $self = shift;
	$self->{definitionSource} = shift;
}

sub getEvsSource {
	my $self = shift;
	return $self->{evsSource};
}

sub setEvsSource {
	my $self = shift;
	$self->{evsSource} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getComponentConceptCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ComponentConcept", $self);
	return @results;
}

sub getValueDomainPermissibleValueCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainPermissibleValue", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ValueMeaning;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ValueMeaning object
# returns: a ValueMeaning object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ValueMeaning\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ValueMeaning intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ValueMeaning\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# comments;
	if( defined( $self->getComments ) ) {
		$tmpstr = "<comments xsi:type=\"xsd:string\">" . $self->getComments . "</comments>";
	} else {
		$tmpstr = "<comments xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# description;
	if( defined( $self->getDescription ) ) {
		$tmpstr = "<description xsi:type=\"xsd:string\">" . $self->getDescription . "</description>";
	} else {
		$tmpstr = "<description xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# shortMeaning;
	if( defined( $self->getShortMeaning ) ) {
		$tmpstr = "<shortMeaning xsi:type=\"xsd:string\">" . $self->getShortMeaning . "</shortMeaning>";
	} else {
		$tmpstr = "<shortMeaning xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ValueMeaning objects
# param: xml doc
# returns: list of ValueMeaning objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ValueMeaning objects
# param: xml node
# returns: a list of ValueMeaning objects
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

# parse a given xml node, construct one ValueMeaning object
# param: xml node
# returns: one ValueMeaning object
sub fromWSXMLNode {
	my $ValueMeaningNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $comments;
		my $description;
		my $shortMeaning;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ValueMeaningNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "comments") {
				$comments=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "shortMeaning") {
				$shortMeaning=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ValueMeaning;
	## begin set attr ##
		$newobj->setComments($comments);
		$newobj->setDescription($description);
		$newobj->setShortMeaning($shortMeaning);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getComments {
	my $self = shift;
	return $self->{comments};
}

sub setComments {
	my $self = shift;
	$self->{comments} = shift;
}

sub getDescription {
	my $self = shift;
	return $self->{description};
}

sub setDescription {
	my $self = shift;
	$self->{description} = shift;
}

sub getShortMeaning {
	my $self = shift;
	return $self->{shortMeaning};
}

sub setShortMeaning {
	my $self = shift;
	$self->{shortMeaning} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getConceptualDomainCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptualDomain", $self);
	return @results;
}

sub getPermissibleValueCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::PermissibleValue", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::PermissibleValue;

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

# create an instance of the PermissibleValue object
# returns: a PermissibleValue object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new PermissibleValue\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this PermissibleValue intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":PermissibleValue\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# highValueNumber;
	if( defined( $self->getHighValueNumber ) ) {
		$tmpstr = "<highValueNumber xsi:type=\"xsd:long\">" . $self->getHighValueNumber . "</highValueNumber>";
	} else {
		$tmpstr = "<highValueNumber xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# lowValueNumber;
	if( defined( $self->getLowValueNumber ) ) {
		$tmpstr = "<lowValueNumber xsi:type=\"xsd:long\">" . $self->getLowValueNumber . "</lowValueNumber>";
	} else {
		$tmpstr = "<lowValueNumber xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of PermissibleValue objects
# param: xml doc
# returns: list of PermissibleValue objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of PermissibleValue objects
# param: xml node
# returns: a list of PermissibleValue objects
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

# parse a given xml node, construct one PermissibleValue object
# param: xml node
# returns: one PermissibleValue object
sub fromWSXMLNode {
	my $PermissibleValueNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $highValueNumber;
		my $id;
		my $lowValueNumber;
		my $modifiedBy;
		my $value;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($PermissibleValueNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "highValueNumber") {
				$highValueNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "lowValueNumber") {
				$lowValueNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "value") {
				$value=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::PermissibleValue;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setHighValueNumber($highValueNumber);
		$newobj->setId($id);
		$newobj->setLowValueNumber($lowValueNumber);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setValue($value);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getHighValueNumber {
	my $self = shift;
	return $self->{highValueNumber};
}

sub setHighValueNumber {
	my $self = shift;
	$self->{highValueNumber} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLowValueNumber {
	my $self = shift;
	return $self->{lowValueNumber};
}

sub setLowValueNumber {
	my $self = shift;
	$self->{lowValueNumber} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getValueDomainPermissibleValueCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainPermissibleValue", $self);
	return @results;
}

sub getValueMeaning {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueMeaning", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ValueDomainPermissibleValue;

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

# create an instance of the ValueDomainPermissibleValue object
# returns: a ValueDomainPermissibleValue object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ValueDomainPermissibleValue\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ValueDomainPermissibleValue intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ValueDomainPermissibleValue\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ValueDomainPermissibleValue objects
# param: xml doc
# returns: list of ValueDomainPermissibleValue objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ValueDomainPermissibleValue objects
# param: xml node
# returns: a list of ValueDomainPermissibleValue objects
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

# parse a given xml node, construct one ValueDomainPermissibleValue object
# param: xml node
# returns: one ValueDomainPermissibleValue object
sub fromWSXMLNode {
	my $ValueDomainPermissibleValueNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $beginDate;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $endDate;
		my $id;
		my $modifiedBy;
		my $origin;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ValueDomainPermissibleValueNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ValueDomainPermissibleValue;
	## begin set attr ##
		$newobj->setBeginDate($beginDate);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getConcept {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Concept", $self);
	return $results[0];
}

sub getEnumeratedValueDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::EnumeratedValueDomain", $self);
	return $results[0];
}

sub getPermissibleValue {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::PermissibleValue", $self);
	return $results[0];
}

sub getValidValueCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValidValue", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ValidValue;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::FormElement);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ValidValue object
# returns: a ValidValue object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ValidValue\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ValidValue intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ValidValue\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
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

	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# meaningText;
	if( defined( $self->getMeaningText ) ) {
		$tmpstr = "<meaningText xsi:type=\"xsd:string\">" . $self->getMeaningText . "</meaningText>";
	} else {
		$tmpstr = "<meaningText xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ValidValue objects
# param: xml doc
# returns: list of ValidValue objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ValidValue objects
# param: xml node
# returns: a list of ValidValue objects
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

# parse a given xml node, construct one ValidValue object
# param: xml node
# returns: one ValidValue object
sub fromWSXMLNode {
	my $ValidValueNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $description;
		my $displayOrder;
		my $meaningText;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ValidValueNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "meaningText") {
				$meaningText=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ValidValue;
	## begin set attr ##
		$newobj->setDescription($description);
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setMeaningText($meaningText);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
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

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getMeaningText {
	my $self = shift;
	return $self->{meaningText};
}

sub setMeaningText {
	my $self = shift;
	$self->{meaningText} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getConditionComponentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return @results;
}

sub getQuestion {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return $results[0];
}

sub getValueDomainPermissibleValue {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomainPermissibleValue", $self);
	return $results[0];
}

sub getInstructionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Instruction", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ClassificationScheme;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ClassificationScheme object
# returns: a ClassificationScheme object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ClassificationScheme\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ClassificationScheme intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ClassificationScheme\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# labelTypeFlag;
	if( defined( $self->getLabelTypeFlag ) ) {
		$tmpstr = "<labelTypeFlag xsi:type=\"xsd:string\">" . $self->getLabelTypeFlag . "</labelTypeFlag>";
	} else {
		$tmpstr = "<labelTypeFlag xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ClassificationScheme objects
# param: xml doc
# returns: list of ClassificationScheme objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ClassificationScheme objects
# param: xml node
# returns: a list of ClassificationScheme objects
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

# parse a given xml node, construct one ClassificationScheme object
# param: xml node
# returns: one ClassificationScheme object
sub fromWSXMLNode {
	my $ClassificationSchemeNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $labelTypeFlag;
		my $type;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ClassificationSchemeNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "labelTypeFlag") {
				$labelTypeFlag=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ClassificationScheme;
	## begin set attr ##
		$newobj->setLabelTypeFlag($labelTypeFlag);
		$newobj->setType($type);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getLabelTypeFlag {
	my $self = shift;
	return $self->{labelTypeFlag};
}

sub setLabelTypeFlag {
	my $self = shift;
	$self->{labelTypeFlag} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getChildClassificationSchemeCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationScheme", $self);
	return @results;
}

sub getChildClassificationSchemeRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeRelationship", $self);
	return @results;
}

sub getClassSchemeClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return @results;
}

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getParentClassificationScheme {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationScheme", $self);
	return $results[0];
}

sub getParentClassificationSchemeRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeRelationship", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ClassificationSchemeItem;

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

# create an instance of the ClassificationSchemeItem object
# returns: a ClassificationSchemeItem object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ClassificationSchemeItem\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ClassificationSchemeItem intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ClassificationSchemeItem\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# comments;
	if( defined( $self->getComments ) ) {
		$tmpstr = "<comments xsi:type=\"xsd:string\">" . $self->getComments . "</comments>";
	} else {
		$tmpstr = "<comments xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
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
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ClassificationSchemeItem objects
# param: xml doc
# returns: list of ClassificationSchemeItem objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ClassificationSchemeItem objects
# param: xml node
# returns: a list of ClassificationSchemeItem objects
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

# parse a given xml node, construct one ClassificationSchemeItem object
# param: xml node
# returns: one ClassificationSchemeItem object
sub fromWSXMLNode {
	my $ClassificationSchemeItemNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $comments;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $description;
		my $id;
		my $modifiedBy;
		my $name;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ClassificationSchemeItemNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "comments") {
				$comments=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
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
	my $newobj = new CaCORE::CaDSR::ClassificationSchemeItem;
	## begin set attr ##
		$newobj->setComments($comments);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getComments {
	my $self = shift;
	return $self->{comments};
}

sub setComments {
	my $self = shift;
	$self->{comments} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
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

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getChildClassificationSchemeItemRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeItemRelationship", $self);
	return @results;
}

sub getClassSchemeClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return @results;
}

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getParentClassificationSchemeItemRelationshipCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeItemRelationship", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ClassSchemeClassSchemeItem;

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

# create an instance of the ClassSchemeClassSchemeItem object
# returns: a ClassSchemeClassSchemeItem object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ClassSchemeClassSchemeItem\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ClassSchemeClassSchemeItem intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ClassSchemeClassSchemeItem\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ClassSchemeClassSchemeItem objects
# param: xml doc
# returns: list of ClassSchemeClassSchemeItem objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ClassSchemeClassSchemeItem objects
# param: xml node
# returns: a list of ClassSchemeClassSchemeItem objects
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

# parse a given xml node, construct one ClassSchemeClassSchemeItem object
# param: xml node
# returns: one ClassSchemeClassSchemeItem object
sub fromWSXMLNode {
	my $ClassSchemeClassSchemeItemNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $displayOrder;
		my $id;
		my $modifiedBy;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ClassSchemeClassSchemeItemNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ClassSchemeClassSchemeItem;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getChildClassSchemeClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return @results;
}

sub getClassificationScheme {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationScheme", $self);
	return $results[0];
}

sub getClassificationSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeItem", $self);
	return $results[0];
}

sub getDefinitionClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DefinitionClassSchemeItem", $self);
	return @results;
}

sub getDesignationClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DesignationClassSchemeItem", $self);
	return @results;
}

sub getParentClassSchemeClassSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return $results[0];
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Definition;

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
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Definition\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# languageName;
	if( defined( $self->getLanguageName ) ) {
		$tmpstr = "<languageName xsi:type=\"xsd:string\">" . $self->getLanguageName . "</languageName>";
	} else {
		$tmpstr = "<languageName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# text;
	if( defined( $self->getText ) ) {
		$tmpstr = "<text xsi:type=\"xsd:string\">" . $self->getText . "</text>";
	} else {
		$tmpstr = "<text xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $languageName;
		my $modifiedBy;
		my $text;
		my $type;
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
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "languageName") {
				$languageName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "text") {
				$text=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Definition;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setLanguageName($languageName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setText($text);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLanguageName {
	my $self = shift;
	return $self->{languageName};
}

sub setLanguageName {
	my $self = shift;
	$self->{languageName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getText {
	my $self = shift;
	return $self->{text};
}

sub setText {
	my $self = shift;
	$self->{text} = shift;
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

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DefinitionClassSchemeItem", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DefinitionClassSchemeItem;

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

# create an instance of the DefinitionClassSchemeItem object
# returns: a DefinitionClassSchemeItem object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DefinitionClassSchemeItem\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DefinitionClassSchemeItem intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DefinitionClassSchemeItem\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DefinitionClassSchemeItem objects
# param: xml doc
# returns: list of DefinitionClassSchemeItem objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DefinitionClassSchemeItem objects
# param: xml node
# returns: a list of DefinitionClassSchemeItem objects
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

# parse a given xml node, construct one DefinitionClassSchemeItem object
# param: xml node
# returns: one DefinitionClassSchemeItem object
sub fromWSXMLNode {
	my $DefinitionClassSchemeItemNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DefinitionClassSchemeItemNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DefinitionClassSchemeItem;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getClassSchemeClassSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return $results[0];
}

sub getDefinition {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Designation;

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

# create an instance of the Designation object
# returns: a Designation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Designation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Designation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Designation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# languageName;
	if( defined( $self->getLanguageName ) ) {
		$tmpstr = "<languageName xsi:type=\"xsd:string\">" . $self->getLanguageName . "</languageName>";
	} else {
		$tmpstr = "<languageName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of Designation objects
# param: xml doc
# returns: list of Designation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Designation objects
# param: xml node
# returns: a list of Designation objects
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

# parse a given xml node, construct one Designation object
# param: xml node
# returns: one Designation object
sub fromWSXMLNode {
	my $DesignationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $languageName;
		my $modifiedBy;
		my $name;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DesignationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "languageName") {
				$languageName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
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
	my $newobj = new CaCORE::CaDSR::Designation;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setLanguageName($languageName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLanguageName {
	my $self = shift;
	return $self->{languageName};
}

sub setLanguageName {
	my $self = shift;
	$self->{languageName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDesignationClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DesignationClassSchemeItem", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DesignationClassSchemeItem;

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

# create an instance of the DesignationClassSchemeItem object
# returns: a DesignationClassSchemeItem object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DesignationClassSchemeItem\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DesignationClassSchemeItem intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DesignationClassSchemeItem\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DesignationClassSchemeItem objects
# param: xml doc
# returns: list of DesignationClassSchemeItem objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DesignationClassSchemeItem objects
# param: xml node
# returns: a list of DesignationClassSchemeItem objects
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

# parse a given xml node, construct one DesignationClassSchemeItem object
# param: xml node
# returns: one DesignationClassSchemeItem object
sub fromWSXMLNode {
	my $DesignationClassSchemeItemNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DesignationClassSchemeItemNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DesignationClassSchemeItem;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getClassSchemeClassSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return $results[0];
}

sub getDesignation {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DataElementRelationship;

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

# create an instance of the DataElementRelationship object
# returns: a DataElementRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DataElementRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DataElementRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DataElementRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of DataElementRelationship objects
# param: xml doc
# returns: list of DataElementRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DataElementRelationship objects
# param: xml node
# returns: a list of DataElementRelationship objects
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

# parse a given xml node, construct one DataElementRelationship object
# param: xml node
# returns: one DataElementRelationship object
sub fromWSXMLNode {
	my $DataElementRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DataElementRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DataElementRelationship;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getChildDataElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return $results[0];
}

sub getParentDataElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ClassificationSchemeRelationship;

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

# create an instance of the ClassificationSchemeRelationship object
# returns: a ClassificationSchemeRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ClassificationSchemeRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ClassificationSchemeRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ClassificationSchemeRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ClassificationSchemeRelationship objects
# param: xml doc
# returns: list of ClassificationSchemeRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ClassificationSchemeRelationship objects
# param: xml node
# returns: a list of ClassificationSchemeRelationship objects
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

# parse a given xml node, construct one ClassificationSchemeRelationship object
# param: xml node
# returns: one ClassificationSchemeRelationship object
sub fromWSXMLNode {
	my $ClassificationSchemeRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $displayOrder;
		my $id;
		my $modifiedBy;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ClassificationSchemeRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ClassificationSchemeRelationship;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getChildClassificationScheme {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationScheme", $self);
	return $results[0];
}

sub getParentClassificationScheme {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationScheme", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ClassificationSchemeItemRelationship;

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

# create an instance of the ClassificationSchemeItemRelationship object
# returns: a ClassificationSchemeItemRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ClassificationSchemeItemRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ClassificationSchemeItemRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ClassificationSchemeItemRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ClassificationSchemeItemRelationship objects
# param: xml doc
# returns: list of ClassificationSchemeItemRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ClassificationSchemeItemRelationship objects
# param: xml node
# returns: a list of ClassificationSchemeItemRelationship objects
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

# parse a given xml node, construct one ClassificationSchemeItemRelationship object
# param: xml node
# returns: one ClassificationSchemeItemRelationship object
sub fromWSXMLNode {
	my $ClassificationSchemeItemRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ClassificationSchemeItemRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ClassificationSchemeItemRelationship;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getChildClassificationSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeItem", $self);
	return $results[0];
}

sub getParentClassificationSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeItem", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ComponentLevel;

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

# create an instance of the ComponentLevel object
# returns: a ComponentLevel object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ComponentLevel\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ComponentLevel intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ComponentLevel\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# concatenationString;
	if( defined( $self->getConcatenationString ) ) {
		$tmpstr = "<concatenationString xsi:type=\"xsd:string\">" . $self->getConcatenationString . "</concatenationString>";
	} else {
		$tmpstr = "<concatenationString xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# level;
	if( defined( $self->getLevel ) ) {
		$tmpstr = "<level xsi:type=\"xsd:int\">" . $self->getLevel . "</level>";
	} else {
		$tmpstr = "<level xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ComponentLevel objects
# param: xml doc
# returns: list of ComponentLevel objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ComponentLevel objects
# param: xml node
# returns: a list of ComponentLevel objects
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

# parse a given xml node, construct one ComponentLevel object
# param: xml node
# returns: one ComponentLevel object
sub fromWSXMLNode {
	my $ComponentLevelNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $concatenationString;
		my $id;
		my $level;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ComponentLevelNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "concatenationString") {
				$concatenationString=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "level") {
				$level=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ComponentLevel;
	## begin set attr ##
		$newobj->setConcatenationString($concatenationString);
		$newobj->setId($id);
		$newobj->setLevel($level);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getConcatenationString {
	my $self = shift;
	return $self->{concatenationString};
}

sub setConcatenationString {
	my $self = shift;
	$self->{concatenationString} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLevel {
	my $self = shift;
	return $self->{level};
}

sub setLevel {
	my $self = shift;
	$self->{level} = shift;
}

## end getters and setters ##

## begin bean association methods ##

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::AdministeredComponentClassSchemeItem;

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

# create an instance of the AdministeredComponentClassSchemeItem object
# returns: a AdministeredComponentClassSchemeItem object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new AdministeredComponentClassSchemeItem\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this AdministeredComponentClassSchemeItem intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":AdministeredComponentClassSchemeItem\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of AdministeredComponentClassSchemeItem objects
# param: xml doc
# returns: list of AdministeredComponentClassSchemeItem objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of AdministeredComponentClassSchemeItem objects
# param: xml node
# returns: a list of AdministeredComponentClassSchemeItem objects
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

# parse a given xml node, construct one AdministeredComponentClassSchemeItem object
# param: xml node
# returns: one AdministeredComponentClassSchemeItem object
sub fromWSXMLNode {
	my $AdministeredComponentClassSchemeItemNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AdministeredComponentClassSchemeItemNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::AdministeredComponentClassSchemeItem;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getClassSchemeClassSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return $results[0];
}

sub getSourceObjectClassCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClass", $self);
	return @results;
}

sub getTargetObjectClassCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClass", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Organization;

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

# create an instance of the Organization object
# returns: a Organization object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Organization\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Organization intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Organization\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of Organization objects
# param: xml doc
# returns: list of Organization objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Organization objects
# param: xml node
# returns: a list of Organization objects
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

# parse a given xml node, construct one Organization object
# param: xml node
# returns: one Organization object
sub fromWSXMLNode {
	my $OrganizationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($OrganizationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Organization;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getAddressCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Address", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContactCommunicationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ContactCommunication", $self);
	return @results;
}

sub getPersonCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Person", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ReferenceDocument;

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

# create an instance of the ReferenceDocument object
# returns: a ReferenceDocument object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ReferenceDocument\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ReferenceDocument intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ReferenceDocument\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# URL;
	if( defined( $self->getURL ) ) {
		$tmpstr = "<URL xsi:type=\"xsd:string\">" . $self->getURL . "</URL>";
	} else {
		$tmpstr = "<URL xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:long\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# doctext;
	if( defined( $self->getDoctext ) ) {
		$tmpstr = "<doctext xsi:type=\"xsd:string\">" . $self->getDoctext . "</doctext>";
	} else {
		$tmpstr = "<doctext xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# languageName;
	if( defined( $self->getLanguageName ) ) {
		$tmpstr = "<languageName xsi:type=\"xsd:string\">" . $self->getLanguageName . "</languageName>";
	} else {
		$tmpstr = "<languageName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# organizationId;
	if( defined( $self->getOrganizationId ) ) {
		$tmpstr = "<organizationId xsi:type=\"xsd:string\">" . $self->getOrganizationId . "</organizationId>";
	} else {
		$tmpstr = "<organizationId xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# rdtlName;
	if( defined( $self->getRdtlName ) ) {
		$tmpstr = "<rdtlName xsi:type=\"xsd:string\">" . $self->getRdtlName . "</rdtlName>";
	} else {
		$tmpstr = "<rdtlName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ReferenceDocument objects
# param: xml doc
# returns: list of ReferenceDocument objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ReferenceDocument objects
# param: xml node
# returns: a list of ReferenceDocument objects
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

# parse a given xml node, construct one ReferenceDocument object
# param: xml node
# returns: one ReferenceDocument object
sub fromWSXMLNode {
	my $ReferenceDocumentNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $URL;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $displayOrder;
		my $doctext;
		my $id;
		my $languageName;
		my $modifiedBy;
		my $name;
		my $organizationId;
		my $rdtlName;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ReferenceDocumentNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "URL") {
				$URL=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "doctext") {
				$doctext=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "languageName") {
				$languageName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "organizationId") {
				$organizationId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "rdtlName") {
				$rdtlName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ReferenceDocument;
	## begin set attr ##
		$newobj->setURL($URL);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setDoctext($doctext);
		$newobj->setId($id);
		$newobj->setLanguageName($languageName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
		$newobj->setOrganizationId($organizationId);
		$newobj->setRdtlName($rdtlName);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getURL {
	my $self = shift;
	return $self->{URL};
}

sub setURL {
	my $self = shift;
	$self->{URL} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getDoctext {
	my $self = shift;
	return $self->{doctext};
}

sub setDoctext {
	my $self = shift;
	$self->{doctext} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLanguageName {
	my $self = shift;
	return $self->{languageName};
}

sub setLanguageName {
	my $self = shift;
	$self->{languageName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getOrganizationId {
	my $self = shift;
	return $self->{organizationId};
}

sub setOrganizationId {
	my $self = shift;
	$self->{organizationId} = shift;
}

sub getRdtlName {
	my $self = shift;
	return $self->{rdtlName};
}

sub setRdtlName {
	my $self = shift;
	$self->{rdtlName} = shift;
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

sub getClassSchemeClassSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return $results[0];
}

sub getClassificationSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeItem", $self);
	return $results[0];
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Person;

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

# create an instance of the Person object
# returns: a Person object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Person\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Person intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Person\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# firstName;
	if( defined( $self->getFirstName ) ) {
		$tmpstr = "<firstName xsi:type=\"xsd:string\">" . $self->getFirstName . "</firstName>";
	} else {
		$tmpstr = "<firstName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# lastName;
	if( defined( $self->getLastName ) ) {
		$tmpstr = "<lastName xsi:type=\"xsd:string\">" . $self->getLastName . "</lastName>";
	} else {
		$tmpstr = "<lastName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# middleInitial;
	if( defined( $self->getMiddleInitial ) ) {
		$tmpstr = "<middleInitial xsi:type=\"xsd:string\">" . $self->getMiddleInitial . "</middleInitial>";
	} else {
		$tmpstr = "<middleInitial xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# position;
	if( defined( $self->getPosition ) ) {
		$tmpstr = "<position xsi:type=\"xsd:string\">" . $self->getPosition . "</position>";
	} else {
		$tmpstr = "<position xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# rank;
	if( defined( $self->getRank ) ) {
		$tmpstr = "<rank xsi:type=\"xsd:int\">" . $self->getRank . "</rank>";
	} else {
		$tmpstr = "<rank xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Person objects
# param: xml doc
# returns: list of Person objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Person objects
# param: xml node
# returns: a list of Person objects
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

# parse a given xml node, construct one Person object
# param: xml node
# returns: one Person object
sub fromWSXMLNode {
	my $PersonNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $firstName;
		my $id;
		my $lastName;
		my $middleInitial;
		my $modifiedBy;
		my $position;
		my $rank;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($PersonNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "firstName") {
				$firstName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "lastName") {
				$lastName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "middleInitial") {
				$middleInitial=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "position") {
				$position=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "rank") {
				$rank=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Person;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setFirstName($firstName);
		$newobj->setId($id);
		$newobj->setLastName($lastName);
		$newobj->setMiddleInitial($middleInitial);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setPosition($position);
		$newobj->setRank($rank);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getFirstName {
	my $self = shift;
	return $self->{firstName};
}

sub setFirstName {
	my $self = shift;
	$self->{firstName} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLastName {
	my $self = shift;
	return $self->{lastName};
}

sub setLastName {
	my $self = shift;
	$self->{lastName} = shift;
}

sub getMiddleInitial {
	my $self = shift;
	return $self->{middleInitial};
}

sub setMiddleInitial {
	my $self = shift;
	$self->{middleInitial} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getPosition {
	my $self = shift;
	return $self->{position};
}

sub setPosition {
	my $self = shift;
	$self->{position} = shift;
}

sub getRank {
	my $self = shift;
	return $self->{rank};
}

sub setRank {
	my $self = shift;
	$self->{rank} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAddressCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Address", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContactCommunicationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ContactCommunication", $self);
	return @results;
}

sub getOrganization {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Organization", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::QuestionRepetition;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::FormElement);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the QuestionRepetition object
# returns: a QuestionRepetition object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new QuestionRepetition\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this QuestionRepetition intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":QuestionRepetition\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# defaultValue;
	if( defined( $self->getDefaultValue ) ) {
		$tmpstr = "<defaultValue xsi:type=\"xsd:string\">" . $self->getDefaultValue . "</defaultValue>";
	} else {
		$tmpstr = "<defaultValue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# isEditable;
	if( defined( $self->getIsEditable ) ) {
		$tmpstr = "<isEditable xsi:type=\"xsd:string\">" . $self->getIsEditable . "</isEditable>";
	} else {
		$tmpstr = "<isEditable xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# repeatSequenceNumber;
	if( defined( $self->getRepeatSequenceNumber ) ) {
		$tmpstr = "<repeatSequenceNumber xsi:type=\"xsd:int\">" . $self->getRepeatSequenceNumber . "</repeatSequenceNumber>";
	} else {
		$tmpstr = "<repeatSequenceNumber xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of QuestionRepetition objects
# param: xml doc
# returns: list of QuestionRepetition objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of QuestionRepetition objects
# param: xml node
# returns: a list of QuestionRepetition objects
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

# parse a given xml node, construct one QuestionRepetition object
# param: xml node
# returns: one QuestionRepetition object
sub fromWSXMLNode {
	my $QuestionRepetitionNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $defaultValue;
		my $isEditable;
		my $repeatSequenceNumber;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($QuestionRepetitionNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "defaultValue") {
				$defaultValue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "isEditable") {
				$isEditable=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "repeatSequenceNumber") {
				$repeatSequenceNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::QuestionRepetition;
	## begin set attr ##
		$newobj->setDefaultValue($defaultValue);
		$newobj->setIsEditable($isEditable);
		$newobj->setRepeatSequenceNumber($repeatSequenceNumber);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDefaultValue {
	my $self = shift;
	return $self->{defaultValue};
}

sub setDefaultValue {
	my $self = shift;
	$self->{defaultValue} = shift;
}

sub getIsEditable {
	my $self = shift;
	return $self->{isEditable};
}

sub setIsEditable {
	my $self = shift;
	$self->{isEditable} = shift;
}

sub getRepeatSequenceNumber {
	my $self = shift;
	return $self->{repeatSequenceNumber};
}

sub setRepeatSequenceNumber {
	my $self = shift;
	$self->{repeatSequenceNumber} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getDefaultValidValue {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValidValue", $self);
	return $results[0];
}

sub getInstructionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Instruction", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Instruction;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the Instruction object
# returns: a Instruction object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Instruction\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Instruction intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Instruction\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Instruction objects
# param: xml doc
# returns: list of Instruction objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Instruction objects
# param: xml node
# returns: a list of Instruction objects
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

# parse a given xml node, construct one Instruction object
# param: xml node
# returns: one Instruction object
sub fromWSXMLNode {
	my $InstructionNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $type;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($InstructionNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Instruction;
	## begin set attr ##
		$newobj->setType($type);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getFormElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::FormElement", $self);
	return $results[0];
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Function;

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

# create an instance of the Function object
# returns: a Function object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Function\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Function intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Function\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of Function objects
# param: xml doc
# returns: list of Function objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Function objects
# param: xml node
# returns: a list of Function objects
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

# parse a given xml node, construct one Function object
# param: xml node
# returns: one Function object
sub fromWSXMLNode {
	my $FunctionNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $name;
		my $symbol;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($FunctionNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "symbol") {
				$symbol=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Function;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
		$newobj->setSymbol($symbol);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
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

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getConditionComponentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DataElementDerivation;

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

# create an instance of the DataElementDerivation object
# returns: a DataElementDerivation object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DataElementDerivation\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DataElementDerivation intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DataElementDerivation\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# leadingCharacters;
	if( defined( $self->getLeadingCharacters ) ) {
		$tmpstr = "<leadingCharacters xsi:type=\"xsd:string\">" . $self->getLeadingCharacters . "</leadingCharacters>";
	} else {
		$tmpstr = "<leadingCharacters xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# trailingCharacters;
	if( defined( $self->getTrailingCharacters ) ) {
		$tmpstr = "<trailingCharacters xsi:type=\"xsd:string\">" . $self->getTrailingCharacters . "</trailingCharacters>";
	} else {
		$tmpstr = "<trailingCharacters xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of DataElementDerivation objects
# param: xml doc
# returns: list of DataElementDerivation objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DataElementDerivation objects
# param: xml node
# returns: a list of DataElementDerivation objects
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

# parse a given xml node, construct one DataElementDerivation object
# param: xml node
# returns: one DataElementDerivation object
sub fromWSXMLNode {
	my $DataElementDerivationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $displayOrder;
		my $id;
		my $leadingCharacters;
		my $modifiedBy;
		my $trailingCharacters;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DataElementDerivationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "leadingCharacters") {
				$leadingCharacters=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "trailingCharacters") {
				$trailingCharacters=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DataElementDerivation;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setId($id);
		$newobj->setLeadingCharacters($leadingCharacters);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setTrailingCharacters($trailingCharacters);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLeadingCharacters {
	my $self = shift;
	return $self->{leadingCharacters};
}

sub setLeadingCharacters {
	my $self = shift;
	$self->{leadingCharacters} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getTrailingCharacters {
	my $self = shift;
	return $self->{trailingCharacters};
}

sub setTrailingCharacters {
	my $self = shift;
	$self->{trailingCharacters} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getDataElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElement", $self);
	return $results[0];
}

sub getDerivedDataElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DerivedDataElement", $self);
	return $results[0];
}

sub getLeftOperand {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Function", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::AdministeredComponentContact;

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

# create an instance of the AdministeredComponentContact object
# returns: a AdministeredComponentContact object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new AdministeredComponentContact\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this AdministeredComponentContact intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":AdministeredComponentContact\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# contactRole;
	if( defined( $self->getContactRole ) ) {
		$tmpstr = "<contactRole xsi:type=\"xsd:string\">" . $self->getContactRole . "</contactRole>";
	} else {
		$tmpstr = "<contactRole xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# rank;
	if( defined( $self->getRank ) ) {
		$tmpstr = "<rank xsi:type=\"xsd:int\">" . $self->getRank . "</rank>";
	} else {
		$tmpstr = "<rank xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of AdministeredComponentContact objects
# param: xml doc
# returns: list of AdministeredComponentContact objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of AdministeredComponentContact objects
# param: xml node
# returns: a list of AdministeredComponentContact objects
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

# parse a given xml node, construct one AdministeredComponentContact object
# param: xml node
# returns: one AdministeredComponentContact object
sub fromWSXMLNode {
	my $AdministeredComponentContactNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $contactRole;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $rank;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AdministeredComponentContactNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "contactRole") {
				$contactRole=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "rank") {
				$rank=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::AdministeredComponentContact;
	## begin set attr ##
		$newobj->setContactRole($contactRole);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setRank($rank);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getContactRole {
	my $self = shift;
	return $self->{contactRole};
}

sub setContactRole {
	my $self = shift;
	$self->{contactRole} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getRank {
	my $self = shift;
	return $self->{rank};
}

sub setRank {
	my $self = shift;
	$self->{rank} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getClassSchemeClassSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassSchemeClassSchemeItem", $self);
	return $results[0];
}

sub getClassificationSchemeItem {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ClassificationSchemeItem", $self);
	return $results[0];
}

sub getOrganization {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Organization", $self);
	return $results[0];
}

sub getPerson {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Person", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ValueDomainRelationship;

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

# create an instance of the ValueDomainRelationship object
# returns: a ValueDomainRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ValueDomainRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ValueDomainRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ValueDomainRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ValueDomainRelationship objects
# param: xml doc
# returns: list of ValueDomainRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ValueDomainRelationship objects
# param: xml node
# returns: a list of ValueDomainRelationship objects
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

# parse a given xml node, construct one ValueDomainRelationship object
# param: xml node
# returns: one ValueDomainRelationship object
sub fromWSXMLNode {
	my $ValueDomainRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ValueDomainRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ValueDomainRelationship;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getChildValueDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomain", $self);
	return $results[0];
}

sub getParentValueDomain {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValueDomain", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::DataElementConceptRelationship;

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

# create an instance of the DataElementConceptRelationship object
# returns: a DataElementConceptRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DataElementConceptRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DataElementConceptRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DataElementConceptRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
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
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of DataElementConceptRelationship objects
# param: xml doc
# returns: list of DataElementConceptRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DataElementConceptRelationship objects
# param: xml node
# returns: a list of DataElementConceptRelationship objects
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

# parse a given xml node, construct one DataElementConceptRelationship object
# param: xml node
# returns: one DataElementConceptRelationship object
sub fromWSXMLNode {
	my $DataElementConceptRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $description;
		my $id;
		my $modifiedBy;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DataElementConceptRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "description") {
				$description=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::DataElementConceptRelationship;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDescription($description);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
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

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
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

sub getChildDataElementConcept {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementConcept", $self);
	return $results[0];
}

sub getParentDataElementConcept {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::DataElementConcept", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ConditionMessage;

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

# create an instance of the ConditionMessage object
# returns: a ConditionMessage object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ConditionMessage\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ConditionMessage intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ConditionMessage\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
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

	# message;
	if( defined( $self->getMessage ) ) {
		$tmpstr = "<message xsi:type=\"xsd:string\">" . $self->getMessage . "</message>";
	} else {
		$tmpstr = "<message xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# messageType;
	if( defined( $self->getMessageType ) ) {
		$tmpstr = "<messageType xsi:type=\"xsd:string\">" . $self->getMessageType . "</messageType>";
	} else {
		$tmpstr = "<messageType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ConditionMessage objects
# param: xml doc
# returns: list of ConditionMessage objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ConditionMessage objects
# param: xml node
# returns: a list of ConditionMessage objects
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

# parse a given xml node, construct one ConditionMessage object
# param: xml node
# returns: one ConditionMessage object
sub fromWSXMLNode {
	my $ConditionMessageNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
		my $message;
		my $messageType;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ConditionMessageNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "message") {
				$message=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "messageType") {
				$messageType=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ConditionMessage;
	## begin set attr ##
		$newobj->setId($id);
		$newobj->setMessage($message);
		$newobj->setMessageType($messageType);
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

sub getMessage {
	my $self = shift;
	return $self->{message};
}

sub setMessage {
	my $self = shift;
	$self->{message} = shift;
}

sub getMessageType {
	my $self = shift;
	return $self->{messageType};
}

sub setMessageType {
	my $self = shift;
	$self->{messageType} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getQuestionCondition {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ContactCommunication;

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

# create an instance of the ContactCommunication object
# returns: a ContactCommunication object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ContactCommunication\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ContactCommunication intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ContactCommunication\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# rank;
	if( defined( $self->getRank ) ) {
		$tmpstr = "<rank xsi:type=\"xsd:int\">" . $self->getRank . "</rank>";
	} else {
		$tmpstr = "<rank xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ContactCommunication objects
# param: xml doc
# returns: list of ContactCommunication objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ContactCommunication objects
# param: xml node
# returns: a list of ContactCommunication objects
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

# parse a given xml node, construct one ContactCommunication object
# param: xml node
# returns: one ContactCommunication object
sub fromWSXMLNode {
	my $ContactCommunicationNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $rank;
		my $type;
		my $value;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ContactCommunicationNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "rank") {
				$rank=$textNode->getNodeValue;
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
	my $newobj = new CaCORE::CaDSR::ContactCommunication;
	## begin set attr ##
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setRank($rank);
		$newobj->setType($type);
		$newobj->setValue($value);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getRank {
	my $self = shift;
	return $self->{rank};
}

sub setRank {
	my $self = shift;
	$self->{rank} = shift;
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

sub getOrganization {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Organization", $self);
	return $results[0];
}

sub getPerson {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Person", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::QuestionConditionComponents;

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

# create an instance of the QuestionConditionComponents object
# returns: a QuestionConditionComponents object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new QuestionConditionComponents\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this QuestionConditionComponents intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":QuestionConditionComponents\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# constantValue;
	if( defined( $self->getConstantValue ) ) {
		$tmpstr = "<constantValue xsi:type=\"xsd:string\">" . $self->getConstantValue . "</constantValue>";
	} else {
		$tmpstr = "<constantValue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# logicalOperand;
	if( defined( $self->getLogicalOperand ) ) {
		$tmpstr = "<logicalOperand xsi:type=\"xsd:string\">" . $self->getLogicalOperand . "</logicalOperand>";
	} else {
		$tmpstr = "<logicalOperand xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# operand;
	if( defined( $self->getOperand ) ) {
		$tmpstr = "<operand xsi:type=\"xsd:string\">" . $self->getOperand . "</operand>";
	} else {
		$tmpstr = "<operand xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of QuestionConditionComponents objects
# param: xml doc
# returns: list of QuestionConditionComponents objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of QuestionConditionComponents objects
# param: xml node
# returns: a list of QuestionConditionComponents objects
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

# parse a given xml node, construct one QuestionConditionComponents object
# param: xml node
# returns: one QuestionConditionComponents object
sub fromWSXMLNode {
	my $QuestionConditionComponentsNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $constantValue;
		my $displayOrder;
		my $id;
		my $logicalOperand;
		my $operand;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($QuestionConditionComponentsNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "constantValue") {
				$constantValue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "logicalOperand") {
				$logicalOperand=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "operand") {
				$operand=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::QuestionConditionComponents;
	## begin set attr ##
		$newobj->setConstantValue($constantValue);
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setId($id);
		$newobj->setLogicalOperand($logicalOperand);
		$newobj->setOperand($operand);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getConstantValue {
	my $self = shift;
	return $self->{constantValue};
}

sub setConstantValue {
	my $self = shift;
	$self->{constantValue} = shift;
}

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLogicalOperand {
	my $self = shift;
	return $self->{logicalOperand};
}

sub setLogicalOperand {
	my $self = shift;
	$self->{logicalOperand} = shift;
}

sub getOperand {
	my $self = shift;
	return $self->{operand};
}

sub setOperand {
	my $self = shift;
	$self->{operand} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getFunction {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Function", $self);
	return $results[0];
}

sub getParentQuestionCondition {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return $results[0];
}

sub getQuestion {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Question", $self);
	return $results[0];
}

sub getQuestionCondition {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return $results[0];
}

sub getValidValue {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ValidValue", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ComponentConcept;

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

# create an instance of the ComponentConcept object
# returns: a ComponentConcept object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ComponentConcept\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ComponentConcept intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ComponentConcept\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# primaryFlag;
	if( defined( $self->getPrimaryFlag ) ) {
		$tmpstr = "<primaryFlag xsi:type=\"xsd:string\">" . $self->getPrimaryFlag . "</primaryFlag>";
	} else {
		$tmpstr = "<primaryFlag xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ComponentConcept objects
# param: xml doc
# returns: list of ComponentConcept objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ComponentConcept objects
# param: xml node
# returns: a list of ComponentConcept objects
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

# parse a given xml node, construct one ComponentConcept object
# param: xml node
# returns: one ComponentConcept object
sub fromWSXMLNode {
	my $ComponentConceptNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $displayOrder;
		my $id;
		my $primaryFlag;
		my $value;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ComponentConceptNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "primaryFlag") {
				$primaryFlag=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "value") {
				$value=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ComponentConcept;
	## begin set attr ##
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setId($id);
		$newobj->setPrimaryFlag($primaryFlag);
		$newobj->setValue($value);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getPrimaryFlag {
	my $self = shift;
	return $self->{primaryFlag};
}

sub setPrimaryFlag {
	my $self = shift;
	$self->{primaryFlag} = shift;
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

sub getComponentlevel {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ComponentLevel", $self);
	return $results[0];
}

sub getConcept {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Concept", $self);
	return $results[0];
}

sub getDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::TriggerAction;

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

# create an instance of the TriggerAction object
# returns: a TriggerAction object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new TriggerAction\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this TriggerAction intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":TriggerAction\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# action;
	if( defined( $self->getAction ) ) {
		$tmpstr = "<action xsi:type=\"xsd:string\">" . $self->getAction . "</action>";
	} else {
		$tmpstr = "<action xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# criterionValue;
	if( defined( $self->getCriterionValue ) ) {
		$tmpstr = "<criterionValue xsi:type=\"xsd:string\">" . $self->getCriterionValue . "</criterionValue>";
	} else {
		$tmpstr = "<criterionValue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# forcedValue;
	if( defined( $self->getForcedValue ) ) {
		$tmpstr = "<forcedValue xsi:type=\"xsd:string\">" . $self->getForcedValue . "</forcedValue>";
	} else {
		$tmpstr = "<forcedValue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# instruction;
	if( defined( $self->getInstruction ) ) {
		$tmpstr = "<instruction xsi:type=\"xsd:string\">" . $self->getInstruction . "</instruction>";
	} else {
		$tmpstr = "<instruction xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# triggerRelationship;
	if( defined( $self->getTriggerRelationship ) ) {
		$tmpstr = "<triggerRelationship xsi:type=\"xsd:string\">" . $self->getTriggerRelationship . "</triggerRelationship>";
	} else {
		$tmpstr = "<triggerRelationship xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of TriggerAction objects
# param: xml doc
# returns: list of TriggerAction objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of TriggerAction objects
# param: xml node
# returns: a list of TriggerAction objects
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

# parse a given xml node, construct one TriggerAction object
# param: xml node
# returns: one TriggerAction object
sub fromWSXMLNode {
	my $TriggerActionNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $action;
		my $createdBy;
		my $criterionValue;
		my $dateCreated;
		my $dateModified;
		my $forcedValue;
		my $id;
		my $instruction;
		my $modifiedBy;
		my $triggerRelationship;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($TriggerActionNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "criterionValue") {
				$criterionValue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "forcedValue") {
				$forcedValue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "instruction") {
				$instruction=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "triggerRelationship") {
				$triggerRelationship=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::TriggerAction;
	## begin set attr ##
		$newobj->setAction($action);
		$newobj->setCreatedBy($createdBy);
		$newobj->setCriterionValue($criterionValue);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setForcedValue($forcedValue);
		$newobj->setId($id);
		$newobj->setInstruction($instruction);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setTriggerRelationship($triggerRelationship);
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

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getCriterionValue {
	my $self = shift;
	return $self->{criterionValue};
}

sub setCriterionValue {
	my $self = shift;
	$self->{criterionValue} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getForcedValue {
	my $self = shift;
	return $self->{forcedValue};
}

sub setForcedValue {
	my $self = shift;
	$self->{forcedValue} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getInstruction {
	my $self = shift;
	return $self->{instruction};
}

sub setInstruction {
	my $self = shift;
	$self->{instruction} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getTriggerRelationship {
	my $self = shift;
	return $self->{triggerRelationship};
}

sub setTriggerRelationship {
	my $self = shift;
	$self->{triggerRelationship} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getEnforcedCondition {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return $results[0];
}

sub getProtocolCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Protocol", $self);
	return @results;
}

sub getQuestionCondition {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::QuestionCondition", $self);
	return $results[0];
}

sub getSourceFormElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::FormElement", $self);
	return $results[0];
}

sub getTargetFormElement {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::FormElement", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::ObjectClassRelationship;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ObjectClassRelationship object
# returns: a ObjectClassRelationship object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ObjectClassRelationship\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ObjectClassRelationship intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ObjectClassRelationship\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# dimensionality;
	if( defined( $self->getDimensionality ) ) {
		$tmpstr = "<dimensionality xsi:type=\"xsd:int\">" . $self->getDimensionality . "</dimensionality>";
	} else {
		$tmpstr = "<dimensionality xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# direction;
	if( defined( $self->getDirection ) ) {
		$tmpstr = "<direction xsi:type=\"xsd:string\">" . $self->getDirection . "</direction>";
	} else {
		$tmpstr = "<direction xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# displayOrder;
	if( defined( $self->getDisplayOrder ) ) {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\">" . $self->getDisplayOrder . "</displayOrder>";
	} else {
		$tmpstr = "<displayOrder xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# isArray;
	if( defined( $self->getIsArray ) ) {
		$tmpstr = "<isArray xsi:type=\"xsd:string\">" . $self->getIsArray . "</isArray>";
	} else {
		$tmpstr = "<isArray xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# name;
	if( defined( $self->getName ) ) {
		$tmpstr = "<name xsi:type=\"xsd:string\">" . $self->getName . "</name>";
	} else {
		$tmpstr = "<name xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceHighMultiplicity;
	if( defined( $self->getSourceHighMultiplicity ) ) {
		$tmpstr = "<sourceHighMultiplicity xsi:type=\"xsd:int\">" . $self->getSourceHighMultiplicity . "</sourceHighMultiplicity>";
	} else {
		$tmpstr = "<sourceHighMultiplicity xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceLowMultiplicity;
	if( defined( $self->getSourceLowMultiplicity ) ) {
		$tmpstr = "<sourceLowMultiplicity xsi:type=\"xsd:int\">" . $self->getSourceLowMultiplicity . "</sourceLowMultiplicity>";
	} else {
		$tmpstr = "<sourceLowMultiplicity xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceRole;
	if( defined( $self->getSourceRole ) ) {
		$tmpstr = "<sourceRole xsi:type=\"xsd:string\">" . $self->getSourceRole . "</sourceRole>";
	} else {
		$tmpstr = "<sourceRole xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# targetHighMultiplicity;
	if( defined( $self->getTargetHighMultiplicity ) ) {
		$tmpstr = "<targetHighMultiplicity xsi:type=\"xsd:int\">" . $self->getTargetHighMultiplicity . "</targetHighMultiplicity>";
	} else {
		$tmpstr = "<targetHighMultiplicity xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# targetLowMultiplicity;
	if( defined( $self->getTargetLowMultiplicity ) ) {
		$tmpstr = "<targetLowMultiplicity xsi:type=\"xsd:int\">" . $self->getTargetLowMultiplicity . "</targetLowMultiplicity>";
	} else {
		$tmpstr = "<targetLowMultiplicity xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# targetRole;
	if( defined( $self->getTargetRole ) ) {
		$tmpstr = "<targetRole xsi:type=\"xsd:string\">" . $self->getTargetRole . "</targetRole>";
	} else {
		$tmpstr = "<targetRole xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of ObjectClassRelationship objects
# param: xml doc
# returns: list of ObjectClassRelationship objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ObjectClassRelationship objects
# param: xml node
# returns: a list of ObjectClassRelationship objects
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

# parse a given xml node, construct one ObjectClassRelationship object
# param: xml node
# returns: one ObjectClassRelationship object
sub fromWSXMLNode {
	my $ObjectClassRelationshipNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $dimensionality;
		my $direction;
		my $displayOrder;
		my $isArray;
		my $name;
		my $sourceHighMultiplicity;
		my $sourceLowMultiplicity;
		my $sourceRole;
		my $targetHighMultiplicity;
		my $targetLowMultiplicity;
		my $targetRole;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ObjectClassRelationshipNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "dimensionality") {
				$dimensionality=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "direction") {
				$direction=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "displayOrder") {
				$displayOrder=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "isArray") {
				$isArray=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceHighMultiplicity") {
				$sourceHighMultiplicity=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceLowMultiplicity") {
				$sourceLowMultiplicity=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceRole") {
				$sourceRole=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "targetHighMultiplicity") {
				$targetHighMultiplicity=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "targetLowMultiplicity") {
				$targetLowMultiplicity=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "targetRole") {
				$targetRole=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::ObjectClassRelationship;
	## begin set attr ##
		$newobj->setDimensionality($dimensionality);
		$newobj->setDirection($direction);
		$newobj->setDisplayOrder($displayOrder);
		$newobj->setIsArray($isArray);
		$newobj->setName($name);
		$newobj->setSourceHighMultiplicity($sourceHighMultiplicity);
		$newobj->setSourceLowMultiplicity($sourceLowMultiplicity);
		$newobj->setSourceRole($sourceRole);
		$newobj->setTargetHighMultiplicity($targetHighMultiplicity);
		$newobj->setTargetLowMultiplicity($targetLowMultiplicity);
		$newobj->setTargetRole($targetRole);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getDimensionality {
	my $self = shift;
	return $self->{dimensionality};
}

sub setDimensionality {
	my $self = shift;
	$self->{dimensionality} = shift;
}

sub getDirection {
	my $self = shift;
	return $self->{direction};
}

sub setDirection {
	my $self = shift;
	$self->{direction} = shift;
}

sub getDisplayOrder {
	my $self = shift;
	return $self->{displayOrder};
}

sub setDisplayOrder {
	my $self = shift;
	$self->{displayOrder} = shift;
}

sub getIsArray {
	my $self = shift;
	return $self->{isArray};
}

sub setIsArray {
	my $self = shift;
	$self->{isArray} = shift;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub setName {
	my $self = shift;
	$self->{name} = shift;
}

sub getSourceHighMultiplicity {
	my $self = shift;
	return $self->{sourceHighMultiplicity};
}

sub setSourceHighMultiplicity {
	my $self = shift;
	$self->{sourceHighMultiplicity} = shift;
}

sub getSourceLowMultiplicity {
	my $self = shift;
	return $self->{sourceLowMultiplicity};
}

sub setSourceLowMultiplicity {
	my $self = shift;
	$self->{sourceLowMultiplicity} = shift;
}

sub getSourceRole {
	my $self = shift;
	return $self->{sourceRole};
}

sub setSourceRole {
	my $self = shift;
	$self->{sourceRole} = shift;
}

sub getTargetHighMultiplicity {
	my $self = shift;
	return $self->{targetHighMultiplicity};
}

sub setTargetHighMultiplicity {
	my $self = shift;
	$self->{targetHighMultiplicity} = shift;
}

sub getTargetLowMultiplicity {
	my $self = shift;
	return $self->{targetLowMultiplicity};
}

sub setTargetLowMultiplicity {
	my $self = shift;
	$self->{targetLowMultiplicity} = shift;
}

sub getTargetRole {
	my $self = shift;
	return $self->{targetRole};
}

sub setTargetRole {
	my $self = shift;
	$self->{targetRole} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getSourceConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getSourceObjectClass {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClass", $self);
	return $results[0];
}

sub getSourceObjectClassClassification {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return $results[0];
}

sub getTargetConceptDerivationRule {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ConceptDerivationRule", $self);
	return $results[0];
}

sub getTargetObjectClass {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ObjectClass", $self);
	return $results[0];
}

sub getTargetObjectClassClassification {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return $results[0];
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Address;

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

# create an instance of the Address object
# returns: a Address object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Address\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Address intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Address\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# addressLine1;
	if( defined( $self->getAddressLine1 ) ) {
		$tmpstr = "<addressLine1 xsi:type=\"xsd:string\">" . $self->getAddressLine1 . "</addressLine1>";
	} else {
		$tmpstr = "<addressLine1 xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# addressLine2;
	if( defined( $self->getAddressLine2 ) ) {
		$tmpstr = "<addressLine2 xsi:type=\"xsd:string\">" . $self->getAddressLine2 . "</addressLine2>";
	} else {
		$tmpstr = "<addressLine2 xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# city;
	if( defined( $self->getCity ) ) {
		$tmpstr = "<city xsi:type=\"xsd:string\">" . $self->getCity . "</city>";
	} else {
		$tmpstr = "<city xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# country;
	if( defined( $self->getCountry ) ) {
		$tmpstr = "<country xsi:type=\"xsd:string\">" . $self->getCountry . "</country>";
	} else {
		$tmpstr = "<country xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# postalCode;
	if( defined( $self->getPostalCode ) ) {
		$tmpstr = "<postalCode xsi:type=\"xsd:string\">" . $self->getPostalCode . "</postalCode>";
	} else {
		$tmpstr = "<postalCode xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# rank;
	if( defined( $self->getRank ) ) {
		$tmpstr = "<rank xsi:type=\"xsd:int\">" . $self->getRank . "</rank>";
	} else {
		$tmpstr = "<rank xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# state;
	if( defined( $self->getState ) ) {
		$tmpstr = "<state xsi:type=\"xsd:string\">" . $self->getState . "</state>";
	} else {
		$tmpstr = "<state xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of Address objects
# param: xml doc
# returns: list of Address objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Address objects
# param: xml node
# returns: a list of Address objects
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

# parse a given xml node, construct one Address object
# param: xml node
# returns: one Address object
sub fromWSXMLNode {
	my $AddressNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $addressLine1;
		my $addressLine2;
		my $city;
		my $country;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $id;
		my $modifiedBy;
		my $postalCode;
		my $rank;
		my $state;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($AddressNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "addressLine1") {
				$addressLine1=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "addressLine2") {
				$addressLine2=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "city") {
				$city=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "country") {
				$country=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "postalCode") {
				$postalCode=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "rank") {
				$rank=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "state") {
				$state=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Address;
	## begin set attr ##
		$newobj->setAddressLine1($addressLine1);
		$newobj->setAddressLine2($addressLine2);
		$newobj->setCity($city);
		$newobj->setCountry($country);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setId($id);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setPostalCode($postalCode);
		$newobj->setRank($rank);
		$newobj->setState($state);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getAddressLine1 {
	my $self = shift;
	return $self->{addressLine1};
}

sub setAddressLine1 {
	my $self = shift;
	$self->{addressLine1} = shift;
}

sub getAddressLine2 {
	my $self = shift;
	return $self->{addressLine2};
}

sub setAddressLine2 {
	my $self = shift;
	$self->{addressLine2} = shift;
}

sub getCity {
	my $self = shift;
	return $self->{city};
}

sub setCity {
	my $self = shift;
	$self->{city} = shift;
}

sub getCountry {
	my $self = shift;
	return $self->{country};
}

sub setCountry {
	my $self = shift;
	$self->{country} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getPostalCode {
	my $self = shift;
	return $self->{postalCode};
}

sub setPostalCode {
	my $self = shift;
	$self->{postalCode} = shift;
}

sub getRank {
	my $self = shift;
	return $self->{rank};
}

sub setRank {
	my $self = shift;
	$self->{rank} = shift;
}

sub getState {
	my $self = shift;
	return $self->{state};
}

sub setState {
	my $self = shift;
	$self->{state} = shift;
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

sub getOrganization {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Organization", $self);
	return $results[0];
}

sub getPerson {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Person", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::CaDSR::Protocol;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::CaDSR::AdministeredComponent);
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
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Protocol\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.cadsr.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# approvedBy;
	if( defined( $self->getApprovedBy ) ) {
		$tmpstr = "<approvedBy xsi:type=\"xsd:string\">" . $self->getApprovedBy . "</approvedBy>";
	} else {
		$tmpstr = "<approvedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# approvedDate;
	if( defined( $self->getApprovedDate ) ) {
		$tmpstr = "<approvedDate xsi:type=\"xsd:dateTime\">" . $self->getApprovedDate . "</approvedDate>";
	} else {
		$tmpstr = "<approvedDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNumber;
	if( defined( $self->getChangeNumber ) ) {
		$tmpstr = "<changeNumber xsi:type=\"xsd:string\">" . $self->getChangeNumber . "</changeNumber>";
	} else {
		$tmpstr = "<changeNumber xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeType;
	if( defined( $self->getChangeType ) ) {
		$tmpstr = "<changeType xsi:type=\"xsd:string\">" . $self->getChangeType . "</changeType>";
	} else {
		$tmpstr = "<changeType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# leadOrganizationName;
	if( defined( $self->getLeadOrganizationName ) ) {
		$tmpstr = "<leadOrganizationName xsi:type=\"xsd:string\">" . $self->getLeadOrganizationName . "</leadOrganizationName>";
	} else {
		$tmpstr = "<leadOrganizationName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# phase;
	if( defined( $self->getPhase ) ) {
		$tmpstr = "<phase xsi:type=\"xsd:string\">" . $self->getPhase . "</phase>";
	} else {
		$tmpstr = "<phase xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# protocolID;
	if( defined( $self->getProtocolID ) ) {
		$tmpstr = "<protocolID xsi:type=\"xsd:string\">" . $self->getProtocolID . "</protocolID>";
	} else {
		$tmpstr = "<protocolID xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# reviewedBy;
	if( defined( $self->getReviewedBy ) ) {
		$tmpstr = "<reviewedBy xsi:type=\"xsd:string\">" . $self->getReviewedBy . "</reviewedBy>";
	} else {
		$tmpstr = "<reviewedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# reviewedDate;
	if( defined( $self->getReviewedDate ) ) {
		$tmpstr = "<reviewedDate xsi:type=\"xsd:dateTime\">" . $self->getReviewedDate . "</reviewedDate>";
	} else {
		$tmpstr = "<reviewedDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# type;
	if( defined( $self->getType ) ) {
		$tmpstr = "<type xsi:type=\"xsd:string\">" . $self->getType . "</type>";
	} else {
		$tmpstr = "<type xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# beginDate;
	if( defined( $self->getBeginDate ) ) {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\">" . $self->getBeginDate . "</beginDate>";
	} else {
		$tmpstr = "<beginDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# changeNote;
	if( defined( $self->getChangeNote ) ) {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\">" . $self->getChangeNote . "</changeNote>";
	} else {
		$tmpstr = "<changeNote xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# createdBy;
	if( defined( $self->getCreatedBy ) ) {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\">" . $self->getCreatedBy . "</createdBy>";
	} else {
		$tmpstr = "<createdBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateCreated;
	if( defined( $self->getDateCreated ) ) {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\">" . $self->getDateCreated . "</dateCreated>";
	} else {
		$tmpstr = "<dateCreated xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dateModified;
	if( defined( $self->getDateModified ) ) {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\">" . $self->getDateModified . "</dateModified>";
	} else {
		$tmpstr = "<dateModified xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# deletedIndicator;
	if( defined( $self->getDeletedIndicator ) ) {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\">" . $self->getDeletedIndicator . "</deletedIndicator>";
	} else {
		$tmpstr = "<deletedIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endDate;
	if( defined( $self->getEndDate ) ) {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\">" . $self->getEndDate . "</endDate>";
	} else {
		$tmpstr = "<endDate xsi:type=\"xsd:dateTime\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:string\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# latestVersionIndicator;
	if( defined( $self->getLatestVersionIndicator ) ) {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\">" . $self->getLatestVersionIndicator . "</latestVersionIndicator>";
	} else {
		$tmpstr = "<latestVersionIndicator xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# longName;
	if( defined( $self->getLongName ) ) {
		$tmpstr = "<longName xsi:type=\"xsd:string\">" . $self->getLongName . "</longName>";
	} else {
		$tmpstr = "<longName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# modifiedBy;
	if( defined( $self->getModifiedBy ) ) {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\">" . $self->getModifiedBy . "</modifiedBy>";
	} else {
		$tmpstr = "<modifiedBy xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# origin;
	if( defined( $self->getOrigin ) ) {
		$tmpstr = "<origin xsi:type=\"xsd:string\">" . $self->getOrigin . "</origin>";
	} else {
		$tmpstr = "<origin xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredDefinition;
	if( defined( $self->getPreferredDefinition ) ) {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\">" . $self->getPreferredDefinition . "</preferredDefinition>";
	} else {
		$tmpstr = "<preferredDefinition xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# preferredName;
	if( defined( $self->getPreferredName ) ) {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\">" . $self->getPreferredName . "</preferredName>";
	} else {
		$tmpstr = "<preferredName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# publicID;
	if( defined( $self->getPublicID ) ) {
		$tmpstr = "<publicID xsi:type=\"xsd:long\">" . $self->getPublicID . "</publicID>";
	} else {
		$tmpstr = "<publicID xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# registrationStatus;
	if( defined( $self->getRegistrationStatus ) ) {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\">" . $self->getRegistrationStatus . "</registrationStatus>";
	} else {
		$tmpstr = "<registrationStatus xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# unresolvedIssue;
	if( defined( $self->getUnresolvedIssue ) ) {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\">" . $self->getUnresolvedIssue . "</unresolvedIssue>";
	} else {
		$tmpstr = "<unresolvedIssue xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# version;
	if( defined( $self->getVersion ) ) {
		$tmpstr = "<version xsi:type=\"xsd:float\">" . $self->getVersion . "</version>";
	} else {
		$tmpstr = "<version xsi:type=\"xsd:float\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusDescription;
	if( defined( $self->getWorkflowStatusDescription ) ) {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\">" . $self->getWorkflowStatusDescription . "</workflowStatusDescription>";
	} else {
		$tmpstr = "<workflowStatusDescription xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# workflowStatusName;
	if( defined( $self->getWorkflowStatusName ) ) {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\">" . $self->getWorkflowStatusName . "</workflowStatusName>";
	} else {
		$tmpstr = "<workflowStatusName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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
		my $approvedBy;
		my $approvedDate;
		my $changeNumber;
		my $changeType;
		my $leadOrganizationName;
		my $phase;
		my $protocolID;
		my $reviewedBy;
		my $reviewedDate;
		my $type;
		my $beginDate;
		my $changeNote;
		my $createdBy;
		my $dateCreated;
		my $dateModified;
		my $deletedIndicator;
		my $endDate;
		my $id;
		my $latestVersionIndicator;
		my $longName;
		my $modifiedBy;
		my $origin;
		my $preferredDefinition;
		my $preferredName;
		my $publicID;
		my $registrationStatus;
		my $unresolvedIssue;
		my $version;
		my $workflowStatusDescription;
		my $workflowStatusName;
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
			elsif ($childrenNode->getNodeName eq "approvedBy") {
				$approvedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "approvedDate") {
				$approvedDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNumber") {
				$changeNumber=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeType") {
				$changeType=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "leadOrganizationName") {
				$leadOrganizationName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "phase") {
				$phase=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "protocolID") {
				$protocolID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "reviewedBy") {
				$reviewedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "reviewedDate") {
				$reviewedDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "beginDate") {
				$beginDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "changeNote") {
				$changeNote=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "createdBy") {
				$createdBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateCreated") {
				$dateCreated=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dateModified") {
				$dateModified=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "deletedIndicator") {
				$deletedIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endDate") {
				$endDate=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "latestVersionIndicator") {
				$latestVersionIndicator=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "longName") {
				$longName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "modifiedBy") {
				$modifiedBy=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "origin") {
				$origin=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredDefinition") {
				$preferredDefinition=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "preferredName") {
				$preferredName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "publicID") {
				$publicID=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "registrationStatus") {
				$registrationStatus=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "unresolvedIssue") {
				$unresolvedIssue=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "version") {
				$version=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusDescription") {
				$workflowStatusDescription=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "workflowStatusName") {
				$workflowStatusName=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::CaDSR::Protocol;
	## begin set attr ##
		$newobj->setApprovedBy($approvedBy);
		$newobj->setApprovedDate($approvedDate);
		$newobj->setChangeNumber($changeNumber);
		$newobj->setChangeType($changeType);
		$newobj->setLeadOrganizationName($leadOrganizationName);
		$newobj->setPhase($phase);
		$newobj->setProtocolID($protocolID);
		$newobj->setReviewedBy($reviewedBy);
		$newobj->setReviewedDate($reviewedDate);
		$newobj->setType($type);
		$newobj->setBeginDate($beginDate);
		$newobj->setChangeNote($changeNote);
		$newobj->setCreatedBy($createdBy);
		$newobj->setDateCreated($dateCreated);
		$newobj->setDateModified($dateModified);
		$newobj->setDeletedIndicator($deletedIndicator);
		$newobj->setEndDate($endDate);
		$newobj->setId($id);
		$newobj->setLatestVersionIndicator($latestVersionIndicator);
		$newobj->setLongName($longName);
		$newobj->setModifiedBy($modifiedBy);
		$newobj->setOrigin($origin);
		$newobj->setPreferredDefinition($preferredDefinition);
		$newobj->setPreferredName($preferredName);
		$newobj->setPublicID($publicID);
		$newobj->setRegistrationStatus($registrationStatus);
		$newobj->setUnresolvedIssue($unresolvedIssue);
		$newobj->setVersion($version);
		$newobj->setWorkflowStatusDescription($workflowStatusDescription);
		$newobj->setWorkflowStatusName($workflowStatusName);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getApprovedBy {
	my $self = shift;
	return $self->{approvedBy};
}

sub setApprovedBy {
	my $self = shift;
	$self->{approvedBy} = shift;
}

sub getApprovedDate {
	my $self = shift;
	return $self->{approvedDate};
}

sub setApprovedDate {
	my $self = shift;
	$self->{approvedDate} = shift;
}

sub getChangeNumber {
	my $self = shift;
	return $self->{changeNumber};
}

sub setChangeNumber {
	my $self = shift;
	$self->{changeNumber} = shift;
}

sub getChangeType {
	my $self = shift;
	return $self->{changeType};
}

sub setChangeType {
	my $self = shift;
	$self->{changeType} = shift;
}

sub getLeadOrganizationName {
	my $self = shift;
	return $self->{leadOrganizationName};
}

sub setLeadOrganizationName {
	my $self = shift;
	$self->{leadOrganizationName} = shift;
}

sub getPhase {
	my $self = shift;
	return $self->{phase};
}

sub setPhase {
	my $self = shift;
	$self->{phase} = shift;
}

sub getProtocolID {
	my $self = shift;
	return $self->{protocolID};
}

sub setProtocolID {
	my $self = shift;
	$self->{protocolID} = shift;
}

sub getReviewedBy {
	my $self = shift;
	return $self->{reviewedBy};
}

sub setReviewedBy {
	my $self = shift;
	$self->{reviewedBy} = shift;
}

sub getReviewedDate {
	my $self = shift;
	return $self->{reviewedDate};
}

sub setReviewedDate {
	my $self = shift;
	$self->{reviewedDate} = shift;
}

sub getType {
	my $self = shift;
	return $self->{type};
}

sub setType {
	my $self = shift;
	$self->{type} = shift;
}

sub getBeginDate {
	my $self = shift;
	return $self->{beginDate};
}

sub setBeginDate {
	my $self = shift;
	$self->{beginDate} = shift;
}

sub getChangeNote {
	my $self = shift;
	return $self->{changeNote};
}

sub setChangeNote {
	my $self = shift;
	$self->{changeNote} = shift;
}

sub getCreatedBy {
	my $self = shift;
	return $self->{createdBy};
}

sub setCreatedBy {
	my $self = shift;
	$self->{createdBy} = shift;
}

sub getDateCreated {
	my $self = shift;
	return $self->{dateCreated};
}

sub setDateCreated {
	my $self = shift;
	$self->{dateCreated} = shift;
}

sub getDateModified {
	my $self = shift;
	return $self->{dateModified};
}

sub setDateModified {
	my $self = shift;
	$self->{dateModified} = shift;
}

sub getDeletedIndicator {
	my $self = shift;
	return $self->{deletedIndicator};
}

sub setDeletedIndicator {
	my $self = shift;
	$self->{deletedIndicator} = shift;
}

sub getEndDate {
	my $self = shift;
	return $self->{endDate};
}

sub setEndDate {
	my $self = shift;
	$self->{endDate} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getLatestVersionIndicator {
	my $self = shift;
	return $self->{latestVersionIndicator};
}

sub setLatestVersionIndicator {
	my $self = shift;
	$self->{latestVersionIndicator} = shift;
}

sub getLongName {
	my $self = shift;
	return $self->{longName};
}

sub setLongName {
	my $self = shift;
	$self->{longName} = shift;
}

sub getModifiedBy {
	my $self = shift;
	return $self->{modifiedBy};
}

sub setModifiedBy {
	my $self = shift;
	$self->{modifiedBy} = shift;
}

sub getOrigin {
	my $self = shift;
	return $self->{origin};
}

sub setOrigin {
	my $self = shift;
	$self->{origin} = shift;
}

sub getPreferredDefinition {
	my $self = shift;
	return $self->{preferredDefinition};
}

sub setPreferredDefinition {
	my $self = shift;
	$self->{preferredDefinition} = shift;
}

sub getPreferredName {
	my $self = shift;
	return $self->{preferredName};
}

sub setPreferredName {
	my $self = shift;
	$self->{preferredName} = shift;
}

sub getPublicID {
	my $self = shift;
	return $self->{publicID};
}

sub setPublicID {
	my $self = shift;
	$self->{publicID} = shift;
}

sub getRegistrationStatus {
	my $self = shift;
	return $self->{registrationStatus};
}

sub setRegistrationStatus {
	my $self = shift;
	$self->{registrationStatus} = shift;
}

sub getUnresolvedIssue {
	my $self = shift;
	return $self->{unresolvedIssue};
}

sub setUnresolvedIssue {
	my $self = shift;
	$self->{unresolvedIssue} = shift;
}

sub getVersion {
	my $self = shift;
	return $self->{version};
}

sub setVersion {
	my $self = shift;
	$self->{version} = shift;
}

sub getWorkflowStatusDescription {
	my $self = shift;
	return $self->{workflowStatusDescription};
}

sub setWorkflowStatusDescription {
	my $self = shift;
	$self->{workflowStatusDescription} = shift;
}

sub getWorkflowStatusName {
	my $self = shift;
	return $self->{workflowStatusName};
}

sub setWorkflowStatusName {
	my $self = shift;
	$self->{workflowStatusName} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getFormCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Form", $self);
	return @results;
}

sub getAdministeredComponentClassSchemeItemCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentClassSchemeItem", $self);
	return @results;
}

sub getAdministeredComponentContactCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::AdministeredComponentContact", $self);
	return @results;
}

sub getContext {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Context", $self);
	return $results[0];
}

sub getDefinitionCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Definition", $self);
	return @results;
}

sub getDesignationCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::Designation", $self);
	return @results;
}

sub getReferenceDocumentCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::CaDSR::ReferenceDocument", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# Below is module documentation for Address

=pod

=head1 Address

CaCORE::CaDSR::Address - Perl extension for Address.

=head2 ABSTRACT

The CaCORE::CaDSR::Address is a Perl object representation of the
CaCORE Address object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Address

The following are all the attributes of the Address object and their data types:

=over 4

=item addressLine1

data type: C<string>

=item addressLine2

data type: C<string>

=item city

data type: C<string>

=item country

data type: C<string>

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item postalCode

data type: C<string>

=item rank

data type: C<int>

=item state

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Address

The following are all the objects that are associated with the Address:

=over 4

=item Collection of L</Organization>:

Many to one assoication, use C<getOrganization> to get the associated Organization.

=item Collection of L</Person>:

Many to one assoication, use C<getPerson> to get the associated Person.


=back

=cut

# Below is module documentation for AdministeredComponent

=pod

=head1 AdministeredComponent

CaCORE::CaDSR::AdministeredComponent - Perl extension for AdministeredComponent.

=head2 ABSTRACT

The CaCORE::CaDSR::AdministeredComponent is a Perl object representation of the
CaCORE AdministeredComponent object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of AdministeredComponent

The following are all the attributes of the AdministeredComponent object and their data types:

=over 4

=item beginDate

data type: C<dateTime>

=item changeNote

data type: C<string>

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item deletedIndicator

data type: C<string>

=item endDate

data type: C<dateTime>

=item id

data type: C<string>

=item latestVersionIndicator

data type: C<string>

=item longName

data type: C<string>

=item modifiedBy

data type: C<string>

=item origin

data type: C<string>

=item preferredDefinition

data type: C<string>

=item preferredName

data type: C<string>

=item publicID

data type: C<long>

=item registrationStatus

data type: C<string>

=item unresolvedIssue

data type: C<string>

=item version

data type: C<float>

=item workflowStatusDescription

data type: C<string>

=item workflowStatusName

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of AdministeredComponent

The following are all the objects that are associated with the AdministeredComponent:

=over 4

=item Instance of L</AdministeredComponentClassSchemeItem>:

One to many assoication, use C<getAdministeredComponentClassSchemeItemCollection> to get a collection of associated AdministeredComponentClassSchemeItem.

=item Instance of L</AdministeredComponentContact>:

One to many assoication, use C<getAdministeredComponentContactCollection> to get a collection of associated AdministeredComponentContact.

=item Collection of L</Context>:

Many to one assoication, use C<getContext> to get the associated Context.

=item Instance of L</Definition>:

One to many assoication, use C<getDefinitionCollection> to get a collection of associated Definition.

=item Instance of L</Designation>:

One to many assoication, use C<getDesignationCollection> to get a collection of associated Designation.

=item Instance of L</ReferenceDocument>:

One to many assoication, use C<getReferenceDocumentCollection> to get a collection of associated ReferenceDocument.


=back

=cut

# Below is module documentation for AdministeredComponentClassSchemeItem

=pod

=head1 AdministeredComponentClassSchemeItem

CaCORE::CaDSR::AdministeredComponentClassSchemeItem - Perl extension for AdministeredComponentClassSchemeItem.

=head2 ABSTRACT

The CaCORE::CaDSR::AdministeredComponentClassSchemeItem is a Perl object representation of the
CaCORE AdministeredComponentClassSchemeItem object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of AdministeredComponentClassSchemeItem

The following are all the attributes of the AdministeredComponentClassSchemeItem object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of AdministeredComponentClassSchemeItem

The following are all the objects that are associated with the AdministeredComponentClassSchemeItem:

=over 4

=item Collection of L</ClassSchemeClassSchemeItem>:

Many to one assoication, use C<getClassSchemeClassSchemeItem> to get the associated ClassSchemeClassSchemeItem.

=item Instance of L</SourceObjectClass>:

One to many assoication, use C<getSourceObjectClassCollection> to get a collection of associated SourceObjectClass.

=item Instance of L</TargetObjectClass>:

One to many assoication, use C<getTargetObjectClassCollection> to get a collection of associated TargetObjectClass.


=back

=cut

# Below is module documentation for AdministeredComponentContact

=pod

=head1 AdministeredComponentContact

CaCORE::CaDSR::AdministeredComponentContact - Perl extension for AdministeredComponentContact.

=head2 ABSTRACT

The CaCORE::CaDSR::AdministeredComponentContact is a Perl object representation of the
CaCORE AdministeredComponentContact object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of AdministeredComponentContact

The following are all the attributes of the AdministeredComponentContact object and their data types:

=over 4

=item contactRole

data type: C<string>

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item rank

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of AdministeredComponentContact

The following are all the objects that are associated with the AdministeredComponentContact:

=over 4

=item Collection of L</ClassSchemeClassSchemeItem>:

Many to one assoication, use C<getClassSchemeClassSchemeItem> to get the associated ClassSchemeClassSchemeItem.

=item Collection of L</ClassificationSchemeItem>:

Many to one assoication, use C<getClassificationSchemeItem> to get the associated ClassificationSchemeItem.

=item Collection of L</Organization>:

Many to one assoication, use C<getOrganization> to get the associated Organization.

=item Collection of L</Person>:

Many to one assoication, use C<getPerson> to get the associated Person.


=back

=cut

# Below is module documentation for ClassSchemeClassSchemeItem

=pod

=head1 ClassSchemeClassSchemeItem

CaCORE::CaDSR::ClassSchemeClassSchemeItem - Perl extension for ClassSchemeClassSchemeItem.

=head2 ABSTRACT

The CaCORE::CaDSR::ClassSchemeClassSchemeItem is a Perl object representation of the
CaCORE ClassSchemeClassSchemeItem object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ClassSchemeClassSchemeItem

The following are all the attributes of the ClassSchemeClassSchemeItem object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item displayOrder

data type: C<int>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ClassSchemeClassSchemeItem

The following are all the objects that are associated with the ClassSchemeClassSchemeItem:

=over 4

=item Instance of L</AdministeredComponentClassSchemeItem>:

One to many assoication, use C<getAdministeredComponentClassSchemeItemCollection> to get a collection of associated AdministeredComponentClassSchemeItem.

=item Instance of L</AdministeredComponentContact>:

One to many assoication, use C<getAdministeredComponentContactCollection> to get a collection of associated AdministeredComponentContact.

=item Instance of L</ChildClassSchemeClassSchemeItem>:

One to many assoication, use C<getChildClassSchemeClassSchemeItemCollection> to get a collection of associated ChildClassSchemeClassSchemeItem.

=item Collection of L</ClassificationScheme>:

Many to one assoication, use C<getClassificationScheme> to get the associated ClassificationScheme.

=item Collection of L</ClassificationSchemeItem>:

Many to one assoication, use C<getClassificationSchemeItem> to get the associated ClassificationSchemeItem.

=item Instance of L</DefinitionClassSchemeItem>:

One to many assoication, use C<getDefinitionClassSchemeItemCollection> to get a collection of associated DefinitionClassSchemeItem.

=item Instance of L</DesignationClassSchemeItem>:

One to many assoication, use C<getDesignationClassSchemeItemCollection> to get a collection of associated DesignationClassSchemeItem.

=item Collection of L</ParentClassSchemeClassSchemeItem>:

Many to one assoication, use C<getParentClassSchemeClassSchemeItem> to get the associated ParentClassSchemeClassSchemeItem.

=item Instance of L</ReferenceDocument>:

One to many assoication, use C<getReferenceDocumentCollection> to get a collection of associated ReferenceDocument.


=back

=cut

# Below is module documentation for ClassificationScheme

=pod

=head1 ClassificationScheme

CaCORE::CaDSR::ClassificationScheme - Perl extension for ClassificationScheme.

=head2 ABSTRACT

The CaCORE::CaDSR::ClassificationScheme is a Perl object representation of the
CaCORE ClassificationScheme object.

ClassificationScheme extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ClassificationScheme

The following are all the attributes of the ClassificationScheme object and their data types:

=over 4

=item labelTypeFlag

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ClassificationScheme

The following are all the objects that are associated with the ClassificationScheme:

=over 4

=item Instance of L</ChildClassificationScheme>:

One to many assoication, use C<getChildClassificationSchemeCollection> to get a collection of associated ChildClassificationScheme.

=item Instance of L</ChildClassificationSchemeRelationship>:

One to many assoication, use C<getChildClassificationSchemeRelationshipCollection> to get a collection of associated ChildClassificationSchemeRelationship.

=item Instance of L</ClassSchemeClassSchemeItem>:

One to many assoication, use C<getClassSchemeClassSchemeItemCollection> to get a collection of associated ClassSchemeClassSchemeItem.

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Collection of L</ParentClassificationScheme>:

Many to one assoication, use C<getParentClassificationScheme> to get the associated ParentClassificationScheme.

=item Instance of L</ParentClassificationSchemeRelationship>:

One to many assoication, use C<getParentClassificationSchemeRelationshipCollection> to get a collection of associated ParentClassificationSchemeRelationship.


=back

=cut

# Below is module documentation for ClassificationSchemeItem

=pod

=head1 ClassificationSchemeItem

CaCORE::CaDSR::ClassificationSchemeItem - Perl extension for ClassificationSchemeItem.

=head2 ABSTRACT

The CaCORE::CaDSR::ClassificationSchemeItem is a Perl object representation of the
CaCORE ClassificationSchemeItem object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ClassificationSchemeItem

The following are all the attributes of the ClassificationSchemeItem object and their data types:

=over 4

=item comments

data type: C<string>

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item description

data type: C<string>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ClassificationSchemeItem

The following are all the objects that are associated with the ClassificationSchemeItem:

=over 4

=item Instance of L</AdministeredComponentContact>:

One to many assoication, use C<getAdministeredComponentContactCollection> to get a collection of associated AdministeredComponentContact.

=item Instance of L</ChildClassificationSchemeItemRelationship>:

One to many assoication, use C<getChildClassificationSchemeItemRelationshipCollection> to get a collection of associated ChildClassificationSchemeItemRelationship.

=item Instance of L</ClassSchemeClassSchemeItem>:

One to many assoication, use C<getClassSchemeClassSchemeItemCollection> to get a collection of associated ClassSchemeClassSchemeItem.

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Instance of L</ParentClassificationSchemeItemRelationship>:

One to many assoication, use C<getParentClassificationSchemeItemRelationshipCollection> to get a collection of associated ParentClassificationSchemeItemRelationship.

=item Instance of L</ReferenceDocument>:

One to many assoication, use C<getReferenceDocumentCollection> to get a collection of associated ReferenceDocument.


=back

=cut

# Below is module documentation for ClassificationSchemeItemRelationship

=pod

=head1 ClassificationSchemeItemRelationship

CaCORE::CaDSR::ClassificationSchemeItemRelationship - Perl extension for ClassificationSchemeItemRelationship.

=head2 ABSTRACT

The CaCORE::CaDSR::ClassificationSchemeItemRelationship is a Perl object representation of the
CaCORE ClassificationSchemeItemRelationship object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ClassificationSchemeItemRelationship

The following are all the attributes of the ClassificationSchemeItemRelationship object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ClassificationSchemeItemRelationship

The following are all the objects that are associated with the ClassificationSchemeItemRelationship:

=over 4

=item Collection of L</ChildClassificationSchemeItem>:

Many to one assoication, use C<getChildClassificationSchemeItem> to get the associated ChildClassificationSchemeItem.

=item Collection of L</ParentClassificationSchemeItem>:

Many to one assoication, use C<getParentClassificationSchemeItem> to get the associated ParentClassificationSchemeItem.


=back

=cut

# Below is module documentation for ClassificationSchemeRelationship

=pod

=head1 ClassificationSchemeRelationship

CaCORE::CaDSR::ClassificationSchemeRelationship - Perl extension for ClassificationSchemeRelationship.

=head2 ABSTRACT

The CaCORE::CaDSR::ClassificationSchemeRelationship is a Perl object representation of the
CaCORE ClassificationSchemeRelationship object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ClassificationSchemeRelationship

The following are all the attributes of the ClassificationSchemeRelationship object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item displayOrder

data type: C<int>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ClassificationSchemeRelationship

The following are all the objects that are associated with the ClassificationSchemeRelationship:

=over 4

=item Collection of L</ChildClassificationScheme>:

Many to one assoication, use C<getChildClassificationScheme> to get the associated ChildClassificationScheme.

=item Collection of L</ParentClassificationScheme>:

Many to one assoication, use C<getParentClassificationScheme> to get the associated ParentClassificationScheme.


=back

=cut

# Below is module documentation for ComponentConcept

=pod

=head1 ComponentConcept

CaCORE::CaDSR::ComponentConcept - Perl extension for ComponentConcept.

=head2 ABSTRACT

The CaCORE::CaDSR::ComponentConcept is a Perl object representation of the
CaCORE ComponentConcept object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ComponentConcept

The following are all the attributes of the ComponentConcept object and their data types:

=over 4

=item displayOrder

data type: C<int>

=item id

data type: C<string>

=item primaryFlag

data type: C<string>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ComponentConcept

The following are all the objects that are associated with the ComponentConcept:

=over 4

=item Collection of L</Componentlevel>:

Many to one assoication, use C<getComponentlevel> to get the associated Componentlevel.

=item Collection of L</Concept>:

Many to one assoication, use C<getConcept> to get the associated Concept.

=item Collection of L</DerivationRule>:

Many to one assoication, use C<getDerivationRule> to get the associated DerivationRule.


=back

=cut

# Below is module documentation for ComponentLevel

=pod

=head1 ComponentLevel

CaCORE::CaDSR::ComponentLevel - Perl extension for ComponentLevel.

=head2 ABSTRACT

The CaCORE::CaDSR::ComponentLevel is a Perl object representation of the
CaCORE ComponentLevel object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ComponentLevel

The following are all the attributes of the ComponentLevel object and their data types:

=over 4

=item concatenationString

data type: C<string>

=item id

data type: C<string>

=item level

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ComponentLevel

The following are all the objects that are associated with the ComponentLevel:

=over 4


=back

=cut

# Below is module documentation for Concept

=pod

=head1 Concept

CaCORE::CaDSR::Concept - Perl extension for Concept.

=head2 ABSTRACT

The CaCORE::CaDSR::Concept is a Perl object representation of the
CaCORE Concept object.

Concept extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Concept

The following are all the attributes of the Concept object and their data types:

=over 4

=item definitionSource

data type: C<string>

=item evsSource

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Concept

The following are all the objects that are associated with the Concept:

=over 4

=item Instance of L</ComponentConcept>:

One to many assoication, use C<getComponentConceptCollection> to get a collection of associated ComponentConcept.

=item Instance of L</ValueDomainPermissibleValue>:

One to many assoication, use C<getValueDomainPermissibleValueCollection> to get a collection of associated ValueDomainPermissibleValue.


=back

=cut

# Below is module documentation for ConceptDerivationRule

=pod

=head1 ConceptDerivationRule

CaCORE::CaDSR::ConceptDerivationRule - Perl extension for ConceptDerivationRule.

=head2 ABSTRACT

The CaCORE::CaDSR::ConceptDerivationRule is a Perl object representation of the
CaCORE ConceptDerivationRule object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ConceptDerivationRule

The following are all the attributes of the ConceptDerivationRule object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ConceptDerivationRule

The following are all the objects that are associated with the ConceptDerivationRule:

=over 4

=item Instance of L</ClassificationScheme>:

One to many assoication, use C<getClassificationSchemeCollection> to get a collection of associated ClassificationScheme.

=item Instance of L</ClassificationSchemeItem>:

One to many assoication, use C<getClassificationSchemeItemCollection> to get a collection of associated ClassificationSchemeItem.

=item Instance of L</ComponentConcept>:

One to many assoication, use C<getComponentConceptCollection> to get a collection of associated ComponentConcept.

=item Instance of L</ConceptualDomain>:

One to many assoication, use C<getConceptualDomainCollection> to get a collection of associated ConceptualDomain.

=item Collection of L</DerivationType>:

Many to one assoication, use C<getDerivationType> to get the associated DerivationType.

=item Instance of L</ObjectClass>:

One to many assoication, use C<getObjectClassCollection> to get a collection of associated ObjectClass.

=item Instance of L</ObjectClassRelationship>:

One to many assoication, use C<getObjectClassRelationshipCollection> to get a collection of associated ObjectClassRelationship.

=item Instance of L</Property>:

One to many assoication, use C<getPropertyCollection> to get a collection of associated Property.

=item Instance of L</Representation>:

One to many assoication, use C<getRepresentationCollection> to get a collection of associated Representation.

=item Instance of L</SourceRoleConcept>:

One to many assoication, use C<getSourceRoleConceptCollection> to get a collection of associated SourceRoleConcept.

=item Instance of L</TargetRoleConcept>:

One to many assoication, use C<getTargetRoleConceptCollection> to get a collection of associated TargetRoleConcept.

=item Instance of L</ValueDomain>:

One to many assoication, use C<getValueDomainCollection> to get a collection of associated ValueDomain.

=item Instance of L</ValueMeaning>:

One to many assoication, use C<getValueMeaningCollection> to get a collection of associated ValueMeaning.


=back

=cut

# Below is module documentation for ConceptualDomain

=pod

=head1 ConceptualDomain

CaCORE::CaDSR::ConceptualDomain - Perl extension for ConceptualDomain.

=head2 ABSTRACT

The CaCORE::CaDSR::ConceptualDomain is a Perl object representation of the
CaCORE ConceptualDomain object.

ConceptualDomain extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ConceptualDomain

The following are all the attributes of the ConceptualDomain object and their data types:

=over 4

=item dimensionality

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ConceptualDomain

The following are all the objects that are associated with the ConceptualDomain:

=over 4

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Instance of L</DataElementConcept>:

One to many assoication, use C<getDataElementConceptCollection> to get a collection of associated DataElementConcept.

=item Instance of L</ValueDomain>:

One to many assoication, use C<getValueDomainCollection> to get a collection of associated ValueDomain.

=item Instance of L</ValueMeaning>:

One to many assoication, use C<getValueMeaningCollection> to get a collection of associated ValueMeaning.


=back

=cut

# Below is module documentation for ConditionMessage

=pod

=head1 ConditionMessage

CaCORE::CaDSR::ConditionMessage - Perl extension for ConditionMessage.

=head2 ABSTRACT

The CaCORE::CaDSR::ConditionMessage is a Perl object representation of the
CaCORE ConditionMessage object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ConditionMessage

The following are all the attributes of the ConditionMessage object and their data types:

=over 4

=item id

data type: C<string>

=item message

data type: C<string>

=item messageType

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ConditionMessage

The following are all the objects that are associated with the ConditionMessage:

=over 4

=item Collection of L</QuestionCondition>:

Many to one assoication, use C<getQuestionCondition> to get the associated QuestionCondition.


=back

=cut

# Below is module documentation for ContactCommunication

=pod

=head1 ContactCommunication

CaCORE::CaDSR::ContactCommunication - Perl extension for ContactCommunication.

=head2 ABSTRACT

The CaCORE::CaDSR::ContactCommunication is a Perl object representation of the
CaCORE ContactCommunication object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ContactCommunication

The following are all the attributes of the ContactCommunication object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item rank

data type: C<int>

=item type

data type: C<string>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ContactCommunication

The following are all the objects that are associated with the ContactCommunication:

=over 4

=item Collection of L</Organization>:

Many to one assoication, use C<getOrganization> to get the associated Organization.

=item Collection of L</Person>:

Many to one assoication, use C<getPerson> to get the associated Person.


=back

=cut

# Below is module documentation for Context

=pod

=head1 Context

CaCORE::CaDSR::Context - Perl extension for Context.

=head2 ABSTRACT

The CaCORE::CaDSR::Context is a Perl object representation of the
CaCORE Context object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Context

The following are all the attributes of the Context object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item description

data type: C<string>

=item id

data type: C<string>

=item languageName

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>

=item version

data type: C<float>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Context

The following are all the objects that are associated with the Context:

=over 4

=item Instance of L</AdministeredComponent>:

One to many assoication, use C<getAdministeredComponentCollection> to get a collection of associated AdministeredComponent.

=item Instance of L</Definition>:

One to many assoication, use C<getDefinitionCollection> to get a collection of associated Definition.

=item Instance of L</Designation>:

One to many assoication, use C<getDesignationCollection> to get a collection of associated Designation.

=item Instance of L</ReferenceDocument>:

One to many assoication, use C<getReferenceDocumentCollection> to get a collection of associated ReferenceDocument.


=back

=cut

# Below is module documentation for DataElement

=pod

=head1 DataElement

CaCORE::CaDSR::DataElement - Perl extension for DataElement.

=head2 ABSTRACT

The CaCORE::CaDSR::DataElement is a Perl object representation of the
CaCORE DataElement object.

DataElement extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DataElement

The following are all the attributes of the DataElement object and their data types:

=over 4


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DataElement

The following are all the objects that are associated with the DataElement:

=over 4

=item Instance of L</ChildDataElementRelationships>:

One to many assoication, use C<getChildDataElementRelationshipsCollection> to get a collection of associated ChildDataElementRelationships.

=item Collection of L</DataElementConcept>:

Many to one assoication, use C<getDataElementConcept> to get the associated DataElementConcept.

=item Instance of L</DataElementDerivation>:

One to many assoication, use C<getDataElementDerivationCollection> to get a collection of associated DataElementDerivation.

=item Collection of L</DerivedDataElement>:

Many to one assoication, use C<getDerivedDataElement> to get the associated DerivedDataElement.

=item Instance of L</ParentDataElementRelationships>:

One to many assoication, use C<getParentDataElementRelationshipsCollection> to get a collection of associated ParentDataElementRelationships.

=item Instance of L</Question>:

One to many assoication, use C<getQuestionCollection> to get a collection of associated Question.

=item Collection of L</ValueDomain>:

Many to one assoication, use C<getValueDomain> to get the associated ValueDomain.


=back

=cut

# Below is module documentation for DataElementConcept

=pod

=head1 DataElementConcept

CaCORE::CaDSR::DataElementConcept - Perl extension for DataElementConcept.

=head2 ABSTRACT

The CaCORE::CaDSR::DataElementConcept is a Perl object representation of the
CaCORE DataElementConcept object.

DataElementConcept extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DataElementConcept

The following are all the attributes of the DataElementConcept object and their data types:

=over 4


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DataElementConcept

The following are all the objects that are associated with the DataElementConcept:

=over 4

=item Instance of L</ChildDataElementConceptRelationship>:

One to many assoication, use C<getChildDataElementConceptRelationshipCollection> to get a collection of associated ChildDataElementConceptRelationship.

=item Collection of L</ConceptualDomain>:

Many to one assoication, use C<getConceptualDomain> to get the associated ConceptualDomain.

=item Instance of L</DataElement>:

One to many assoication, use C<getDataElementCollection> to get a collection of associated DataElement.

=item Collection of L</ObjectClass>:

Many to one assoication, use C<getObjectClass> to get the associated ObjectClass.

=item Instance of L</ParentDataElementConceptRelationship>:

One to many assoication, use C<getParentDataElementConceptRelationshipCollection> to get a collection of associated ParentDataElementConceptRelationship.

=item Collection of L</Property>:

Many to one assoication, use C<getProperty> to get the associated Property.


=back

=cut

# Below is module documentation for DataElementConceptRelationship

=pod

=head1 DataElementConceptRelationship

CaCORE::CaDSR::DataElementConceptRelationship - Perl extension for DataElementConceptRelationship.

=head2 ABSTRACT

The CaCORE::CaDSR::DataElementConceptRelationship is a Perl object representation of the
CaCORE DataElementConceptRelationship object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DataElementConceptRelationship

The following are all the attributes of the DataElementConceptRelationship object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item description

data type: C<string>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DataElementConceptRelationship

The following are all the objects that are associated with the DataElementConceptRelationship:

=over 4

=item Collection of L</ChildDataElementConcept>:

Many to one assoication, use C<getChildDataElementConcept> to get the associated ChildDataElementConcept.

=item Collection of L</ParentDataElementConcept>:

Many to one assoication, use C<getParentDataElementConcept> to get the associated ParentDataElementConcept.


=back

=cut

# Below is module documentation for DataElementDerivation

=pod

=head1 DataElementDerivation

CaCORE::CaDSR::DataElementDerivation - Perl extension for DataElementDerivation.

=head2 ABSTRACT

The CaCORE::CaDSR::DataElementDerivation is a Perl object representation of the
CaCORE DataElementDerivation object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DataElementDerivation

The following are all the attributes of the DataElementDerivation object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item displayOrder

data type: C<int>

=item id

data type: C<string>

=item leadingCharacters

data type: C<string>

=item modifiedBy

data type: C<string>

=item trailingCharacters

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DataElementDerivation

The following are all the objects that are associated with the DataElementDerivation:

=over 4

=item Collection of L</DataElement>:

Many to one assoication, use C<getDataElement> to get the associated DataElement.

=item Collection of L</DerivedDataElement>:

Many to one assoication, use C<getDerivedDataElement> to get the associated DerivedDataElement.

=item Collection of L</LeftOperand>:

Many to one assoication, use C<getLeftOperand> to get the associated LeftOperand.


=back

=cut

# Below is module documentation for DataElementRelationship

=pod

=head1 DataElementRelationship

CaCORE::CaDSR::DataElementRelationship - Perl extension for DataElementRelationship.

=head2 ABSTRACT

The CaCORE::CaDSR::DataElementRelationship is a Perl object representation of the
CaCORE DataElementRelationship object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DataElementRelationship

The following are all the attributes of the DataElementRelationship object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DataElementRelationship

The following are all the objects that are associated with the DataElementRelationship:

=over 4

=item Collection of L</ChildDataElement>:

Many to one assoication, use C<getChildDataElement> to get the associated ChildDataElement.

=item Collection of L</ParentDataElement>:

Many to one assoication, use C<getParentDataElement> to get the associated ParentDataElement.


=back

=cut

# Below is module documentation for Definition

=pod

=head1 Definition

CaCORE::CaDSR::Definition - Perl extension for Definition.

=head2 ABSTRACT

The CaCORE::CaDSR::Definition is a Perl object representation of the
CaCORE Definition object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Definition

The following are all the attributes of the Definition object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item languageName

data type: C<string>

=item modifiedBy

data type: C<string>

=item text

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Definition

The following are all the objects that are associated with the Definition:

=over 4

=item Collection of L</Context>:

Many to one assoication, use C<getContext> to get the associated Context.

=item Instance of L</DefinitionClassSchemeItem>:

One to many assoication, use C<getDefinitionClassSchemeItemCollection> to get a collection of associated DefinitionClassSchemeItem.


=back

=cut

# Below is module documentation for DefinitionClassSchemeItem

=pod

=head1 DefinitionClassSchemeItem

CaCORE::CaDSR::DefinitionClassSchemeItem - Perl extension for DefinitionClassSchemeItem.

=head2 ABSTRACT

The CaCORE::CaDSR::DefinitionClassSchemeItem is a Perl object representation of the
CaCORE DefinitionClassSchemeItem object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DefinitionClassSchemeItem

The following are all the attributes of the DefinitionClassSchemeItem object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DefinitionClassSchemeItem

The following are all the objects that are associated with the DefinitionClassSchemeItem:

=over 4

=item Collection of L</ClassSchemeClassSchemeItem>:

Many to one assoication, use C<getClassSchemeClassSchemeItem> to get the associated ClassSchemeClassSchemeItem.

=item Collection of L</Definition>:

Many to one assoication, use C<getDefinition> to get the associated Definition.


=back

=cut

# Below is module documentation for DerivationType

=pod

=head1 DerivationType

CaCORE::CaDSR::DerivationType - Perl extension for DerivationType.

=head2 ABSTRACT

The CaCORE::CaDSR::DerivationType is a Perl object representation of the
CaCORE DerivationType object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DerivationType

The following are all the attributes of the DerivationType object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item description

data type: C<string>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DerivationType

The following are all the objects that are associated with the DerivationType:

=over 4

=item Instance of L</ConceptDerivationRule>:

One to many assoication, use C<getConceptDerivationRuleCollection> to get a collection of associated ConceptDerivationRule.

=item Instance of L</DerivedDataElement>:

One to many assoication, use C<getDerivedDataElementCollection> to get a collection of associated DerivedDataElement.


=back

=cut

# Below is module documentation for DerivedDataElement

=pod

=head1 DerivedDataElement

CaCORE::CaDSR::DerivedDataElement - Perl extension for DerivedDataElement.

=head2 ABSTRACT

The CaCORE::CaDSR::DerivedDataElement is a Perl object representation of the
CaCORE DerivedDataElement object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DerivedDataElement

The following are all the attributes of the DerivedDataElement object and their data types:

=over 4

=item concatenationCharacter

data type: C<string>

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item methods

data type: C<string>

=item modifiedBy

data type: C<string>

=item rule

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DerivedDataElement

The following are all the objects that are associated with the DerivedDataElement:

=over 4

=item Collection of L</DataElement>:

Many to one assoication, use C<getDataElement> to get the associated DataElement.

=item Instance of L</DataElementDerivation>:

One to many assoication, use C<getDataElementDerivationCollection> to get a collection of associated DataElementDerivation.

=item Collection of L</DerivationType>:

Many to one assoication, use C<getDerivationType> to get the associated DerivationType.


=back

=cut

# Below is module documentation for Designation

=pod

=head1 Designation

CaCORE::CaDSR::Designation - Perl extension for Designation.

=head2 ABSTRACT

The CaCORE::CaDSR::Designation is a Perl object representation of the
CaCORE Designation object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Designation

The following are all the attributes of the Designation object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item languageName

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Designation

The following are all the objects that are associated with the Designation:

=over 4

=item Collection of L</Context>:

Many to one assoication, use C<getContext> to get the associated Context.

=item Instance of L</DesignationClassSchemeItem>:

One to many assoication, use C<getDesignationClassSchemeItemCollection> to get a collection of associated DesignationClassSchemeItem.


=back

=cut

# Below is module documentation for DesignationClassSchemeItem

=pod

=head1 DesignationClassSchemeItem

CaCORE::CaDSR::DesignationClassSchemeItem - Perl extension for DesignationClassSchemeItem.

=head2 ABSTRACT

The CaCORE::CaDSR::DesignationClassSchemeItem is a Perl object representation of the
CaCORE DesignationClassSchemeItem object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DesignationClassSchemeItem

The following are all the attributes of the DesignationClassSchemeItem object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DesignationClassSchemeItem

The following are all the objects that are associated with the DesignationClassSchemeItem:

=over 4

=item Collection of L</ClassSchemeClassSchemeItem>:

Many to one assoication, use C<getClassSchemeClassSchemeItem> to get the associated ClassSchemeClassSchemeItem.

=item Collection of L</Designation>:

Many to one assoication, use C<getDesignation> to get the associated Designation.


=back

=cut

# Below is module documentation for EnumeratedValueDomain

=pod

=head1 EnumeratedValueDomain

CaCORE::CaDSR::EnumeratedValueDomain - Perl extension for EnumeratedValueDomain.

=head2 ABSTRACT

The CaCORE::CaDSR::EnumeratedValueDomain is a Perl object representation of the
CaCORE EnumeratedValueDomain object.

EnumeratedValueDomain extends from domain object L<"ValueDomain">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of EnumeratedValueDomain

The following are all the attributes of the EnumeratedValueDomain object and their data types:

=over 4


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of EnumeratedValueDomain

The following are all the objects that are associated with the EnumeratedValueDomain:

=over 4

=item Instance of L</ValueDomainPermissibleValue>:

One to many assoication, use C<getValueDomainPermissibleValueCollection> to get a collection of associated ValueDomainPermissibleValue.


=back

=cut

# Below is module documentation for Form

=pod

=head1 Form

CaCORE::CaDSR::Form - Perl extension for Form.

=head2 ABSTRACT

The CaCORE::CaDSR::Form is a Perl object representation of the
CaCORE Form object.

Form extends from domain object L<"FormElement">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Form

The following are all the attributes of the Form object and their data types:

=over 4

=item displayName

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Form

The following are all the objects that are associated with the Form:

=over 4

=item Instance of L</Module>:

One to many assoication, use C<getModuleCollection> to get a collection of associated Module.

=item Instance of L</Protocol>:

One to many assoication, use C<getProtocolCollection> to get a collection of associated Protocol.


=back

=cut

# Below is module documentation for FormElement

=pod

=head1 FormElement

CaCORE::CaDSR::FormElement - Perl extension for FormElement.

=head2 ABSTRACT

The CaCORE::CaDSR::FormElement is a Perl object representation of the
CaCORE FormElement object.

FormElement extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of FormElement

The following are all the attributes of the FormElement object and their data types:

=over 4


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of FormElement

The following are all the objects that are associated with the FormElement:

=over 4

=item Instance of L</Instruction>:

One to many assoication, use C<getInstructionCollection> to get a collection of associated Instruction.


=back

=cut

# Below is module documentation for Function

=pod

=head1 Function

CaCORE::CaDSR::Function - Perl extension for Function.

=head2 ABSTRACT

The CaCORE::CaDSR::Function is a Perl object representation of the
CaCORE Function object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Function

The following are all the attributes of the Function object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>

=item symbol

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Function

The following are all the objects that are associated with the Function:

=over 4

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Instance of L</ConditionComponent>:

One to many assoication, use C<getConditionComponentCollection> to get a collection of associated ConditionComponent.


=back

=cut

# Below is module documentation for Instruction

=pod

=head1 Instruction

CaCORE::CaDSR::Instruction - Perl extension for Instruction.

=head2 ABSTRACT

The CaCORE::CaDSR::Instruction is a Perl object representation of the
CaCORE Instruction object.

Instruction extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Instruction

The following are all the attributes of the Instruction object and their data types:

=over 4

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Instruction

The following are all the objects that are associated with the Instruction:

=over 4

=item Collection of L</FormElement>:

Many to one assoication, use C<getFormElement> to get the associated FormElement.


=back

=cut

# Below is module documentation for Module

=pod

=head1 Module

CaCORE::CaDSR::Module - Perl extension for Module.

=head2 ABSTRACT

The CaCORE::CaDSR::Module is a Perl object representation of the
CaCORE Module object.

Module extends from domain object L<"FormElement">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Module

The following are all the attributes of the Module object and their data types:

=over 4

=item displayOrder

data type: C<int>

=item maximumQuestionRepeat

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Module

The following are all the objects that are associated with the Module:

=over 4

=item Collection of L</Form>:

Many to one assoication, use C<getForm> to get the associated Form.

=item Instance of L</Question>:

One to many assoication, use C<getQuestionCollection> to get a collection of associated Question.


=back

=cut

# Below is module documentation for NonenumeratedValueDomain

=pod

=head1 NonenumeratedValueDomain

CaCORE::CaDSR::NonenumeratedValueDomain - Perl extension for NonenumeratedValueDomain.

=head2 ABSTRACT

The CaCORE::CaDSR::NonenumeratedValueDomain is a Perl object representation of the
CaCORE NonenumeratedValueDomain object.

NonenumeratedValueDomain extends from domain object L<"ValueDomain">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of NonenumeratedValueDomain

The following are all the attributes of the NonenumeratedValueDomain object and their data types:

=over 4


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of NonenumeratedValueDomain

The following are all the objects that are associated with the NonenumeratedValueDomain:

=over 4


=back

=cut

# Below is module documentation for ObjectClass

=pod

=head1 ObjectClass

CaCORE::CaDSR::ObjectClass - Perl extension for ObjectClass.

=head2 ABSTRACT

The CaCORE::CaDSR::ObjectClass is a Perl object representation of the
CaCORE ObjectClass object.

ObjectClass extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ObjectClass

The following are all the attributes of the ObjectClass object and their data types:

=over 4

=item definitionSource

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ObjectClass

The following are all the objects that are associated with the ObjectClass:

=over 4

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Instance of L</DataElementConcept>:

One to many assoication, use C<getDataElementConceptCollection> to get a collection of associated DataElementConcept.

=item Instance of L</SourcObjectClassRelationship>:

One to many assoication, use C<getSourcObjectClassRelationshipCollection> to get a collection of associated SourcObjectClassRelationship.

=item Instance of L</TargetObjectClassRelationship>:

One to many assoication, use C<getTargetObjectClassRelationshipCollection> to get a collection of associated TargetObjectClassRelationship.


=back

=cut

# Below is module documentation for ObjectClassRelationship

=pod

=head1 ObjectClassRelationship

CaCORE::CaDSR::ObjectClassRelationship - Perl extension for ObjectClassRelationship.

=head2 ABSTRACT

The CaCORE::CaDSR::ObjectClassRelationship is a Perl object representation of the
CaCORE ObjectClassRelationship object.

ObjectClassRelationship extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ObjectClassRelationship

The following are all the attributes of the ObjectClassRelationship object and their data types:

=over 4

=item dimensionality

data type: C<int>

=item direction

data type: C<string>

=item displayOrder

data type: C<int>

=item isArray

data type: C<string>

=item name

data type: C<string>

=item sourceHighMultiplicity

data type: C<int>

=item sourceLowMultiplicity

data type: C<int>

=item sourceRole

data type: C<string>

=item targetHighMultiplicity

data type: C<int>

=item targetLowMultiplicity

data type: C<int>

=item targetRole

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ObjectClassRelationship

The following are all the objects that are associated with the ObjectClassRelationship:

=over 4

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Collection of L</SourceConceptDerivationRule>:

Many to one assoication, use C<getSourceConceptDerivationRule> to get the associated SourceConceptDerivationRule.

=item Collection of L</SourceObjectClass>:

Many to one assoication, use C<getSourceObjectClass> to get the associated SourceObjectClass.

=item Collection of L</SourceObjectClassClassification>:

Many to one assoication, use C<getSourceObjectClassClassification> to get the associated SourceObjectClassClassification.

=item Collection of L</TargetConceptDerivationRule>:

Many to one assoication, use C<getTargetConceptDerivationRule> to get the associated TargetConceptDerivationRule.

=item Collection of L</TargetObjectClass>:

Many to one assoication, use C<getTargetObjectClass> to get the associated TargetObjectClass.

=item Collection of L</TargetObjectClassClassification>:

Many to one assoication, use C<getTargetObjectClassClassification> to get the associated TargetObjectClassClassification.


=back

=cut

# Below is module documentation for Organization

=pod

=head1 Organization

CaCORE::CaDSR::Organization - Perl extension for Organization.

=head2 ABSTRACT

The CaCORE::CaDSR::Organization is a Perl object representation of the
CaCORE Organization object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Organization

The following are all the attributes of the Organization object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Organization

The following are all the objects that are associated with the Organization:

=over 4

=item Instance of L</Address>:

One to many assoication, use C<getAddressCollection> to get a collection of associated Address.

=item Instance of L</AdministeredComponentContact>:

One to many assoication, use C<getAdministeredComponentContactCollection> to get a collection of associated AdministeredComponentContact.

=item Instance of L</ContactCommunication>:

One to many assoication, use C<getContactCommunicationCollection> to get a collection of associated ContactCommunication.

=item Instance of L</Person>:

One to many assoication, use C<getPersonCollection> to get a collection of associated Person.


=back

=cut

# Below is module documentation for PermissibleValue

=pod

=head1 PermissibleValue

CaCORE::CaDSR::PermissibleValue - Perl extension for PermissibleValue.

=head2 ABSTRACT

The CaCORE::CaDSR::PermissibleValue is a Perl object representation of the
CaCORE PermissibleValue object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of PermissibleValue

The following are all the attributes of the PermissibleValue object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item highValueNumber

data type: C<long>

=item id

data type: C<string>

=item lowValueNumber

data type: C<long>

=item modifiedBy

data type: C<string>

=item value

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of PermissibleValue

The following are all the objects that are associated with the PermissibleValue:

=over 4

=item Instance of L</ValueDomainPermissibleValue>:

One to many assoication, use C<getValueDomainPermissibleValueCollection> to get a collection of associated ValueDomainPermissibleValue.

=item Collection of L</ValueMeaning>:

Many to one assoication, use C<getValueMeaning> to get the associated ValueMeaning.


=back

=cut

# Below is module documentation for Person

=pod

=head1 Person

CaCORE::CaDSR::Person - Perl extension for Person.

=head2 ABSTRACT

The CaCORE::CaDSR::Person is a Perl object representation of the
CaCORE Person object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Person

The following are all the attributes of the Person object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item firstName

data type: C<string>

=item id

data type: C<string>

=item lastName

data type: C<string>

=item middleInitial

data type: C<string>

=item modifiedBy

data type: C<string>

=item position

data type: C<string>

=item rank

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Person

The following are all the objects that are associated with the Person:

=over 4

=item Instance of L</Address>:

One to many assoication, use C<getAddressCollection> to get a collection of associated Address.

=item Instance of L</AdministeredComponentContact>:

One to many assoication, use C<getAdministeredComponentContactCollection> to get a collection of associated AdministeredComponentContact.

=item Instance of L</ContactCommunication>:

One to many assoication, use C<getContactCommunicationCollection> to get a collection of associated ContactCommunication.

=item Collection of L</Organization>:

Many to one assoication, use C<getOrganization> to get the associated Organization.


=back

=cut

# Below is module documentation for Property

=pod

=head1 Property

CaCORE::CaDSR::Property - Perl extension for Property.

=head2 ABSTRACT

The CaCORE::CaDSR::Property is a Perl object representation of the
CaCORE Property object.

Property extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Property

The following are all the attributes of the Property object and their data types:

=over 4

=item definitionSource

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Property

The following are all the objects that are associated with the Property:

=over 4

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Instance of L</DataElementConcept>:

One to many assoication, use C<getDataElementConceptCollection> to get a collection of associated DataElementConcept.


=back

=cut

# Below is module documentation for Protocol

=pod

=head1 Protocol

CaCORE::CaDSR::Protocol - Perl extension for Protocol.

=head2 ABSTRACT

The CaCORE::CaDSR::Protocol is a Perl object representation of the
CaCORE Protocol object.

Protocol extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Protocol

The following are all the attributes of the Protocol object and their data types:

=over 4

=item approvedBy

data type: C<string>

=item approvedDate

data type: C<dateTime>

=item changeNumber

data type: C<string>

=item changeType

data type: C<string>

=item leadOrganizationName

data type: C<string>

=item phase

data type: C<string>

=item protocolID

data type: C<string>

=item reviewedBy

data type: C<string>

=item reviewedDate

data type: C<dateTime>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Protocol

The following are all the objects that are associated with the Protocol:

=over 4

=item Instance of L</Form>:

One to many assoication, use C<getFormCollection> to get a collection of associated Form.


=back

=cut

# Below is module documentation for Question

=pod

=head1 Question

CaCORE::CaDSR::Question - Perl extension for Question.

=head2 ABSTRACT

The CaCORE::CaDSR::Question is a Perl object representation of the
CaCORE Question object.

Question extends from domain object L<"FormElement">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Question

The following are all the attributes of the Question object and their data types:

=over 4

=item defaultValidValueId

data type: C<string>

=item defaultValue

data type: C<string>

=item displayOrder

data type: C<int>

=item isEditable

data type: C<string>

=item isMandatory

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Question

The following are all the objects that are associated with the Question:

=over 4

=item Collection of L</DataElement>:

Many to one assoication, use C<getDataElement> to get the associated DataElement.

=item Collection of L</Module>:

Many to one assoication, use C<getModule> to get the associated Module.

=item Instance of L</QuestionComponent>:

One to many assoication, use C<getQuestionComponentCollection> to get a collection of associated QuestionComponent.

=item Collection of L</QuestionCondition>:

Many to one assoication, use C<getQuestionCondition> to get the associated QuestionCondition.

=item Instance of L</QuestionRepetition>:

One to many assoication, use C<getQuestionRepetitionCollection> to get a collection of associated QuestionRepetition.

=item Instance of L</ValidValue>:

One to many assoication, use C<getValidValueCollection> to get a collection of associated ValidValue.

=item Collection of L</ValueDomain>:

Many to one assoication, use C<getValueDomain> to get the associated ValueDomain.


=back

=cut

# Below is module documentation for QuestionCondition

=pod

=head1 QuestionCondition

CaCORE::CaDSR::QuestionCondition - Perl extension for QuestionCondition.

=head2 ABSTRACT

The CaCORE::CaDSR::QuestionCondition is a Perl object representation of the
CaCORE QuestionCondition object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of QuestionCondition

The following are all the attributes of the QuestionCondition object and their data types:

=over 4

=item id

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of QuestionCondition

The following are all the objects that are associated with the QuestionCondition:

=over 4

=item Instance of L</ConditionComponent>:

One to many assoication, use C<getConditionComponentCollection> to get a collection of associated ConditionComponent.

=item Instance of L</CondtionMessage>:

One to many assoication, use C<getCondtionMessageCollection> to get a collection of associated CondtionMessage.

=item Instance of L</ForcedConditionTriggeredAction>:

One to many assoication, use C<getForcedConditionTriggeredActionCollection> to get a collection of associated ForcedConditionTriggeredAction.

=item Instance of L</Question>:

One to many assoication, use C<getQuestionCollection> to get a collection of associated Question.

=item Instance of L</QuestionCondition>:

One to many assoication, use C<getQuestionConditionCollection> to get a collection of associated QuestionCondition.

=item Instance of L</TriggeredAction>:

One to many assoication, use C<getTriggeredActionCollection> to get a collection of associated TriggeredAction.


=back

=cut

# Below is module documentation for QuestionConditionComponents

=pod

=head1 QuestionConditionComponents

CaCORE::CaDSR::QuestionConditionComponents - Perl extension for QuestionConditionComponents.

=head2 ABSTRACT

The CaCORE::CaDSR::QuestionConditionComponents is a Perl object representation of the
CaCORE QuestionConditionComponents object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of QuestionConditionComponents

The following are all the attributes of the QuestionConditionComponents object and their data types:

=over 4

=item constantValue

data type: C<string>

=item displayOrder

data type: C<int>

=item id

data type: C<string>

=item logicalOperand

data type: C<string>

=item operand

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of QuestionConditionComponents

The following are all the objects that are associated with the QuestionConditionComponents:

=over 4

=item Collection of L</Function>:

Many to one assoication, use C<getFunction> to get the associated Function.

=item Collection of L</ParentQuestionCondition>:

Many to one assoication, use C<getParentQuestionCondition> to get the associated ParentQuestionCondition.

=item Collection of L</Question>:

Many to one assoication, use C<getQuestion> to get the associated Question.

=item Collection of L</QuestionCondition>:

Many to one assoication, use C<getQuestionCondition> to get the associated QuestionCondition.

=item Collection of L</ValidValue>:

Many to one assoication, use C<getValidValue> to get the associated ValidValue.


=back

=cut

# Below is module documentation for QuestionRepetition

=pod

=head1 QuestionRepetition

CaCORE::CaDSR::QuestionRepetition - Perl extension for QuestionRepetition.

=head2 ABSTRACT

The CaCORE::CaDSR::QuestionRepetition is a Perl object representation of the
CaCORE QuestionRepetition object.

QuestionRepetition extends from domain object L<"FormElement">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of QuestionRepetition

The following are all the attributes of the QuestionRepetition object and their data types:

=over 4

=item defaultValue

data type: C<string>

=item isEditable

data type: C<string>

=item repeatSequenceNumber

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of QuestionRepetition

The following are all the objects that are associated with the QuestionRepetition:

=over 4

=item Collection of L</DefaultValidValue>:

Many to one assoication, use C<getDefaultValidValue> to get the associated DefaultValidValue.


=back

=cut

# Below is module documentation for ReferenceDocument

=pod

=head1 ReferenceDocument

CaCORE::CaDSR::ReferenceDocument - Perl extension for ReferenceDocument.

=head2 ABSTRACT

The CaCORE::CaDSR::ReferenceDocument is a Perl object representation of the
CaCORE ReferenceDocument object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ReferenceDocument

The following are all the attributes of the ReferenceDocument object and their data types:

=over 4

=item URL

data type: C<string>

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item displayOrder

data type: C<long>

=item doctext

data type: C<string>

=item id

data type: C<string>

=item languageName

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>

=item organizationId

data type: C<string>

=item rdtlName

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ReferenceDocument

The following are all the objects that are associated with the ReferenceDocument:

=over 4

=item Collection of L</ClassSchemeClassSchemeItem>:

Many to one assoication, use C<getClassSchemeClassSchemeItem> to get the associated ClassSchemeClassSchemeItem.

=item Collection of L</ClassificationSchemeItem>:

Many to one assoication, use C<getClassificationSchemeItem> to get the associated ClassificationSchemeItem.

=item Collection of L</Context>:

Many to one assoication, use C<getContext> to get the associated Context.


=back

=cut

# Below is module documentation for Representation

=pod

=head1 Representation

CaCORE::CaDSR::Representation - Perl extension for Representation.

=head2 ABSTRACT

The CaCORE::CaDSR::Representation is a Perl object representation of the
CaCORE Representation object.

Representation extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Representation

The following are all the attributes of the Representation object and their data types:

=over 4

=item definitionSource

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Representation

The following are all the objects that are associated with the Representation:

=over 4

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Instance of L</ValueDomain>:

One to many assoication, use C<getValueDomainCollection> to get a collection of associated ValueDomain.


=back

=cut

# Below is module documentation for TriggerAction

=pod

=head1 TriggerAction

CaCORE::CaDSR::TriggerAction - Perl extension for TriggerAction.

=head2 ABSTRACT

The CaCORE::CaDSR::TriggerAction is a Perl object representation of the
CaCORE TriggerAction object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of TriggerAction

The following are all the attributes of the TriggerAction object and their data types:

=over 4

=item action

data type: C<string>

=item createdBy

data type: C<string>

=item criterionValue

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item forcedValue

data type: C<string>

=item id

data type: C<string>

=item instruction

data type: C<string>

=item modifiedBy

data type: C<string>

=item triggerRelationship

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of TriggerAction

The following are all the objects that are associated with the TriggerAction:

=over 4

=item Instance of L</AdministeredComponentClassSchemeItem>:

One to many assoication, use C<getAdministeredComponentClassSchemeItemCollection> to get a collection of associated AdministeredComponentClassSchemeItem.

=item Collection of L</EnforcedCondition>:

Many to one assoication, use C<getEnforcedCondition> to get the associated EnforcedCondition.

=item Instance of L</Protocol>:

One to many assoication, use C<getProtocolCollection> to get a collection of associated Protocol.

=item Collection of L</QuestionCondition>:

Many to one assoication, use C<getQuestionCondition> to get the associated QuestionCondition.

=item Collection of L</SourceFormElement>:

Many to one assoication, use C<getSourceFormElement> to get the associated SourceFormElement.

=item Collection of L</TargetFormElement>:

Many to one assoication, use C<getTargetFormElement> to get the associated TargetFormElement.


=back

=cut

# Below is module documentation for ValidValue

=pod

=head1 ValidValue

CaCORE::CaDSR::ValidValue - Perl extension for ValidValue.

=head2 ABSTRACT

The CaCORE::CaDSR::ValidValue is a Perl object representation of the
CaCORE ValidValue object.

ValidValue extends from domain object L<"FormElement">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ValidValue

The following are all the attributes of the ValidValue object and their data types:

=over 4

=item description

data type: C<string>

=item displayOrder

data type: C<int>

=item meaningText

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ValidValue

The following are all the objects that are associated with the ValidValue:

=over 4

=item Instance of L</ConditionComponent>:

One to many assoication, use C<getConditionComponentCollection> to get a collection of associated ConditionComponent.

=item Collection of L</Question>:

Many to one assoication, use C<getQuestion> to get the associated Question.

=item Collection of L</ValueDomainPermissibleValue>:

Many to one assoication, use C<getValueDomainPermissibleValue> to get the associated ValueDomainPermissibleValue.


=back

=cut

# Below is module documentation for ValueDomain

=pod

=head1 ValueDomain

CaCORE::CaDSR::ValueDomain - Perl extension for ValueDomain.

=head2 ABSTRACT

The CaCORE::CaDSR::ValueDomain is a Perl object representation of the
CaCORE ValueDomain object.

ValueDomain extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ValueDomain

The following are all the attributes of the ValueDomain object and their data types:

=over 4

=item UOMName

data type: C<string>

=item characterSetName

data type: C<string>

=item datatypeAnnotation

data type: C<string>

=item datatypeDescription

data type: C<string>

=item datatypeIsCodegenCompatible

data type: C<string>

=item datatypeName

data type: C<string>

=item datatypeSchemeReference

data type: C<string>

=item decimalPlace

data type: C<int>

=item formatName

data type: C<string>

=item highValueNumber

data type: C<string>

=item lowValueNumber

data type: C<string>

=item maximumLengthNumber

data type: C<int>

=item minimumLengthNumber

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ValueDomain

The following are all the objects that are associated with the ValueDomain:

=over 4

=item Instance of L</ChildValueDomainRelationship>:

One to many assoication, use C<getChildValueDomainRelationshipCollection> to get a collection of associated ChildValueDomainRelationship.

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Collection of L</ConceptualDomain>:

Many to one assoication, use C<getConceptualDomain> to get the associated ConceptualDomain.

=item Instance of L</DataElement>:

One to many assoication, use C<getDataElementCollection> to get a collection of associated DataElement.

=item Instance of L</ParentValueDomainRelationship>:

One to many assoication, use C<getParentValueDomainRelationshipCollection> to get a collection of associated ParentValueDomainRelationship.

=item Instance of L</Question>:

One to many assoication, use C<getQuestionCollection> to get a collection of associated Question.

=item Collection of L</Represention>:

Many to one assoication, use C<getRepresention> to get the associated Represention.


=back

=cut

# Below is module documentation for ValueDomainPermissibleValue

=pod

=head1 ValueDomainPermissibleValue

CaCORE::CaDSR::ValueDomainPermissibleValue - Perl extension for ValueDomainPermissibleValue.

=head2 ABSTRACT

The CaCORE::CaDSR::ValueDomainPermissibleValue is a Perl object representation of the
CaCORE ValueDomainPermissibleValue object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ValueDomainPermissibleValue

The following are all the attributes of the ValueDomainPermissibleValue object and their data types:

=over 4

=item beginDate

data type: C<dateTime>

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item endDate

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item origin

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ValueDomainPermissibleValue

The following are all the objects that are associated with the ValueDomainPermissibleValue:

=over 4

=item Collection of L</Concept>:

Many to one assoication, use C<getConcept> to get the associated Concept.

=item Collection of L</EnumeratedValueDomain>:

Many to one assoication, use C<getEnumeratedValueDomain> to get the associated EnumeratedValueDomain.

=item Collection of L</PermissibleValue>:

Many to one assoication, use C<getPermissibleValue> to get the associated PermissibleValue.

=item Instance of L</ValidValue>:

One to many assoication, use C<getValidValueCollection> to get a collection of associated ValidValue.


=back

=cut

# Below is module documentation for ValueDomainRelationship

=pod

=head1 ValueDomainRelationship

CaCORE::CaDSR::ValueDomainRelationship - Perl extension for ValueDomainRelationship.

=head2 ABSTRACT

The CaCORE::CaDSR::ValueDomainRelationship is a Perl object representation of the
CaCORE ValueDomainRelationship object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ValueDomainRelationship

The following are all the attributes of the ValueDomainRelationship object and their data types:

=over 4

=item createdBy

data type: C<string>

=item dateCreated

data type: C<dateTime>

=item dateModified

data type: C<dateTime>

=item id

data type: C<string>

=item modifiedBy

data type: C<string>

=item name

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ValueDomainRelationship

The following are all the objects that are associated with the ValueDomainRelationship:

=over 4

=item Collection of L</ChildValueDomain>:

Many to one assoication, use C<getChildValueDomain> to get the associated ChildValueDomain.

=item Collection of L</ParentValueDomain>:

Many to one assoication, use C<getParentValueDomain> to get the associated ParentValueDomain.


=back

=cut

# Below is module documentation for ValueMeaning

=pod

=head1 ValueMeaning

CaCORE::CaDSR::ValueMeaning - Perl extension for ValueMeaning.

=head2 ABSTRACT

The CaCORE::CaDSR::ValueMeaning is a Perl object representation of the
CaCORE ValueMeaning object.

ValueMeaning extends from domain object L<"AdministeredComponent">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ValueMeaning

The following are all the attributes of the ValueMeaning object and their data types:

=over 4

=item comments

data type: C<string>

=item description

data type: C<string>

=item shortMeaning

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ValueMeaning

The following are all the objects that are associated with the ValueMeaning:

=over 4

=item Collection of L</ConceptDerivationRule>:

Many to one assoication, use C<getConceptDerivationRule> to get the associated ConceptDerivationRule.

=item Instance of L</ConceptualDomain>:

One to many assoication, use C<getConceptualDomainCollection> to get a collection of associated ConceptualDomain.

=item Instance of L</PermissibleValue>:

One to many assoication, use C<getPermissibleValueCollection> to get a collection of associated PermissibleValue.


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


