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

package Amazon::SQS::Model::Message;

use strict;
use warnings;

use base qw (Amazon::SQS::Model);

#
# Amazon::SQS::Model::Message
#
# Properties:
#
#
# MessageId: string
# ReceiptHandle: string
# MD5OfBody: string
# Body: string
# Attribute: Amazon::SQS::Model::Attribute
#
#
#
sub new {
  my ( $class, $data ) = @_;

  my $self = {};

  $self->{_fields} = {

    MessageId     => { FieldValue => undef, FieldType => 'string' },
    ReceiptHandle => { FieldValue => undef, FieldType => 'string' },
    MD5OfBody     => { FieldValue => undef, FieldType => 'string' },
    Body          => { FieldValue => undef, FieldType => 'string' },

    MessageAttribute => { FieldValue => [], FieldType => ['Amazon::SQS::Model::MessageAttribute'] },
  };

  bless $self, $class;

  if ( defined $data ) {
    $self->_fromHashRef($data);
  }

  return $self;
}

sub getMessageId {
  return shift->{_fields}->{MessageId}->{FieldValue};
}

sub setMessageId {
  my ( $self, $value ) = @_;

  $self->{_fields}->{MessageId}->{FieldValue} = $value;
  return $self;
}

sub withMessageId {
  my ( $self, $value ) = @_;
  $self->setMessageId($value);
  return $self;
}

sub isSetMessageId {
  return defined( shift->{_fields}->{MessageId}->{FieldValue} );
}

sub getReceiptHandle {
  return shift->{_fields}->{ReceiptHandle}->{FieldValue};
}

sub setReceiptHandle {
  my ( $self, $value ) = @_;

  $self->{_fields}->{ReceiptHandle}->{FieldValue} = $value;
  return $self;
}

sub withReceiptHandle {
  my ( $self, $value ) = @_;
  $self->setReceiptHandle($value);
  return $self;
}

sub isSetReceiptHandle {
  return defined( shift->{_fields}->{ReceiptHandle}->{FieldValue} );
}

sub getMD5OfBody {
  return shift->{_fields}->{MD5OfBody}->{FieldValue};
}

sub setMD5OfBody {
  my ( $self, $value ) = @_;

  $self->{_fields}->{MD5OfBody}->{FieldValue} = $value;
  return $self;
}

sub withMD5OfBody {
  my ( $self, $value ) = @_;
  $self->setMD5OfBody($value);
  return $self;
}

sub isSetMD5OfBody {
  return defined( shift->{_fields}->{MD5OfBody}->{FieldValue} );
}

sub getBody {
  return shift->{_fields}->{Body}->{FieldValue};
}

sub setBody {
  my ( $self, $value ) = @_;

  $self->{_fields}->{Body}->{FieldValue} = $value;
  return $self;
}

sub withBody {
  my ( $self, $value ) = @_;
  $self->setBody($value);
  return $self;
}

sub isSetBody {
  return defined( shift->{_fields}->{Body}->{FieldValue} );
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
