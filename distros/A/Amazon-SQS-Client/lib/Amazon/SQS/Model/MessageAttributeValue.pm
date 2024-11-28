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

package Amazon::SQS::Model::MessageAttributeValue;

use base qw (Amazon::SQS::Model);

    

#
# Amazon::SQS::Model::MessageAttributeValue
# 
# Properties:
#
# 
# BinaryValue: string
# StringValue: string
# DataType: string ('StringValue', 'BinaryValue')
# 
sub new {
  my ($class, $data) = @_;
  my $self = {};
  $self->{_fields} = {
		      BinaryValue => {FieldValue => undef, FieldType => "string"},
		      StringValue => {FieldValue => undef, FieldType => "string"},
		      DataType => { FieldValue => undef, FieldType => "string"}
		     };

  bless ($self, $class);
  if (defined $data) {
    $self->_fromHashRef($data); 
  }
  
  return $self;
}

sub getBinaryValue {
  return shift->{_fields}->{BinaryValue}->{FieldValue};
}


sub setBinaryValue {
  my ($self, $value) = @_;

  $self->{_fields}->{BinaryValue}->{FieldValue} = $value;
  return $self;
}


sub withBinaryValue {
  my ($self, $value) = @_;
  $self->setBinaryValue($value);
  return $self;
}


sub isSetBinaryValue {
  return defined (shift->{_fields}->{BinaryValue}->{FieldValue});
}


sub getStringValue {
  return shift->{_fields}->{StringValue}->{FieldValue};
}


sub setStringValue {
  my ($self, $value) = @_;

  $self->{_fields}->{StringValue}->{FieldValue} = $value;
  return $self;
}


sub withStringValue {
  my ($self, $value) = @_;
  $self->setStringValue($value);
  return $self;
}


sub isSetStringValue {
  return defined (shift->{_fields}->{StringValue}->{FieldValue});
}


sub getDataType {
  return shift->{_fields}->{DataType}->{FieldValue};
}

sub setDataType {
  my ($self, $value) = @_;

  $self->{_fields}->{DataType}->{FieldValue} = $value;
  return $self;
}


sub withDataType {
  my ($self, $value) = @_;
  $self->setDataType($value);
  return $self;
}


sub isSetDataType {
  return defined (shift->{_fields}->{DataType}->{FieldValue});
}


1;
