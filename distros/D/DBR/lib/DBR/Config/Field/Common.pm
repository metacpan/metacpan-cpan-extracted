# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Field::Common;

use strict;
use base 'DBR::Common';
use Carp;

use constant ({
	       # Object fields
	       O_xname       => 0,
	       O_session     => 1,
	       O_index       => 2,
	       O_table_alias => 3,
	       O_alias_flag  => 4,
	      });

sub makevalue{ undef }
sub table_id { undef };
sub field_id { undef };
sub name     { confess "shouldn't get here" };
sub is_pkey  { undef }
sub table    { undef }
sub is_numeric{ undef }
sub translator { undef }
sub is_readonly  { 0 }
sub testsub      { sub { 0 } }
sub default_val  { undef }

sub table_alias{
      my $self = shift;
      my $set = shift;
      if($set){
	    return $self->[O_table_alias] = $set;
      }

      return $self->[O_table_alias];

}

sub index{
      my $self = shift;
      my $set = shift;

      if(defined($set)){
	    croak "Cannot set the index on a field object twice" if defined( $self->[O_index] ); # I want this to fail obnoxiously
	    $self->[O_index] = $set;
	    return 1;
      }

      return $self->[O_index];
}

sub validate { 1 }

sub sql  {
      my $self = shift;
      my $name  = $self->name;
      my $alias = $self->table_alias;

      my $sql;
      $sql  = $alias . '.' if $alias;
      $sql .= $name;

      if(defined($self->[O_alias_flag])){

	    if ( $self->{O_alias_flag} == 1 ) {
		  $sql .= " AS $name";
	    } elsif ( $self->{O_alias_flag} == 2 ) {
		  $sql .= " AS '$alias.$name'";
	    }

      }

      return $sql;
}

sub _session { $_[0]->[O_session] }

1;
