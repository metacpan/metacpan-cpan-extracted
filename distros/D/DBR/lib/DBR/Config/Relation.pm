# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Relation;

use strict;
use base 'DBR::Common';
use DBR::Config::Table;
use DBR::Config::Field;
use Carp;
use Clone 'clone';

my %TYPES = (
	     1 => { name => 'parentof', mode => '1toM', opposite => 2 }, #reciprocal
	     2 => { name => 'childof',  mode => 'Mto1', opposite => 1 },
	     3 => { name => 'assoc',    mode => 'MtoM' },
	     4 => { name => 'other',    mode => 'MtoM' },
	    );

map { $TYPES{$_}{type_id} = $_ } keys %TYPES;

sub list_types{
      return clone( [ sort {$a->{type_id} <=> $b->{type_id} } values %TYPES ] );
}


my %RELATIONS_BY_ID;
sub load{
      my( $package ) = shift;
      my %params = @_;

      my $self = { session => $params{session} };
      bless( $self, $package ); # Dummy object

      my $instance = $params{instance} || return $self->_error('instance is required');

      my $table_ids = $params{table_id} || return $self->_error('table_id is required');
      $table_ids = [$table_ids] unless ref($table_ids) eq 'ARRAY';

      return 1 unless @$table_ids;

      my $dbrh = $instance->connect || return $self->_error("Failed to connect to ${\$instance->name}");

      return $self->_error('Failed to select from dbr_relationships') unless
	my $relations = $dbrh->select(
				      -table => 'dbr_relationships',
				      -fields => 'relationship_id from_name from_table_id from_field_id to_name to_table_id to_field_id type',
				      -where  => { from_table_id => ['d in',@$table_ids] },
				     );

      my @rel_ids;
      foreach my $relation (@$relations){

	    my $table1 = DBR::Config::Table->_register_relation(
								table_id    => $relation->{to_table_id},
								name        => $relation->{from_name}, #yes, this is kinda confusing
								relation_id => $relation->{relationship_id},
							       ) or return $self->_error('failed to register to relationship');

	    my $table2 = DBR::Config::Table->_register_relation(
								table_id    => $relation->{from_table_id},
								name        => $relation->{to_name}, #yes, this is kinda confusing
								relation_id => $relation->{relationship_id},
							       ) or return $self->_error('failed to register from relationship');


	    $relation->{same_schema} = ( $table1->{schema_id} == $table2->{schema_id} );

	    $RELATIONS_BY_ID{ $relation->{relationship_id} } = $relation;
	    push @rel_ids, $relation->{relationship_id};

      }

      return 1;
}


sub new {
      my $package = shift;
      my %params = @_;
      my $self = {
		  session      => $params{session},
		  relation_id => $params{relation_id},
		  table_id    => $params{table_id},
		 };

      bless( $self, $package );

      return $self->_error('relation_id is required') unless $self->{relation_id};
      return $self->_error('table_id is required')    unless $self->{table_id};


      my $ref = $RELATIONS_BY_ID{ $self->{relation_id} } or return $self->_error('invalid relation_id');
      return $self->_error("Invalid type_id $ref->{type}") unless $TYPES{ $ref->{type} };

      if($ref->{from_table_id} == $self->{table_id}){

	    $self->{forward} = 'from';
	    $self->{reverse} = 'to';
	    $self->{type_id} = $ref->{type};
      }elsif($ref->{to_table_id} == $self->{table_id}){

	    $self->{forward} = 'to';
	    $self->{reverse} = 'from';
	    $self->{type_id} = $TYPES{ $ref->{type} }->{opposite} || $ref->{type};

      }else{
	    return $self->_error("table_id $self->{table_id} is invalid for this relationship");
      }

      return( $self );
}

sub relation_id { $_[0]->{relation_id} }
sub name     { $RELATIONS_BY_ID{  $_[0]->{relation_id} }->{ $_[0]->{reverse}  . '_name' }    } # Name is always the opposite of everything else

sub field_id {
      my $self = shift;

      return $RELATIONS_BY_ID{  $self->{relation_id} }->{ $self->{forward}  . '_field_id' };
}

sub field {
      my $self = shift;
      my $field_id = $RELATIONS_BY_ID{  $self->{relation_id} }->{ $self->{forward}  . '_field_id' };

      my $field = DBR::Config::Field->new(
					  session  => $self->{session},
					  field_id => $field_id,
					 ) or return $self->_error('failed to create field object');

      return $field;
}

sub mapfield {
      my $self = shift;
      my $mapfield_id = $RELATIONS_BY_ID{  $self->{relation_id} }->{ $self->{reverse}  . '_field_id' };

      my $field = DBR::Config::Field->new(
					  session  => $self->{session},
					  field_id => $mapfield_id,
					 ) or return $self->_error('failed to create field object');

      return $field;
}

sub table {
      my $self = shift;

      return DBR::Config::Table->new(
				     session   => $self->{session},
				     table_id => $RELATIONS_BY_ID{  $self->{relation_id} }->{$self->{forward} . '_table_id'}
				    );
}

sub maptable {
      my $self = shift;

      return DBR::Config::Table->new(
				     session   => $self->{session},
				     table_id => $RELATIONS_BY_ID{  $self->{relation_id} }->{$self->{reverse} . '_table_id'}
				    );
}

sub is_to_one{
      my $mode = $TYPES{ $_[0]->{type_id} }->{mode};

      return 1 if $mode eq 'Mto1';
      return 1 if $mode eq '1to1';

      return 0;
}

sub is_same_schema{ $RELATIONS_BY_ID{  shift->{relation_id} }->{same_schema} }


sub index{
      my $self = shift;
      my $set = shift;

      if(defined($set)){
	    croak "Cannot set the index on a relation object twice" if defined($self->{index}); # I want this to fail obnoxiously
	    $self->{index} = $set;
	    return 1;
      }

      return $self->{index};
}

1;
