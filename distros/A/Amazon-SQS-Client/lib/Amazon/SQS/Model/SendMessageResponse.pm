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

package Amazon::SQS::Model::SendMessageResponse;

use strict;
use warnings;

use XML::Simple;
use Amazon::SQS::Constants qw(:all);

use parent qw (Amazon::SQS::Model);

#
# Amazon::SQS::Model::SendMessageResponse
#
# Properties:
#
#
# SendMessageResult: Amazon::SQS::Model::SendMessageResult
# ResponseMetadata: Amazon::SQS::Model::ResponseMetadata
#
#
#
sub new {
  my ( $class, $data ) = @_;
  my $self = {};

  $self->{_fields} = {

    SendMessageResult => { FieldValue => undef, FieldType => 'Amazon::SQS::Model::SendMessageResult' },
    ResponseMetadata  => { FieldValue => undef, FieldType => 'Amazon::SQS::Model::ResponseMetadata' },
  };

  bless $self, $class;

  if ( defined $data ) {
    $self->_fromHashRef($data);
  }

  return $self;
}

#
# Construct Amazon::SQS::Model::SendMessageResponse from XML string
#
sub fromXML {
  my ( $self, $xml ) = @_;

  my $tree = XML::Simple::XMLin($xml);

  return Amazon::SQS::Model::SendMessageResponse->new($tree);
}

sub getSendMessageResult {
  return shift->{_fields}->{SendMessageResult}->{FieldValue};
}

sub setSendMessageResult {
  my ( $self, $value ) = @_;
  return $self->{_fields}->{SendMessageResult}->{FieldValue} = $value;
}

sub withSendMessageResult {
  my ( $self, $value ) = @_;
  $self->setSendMessageResult($value);
  return $self;
}

sub isSetSendMessageResult {
  return defined( shift->{_fields}->{SendMessageResult}->{FieldValue} );

}

sub getResponseMetadata {
  return shift->{_fields}->{ResponseMetadata}->{FieldValue};
}

sub setResponseMetadata {
  my ( $self, $value ) = @_;
  $self->{_fields}->{ResponseMetadata}->{FieldValue} = $value;
}

sub withResponseMetadata {
  my ( $self, $value ) = @_;
  $self->setResponseMetadata($value);
  return $self;
}

sub isSetResponseMetadata {
  return defined( shift->{_fields}->{ResponseMetadata}->{FieldValue} );

}

#
# XML Representation for this object
#
# Returns string XML for this object
#
sub toXML {
  my ($self) = @_;

  my $xml = $EMPTY;
  $xml .= q{<SendMessageResponse xmlns="http://queue.amazonaws.com/doc/2009-02-01/">};
  $xml .= $self->_toXMLFragment();
  $xml .= '</SendMessageResponse>';

  return $xml;
}

1;
