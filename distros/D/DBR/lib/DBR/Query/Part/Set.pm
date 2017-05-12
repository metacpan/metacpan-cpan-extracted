# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

###########################################
package DBR::Query::Part::Set;

use strict;
use base 'DBR::Query::Part';

sub new{
      my( $package ) = shift;
      my ($field,$value) = @_;

      return $package->_error('field must be a Field object') unless ref($field) =~ /^DBR::Config::Field/; # Could be ::Anon
      return $package->_error('value must be a Value object') unless ref($value) eq 'DBR::Query::Part::Value';

      my $self = [ $field, $value ];

      bless( $self, $package );
      return $self;
}



sub field   { return $_[0]->[0] }
sub value { return $_[0]->[1] }
sub sql   { return $_[0]->field->sql($_[1]) . ' = ' . $_[0]->value->sql($_[1]) }
sub _validate_self{ 1 }

sub validate{ 1 }

1;
