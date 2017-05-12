# ------------------------------------------------------------------------------------------
package CaCORE::Common::Provenance::Source;

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
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Source\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.provenance.common.nci.nih.gov\">";
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
		my $id;
		my $name;
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
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "name") {
				$name=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::Common::Provenance::Source;
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
package CaCORE::Common::Provenance::PublicationSource;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::Common::Provenance::Source);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the PublicationSource object
# returns: a PublicationSource object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new PublicationSource\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this PublicationSource intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":PublicationSource\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.provenance.common.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# authors;
	if( defined( $self->getAuthors ) ) {
		$tmpstr = "<authors xsi:type=\"xsd:string\">" . $self->getAuthors . "</authors>";
	} else {
		$tmpstr = "<authors xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# endPage;
	if( defined( $self->getEndPage ) ) {
		$tmpstr = "<endPage xsi:type=\"xsd:int\">" . $self->getEndPage . "</endPage>";
	} else {
		$tmpstr = "<endPage xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# startPage;
	if( defined( $self->getStartPage ) ) {
		$tmpstr = "<startPage xsi:type=\"xsd:int\">" . $self->getStartPage . "</startPage>";
	} else {
		$tmpstr = "<startPage xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# title;
	if( defined( $self->getTitle ) ) {
		$tmpstr = "<title xsi:type=\"xsd:string\">" . $self->getTitle . "</title>";
	} else {
		$tmpstr = "<title xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# volume;
	if( defined( $self->getVolume ) ) {
		$tmpstr = "<volume xsi:type=\"xsd:int\">" . $self->getVolume . "</volume>";
	} else {
		$tmpstr = "<volume xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# year;
	if( defined( $self->getYear ) ) {
		$tmpstr = "<year xsi:type=\"xsd:int\">" . $self->getYear . "</year>";
	} else {
		$tmpstr = "<year xsi:type=\"xsd:int\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of PublicationSource objects
# param: xml doc
# returns: list of PublicationSource objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of PublicationSource objects
# param: xml node
# returns: a list of PublicationSource objects
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

# parse a given xml node, construct one PublicationSource object
# param: xml node
# returns: one PublicationSource object
sub fromWSXMLNode {
	my $PublicationSourceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $authors;
		my $endPage;
		my $startPage;
		my $title;
		my $volume;
		my $year;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($PublicationSourceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "authors") {
				$authors=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "endPage") {
				$endPage=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "startPage") {
				$startPage=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "title") {
				$title=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "volume") {
				$volume=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "year") {
				$year=$textNode->getNodeValue;
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
	my $newobj = new CaCORE::Common::Provenance::PublicationSource;
	## begin set attr ##
		$newobj->setAuthors($authors);
		$newobj->setEndPage($endPage);
		$newobj->setStartPage($startPage);
		$newobj->setTitle($title);
		$newobj->setVolume($volume);
		$newobj->setYear($year);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getAuthors {
	my $self = shift;
	return $self->{authors};
}

sub setAuthors {
	my $self = shift;
	$self->{authors} = shift;
}

sub getEndPage {
	my $self = shift;
	return $self->{endPage};
}

sub setEndPage {
	my $self = shift;
	$self->{endPage} = shift;
}

sub getStartPage {
	my $self = shift;
	return $self->{startPage};
}

sub setStartPage {
	my $self = shift;
	$self->{startPage} = shift;
}

sub getTitle {
	my $self = shift;
	return $self->{title};
}

sub setTitle {
	my $self = shift;
	$self->{title} = shift;
}

sub getVolume {
	my $self = shift;
	return $self->{volume};
}

sub setVolume {
	my $self = shift;
	$self->{volume} = shift;
}

sub getYear {
	my $self = shift;
	return $self->{year};
}

sub setYear {
	my $self = shift;
	$self->{year} = shift;
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

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::Common::Provenance::SourceReference;

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

# create an instance of the SourceReference object
# returns: a SourceReference object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new SourceReference\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this SourceReference intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":SourceReference\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.provenance.common.nci.nih.gov\">";
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

	# reference;
	if( defined( $self->getReference ) ) {
		$tmpstr = "<reference xsi:type=\"xsd:string\">" . $self->getReference . "</reference>";
	} else {
		$tmpstr = "<reference xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceReferenceType;
	if( defined( $self->getSourceReferenceType ) ) {
		$tmpstr = "<sourceReferenceType xsi:type=\"xsd:string\">" . $self->getSourceReferenceType . "</sourceReferenceType>";
	} else {
		$tmpstr = "<sourceReferenceType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of SourceReference objects
# param: xml doc
# returns: list of SourceReference objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of SourceReference objects
# param: xml node
# returns: a list of SourceReference objects
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

# parse a given xml node, construct one SourceReference object
# param: xml node
# returns: one SourceReference object
sub fromWSXMLNode {
	my $SourceReferenceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $id;
		my $reference;
		my $sourceReferenceType;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($SourceReferenceNode->getChildNodes) {
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
			elsif ($childrenNode->getNodeName eq "reference") {
				$reference=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceReferenceType") {
				$sourceReferenceType=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::Common::Provenance::SourceReference;
	## begin set attr ##
		$newobj->setId($id);
		$newobj->setReference($reference);
		$newobj->setSourceReferenceType($sourceReferenceType);
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

sub getReference {
	my $self = shift;
	return $self->{reference};
}

sub setReference {
	my $self = shift;
	$self->{reference} = shift;
}

sub getSourceReferenceType {
	my $self = shift;
	return $self->{sourceReferenceType};
}

sub setSourceReferenceType {
	my $self = shift;
	$self->{sourceReferenceType} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getProvenanceCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::Provenance::Provenance", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::Common::Provenance::WebServicesSourceReference;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::Common::Provenance::SourceReference);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the WebServicesSourceReference object
# returns: a WebServicesSourceReference object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new WebServicesSourceReference\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this WebServicesSourceReference intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":WebServicesSourceReference\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.provenance.common.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# request;
	if( defined( $self->getRequest ) ) {
		$tmpstr = "<request xsi:type=\"xsd:string\">" . $self->getRequest . "</request>";
	} else {
		$tmpstr = "<request xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# reference;
	if( defined( $self->getReference ) ) {
		$tmpstr = "<reference xsi:type=\"xsd:string\">" . $self->getReference . "</reference>";
	} else {
		$tmpstr = "<reference xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceReferenceType;
	if( defined( $self->getSourceReferenceType ) ) {
		$tmpstr = "<sourceReferenceType xsi:type=\"xsd:string\">" . $self->getSourceReferenceType . "</sourceReferenceType>";
	} else {
		$tmpstr = "<sourceReferenceType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of WebServicesSourceReference objects
# param: xml doc
# returns: list of WebServicesSourceReference objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of WebServicesSourceReference objects
# param: xml node
# returns: a list of WebServicesSourceReference objects
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

# parse a given xml node, construct one WebServicesSourceReference object
# param: xml node
# returns: one WebServicesSourceReference object
sub fromWSXMLNode {
	my $WebServicesSourceReferenceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $request;
		my $id;
		my $reference;
		my $sourceReferenceType;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($WebServicesSourceReferenceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "request") {
				$request=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "reference") {
				$reference=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceReferenceType") {
				$sourceReferenceType=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::Common::Provenance::WebServicesSourceReference;
	## begin set attr ##
		$newobj->setRequest($request);
		$newobj->setId($id);
		$newobj->setReference($reference);
		$newobj->setSourceReferenceType($sourceReferenceType);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getRequest {
	my $self = shift;
	return $self->{request};
}

sub setRequest {
	my $self = shift;
	$self->{request} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getReference {
	my $self = shift;
	return $self->{reference};
}

sub setReference {
	my $self = shift;
	$self->{reference} = shift;
}

sub getSourceReferenceType {
	my $self = shift;
	return $self->{sourceReferenceType};
}

sub setSourceReferenceType {
	my $self = shift;
	$self->{sourceReferenceType} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getProvenanceCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::Provenance::Provenance", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::Common::Provenance::URLSourceReference;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::Common::Provenance::SourceReference);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the URLSourceReference object
# returns: a URLSourceReference object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new URLSourceReference\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this URLSourceReference intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":URLSourceReference\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.provenance.common.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# sourceURL;
	if( defined( $self->getSourceURL ) ) {
		$tmpstr = "<sourceURL xsi:type=\"xsd:string\">" . $self->getSourceURL . "</sourceURL>";
	} else {
		$tmpstr = "<sourceURL xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# reference;
	if( defined( $self->getReference ) ) {
		$tmpstr = "<reference xsi:type=\"xsd:string\">" . $self->getReference . "</reference>";
	} else {
		$tmpstr = "<reference xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceReferenceType;
	if( defined( $self->getSourceReferenceType ) ) {
		$tmpstr = "<sourceReferenceType xsi:type=\"xsd:string\">" . $self->getSourceReferenceType . "</sourceReferenceType>";
	} else {
		$tmpstr = "<sourceReferenceType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of URLSourceReference objects
# param: xml doc
# returns: list of URLSourceReference objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of URLSourceReference objects
# param: xml node
# returns: a list of URLSourceReference objects
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

# parse a given xml node, construct one URLSourceReference object
# param: xml node
# returns: one URLSourceReference object
sub fromWSXMLNode {
	my $URLSourceReferenceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $sourceURL;
		my $id;
		my $reference;
		my $sourceReferenceType;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($URLSourceReferenceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "sourceURL") {
				$sourceURL=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "reference") {
				$reference=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceReferenceType") {
				$sourceReferenceType=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::Common::Provenance::URLSourceReference;
	## begin set attr ##
		$newobj->setSourceURL($sourceURL);
		$newobj->setId($id);
		$newobj->setReference($reference);
		$newobj->setSourceReferenceType($sourceReferenceType);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getSourceURL {
	my $self = shift;
	return $self->{sourceURL};
}

sub setSourceURL {
	my $self = shift;
	$self->{sourceURL} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getReference {
	my $self = shift;
	return $self->{reference};
}

sub setReference {
	my $self = shift;
	$self->{reference} = shift;
}

sub getSourceReferenceType {
	my $self = shift;
	return $self->{sourceReferenceType};
}

sub setSourceReferenceType {
	my $self = shift;
	$self->{sourceReferenceType} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getProvenanceCollection {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::Provenance::Provenance", $self);
	return @results;
}

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::Common::Provenance::InternetSource;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::Common::Provenance::Source);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the InternetSource object
# returns: a InternetSource object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new InternetSource\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this InternetSource intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":InternetSource\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.provenance.common.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# ownerInstitution;
	if( defined( $self->getOwnerInstitution ) ) {
		$tmpstr = "<ownerInstitution xsi:type=\"xsd:string\">" . $self->getOwnerInstitution . "</ownerInstitution>";
	} else {
		$tmpstr = "<ownerInstitution xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# ownerPersons;
	if( defined( $self->getOwnerPersons ) ) {
		$tmpstr = "<ownerPersons xsi:type=\"xsd:string\">" . $self->getOwnerPersons . "</ownerPersons>";
	} else {
		$tmpstr = "<ownerPersons xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceURI;
	if( defined( $self->getSourceURI ) ) {
		$tmpstr = "<sourceURI xsi:type=\"xsd:string\">" . $self->getSourceURI . "</sourceURI>";
	} else {
		$tmpstr = "<sourceURI xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of InternetSource objects
# param: xml doc
# returns: list of InternetSource objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of InternetSource objects
# param: xml node
# returns: a list of InternetSource objects
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

# parse a given xml node, construct one InternetSource object
# param: xml node
# returns: one InternetSource object
sub fromWSXMLNode {
	my $InternetSourceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $ownerInstitution;
		my $ownerPersons;
		my $sourceURI;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($InternetSourceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "ownerInstitution") {
				$ownerInstitution=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "ownerPersons") {
				$ownerPersons=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceURI") {
				$sourceURI=$textNode->getNodeValue;
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
	my $newobj = new CaCORE::Common::Provenance::InternetSource;
	## begin set attr ##
		$newobj->setOwnerInstitution($ownerInstitution);
		$newobj->setOwnerPersons($ownerPersons);
		$newobj->setSourceURI($sourceURI);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getOwnerInstitution {
	my $self = shift;
	return $self->{ownerInstitution};
}

sub setOwnerInstitution {
	my $self = shift;
	$self->{ownerInstitution} = shift;
}

sub getOwnerPersons {
	my $self = shift;
	return $self->{ownerPersons};
}

sub setOwnerPersons {
	my $self = shift;
	$self->{ownerPersons} = shift;
}

sub getSourceURI {
	my $self = shift;
	return $self->{sourceURI};
}

sub setSourceURI {
	my $self = shift;
	$self->{sourceURI} = shift;
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

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::Common::Provenance::ResearchInstitutionSource;

use 5.005;
#use strict;
use warnings;

require Exporter;

use XML::DOM;

## begin import objects ##
use CaCORE::ApplicationService;
## end import objects ##


@ISA = qw(CaCORE::Common::Provenance::Source);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# create an instance of the ResearchInstitutionSource object
# returns: a ResearchInstitutionSource object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new ResearchInstitutionSource\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this ResearchInstitutionSource intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":ResearchInstitutionSource\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.provenance.common.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# institutionAddress;
	if( defined( $self->getInstitutionAddress ) ) {
		$tmpstr = "<institutionAddress xsi:type=\"xsd:string\">" . $self->getInstitutionAddress . "</institutionAddress>";
	} else {
		$tmpstr = "<institutionAddress xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# institutionDepartment;
	if( defined( $self->getInstitutionDepartment ) ) {
		$tmpstr = "<institutionDepartment xsi:type=\"xsd:string\">" . $self->getInstitutionDepartment . "</institutionDepartment>";
	} else {
		$tmpstr = "<institutionDepartment xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# institutionName;
	if( defined( $self->getInstitutionName ) ) {
		$tmpstr = "<institutionName xsi:type=\"xsd:string\">" . $self->getInstitutionName . "</institutionName>";
	} else {
		$tmpstr = "<institutionName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# institutionPersons;
	if( defined( $self->getInstitutionPersons ) ) {
		$tmpstr = "<institutionPersons xsi:type=\"xsd:string\">" . $self->getInstitutionPersons . "</institutionPersons>";
	} else {
		$tmpstr = "<institutionPersons xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of ResearchInstitutionSource objects
# param: xml doc
# returns: list of ResearchInstitutionSource objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of ResearchInstitutionSource objects
# param: xml node
# returns: a list of ResearchInstitutionSource objects
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

# parse a given xml node, construct one ResearchInstitutionSource object
# param: xml node
# returns: one ResearchInstitutionSource object
sub fromWSXMLNode {
	my $ResearchInstitutionSourceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $institutionAddress;
		my $institutionDepartment;
		my $institutionName;
		my $institutionPersons;
		my $id;
		my $name;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ResearchInstitutionSourceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "institutionAddress") {
				$institutionAddress=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "institutionDepartment") {
				$institutionDepartment=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "institutionName") {
				$institutionName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "institutionPersons") {
				$institutionPersons=$textNode->getNodeValue;
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
	my $newobj = new CaCORE::Common::Provenance::ResearchInstitutionSource;
	## begin set attr ##
		$newobj->setInstitutionAddress($institutionAddress);
		$newobj->setInstitutionDepartment($institutionDepartment);
		$newobj->setInstitutionName($institutionName);
		$newobj->setInstitutionPersons($institutionPersons);
		$newobj->setId($id);
		$newobj->setName($name);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getInstitutionAddress {
	my $self = shift;
	return $self->{institutionAddress};
}

sub setInstitutionAddress {
	my $self = shift;
	$self->{institutionAddress} = shift;
}

sub getInstitutionDepartment {
	my $self = shift;
	return $self->{institutionDepartment};
}

sub setInstitutionDepartment {
	my $self = shift;
	$self->{institutionDepartment} = shift;
}

sub getInstitutionName {
	my $self = shift;
	return $self->{institutionName};
}

sub setInstitutionName {
	my $self = shift;
	$self->{institutionName} = shift;
}

sub getInstitutionPersons {
	my $self = shift;
	return $self->{institutionPersons};
}

sub setInstitutionPersons {
	my $self = shift;
	$self->{institutionPersons} = shift;
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

## end bean association methods ##

1;
#end
# ------------------------------------------------------------------------------------------
package CaCORE::Common::Provenance::Provenance;

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

# create an instance of the Provenance object
# returns: a Provenance object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new Provenance\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this Provenance intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":Provenance\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.provenance.common.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# evidenceCode;
	if( defined( $self->getEvidenceCode ) ) {
		$tmpstr = "<evidenceCode xsi:type=\"xsd:string\">" . $self->getEvidenceCode . "</evidenceCode>";
	} else {
		$tmpstr = "<evidenceCode xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# fullyQualifiedClassName;
	if( defined( $self->getFullyQualifiedClassName ) ) {
		$tmpstr = "<fullyQualifiedClassName xsi:type=\"xsd:string\">" . $self->getFullyQualifiedClassName . "</fullyQualifiedClassName>";
	} else {
		$tmpstr = "<fullyQualifiedClassName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# immediateSourceId;
	if( defined( $self->getImmediateSourceId ) ) {
		$tmpstr = "<immediateSourceId xsi:type=\"xsd:long\">" . $self->getImmediateSourceId . "</immediateSourceId>";
	} else {
		$tmpstr = "<immediateSourceId xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# objectIdentifier;
	if( defined( $self->getObjectIdentifier ) ) {
		$tmpstr = "<objectIdentifier xsi:type=\"xsd:string\">" . $self->getObjectIdentifier . "</objectIdentifier>";
	} else {
		$tmpstr = "<objectIdentifier xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# originalSourceId;
	if( defined( $self->getOriginalSourceId ) ) {
		$tmpstr = "<originalSourceId xsi:type=\"xsd:long\">" . $self->getOriginalSourceId . "</originalSourceId>";
	} else {
		$tmpstr = "<originalSourceId xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# supplyingSourceId;
	if( defined( $self->getSupplyingSourceId ) ) {
		$tmpstr = "<supplyingSourceId xsi:type=\"xsd:long\">" . $self->getSupplyingSourceId . "</supplyingSourceId>";
	} else {
		$tmpstr = "<supplyingSourceId xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# transformation;
	if( defined( $self->getTransformation ) ) {
		$tmpstr = "<transformation xsi:type=\"xsd:string\">" . $self->getTransformation . "</transformation>";
	} else {
		$tmpstr = "<transformation xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	## end attribute to XML ##
	
	## begin association to XML ##
	## end association to XML ##
	
	# add trailing close tags
	$result .= "</multiRef>";
	
	return ($result, $current_id, %worklist);
}

# parse a given webservice response xml, construct a list of Provenance objects
# param: xml doc
# returns: list of Provenance objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of Provenance objects
# param: xml node
# returns: a list of Provenance objects
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

# parse a given xml node, construct one Provenance object
# param: xml node
# returns: one Provenance object
sub fromWSXMLNode {
	my $ProvenanceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $evidenceCode;
		my $fullyQualifiedClassName;
		my $id;
		my $immediateSourceId;
		my $objectIdentifier;
		my $originalSourceId;
		my $supplyingSourceId;
		my $transformation;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($ProvenanceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "evidenceCode") {
				$evidenceCode=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "fullyQualifiedClassName") {
				$fullyQualifiedClassName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "immediateSourceId") {
				$immediateSourceId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "objectIdentifier") {
				$objectIdentifier=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "originalSourceId") {
				$originalSourceId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "supplyingSourceId") {
				$supplyingSourceId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "transformation") {
				$transformation=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::Common::Provenance::Provenance;
	## begin set attr ##
		$newobj->setEvidenceCode($evidenceCode);
		$newobj->setFullyQualifiedClassName($fullyQualifiedClassName);
		$newobj->setId($id);
		$newobj->setImmediateSourceId($immediateSourceId);
		$newobj->setObjectIdentifier($objectIdentifier);
		$newobj->setOriginalSourceId($originalSourceId);
		$newobj->setSupplyingSourceId($supplyingSourceId);
		$newobj->setTransformation($transformation);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getEvidenceCode {
	my $self = shift;
	return $self->{evidenceCode};
}

sub setEvidenceCode {
	my $self = shift;
	$self->{evidenceCode} = shift;
}

sub getFullyQualifiedClassName {
	my $self = shift;
	return $self->{fullyQualifiedClassName};
}

sub setFullyQualifiedClassName {
	my $self = shift;
	$self->{fullyQualifiedClassName} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getImmediateSourceId {
	my $self = shift;
	return $self->{immediateSourceId};
}

sub setImmediateSourceId {
	my $self = shift;
	$self->{immediateSourceId} = shift;
}

sub getObjectIdentifier {
	my $self = shift;
	return $self->{objectIdentifier};
}

sub setObjectIdentifier {
	my $self = shift;
	$self->{objectIdentifier} = shift;
}

sub getOriginalSourceId {
	my $self = shift;
	return $self->{originalSourceId};
}

sub setOriginalSourceId {
	my $self = shift;
	$self->{originalSourceId} = shift;
}

sub getSupplyingSourceId {
	my $self = shift;
	return $self->{supplyingSourceId};
}

sub setSupplyingSourceId {
	my $self = shift;
	$self->{supplyingSourceId} = shift;
}

sub getTransformation {
	my $self = shift;
	return $self->{transformation};
}

sub setTransformation {
	my $self = shift;
	$self->{transformation} = shift;
}

## end getters and setters ##

## begin bean association methods ##

sub getImmediateSource {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::Provenance::Source", $self);
	return $results[0];
}

sub getOriginalSource {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::Provenance::Source", $self);
	return $results[0];
}

sub getSourceReference {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::Provenance::SourceReference", $self);
	return $results[0];
}

sub getSupplyingSource {
	my $self = shift;
	my $appSvc = CaCORE::ApplicationService->instance();
	my @results = $appSvc->queryObject("CaCORE::Common::Provenance::Source", $self);
	return $results[0];
}

## end bean association methods ##

1;
#end
# Below is module documentation for InternetSource

=pod

=head1 InternetSource

CaCORE::Common::Provenance::InternetSource - Perl extension for InternetSource.

=head2 ABSTRACT

The CaCORE::Common::Provenance::InternetSource is a Perl object representation of the
CaCORE InternetSource object.

InternetSource extends from domain object L<"Source">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of InternetSource

The following are all the attributes of the InternetSource object and their data types:

=over 4

=item ownerInstitution

data type: C<string>

=item ownerPersons

data type: C<string>

=item sourceURI

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of InternetSource

The following are all the objects that are associated with the InternetSource:

=over 4


=back

=cut

# Below is module documentation for Provenance

=pod

=head1 Provenance

CaCORE::Common::Provenance::Provenance - Perl extension for Provenance.

=head2 ABSTRACT

The CaCORE::Common::Provenance::Provenance is a Perl object representation of the
CaCORE Provenance object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Provenance

The following are all the attributes of the Provenance object and their data types:

=over 4

=item evidenceCode

data type: C<string>

=item fullyQualifiedClassName

data type: C<string>

=item id

data type: C<long>

=item immediateSourceId

data type: C<long>

=item objectIdentifier

data type: C<string>

=item originalSourceId

data type: C<long>

=item supplyingSourceId

data type: C<long>

=item transformation

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of Provenance

The following are all the objects that are associated with the Provenance:

=over 4

=item Collection of L</ImmediateSource>:

Many to one assoication, use C<getImmediateSource> to get the associated ImmediateSource.

=item Collection of L</OriginalSource>:

Many to one assoication, use C<getOriginalSource> to get the associated OriginalSource.

=item Collection of L</SourceReference>:

Many to one assoication, use C<getSourceReference> to get the associated SourceReference.

=item Collection of L</SupplyingSource>:

Many to one assoication, use C<getSupplyingSource> to get the associated SupplyingSource.


=back

=cut

# Below is module documentation for PublicationSource

=pod

=head1 PublicationSource

CaCORE::Common::Provenance::PublicationSource - Perl extension for PublicationSource.

=head2 ABSTRACT

The CaCORE::Common::Provenance::PublicationSource is a Perl object representation of the
CaCORE PublicationSource object.

PublicationSource extends from domain object L<"Source">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of PublicationSource

The following are all the attributes of the PublicationSource object and their data types:

=over 4

=item authors

data type: C<string>

=item endPage

data type: C<int>

=item startPage

data type: C<int>

=item title

data type: C<string>

=item volume

data type: C<int>

=item year

data type: C<int>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of PublicationSource

The following are all the objects that are associated with the PublicationSource:

=over 4


=back

=cut

# Below is module documentation for ResearchInstitutionSource

=pod

=head1 ResearchInstitutionSource

CaCORE::Common::Provenance::ResearchInstitutionSource - Perl extension for ResearchInstitutionSource.

=head2 ABSTRACT

The CaCORE::Common::Provenance::ResearchInstitutionSource is a Perl object representation of the
CaCORE ResearchInstitutionSource object.

ResearchInstitutionSource extends from domain object L<"Source">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of ResearchInstitutionSource

The following are all the attributes of the ResearchInstitutionSource object and their data types:

=over 4

=item institutionAddress

data type: C<string>

=item institutionDepartment

data type: C<string>

=item institutionName

data type: C<string>

=item institutionPersons

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of ResearchInstitutionSource

The following are all the objects that are associated with the ResearchInstitutionSource:

=over 4


=back

=cut

# Below is module documentation for Source

=pod

=head1 Source

CaCORE::Common::Provenance::Source - Perl extension for Source.

=head2 ABSTRACT

The CaCORE::Common::Provenance::Source is a Perl object representation of the
CaCORE Source object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of Source

The following are all the attributes of the Source object and their data types:

=over 4

=item id

data type: C<long>

=item name

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

# Below is module documentation for SourceReference

=pod

=head1 SourceReference

CaCORE::Common::Provenance::SourceReference - Perl extension for SourceReference.

=head2 ABSTRACT

The CaCORE::Common::Provenance::SourceReference is a Perl object representation of the
CaCORE SourceReference object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of SourceReference

The following are all the attributes of the SourceReference object and their data types:

=over 4

=item id

data type: C<long>

=item reference

data type: C<string>

=item sourceReferenceType

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of SourceReference

The following are all the objects that are associated with the SourceReference:

=over 4

=item Instance of L</Provenance>:

One to many assoication, use C<getProvenanceCollection> to get a collection of associated Provenance.


=back

=cut

# Below is module documentation for URLSourceReference

=pod

=head1 URLSourceReference

CaCORE::Common::Provenance::URLSourceReference - Perl extension for URLSourceReference.

=head2 ABSTRACT

The CaCORE::Common::Provenance::URLSourceReference is a Perl object representation of the
CaCORE URLSourceReference object.

URLSourceReference extends from domain object L<"SourceReference">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of URLSourceReference

The following are all the attributes of the URLSourceReference object and their data types:

=over 4

=item sourceURL

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of URLSourceReference

The following are all the objects that are associated with the URLSourceReference:

=over 4


=back

=cut

# Below is module documentation for WebServicesSourceReference

=pod

=head1 WebServicesSourceReference

CaCORE::Common::Provenance::WebServicesSourceReference - Perl extension for WebServicesSourceReference.

=head2 ABSTRACT

The CaCORE::Common::Provenance::WebServicesSourceReference is a Perl object representation of the
CaCORE WebServicesSourceReference object.

WebServicesSourceReference extends from domain object L<"SourceReference">.

=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of WebServicesSourceReference

The following are all the attributes of the WebServicesSourceReference object and their data types:

=over 4

=item request

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of WebServicesSourceReference

The following are all the objects that are associated with the WebServicesSourceReference:

=over 4


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


