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

package Amazon::SQS::Model::ChangeMessageVisibilityBatchResult;

use base qw (Amazon::SQS::Model);

#
# Amazon::SQS::Model::ChangeMessageVisibilityBatchResult
# 
# Properties:
#
# ChangeMessageVisibilityBatchResultEntry => ["Amazon::SQS::Model::ChangeMessageVisibilityBatchResultEntry"]

sub new {
  my ($class, $data) = @_;
  my $self = {};
  
  $self->{_fields} = {
		      ChangeMessageVisibilityBatchResultEntry => {
								  FieldValue => [],
								  FieldType   => ["Amazon::SQS::Model::ChangeMessageVisibilityBatchResultEntry"]},
		     };
  
  bless ($self, $class);
  if (defined $data) {
    $self->_fromHashRef($data); 
  }
        
  return $self;
}

sub getChangeMessageVisibilityBatchResultEntry {
  return shift->{_fields}->{ChangeMessageVisibilityBatchResultEntry}->{FieldValue};
}

sub setChangeMessageVisibilityBatchResultEntry {
  my $self = shift;
  foreach my $message (@_) {
    if (not $self->_isArrayRef($message)) {
      $message =  [$message];    
    }
    $self->{_fields}->{ChangeMessageVisibilityBatchResultEntry}->{FieldValue} = $message;
  }
}

sub withChangeMessageVisibilityBatchResultEntry {
  my ($self, $messageArgs) = @_;
  foreach my $message (@$messageArgs) {
    $self->{_fields}->{ChangeMessageVisibilityBatchResultEntry}->{FieldValue} = $message;
  }
  return $self;
}   

sub isSetChangeMessageVisibilityBatchResultEntry {
  return  scalar (@{shift->{_fields}->{ChangeMessageVisibilityBatchResultEntry}->{FieldValue}}) > 0;
}

1;
