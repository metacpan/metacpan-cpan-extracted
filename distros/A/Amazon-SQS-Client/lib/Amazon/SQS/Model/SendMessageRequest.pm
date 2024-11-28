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

package Amazon::SQS::Model::SendMessageRequest;

use strict;
use warnings;

use parent qw(Amazon::SQS::Model);

#
# Amazon::SQS::Model::SendMessageRequest
#
# Properties:
#
#
# QueueUrl: string
# MessageBody: string
# DelaySeconds: int
# MessageDuplicationId: string
# MessageGroupId: string
# MessageAttribute: Amazon::SQS::Model::MessageAttribute
#
#
sub new {
  my ( $class, $data ) = @_;
  my $self = {};

  $self->{_fields} = {
    QueueUrl             => { FieldValue => undef, FieldType => 'string' },
    MessageBody          => { FieldValue => undef, FieldType => 'string' },
    DelaySeconds         => { FieldValue => undef, FieldType => 'int' },
    MessageDuplicationId => { FieldValue => undef, FieldType => 'string' },
    MessageGroupId       => { FieldValue => undef, FieldType => 'string' },
    MessageAttribute     => { FieldValue => [],    FieldType => ['Amazon::SQS::Model::MessageAttribute'] },
  };

  bless $self, $class;
  if ( defined $data ) {
    $self->_fromHashRef($data);
  }

  return $self;
}

sub getQueueUrl {
  return shift->{_fields}->{QueueUrl}->{FieldValue};
}

sub setQueueUrl {
  my ( $self, $value ) = @_;

  $self->{_fields}->{QueueUrl}->{FieldValue} = $value;
  return $self;
}

sub withQueueUrl {
  my ( $self, $value ) = @_;
  $self->setQueueUrl($value);
  return $self;
}

sub isSetQueueUrl {
  return defined( shift->{_fields}->{QueueUrl}->{FieldValue} );
}

sub getDelaySeconds {
  return shift->{_fields}->{DelaySeconds}->{FieldValue};
}

sub setDelaySeconds {
  my ( $self, $value ) = @_;

  $self->{_fields}->{DelaySeconds}->{FieldValue} = $value;
  return $self;
}

sub withDelaySeconds {
  my ( $self, $value ) = @_;
  $self->setDelaySeconds($value);
  return $self;
}

sub isSetDelaySeconds {
  return defined( shift->{_fields}->{DelaySeconds}->{FieldValue} );
}

sub getMessageDuplicationId {
  return shift->{_fields}->{MessageDuplicationId}->{FieldValue};
}

sub setMessageDuplicationId {
  my ( $self, $value ) = @_;

  $self->{_fields}->{MessageDuplicationId}->{FieldValue} = $value;
  return $self;
}

sub withMessageDuplicationId {
  my ( $self, $value ) = @_;
  $self->setMessageDuplicationId($value);
  return $self;
}

sub isSetMessageDuplicationId {
  return defined( shift->{_fields}->{MessageDuplicationId}->{FieldValue} );
}

sub getMessageGroupId {
  return shift->{_fields}->{MessageGroupId}->{FieldValue};
}

sub setMessageGroupId {
  my ( $self, $value ) = @_;

  $self->{_fields}->{MessageGroupId}->{FieldValue} = $value;
  return $self;
}

sub withMessageGroupId {
  my ( $self, $value ) = @_;
  $self->setMessageGroupId($value);
  return $self;
}

sub isSetMessageGroupId {
  return defined( shift->{_fields}->{MessageGroupId}->{FieldValue} );
}

sub getMessageBody {
  return shift->{_fields}->{MessageBody}->{FieldValue};
}

sub setMessageBody {
  my ( $self, $value ) = @_;

  $self->{_fields}->{MessageBody}->{FieldValue} = $value;
  return $self;
}

sub withMessageBody {
  my ( $self, $value ) = @_;
  $self->setMessageBody($value);
  return $self;
}

sub isSetMessageBody {
  return defined( shift->{_fields}->{MessageBody}->{FieldValue} );
}

sub getMessageAttribute {
  return shift->{_fields}->{MessageAttribute}->{FieldValue};
}

sub setMessageAttribute {
  my ( $self, @args ) = @_;

  foreach my $attribute (@args) {
    if ( not $self->_isArrayRef($attribute) ) {
      $attribute = [$attribute];
    }

    $self->{_fields}->{MessageAttribute}->{FieldValue} = $attribute;
  }

  return;
}

sub withMessageAttribute {
  my ( $self, $attributeArgs ) = @_;

  foreach my $attribute ( @{$attributeArgs} ) {
    $self->{_fields}->{MessageAttribute}->{FieldValue} = $attribute;
  }
  return $self;
}

sub isSetMessageAttribute {
  return scalar( @{ shift->{_fields}->{MessageAttribute}->{FieldValue} } ) > 0;
}

1;

__END__
