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
# Amazon::SQS::Model - base class for all model classes
#
package Amazon::SQS::Model;

use strict;
use warnings;

use Amazon::SQS::Constants qw(:all);
use List::Util qw(pairs);
use Module::Load qw(load);

#
# XML fragment representation of this object
# Note, name of the root determined by caller
# This fragment returns inner fields representation only
sub _toXMLFragment {
  my ($self) = @_;
  my $xml = $EMPTY;

  foreach my $p ( pairs %{ $self->{_fields} } ) {
    my ( $fieldName, $field ) = @{$p};

    my $fieldValue = $field->{FieldValue};

    if ( defined $fieldValue ) {
      my $fieldType = $field->{FieldType};

      if ( _isArrayRef($fieldType) ) {
        if ( _isComplexType( $fieldType->[0] ) ) {
          for my $item ( @{$fieldValue} ) {
            $xml .= "<$fieldName>";
            $xml .= $item->_toXMLFragment();
            $xml .= "</$fieldName>";
          }
        }
        else {
          for my $item ($fieldValue) {
            $xml .= "<$fieldName>";
            $xml .= $self->_escapeXML($item);
            $xml .= "</$fieldName>";
          }
        }
      }
      else {
        if ( _isComplexType($fieldType) ) {
          $xml .= "<$fieldName>";
          $xml .= $fieldValue->_toXMLFragment();
          $xml .= "</$fieldName>";
        }
        else {
          $xml .= "<$fieldName>";
          $xml .= $self->_escapeXML($fieldValue);
          $xml .= "</$fieldName>";
        }
      }
    }
  }

  return $xml;
}

#
# Escape special XML characters
# return string with escaped XML characters
#
sub _escapeXML {
  my ( $self, $str ) = @_;

  $str =~ s/&/&amp;/xsmg;
  $str =~ s/</&lt;/xsmg;
  $str =~ s/>/&gt;/xsmg;
  $str =~ s/'/&#039;/xsmg;
  $str =~ s/"/&quot;/xsmg;

  return $str;
}

#
# Determines if field is complex type
#
sub _isComplexType {
  my ( $self, $fieldType ) = @_;

  return $fieldType =~ m/^Amazon::SQS::Model::/xsm;
}

#
# Checks  whether passed variable is an associative array
#
sub _isHashRef {
  my ( $self, $var ) = @_;

  return ref $var eq 'HASH';
}

#
# Checks  whether passed variable is an array reference
#
sub _isArrayRef {
  my ( $self, $var ) = @_;

  return ref $var eq 'ARRAY';
}

#
# Construct from hash ref
#
sub _fromHashRef {
  my ( $self, $array ) = @_;

  foreach my $p ( pairs %{ $self->{_fields} } ) {
    my ( $fieldName, $field ) = @{$p};

    my $fieldType = $field->{FieldType};

    if ( $self->_isArrayRef($fieldType) ) {

      if ( $self->_isComplexType( $fieldType->[0] ) ) {
        my $elements = $array->{$fieldName};

        if ( !$self->_isArrayRef($elements) ) {
          $elements = defined $elements ? [$elements] : [];
        }

        if ( scalar @{$elements} >= 1 ) {
          my $package = $fieldType->[0];
          load $package;

          my $list = $self->{_fields}->{$fieldName}->{FieldValue};

          for my $element ( @{$elements} ) {
            push @{$list}, $fieldType->[0]->new($element);
          }

          $self->{_fields}->{$fieldName}->{FieldValue} = $list;
        }
      }
      else {
        my $elements = $array->{$fieldName};

        if ( !$self->_isArrayRef($elements) ) {
          $elements = defined $elements ? [$elements] : [];
        }

        if ( scalar @{$elements} >= 1 ) {
          my $list = $self->{_fields}->{$fieldName}->{FieldValue};

          for my $element ( @{$elements} ) {
            push @{$list}, $element;
          }

          $self->{_fields}->{$fieldName}->{FieldValue} = $list;
        }
      }
    }
    else {
      if ( $self->_isComplexType($fieldType) ) {
        my $element = $array->{$fieldName};

        if ( defined $element ) {
          my $package = $fieldType;
          load $package;

          $self->{_fields}->{$fieldName}->{FieldValue} = $fieldType->new($element);
        }
      }
      else {
        my $element = $array->{$fieldName};
        if ( defined $element ) {
          $self->{_fields}->{$fieldName}->{FieldValue} = $element;
        }
      }
    }
  }

  return;
}

1;
