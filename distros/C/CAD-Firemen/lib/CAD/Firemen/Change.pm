#!/usr/bin/perl
######################
#
#    Copyright (C) 2011  TU Clausthal, Institut fuer Maschinenwesen, Joachim Langenbach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################

use strict;
use warnings;

# Pod::Weaver infos
# ABSTRACT: Object to represant the changes of an option

package CAD::Firemen::Change;
{
  $CAD::Firemen::Change::VERSION = '0.7.2';
}
use Exporter 'import';

use CAD::Firemen::Common qw(strip);
use CAD::Firemen::Change::Type;

sub new {
  my ($class) = shift;
  my (%params) = @_;

  # check parameters
  if(!exists($params{"name"})){
    $params{"name"} = "";
  }
  if(!exists($params{"valueOld"})){
    $params{"valueOld"} = "";
  }
  if(!exists($params{"valueNew"})){
    $params{"valueNew"} = "";
  }

  my $self = {
    '_option' => $params{"name"},
    '_valueOld' => $params{"valueOld"},
    '_valueNew' => $params{"valueNew"},
    '_changeType' => {},
    '_changeDescription' => "",
    '_possibleValuesOld' => [],
    '_possibleValuesNew' => [],
    '_defaultValueOld' => "",
    '_defaultValueNew' => ""
  };
  bless $self, $class;
  $self->evalChange();
  return $self;
}

sub setOption {
  my $self = shift;
  my $name = shift;
  if(!defined($name)){
    return 0;
  }
  $self->{'_option'} = $name;
  return 1;
}

sub option {
  my $self = shift;
  return $self->{'_option'};
}

sub setValueOld {
  my $self = shift;
  my $value = shift;
  if(!defined($value)){
    return 0;
  }
  $self->{'_valueOld'} = $value;
  return 1;
}

sub valueOld {
  my $self = shift;
  return $self->{'_valueOld'};
}

sub setValueNew {
  my $self = shift;
  my $value = shift;
  if(!defined($value)){
    return 0;
  }
  $self->{'_valueNew'} = $value;
  return 1;
}

sub valueNew {
  my $self = shift;
  return $self->{'_valueNew'};
}

sub setPossibleValuesOld {
  my $self = shift;
  my $valuesRef = shift;
  if(!defined($valuesRef) || (ref($valuesRef) ne "ARRAY")){
    return 0;
  }
  $self->{'_possibleValuesOld'} = $valuesRef;
  return 1;
}

sub possibleValuesOld {
  my $self = shift;
  return $self->{'_possibleValuesOld'};
}

sub setPossibleValuesNew {
  my $self = shift;
  my $valuesRef = shift;
  if(!defined($valuesRef) || (ref($valuesRef) ne "ARRAY")){
    return 0;
  }
  $self->{'_possibleValuesNew'} = $valuesRef;
  return 1;
}

sub possibleValuesNew {
  my $self = shift;
  return $self->{'_possibleValuesNew'};
}


sub setDefaultValueOld {
  my $self = shift;
  my $value = shift;
  if(!defined($value)){
    return 0;
  }
  # default value must be an possible value
  my $found = 0;
  foreach my $posValue (@{$self->possibleValuesOld()}){
    if($value eq $posValue){
      $found = 1;
    }
  }
  if(!$found){
    return 0;
  }
  $self->{'_defaultValueOld'} = $value;
  return 1;
}

sub defaultValueOld {
  my $self = shift;
  return $self->{'_defaultValueOld'};
}

sub setDefaultValueNew {
  my $self = shift;
  my $value = shift;
  if(!defined($value)){
    return 0;
  }
  # default value must be an possible value
  my $found = 0;
  foreach my $posValue (@{$self->possibleValuesNew()}){
    if($value eq $posValue){
      $found = 1;
    }
  }
  if(!$found){
    return 0;
  }
  $self->{'_defaultValueNew'} = $value;
  return 1;
}

sub defaultValueNew {
  my $self = shift;
  return $self->{'_defaultValueNew'};
}

sub setChangeDescription {
  my $self = shift;
  my $value = shift;
  if(!defined($value)){
    return 0;
  }
  $self->{'_changeDescription'} = strip($value);
  return 1;
}

sub changeDescription {
  my $self = shift;
  return $self->{'_changeDescription'};
}

sub evalChange {
  my $self = shift;

  # reset change type
  $self->_setChangeType(CAD::Firemen::Change::Type->NoChange);

  # determine whether values or default values have changed
  my $valuesChanged = 0;
  my $defaultChanged = 0;
  # check for removed options
  foreach my $value (@{$self->possibleValuesOld()}){
    my $exist = 0;
    foreach my $newValue (@{$self->possibleValuesNew()}){
      if($value eq $newValue){
        $exist = 1;
        last;
      }
    }
    if(!$exist){
      $self->setChangeDescription($self->changeDescription() ."\nRemoved ". $value);
      $valuesChanged = 1;
    }
  }

  # check for added options
  foreach my $value (@{$self->possibleValuesNew()}){
    my $exist = 0;
    foreach my $oldValue (@{$self->possibleValuesOld()}){
      if($value eq $oldValue){
        $exist = 1;
        last;
      }
    }
    if(!$exist){
      $self->setChangeDescription($self->changeDescription() ."\nAdded ". $value);
      $valuesChanged = 1;
    }
  }

  # check for changed default value
  if($self->defaultValueNew() ne $self->defaultValueOld()){
    $self->setChangeDescription($self->changeDescription() ."\nDefault value changed from ". $self->defaultValueOld() ." to ". $self->defaultValueNew());
    $defaultChanged = 1;
  }

  # evaluate results
  if(($self->valueOld() ne $self->valueNew()) && (uc($self->valueOld()) eq uc($self->valueNew()))){
    $self->_addChangeType(CAD::Firemen::Change::Type->Case);
  }
  if(($self->valueOld() =~ m/^[A-Za-z]:[\\\/]/) && ($self->valueNew() =~ m/^[A-Za-z]:[\\\/]/)){
    $self->_addChangeType(CAD::Firemen::Change::Type->Path);
  }
  # NoSpecial means only valueOld and valueNew have changed
  # therefore it is NoSpecial, if values are not equal and it is not Case or Path
  if(($self->valueOld() ne $self->valueNew()) && !$self->changeType(CAD::Firemen::Change::Type->Case) && !$self->changeType(CAD::Firemen::Change::Type->Case)){
    $self->_addChangeType(CAD::Firemen::Change::Type->NoSpecial);
  }

  if($valuesChanged){
    $self->_addChangeType(CAD::Firemen::Change::Type->ValuesChanged);
  }
  if($defaultChanged){
    $self->_addChangeType(CAD::Firemen::Change::Type->DefaultValueChanged);
  }

  return 1;
}

