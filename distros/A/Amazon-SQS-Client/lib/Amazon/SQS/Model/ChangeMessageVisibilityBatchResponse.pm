################################################################################ 
#  Copyright 2008 Amazon Technologies, Inc.
#  Licensed under the Apache License, Version 2.0 (the "License"); 
#  
#  You may not use this file except in compliance with the License. 
#  You may obtain a copy of the License at: http://aws.amazon.com/apache2.0
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
#  CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#  specific language governing permissions and limitations under the License.
#
#  Copyright 2016 Robert C. Lauer
#
#  Note: The software contained in this distribution has been modified from the
#  original. You may freely use and distribute this software under the
#  terms of the original license. 
#
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

# This work has been modified from the original Copyright 2016 Robert C. Lauer

package Amazon::SQS::Model::ChangeMessageVisibilityBatchResponse;

use base qw (Amazon::SQS::Model);
use Data::Dumper;

#
# Amazon::SQS::Model::ChangeMessageVisibilityBatchResponse
# 
# Properties:
#
# 
# ResponseMetadata: Amazon::SQS::Model::ResponseMetadata
# ChangeMessageVisibilityBatchResult: Amazon::SQS::Model::ChangeMessageVisibilityBatchResult
# 
# 
sub new {
  my ($class, $data) = @_;
  my $self = {};
  $self->{_fields} = {
		      ChangeMessageVisibilityBatchResult => {FieldValue => undef, FieldType => "Amazon::SQS::Model::ChangeMessageVisibilityBatchResult"},
		      ResponseMetadata => {FieldValue => undef, FieldType => "Amazon::SQS::Model::ResponseMetadata"},
		     };

  bless ($self, $class);
  if (defined $data) {
    $self->_fromHashRef($data); 
  }
        
  return $self;
}

       
#
# Construct Amazon::SQS::Model::ChangeMessageVisibilityBatchResponse from XML string
# 
sub fromXML {
  my ($self, $xml) = @_;
  eval "use XML::Simple";
  my $tree = XML::Simple::XMLin ($xml);
  
  # TODO: check valid XML (is this a response XML?)
  return new Amazon::SQS::Model::ChangeMessageVisibilityBatchResponse($tree);
          
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


sub getChangeMessageVisibilityBatchResult {
  return shift->{_fields}->{ChangeMessageVisibilityBatchResult}->{FieldValue};
}


sub setChangeMessageVisibilityBatchResult {
  my ($self, $value) = @_;
  $self->{_fields}->{ChangeMessageVisibilityBatchResult}->{FieldValue} = $value;
}


sub withChangeMessageVisibilityBatchResult {
  my ($self, $value) = @_;
  $self->setChangeMessageVisibilityBatchResult($value);
  return $self;
}


sub isSetChangeMessageVisibilityBatchResult {
  return defined (shift->{_fields}->{ChangeMessageVisibilityBatchResult}->{FieldValue});

}

#
# XML Representation for this object
# 
# Returns string XML for this object
#
sub toXML {
  my $self = shift;
  my $xml = "";
  $xml .= "<ChangeMessageVisibilityBatchResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\">";
  $xml .= $self->_toXMLFragment();
  $xml .= "</ChangeMessageVisibilityBatchResponse>";

  return $xml;
}

1;
