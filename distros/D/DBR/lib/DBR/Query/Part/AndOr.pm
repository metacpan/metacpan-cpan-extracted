# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

###########################################
package DBR::Query::Part::AndOr;

use strict;
use base 'DBR::Query::Part';
use Carp;
use Data::Dumper;

sub new{
      my( $package ) = shift;

      for (@_){
	    ref($_) =~ /^DBR::Query::Part::/ || confess("arguments must be part objects ($_)")
      };

      my $self = [@_];

      bless( $self, $package );

      return $self;
}

sub children{ @{$_[0]} }

sub _validate_self{ return scalar($_[0]->children)?1:$_[0]->_error('Invalid object')  } # AND/OR are only valid if they have at least one child

sub sql { # Used by AND/OR
      my $self = shift;
      my $conn = shift or return $self->_error('conn must be specified');
      my $nested = shift;


      my $type = $self->type;
      $type =~ /^(AND|OR)$/ or return $self->_error('this sql function is only used for AND/OR');

      my $sql;
      $sql .= '(' if $nested;
      $sql .= join(' ' . $type . ' ', map { $_->sql($conn,1) } $self->children );
      $sql .= ')' if $nested;

      return $sql;
}

1;

###########################################
package DBR::Query::Part::And;
use strict;
our @ISA = ('DBR::Query::Part::AndOr');

sub type { return 'AND' };

#If any children are empty, we are empty
sub is_emptyset{
    $_->is_emptyset && return 1 for ($_[0]->children);
    return 0;
}

1;

###########################################
package DBR::Query::Part::Or;
use strict;
our @ISA = ('DBR::Query::Part::AndOr');

sub type { return 'OR' };

# If any children are non-empty, then we are non-empty
sub is_emptyset{
    $_->is_emptyset || return 0 for ($_[0]->children);
    return 1;
}

1;
