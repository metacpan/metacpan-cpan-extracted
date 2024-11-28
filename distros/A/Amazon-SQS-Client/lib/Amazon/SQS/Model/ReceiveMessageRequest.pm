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
#  Note: The software contained in this file has been modified from the
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

package Amazon::SQS::Model::ReceiveMessageRequest;

use strict;
use warnings;

use parent qw (Amazon::SQS::Model);

#
# Amazon::SQS::Model::ReceiveMessageRequest
#
# Properties:
#
#
# QueueUrl: string
# MaxNumberOfMessages: int
# WaitTimeSeconds: int
# VisibilityTimeout: int
# AttributeName: string
# MessageAttributeName: ["string"]
# ReceiveRequestAttemptId: "string"
#
#

sub new {
  my ( $class, $data ) = @_;

  my %fields = (
    _fields => {
      QueueUrl                => { FieldValue => undef, FieldType => 'string' },
      MaxNumberOfMessages     => { FieldValue => undef, FieldType => 'int' },
      WaitTimeSeconds         => { FieldValue => undef, FieldType => 'int' },
      VisibilityTimeout       => { FieldValue => undef, FieldType => 'int' },
      AttributeName           => { FieldValue => [],    FieldType => ['string'] },
      MessageAttributeName    => { FieldValue => [],    FieldType => ['string'] },
      ReceiveRequestAttemptId => { FieldValue => undef, FieldType => 'string' },
    }
  );

  my $self = bless \%fields, $class;

  if ( defined $data ) {
    $self->_fromHashRef($data);
  }

  return $self;
}

sub getWaitTimeSeconds {
  my ($self) = @_;

  return $self->{_fields}->{WaitTimeSeconds}->{FieldValue};
}

sub setWaitTimeSeconds {
  my ( $self, $value ) = @_;

  $self->{_fields}->{WaitTimeSeconds}->{FieldValue} = $value;
  return $self;
}

sub withWaitTimeSeconds {
  my ( $self, $value ) = @_;
  $self->setWaitTimeSeconds($value);
  return $self;
}

sub isSetWaitTimeSeconds {
  return defined( shift->{_fields}->{WaitTimeSeconds}->{FieldValue} );
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

sub getReceiveRequestAttemptId {
  return shift->{_fields}->{ReceiveRequestAttemptId}->{FieldValue};
}

sub setReceiveRequestAttemptId {
  my ( $self, $value ) = @_;

  $self->{_fields}->{ReceiveRequestAttemptId}->{FieldValue} = $value;
  return $self;
}

sub withReceiveRequestAttemptId {
  my ( $self, $value ) = @_;
  $self->setReceiveRequestAttemptId($value);
  return $self;
}

sub isSetReceiveRequestAttemptId {
  return defined( shift->{_fields}->{ReceiveRequestAttemptId}->{FieldValue} );
}

sub getMaxNumberOfMessages {
  return shift->{_fields}->{MaxNumberOfMessages}->{FieldValue};
}

sub setMaxNumberOfMessages {
  my ( $self, $value ) = @_;

  $self->{_fields}->{MaxNumberOfMessages}->{FieldValue} = $value;
  return $self;
}

sub withMaxNumberOfMessages {
  my ( $self, $value ) = @_;
  $self->setMaxNumberOfMessages($value);
  return $self;
}

sub isSetMaxNumberOfMessages {
  return defined( shift->{_fields}->{MaxNumberOfMessages}->{FieldValue} );
}

sub getVisibilityTimeout {
  return shift->{_fields}->{VisibilityTimeout}->{FieldValue};
}

sub setVisibilityTimeout {
  my ( $self, $value ) = @_;

  $self->{_fields}->{VisibilityTimeout}->{FieldValue} = $value;
  return $self;
}

sub withVisibilityTimeout {
  my ( $self, $value ) = @_;
  $self->setVisibilityTimeout($value);
  return $self;
}

sub isSetVisibilityTimeout {
  return defined( shift->{_fields}->{VisibilityTimeout}->{FieldValue} );
}

sub getAttributeName {
  return shift->{_fields}->{AttributeName}->{FieldValue};
}

sub setAttributeName {
  my ( $self, $value ) = @_;
  $self->{_fields}->{AttributeName}->{FieldValue} = $value;
  return $self;
}

sub withAttributeName {
  my ( $self, @attributes ) = @_;

  my $list = $self->{_fields}->{AttributeName}->{FieldValue};

  push @{$list}, @attributes;

  return $self;
}

sub isSetAttributeName {
  my ($self) = @_;

  return @{ $self->{_fields}->{AttributeName}->{FieldValue} } > 0;
}

sub getMessageAttributeName {
  return shift->{_fields}->{MessageAttributeName}->{FieldValue};
}

sub setMessageAttributeName {
  my ( $self, $value ) = @_;
  $self->{_fields}->{MessageAttributeName}->{FieldValue} = $value;
  return $self;
}

sub withMessageAttributeName {
  my ( $self, @attributes ) = @_;

  my $list = $self->{_fields}->{MessageAttributeName}->{FieldValue};

  push @{$list}, @attributes;

  return $self;
}

sub isSetMessageAttributeName {
  my ($self) = @_;

  return @{ $self->{_fields}->{MessageAttributeName}->{FieldValue} } > 0;
}

1;

__END__
