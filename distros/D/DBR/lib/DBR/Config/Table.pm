# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Table;

use strict;
use base 'DBR::Config::Table::Common';

use DBR::Config::Field;
use DBR::Config::Relation;
use Carp;

my %TABLES_BY_ID;
my %FIELDS_BY_NAME;
my %RELATIONS_BY_NAME;
my %PK_FIELDS;
my %REQ_FIELDS;

sub load{
      my( $package ) = shift;
      my %params = @_;

      my $self = { session => $params{session} };
      bless( $self, $package ); # Dummy object

      my $instance = $params{instance} || return $self->_error('instance is required');

      my $schema_ids = $params{schema_id} || return $self->_error('schema_id is required');
      $schema_ids = [$schema_ids] unless ref($schema_ids) eq 'ARRAY';

      return 1 unless @$schema_ids;

      my $dbrh = $instance->connect || return $self->_error("Failed to connect to @{[$instance->name]}");

      return $self->_error('Failed to select instances') unless
	my $tables = $dbrh->select(
				   -table  => 'dbr_tables',
				   -fields => 'table_id schema_id name',
				   -where  => { schema_id => ['d in', @{$schema_ids}] },
				  );

      my @table_ids;
      foreach my $table (@$tables){
	    DBR::Config::Schema->_register_table(
						 schema_id => $table->{schema_id},
						 name      => $table->{name},
						 table_id  => $table->{table_id},
						) or return $self->_error('failed to register table');

	    $table->{conf_instance_guid} = $instance->guid;

	    $TABLES_BY_ID{ $table->{table_id} } = $table;
	    push @table_ids, $table->{table_id};

	    #Purge in case this is a reload
	    $FIELDS_BY_NAME{  $table->{table_id} } = {};
	    $PK_FIELDS{       $table->{table_id} } = [];
	    $REQ_FIELDS{      $table->{table_id} } = [];
      }

      if(@table_ids){
	    DBR::Config::Field->load(
				     session => $self->{session},
				     instance => $instance,
				     table_id => \@table_ids,
				    ) or return $self->_error('failed to load fields');

	    DBR::Config::Relation->load(
					session => $self->{session},
					instance => $instance,
					table_id => \@table_ids,
				       ) or return $self->_error('failed to load relationships');
      }

      return 1;
}

sub _register_field{
      my $package = shift; # no dummy $self object here, for efficiency
      my %params = @_;

      my $table_id = $params{table_id} or croak('table_id is required');
      $TABLES_BY_ID{ $table_id }       or croak('invalid table_id');

      my $name     = $params{name}     or croak('name is required');
      my $field_id = $params{field_id} or croak('field_id is required');
      defined($params{is_pkey})        or croak('is_pkey is required');

      $FIELDS_BY_NAME{ $table_id } -> { $name } = $field_id;

      if( $params{is_pkey} ){  push @{$PK_FIELDS{ $table_id }},  $field_id }
      if( $params{is_req}  ){  push @{$REQ_FIELDS{ $table_id }}, $field_id }

      return 1;
}

sub _register_relation{
      my $package = shift; # no dummy $self object here, for efficiency
      my %params = @_;

      my $table_id = $params{table_id} or croak ('table_id is required');
      $TABLES_BY_ID{ $table_id }       or croak('invalid table_id');

      my $name        = $params{name}        or croak('name is required');
      my $relation_id = $params{relation_id} or croak('relation_id is required');

      $RELATIONS_BY_NAME{ $table_id } -> { $name } = $relation_id;

      return {
	      %{ $TABLES_BY_ID{ $table_id } }
	     }; # shallow clone
}

sub new {
  my( $package ) = shift;
  my %params = @_;
  my $self = {
	      session  => $params{session},
	      table_id => $params{table_id}
	     };

  bless( $self, $package );

  return $self->_error('table_id is required') unless $self->{table_id};
  return $self->_error('session is required' ) unless $self->{session};

  $TABLES_BY_ID{ $self->{table_id} } or return $self->_error("table_id $self->{table_id} doesn't exist");

  return( $self );
}

sub clone{
      my $self = shift;
      my %params = @_;

      return bless({
                  session   => $self->{session},
                  table_id  => $self->{table_id},
                  $params{with_alias} ? ( alias => $self->{alias} ) : (),
            },
           ref($self)
      );

}


sub table_id { $_[0]->{table_id} }
sub get_field{
      my $self  = shift;
      my $name = shift or return $self->_error('name is required');

      my $field_id = $FIELDS_BY_NAME{ $self->{table_id} } -> { $name } || return $self->_error("field $name does not exist");

      my $field = DBR::Config::Field->new(
					  session   => $self->{session},
					  field_id => $field_id,
					 ) or return $self->_error('failed to create table object');
      return $field;
}

sub fields{
      my $self  = shift;
      [
       map {
	     DBR::Config::Field->new(session   => $self->{session}, field_id => $_ ) or return $self->_error('failed to create field object')
	   } values %{$FIELDS_BY_NAME{$self->{table_id}}}
      ];
}

sub req_fields{
      my $self = shift;
      [
       map {
	     DBR::Config::Field->new(session   => $self->{session}, field_id => $_ ) or return $self->_error('failed to create field object')
	   } @{ $REQ_FIELDS{ $self->{table_id} } }
      ];

}
sub primary_key{
      my $self = shift;
      [
       map {
	     DBR::Config::Field->new(session   => $self->{session}, field_id => $_ ) or return $self->_error('failed to create field object')
	   } @{ $PK_FIELDS{ $self->{table_id} } }
      ];

}
sub get_relation{
      my $self  = shift;
      my $name = shift or return $self->_error('name is required');

      my $relation_id = $RELATIONS_BY_NAME{ $self->{table_id} } -> { $name } or return $self->_error("relationship $name does not exist");


      my $relation = DBR::Config::Relation->new(
						session     => $self->{session},
						relation_id => $relation_id,
						table_id    => $self->{table_id},
					       ) or return $self->_error('failed to create relation object');

      return $relation;
}

sub relations{
      my $self  = shift;

      my @relations;

      foreach my $relation_id (    values %{$RELATIONS_BY_NAME{$self->{table_id}}}   ) {

	    my $relation = DBR::Config::Relation->new(
						      session      => $self->{session},
						      relation_id => $relation_id,
						      table_id    => $self->{table_id},
						     ) or return $self->_error('failed to create relation object');
	    push @relations, $relation;
      }


      return \@relations;
}


sub name      { $TABLES_BY_ID{  $_[0]->{table_id} }->{name} };
sub schema_id { $TABLES_BY_ID{  $_[0]->{table_id} }->{schema_id} };

sub schema{
      my $self = shift;
      my %params = @_;

      my $schema_id = $self->schema_id || return ''; # No schemas here

      my $schema = DBR::Config::Schema->new(
					    session   => $self->{session},
					    schema_id => $schema_id,
					   ) || return $self->_error("failed to fetch schema object for schema_id $schema_id");

      return $schema;
}


sub conf_instance {
      my $self = shift;


      my $guid = $TABLES_BY_ID{  $self->{table_id} }->{conf_instance_guid};

      return DBR::Config::Instance->lookup(
					   session => $self->{session},
					   guid   => $guid
					  ) or return $self->_error('Failed to fetch conf instance');
}


1;