sub _setChangeType {
  my $self = shift;
  my $value = shift;
  if(!defined($value)){
    return 0;
  }
  delete($self->{'_changeType'});
  $self->{'_changeType'} = {};
  return $self->_addChangeType($value);
}

sub _addChangeType {
  my $self = shift;
  my $value = shift;
  if(!defined($value)){
    return 0;
  }
  $self->{'_changeType'}->{$value} = 1;
  # if we have a change now, remove NoChange
  if($value ne CAD::Firemen::Change::Type->NoChange){
    if(exists($self->{'_changeType'}->{CAD::Firemen::Change::Type->NoChange})){
      delete($self->{'_changeType'}->{CAD::Firemen::Change::Type->NoChange});
    }
  }
  return 1;
}

sub changeType {
  my $self = shift;
  my $type = shift;
  if(!defined($type)){
    return 0;
  }
  if(exists($self->{'_changeType'}->{$type})){
    return 1;
  }
  return 0;
}

sub highlightColor {
  my $self = shift;
  if($self->changeType(CAD::Firemen::Change::Type->Case)){
    return "CYAN";
  }
  elsif($self->changeType(CAD::Firemen::Change::Type->Path)){
    return "MAGENTA";
  }
  return "YELLOW";
}

1;

__END__

=pod

=head1 NAME

CAD::Firemen::Change - Object to represant the changes of an option

=head1 VERSION

version 0.7.2

=head1 DESCRIPTION

Create a new object of CAD::Firemen::Change with

my $change = new CAD::Firemen::Change("name" => "OPTION_NAME");

afterwards, set the old and new value (or specify them already
at the constructor with ("valueOld" => "OLD_VALUE", "valueNew" => "NEW_VALUE"))

$change->setValueOld("OLD_VALUE");
$change->setValueNew("NEW_VALUE");

To evaluate the changes between old and new value, just call

my $changeType = $change->evalChange();

which returns the type of the change as one of the CAD::Firemen::Change::Type.
To get the color of which should be used to print the change, use

$change->highlightColor();

To evaluate the change type, you can get it with

$change->changeType();

=head1 METHODS

=head2 new

Creates a new object of type CAD::Firemen::Change.
Per default, all values are empty and the change type is set
to CAD::Firemen::NoChange.

You can specify values like that:

my $change = new CAD::Firemen::Change(
  "name" => "OPTION_NAME",
  "valueOld" => "VALUE_OLD",
  "valueNew" => "VALUE_NEW"
);

=head2 setOption

Sets the option name. To read it, just use method option().

=head2 option

Returns the name of this option.

=head2 setValueOld

Sets the old value of this option. To read it use valueOld().

=head2 valueOld

Returns the old value of this option.

=head2 setValueNew

Sets the new value of this option. To read the value use valueNew().

=head2 valueNew

Returns the new value of this option.

=head2 setPossibleValuesOld

Set's the array of possible old values.

=head2 possibleValuesOld

Returns an array with old possible values.

=head2 setPossibleValuesNew

Set's the array of possible new values.

=head2 possibleValuesNew

Returns an array with new possible values.

=head2 setDefaultValueOld

Set's the old default value.

=head2 defaultValueOld

Returns the old default value.

=head2 setDefaultValueNew

Set's the new default value.

=head2 defaultValueNew

Returns the new default value.

=head2 setChangeDescription
FOR INTERNAL USE ONLY!

Set's the description of this change. It set's
automatically by evalChange().

=head2 changeDescription

Return the stored description, to give some more info on the current change.

=head2 evalChange

Evaluates the changes from old value to new value and sets the changeType() according to
the detected change.
It also evaluates changes within the possible and default values.

=head2 _setChangeType
FOR INTERNAL USE ONLY!

Sets the change type of this change. But the change type
is set automatically by evalChange(). Therefore the user
does not need to set it. Just use changeType() to get the
current type.

=head2 _addChangeType
FOR INTERNAL USE ONLY!

Adds the change type to the already listed ones. Use
setChangeType() to overwrite all already listed types.

But the change type is set automatically by evalChange().
Therefore the user does not need to set it. Just use
changeType() to get the current type.

=head2 changeType

Returns true, if that change is of the given type. But it can be also of another
type too. The change type is set automatically by evalChange() to one of the values
of CAD::Firemen::Change::Type.

=head2 highlightColor

Returns the name of the color, which should be used
to highlight this type of change.

All other   - YELLOW
Case        - CYAN
Path        - MAGENTA

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
