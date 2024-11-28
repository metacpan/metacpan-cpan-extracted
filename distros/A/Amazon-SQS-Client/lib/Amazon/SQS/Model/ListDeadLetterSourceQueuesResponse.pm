################################################################################ 
#  Copyright 2008 Amazon Technologies, Inc.
#  Licensed under the Apache License, Version 2.0 (the "License"); 
#  
#  You may not use this file except in compliance with the License. 
#  You may obtain a copy of the License at: http://aws.amazon.com/apache2.0
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
#  CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#  specific language governing permissions and limitations under the License.
################################################################################ 
#    __  _    _  ___ 
#   (  )( \/\/ )/ __)
#   /__\ \    / \__ \
#  (_)(_) \/\/  (___/
# 
#  Amazon SQS Perl Library
#  API Version: 2009-02-01
#  Generated: Thu Apr 09 01:13:11 PDT 2009 
# 


package Amazon::SQS::Model::ListDeadLetterSourceQueuesResponse;

use base qw (Amazon::SQS::Model);
use Data::Dumper;

=pod

=head1 NAME

C<Amazon::SQS::Model::ListQueuesResponse>

=head1 SYNOPSIS

 my $response = new Amazon::SQS::Model::ListQueuesResponse( { ListQueuesResult => $result,
                                                              ResponseMetadata => $response_metadata
                                                            }
                                                          );

=head1 DESCRIPTION

Implements a class that contains the response from a C<ListQueues> request.

=head1 METHODS

=head2 new

 new( options )

=head2 isSetListQueuesResult

Returns true if a C<Amazon::SQS::Model::ListQueuesResult> object is set in the response,
false otherwise.

=head2 isSetResponseMetadata

Returns true if a C<Amazon::SQS::Model::ResponseMetadata> object is set in the response,
false otherwise.

=head2 getListQueuesResult

Returns the C<Amazon::SQS::Model::ListQueuesResult> object.

=head2 getResponseMetadata

Returns the C<Amazon::SQS::Model::ResponseMetadata> object.

=cut

sub new {
  my ($class, $data) = @_;

  my $self = {};

  $self->{_fields} = {
		      ListDeadLetterSourceQueuesResult => { 
							   FieldValue => undef,
							   FieldType => "Amazon::SQS::Model::ListDeadLetterSourceQueuesResult"
							  },

		      ResponseMetadata => {
					   FieldValue => undef, 
					   FieldType => "Amazon::SQS::Model::ResponseMetadata"
					  },
		     };

  bless ($self, $class);

  if (defined $data) {
    $self->_fromHashRef($data); 
  }
        
  return $self;
}

       
#
# Construct Amazon::SQS::Model::ListQueuesResponse from XML string
# 
sub fromXML {
  my ($self, $xml) = @_;
  eval "use XML::Simple";
  my $tree = XML::Simple::XMLin ($xml);
         
  # TODO: check valid XML (is this a response XML?)
  print Dumper [ $tree ];
  print STDERR $xml;
  
  return new Amazon::SQS::Model::ListDeadLetterSourceQueuesResponse($tree);
          
}
    
sub getListDeadLetterSourceQueuesResult {
  return shift->{_fields}->{ListDeadLetterSourceQueuesResult}->{FieldValue};
}


sub setListDeadLetterSourceQueuesResult {
  my ($self, $value) = @_;
  $self->{_fields}->{ListDeadLetterSourceQueuesResult}->{FieldValue} = $value;
}


sub withListDeadLetterSourceQueuesResult {
  my ($self, $value) = @_;
  $self->setListDeadLetterSourceQueuesResult($value);
  return $self;
}


sub isSetListDeadLetterSourceQueuesResult {
  return defined (shift->{_fields}->{ListDeadLetterSourceQueuesResult}->{FieldValue});

}

sub getResponseMetadata {
  return shift->{_fields}->{ResponseMetadata}->{FieldValue};
}


sub setResponseMetadata {
  my ($self, $value) = @_;
  $self->{_fields}->{ResponseMetadata}->{FieldValue} = $value;
}


sub withResponseMetadata {
  my ($self, $value) = @_;
  $self->setResponseMetadata($value);
  return $self;
}


sub isSetResponseMetadata {
  return defined (shift->{_fields}->{ResponseMetadata}->{FieldValue});

}



#
# XML Representation for this object
# 
# Returns string XML for this object
#
sub toXML {
  my $self = shift;
  my $xml = "";
  $xml .= "<ListDeadLetterSourceQueuesResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\">";
  $xml .= $self->_toXMLFragment();
  $xml .= "</ListDeadLetterSourceQueuesResponse>";
  return $xml;
}

=pod

=head1 SEE OTHER

C<Amazon::SQS::Client>, C<Amazon::SQS::ListDeadLetterSourceQueuesResult>

=head1 AUTHOR

Elena@AWS

=cut

1;
