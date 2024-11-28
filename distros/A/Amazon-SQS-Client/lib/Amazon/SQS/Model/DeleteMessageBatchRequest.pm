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

package Amazon::SQS::Model::DeleteMessageBatchRequest;

use base qw (Amazon::SQS::Model);

#
# Amazon::SQS::Model::DeleteMessageBatchRequest
# 
# Properties:
#
# 
# QueueUrl: string
# DeleteMessageBatchRequestEntry: Amazon::SQS::Model::DeleteMessageBatchRequestEntry
#
# 
# 
sub new {
  my ($class, $data) = @_;
  my $self = {};
  $self->{_fields} = {
		      QueueUrl => { FieldValue => undef, FieldType => "string"},
		      DeleteMessageBatchRequestEntry => { FieldValue => [], FieldType => ["Amazon::SQS::Model::DeleteMessageBatchRequestEntry"]}
		     };
  
  bless ($self, $class);
  if (defined $data) {
    $self->_fromHashRef($data); 
  }
  
  return $self;
}
    

sub getQueueUrl {
  return shift->{_fields}->{QueueUrl}->{FieldValue};
}


sub setQueueUrl {
  my ($self, $value) = @_;

  $self->{_fields}->{QueueUrl}->{FieldValue} = $value;
  return $self;
}


sub withQueueUrl {
  my ($self, $value) = @_;
  $self->setQueueUrl($value);
  return $self;
}


sub isSetQueueUrl {
  return defined (shift->{_fields}->{QueueUrl}->{FieldValue});
}

sub getDeleteMessageBatchRequestEntry {
  return shift->{_fields}->{DeleteMessageBatchRequestEntry}->{FieldValue};
}

sub setDeleteMessageBatchRequestEntry {
  my $self = shift;
  foreach my $attribute (@_) {
    if (not $self->_isArrayRef($attribute)) {
      $attribute =  [$attribute];    
    }
    $self->{_fields}->{DeleteMessageBatchRequestEntry}->{FieldValue} = $attribute;
  }
}


sub withDeleteMessageBatchRequestEntry {
  my ($self, $attributeArgs) = @_;
  foreach my $attribute (@$attributeArgs) {
    $self->{_fields}->{DeleteMessageBatchRequestEntry}->{FieldValue} = $attribute;
  }
  return $self;
}   


sub isSetDeleteMessageBatchRequestEntry {
  return  scalar (@{shift->{_fields}->{DeleteMessageBatchRequestEntry}->{FieldValue}}) > 0;
}


1;
