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

package Amazon::SQS::Model::DeleteMessageBatchRequestEntry;

use base qw (Amazon::SQS::Model);

=pod

=head1 NAME

 Amazon::SQS::Model::DeleteMessageBatchRequestEntry

=head1 SYNOPSIS

 my $attribute = new Amazon::SQS::Model::DeleteMessageBatchRequestEntry( 
                                                   { 
                                                    Id => id,
                                                    ReceiptHandle => receiptHandle
                                                   }

=cut

sub new {
  my ($class, $data) = @_;
  my $self = {};
  $self->{_fields} = {
		      Id => { FieldValue => undef, FieldType => "string"},
		      ReceiptHandle => { FieldValue => undef, FieldType => "string" }
        };
  
  bless ($self, $class);
  
  if (defined $data) {
    $self->_fromHashRef($data); 
  }
  
  return $self;
}

sub getId {
  return shift->{_fields}->{Id}->{FieldValue};
}


sub setId {
  my ($self, $value) = @_;

  $self->{_fields}->{Id}->{FieldValue} = $value;
  return $self;
}


sub withId {
  my ($self, $value) = @_;
  $self->setId($value);
  return $self;
}


sub isSetId {
  return defined (shift->{_fields}->{Id}->{FieldValue});
}



sub getReceiptHandle {
  return shift->{_fields}->{ReceiptHandle}->{FieldValue};
}


sub setReceiptHandle {
  my ($self, $value) = @_;

  $self->{_fields}->{ReceiptHandle}->{FieldValue} = $value;
  return $self;
}

sub withReceiptHandle {
  my ($self, $value) = @_;
  $self->setReceiptHandle($value);
  return $self;
}

sub isSetReceiptHandle {
  return defined (shift->{_fields}->{ReceiptHandle}->{FieldValue});
}


=pod

=head1 SEE OTHER

C<Amazon::SQS::Client>

=head1 AUTHOR

Elena@AWS

=cut


1;
