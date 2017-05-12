# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Field::Anon;

use strict;
use base 'DBR::Config::Field::Common';
use constant ({
	       # Object fields
	       O_fieldname   => 0,
	       O_session     => 1,
	       O_index       => 2,
	       O_table_alias => 3,
	       O_alias_flag  => 4,
	      });
sub new{
      my( $package ) = shift;
      my %params = @_;

      my $field;

      my $self = [undef,$params{session}];

      bless( $self, $package );

      my $table = $params{table};

      my $name = $params{name} or return $self->_error('name is required');

      my @parts = split(/\./,$name);
      if(scalar(@parts) == 1){
	    ($field) = @parts;
      }elsif(scalar(@parts) == 2){
	    return $self->_error("illegal use of table parameter with table.field notation") if length($table);
	    ($table,$field) = @parts;
      }else{
	    return $self->_error('Invalid name');
      }

      return $self->_error("invalid field name '$field'") unless $field =~ /^[A-Z][A-Z0-9_-]*$/i;

      if($table){
	    return $self->_error("invalid table name '$table'") unless $table =~ /^[A-Z][A-Z0-9_-]*$/i;
      }

      $self->[O_table_alias] = $table;
      $self->[O_fieldname] = $field;

      return $self;
}

sub clone{
      my $self = shift;
      my %params = @_;

      return bless(
		   [
		    $self->[O_fieldname],
		    $self->[O_session],
		    $params{with_index} ? $self->[O_index]        : undef, # index
		    $params{with_alias} ? $self->[O_table_alias]  : undef, #alias
		   ],
		   ref($self),
		  );
}

sub name { $_[0]->[O_fieldname] }

1;
