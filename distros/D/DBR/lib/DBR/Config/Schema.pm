# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Schema;

use strict;
use base 'DBR::Common';

use DBR::Config::Table;
use Clone;

my %TABLES_BY_NAME;
my %INSTANCES_BY_CLASS;
my %SCHEMAS_BY_ID;
my %SCHEMAS_BY_HANDLE;

sub load{
      my( $package ) = shift;
      my %params = @_;

      my $self = { session => $params{session} };
      bless( $self, $package ); # Dummy object

      my $instance = $params{instance} || return $self->_error('instance is required');

      my $dbrh = $instance->connect || return $self->_error("Failed to connect to ${\$instance->name}");

      my $schema_ids = $params{schema_id} || return $self->_error('schema_id is required');
      $schema_ids = [$schema_ids] unless ref($schema_ids) eq 'ARRAY';

      return 1 unless @$schema_ids;

      return $self->_error('Failed to select instances') unless
	my $schemas = $dbrh->select(
				    -table => 'dbr_schemas',
				    -fields => 'schema_id handle display_name',
				    -where  => { schema_id => ['d in', @{$schema_ids}] },
				   );

      my @schema_ids; # track the schema ids from this request seperately from the global cache
      foreach my $schema (@$schemas){
	    $SCHEMAS_BY_ID{  $schema->{schema_id} } = $schema;
	    $SCHEMAS_BY_HANDLE{ $schema->{handle} } = $schema->{schema_id};

	    push @schema_ids, $schema->{schema_id};
      }

      DBR::Config::Table->load(
			       session => $self->{session},
			       instance => $instance,
			       schema_id => \@schema_ids,
			      ) or return $package->_error('failed to load tables');

      return 1;
}

sub list_schemas {
      return Clone::clone( [ sort { ($a->{display_name} || '') cmp ($b->{display_name} || '') } values %SCHEMAS_BY_ID ] );
}

sub _register_table{
      my $package = shift; # no dummy $self object here, for efficiency
      my %params = @_;

      my $schema_id = $params{schema_id} or return $package->_error('schema_id is required');
      $SCHEMAS_BY_ID{ $schema_id } or return $package->_error('invalid schema_id');

      my $name      = $params{name}      or return $package->_error('name is required');
      my $table_id  = $params{table_id}  or return $package->_error('table_id is required');

      $TABLES_BY_NAME{ $schema_id } -> { $name } = $table_id;

      return 1;
}

sub _register_instance{
      my $package = shift; # no dummy $self object here, for efficiency
      my %params = @_;

      my $schema_id = $params{schema_id} or die 'schema_id is required';
      my $class     = $params{class}     or die 'class is required';
      my $guid      = $params{guid}      or die 'guid is required';

      $INSTANCES_BY_CLASS{ $schema_id } -> { $class } = $guid;

      return 1;
}

###################### BEGIN OBJECT ORIENTED CODE ######################

sub new {
  my( $package ) = shift;
  my %params = @_;
  my $self = {
	      session    => $params{session},
	     };

  bless( $self, $package );

  return $self->_error('session is required') unless $self->{session};

  if ($params{schema_id}){
	$self->{schema_id} = $params{schema_id};
  }elsif($params{handle}){
	$self->{schema_id} = $SCHEMAS_BY_HANDLE{ $params{handle} } or return $self->_error("handle $params{handle} is invalid");
  }else{
	return $self->_error('schema_id is required');
  }

  return $self->_error("schema_id $self->{schema_id} is not defined") unless $SCHEMAS_BY_ID{ $self->{schema_id} };

  return( $self );
}

sub get_table{
      my $self  = shift;
      my $tname = shift or return $self->_error('name is required');

      my $table_id = $TABLES_BY_NAME{ $self->{schema_id} } -> { $tname } || return $self->_error("table $tname does not exist");

      my $table = DBR::Config::Table->new(
					  session   => $self->{session},
					  table_id => $table_id,
					 ) or return $self->_error('failed to create table object');
      return $table;
}

sub tables{
      my $self  = shift;

      my @tables;

      foreach my $table_id (    values %{$TABLES_BY_NAME{ $self->{schema_id}} }   ) {

	    my $table = DBR::Config::Table->new(
						session   => $self->{session},
						table_id => $table_id,
					       ) or return $self->_error('failed to create table object');
	    push @tables, $table;
      }


      return  wantarray ? @tables : \@tables;
}

sub get_instance{
      my $self  = shift;
      my $class = shift || 'master';

      my $guid = $INSTANCES_BY_CLASS{ $self->{schema_id} } -> { $class } || return $self->_error("instance of class $class does not exist");

      my $instance = DBR::Config::Instance->lookup(
						   session => $self->{session},
						   guid    => $guid,
						  ) or return $self->_error('failed to create table object');
      return $instance;
}

sub instances{
      my $self  = shift;

      my @instances;

      foreach my $guid (    values %{$INSTANCES_BY_CLASS{ $self->{schema_id}} }   ) {

	    my $instance = DBR::Config::Instance->lookup(
							 session => $self->{session},
							 guid    => $guid,
							) or return $self->_error('failed to create instance object');
	    push @instances, $instance;
      }


      return wantarray ? @instances : \@instances;
}



sub schema_id {
      my $self = shift;
      return $self->{schema_id};
}

sub handle {
      my $self = shift;
      my $schema = $SCHEMAS_BY_ID{ $self->{schema_id} } or return $self->_error( 'lookup failed' );
      return $schema->{handle};
}

sub display_name {
      my $self = shift;
      my $schema = $SCHEMAS_BY_ID{ $self->{schema_id} } or return $self->_error( 'lookup failed' );
      return $schema->{display_name} || '';
}

1;
