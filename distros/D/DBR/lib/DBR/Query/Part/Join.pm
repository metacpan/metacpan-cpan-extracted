# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

###########################################
package DBR::Query::Part::Join;
use strict;
use base 'DBR::Query::Part';

sub new{
      my( $package ) = shift;
      my ($from,$to) = @_;

      return $package->_error('from must be specified') unless ref($from) =~ /^DBR::Config::Field/; # Could be ::Anon
      return $package->_error( 'to must be specified' ) unless ref($to)   =~ /^DBR::Config::Field/; # Could be ::Anon


      $to->table_alias   or   return $package->_error('field ' . $to->name   . ' cannot be joined without a table alias');
      $from->table_alias or   return $package->_error('field ' . $from->name . ' cannot be joined without a table alias');


      my $self = [ $to, $from ];

      bless( $self, $package );
      return $self;
}

sub from { return $_[0]->[0] }
sub to   { return $_[0]->[1] }

sub type { return 'JOIN' };

sub sql {
      my $self = shift;
      my $conn = shift or return $self->_error('conn must be specified');

      return $self->from->sql( $conn ) . ' = ' . $self->to->sql( $conn );
}
sub _validate_self{
      my $self = shift;
      my $query = shift;

      $query->check_table( $self->from->table_alias ) or return $self->_error( 'Invalid join-from table ' . $self->from->table_alias );
      $query->check_table( $self->to->table_alias   ) or return $self->_error( 'Invalid join-to table '   . $self->to->table_alias   );

      return 1;
}

sub is_emptyset { 0 }

1;
