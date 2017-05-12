# ------------------------------------------------------------------------------------------
package CaCORE::Common::DatabaseCrossReference;

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

# create an instance of the DatabaseCrossReference object
# returns: a DatabaseCrossReference object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	#print "new DatabaseCrossReference\n";
	return $self;
}

# Construct the specific section of the WSDL request corresponding
# to this DatabaseCrossReference intance
# returns: XML in string format
sub toWebserviceXML {
	my $self = shift;
	my $result = shift;
	my $assigned_id = shift;
	my $current_id = shift;
	my $l = shift;
	my %worklist = %$l;
	
	# prefix portion of the xml
	$result .= "<multiRef id=\"id" . $assigned_id ."\" soapenc:root=\"0\" soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xsi:type=\"ns" . $current_id . ":DatabaseCrossReference\" xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:ns" . $current_id . "=\"urn:ws.domain.common.nci.nih.gov\">";
	my $tmpstr = "";
	$current_id ++;
	
	## begin attribute to XML ##
	# crossReferenceId;
	if( defined( $self->getCrossReferenceId ) ) {
		$tmpstr = "<crossReferenceId xsi:type=\"xsd:string\">" . $self->getCrossReferenceId . "</crossReferenceId>";
	} else {
		$tmpstr = "<crossReferenceId xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# dataSourceName;
	if( defined( $self->getDataSourceName ) ) {
		$tmpstr = "<dataSourceName xsi:type=\"xsd:string\">" . $self->getDataSourceName . "</dataSourceName>";
	} else {
		$tmpstr = "<dataSourceName xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# id;
	if( defined( $self->getId ) ) {
		$tmpstr = "<id xsi:type=\"xsd:long\">" . $self->getId . "</id>";
	} else {
		$tmpstr = "<id xsi:type=\"xsd:long\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# sourceType;
	if( defined( $self->getSourceType ) ) {
		$tmpstr = "<sourceType xsi:type=\"xsd:string\">" . $self->getSourceType . "</sourceType>";
	} else {
		$tmpstr = "<sourceType xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
	}
	$result .= $tmpstr;

	# summary;
	if( defined( $self->getSummary ) ) {
		$tmpstr = "<summary xsi:type=\"xsd:string\">" . $self->getSummary . "</summary>";
	} else {
		$tmpstr = "<summary xsi:type=\"xsd:string\" xsi:nil=\"true\" />";
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

# parse a given webservice response xml, construct a list of DatabaseCrossReference objects
# param: xml doc
# returns: list of DatabaseCrossReference objects
sub fromWebserviceXML {
	my $self = shift;
	my $parser = new XML::DOM::Parser;
	my $docnode = $parser->parse(shift);
	my $root = $docnode->getFirstChild->getFirstChild->getFirstChild->getFirstChild;
	
	return $self->fromWSXMLListNode($root);
}

# parse a given xml node, construct a list of DatabaseCrossReference objects
# param: xml node
# returns: a list of DatabaseCrossReference objects
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

# parse a given xml node, construct one DatabaseCrossReference object
# param: xml node
# returns: one DatabaseCrossReference object
sub fromWSXMLNode {
	my $DatabaseCrossReferenceNode = $_[1];
	
	## begin ELEMENT_NODE children ##
		my $crossReferenceId;
		my $dataSourceName;
		my $id;
		my $sourceType;
		my $summary;
		my $type;
	## end ELEMENT_NODE children ##

	# get all children for this node
	for my $childrenNode ($DatabaseCrossReferenceNode->getChildNodes) {
	    if ($childrenNode->getNodeType == XML::DOM::ELEMENT_NODE()) {
		if( ! defined($childrenNode->getFirstChild) ){ next; };
		my $textNode = $childrenNode->getFirstChild;
		## begin iterate ELEMENT_NODE ##
		if (0) {
			# do nothing, just a place holder for "if" component
		}
			elsif ($childrenNode->getNodeName eq "crossReferenceId") {
				$crossReferenceId=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "dataSourceName") {
				$dataSourceName=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "id") {
				$id=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "sourceType") {
				$sourceType=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "summary") {
				$summary=$textNode->getNodeValue;
			}
			elsif ($childrenNode->getNodeName eq "type") {
				$type=$textNode->getNodeValue;
			}
		## end iterate ELEMENT_NODE ##
	    }
	}
	my $newobj = new CaCORE::Common::DatabaseCrossReference;
	## begin set attr ##
		$newobj->setCrossReferenceId($crossReferenceId);
		$newobj->setDataSourceName($dataSourceName);
		$newobj->setId($id);
		$newobj->setSourceType($sourceType);
		$newobj->setSummary($summary);
		$newobj->setType($type);
	## end set attr ##
	
	return $newobj;
}

## begin getters and setters ##

sub getCrossReferenceId {
	my $self = shift;
	return $self->{crossReferenceId};
}

sub setCrossReferenceId {
	my $self = shift;
	$self->{crossReferenceId} = shift;
}

sub getDataSourceName {
	my $self = shift;
	return $self->{dataSourceName};
}

sub setDataSourceName {
	my $self = shift;
	$self->{dataSourceName} = shift;
}

sub getId {
	my $self = shift;
	return $self->{id};
}

sub setId {
	my $self = shift;
	$self->{id} = shift;
}

sub getSourceType {
	my $self = shift;
	return $self->{sourceType};
}

sub setSourceType {
	my $self = shift;
	$self->{sourceType} = shift;
}

sub getSummary {
	my $self = shift;
	return $self->{summary};
}

sub setSummary {
	my $self = shift;
	$self->{summary} = shift;
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
# Below is module documentation for DatabaseCrossReference

=pod

=head1 DatabaseCrossReference

CaCORE::Common::DatabaseCrossReference - Perl extension for DatabaseCrossReference.

=head2 ABSTRACT

The CaCORE::Common::DatabaseCrossReference is a Perl object representation of the
CaCORE DatabaseCrossReference object.


=head2 SYNOPSIS

See L<CaCORE::ApplicationService>.

=head2 DESCRIPTION



=head2 ATTRIBUTES of DatabaseCrossReference

The following are all the attributes of the DatabaseCrossReference object and their data types:

=over 4

=item crossReferenceId

data type: C<string>

=item dataSourceName

data type: C<string>

=item id

data type: C<long>

=item sourceType

data type: C<string>

=item summary

data type: C<string>

=item type

data type: C<string>


=back

Note: Although you can also use the corresponding setter methods to set the
attribute values, it is not recommended to do so unless you absolutely have
to change the object's attributes.

=head2 ASSOCIATIONS of DatabaseCrossReference

The following are all the objects that are associated with the DatabaseCrossReference:

=over 4

=item Collection of L</SNP>:

Many to one assoication, use C<getSNP> to get the associated SNP.

=item Collection of L</Gene>:

Many to one assoication, use C<getGene> to get the associated Gene.

=item Collection of L</NucleicAcidSequence>:

Many to one assoication, use C<getNucleicAcidSequence> to get the associated NucleicAcidSequence.


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


