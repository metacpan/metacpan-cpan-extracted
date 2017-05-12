# Connector::Types
#
# Utility class containing customized Moose types and constraints
#
# Written by Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Types;

use Moose;
use Moose::Util::TypeConstraints;

###########################################################################
# Types
subtype 'Connector::Types::Char'
  => as 'Str',
  => where { length($_) == 1 }
  => message { 'Exactly one character expected' };

# location for a connector
subtype 'Connector::Types::Location'
  => as 'Str';

# unique key for accessing records
subtype 'Connector::Types::Key'
  => as 'Str';


1;

