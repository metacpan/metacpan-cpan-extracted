# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::ScanDB;

use strict;
use base 'DBR::Common';
use DBR::Config::Field;
use DBR::Config::Schema;

sub new {
      my( $package ) = shift;
      my %params = @_;
      my $self = {
		  session   => $params{session},
		  conf_instance => $params{conf_instance},
		  scan_instance => $params{scan_instance},
		 };

      bless( $self, $package );

      return $self->_error('session object must be specified')   unless $self->{session};
      return $self->_error('conf_instance object must be specified')   unless $self->{conf_instance};
      return $self->_error('scan_instance object must be specified')   unless $self->{scan_instance};

      $self->{schema_id} = $self->{scan_instance}->schema_id or
	return $self->_error('Cannot scan an instance that has no schema');

      return( $self );
}

sub scan{
      my $self = shift;
      my %params = @_; 

      my $tables = $self->scan_tables() || die "failed to scan tables";
      my $pkeys = $self->scan_pkeys(); # || die "failed to scan primary keys";

      foreach my $table (@{$tables}){
            print "Scanning $table\n" if $params{pretty};
            
       	    my $fields = $self->scan_fields($table) or return $self->_error( "failed to describe table" );
            my $pkey = $pkeys ? $pkeys->{$table} : $self->scan_pkeys( $table );

            $self->update_table($fields,$table,$pkey) or return $self->_error("failed to update table");
      }

      #HACK - the scanner should load up the in-memory representation at the same time
      DBR::Config::Schema->load(
            session   => $self->{session},
            schema_id => $self->{schema_id},
            instance  => $self->{conf_instance},
          ) or die "Failed to reload schema";

      return 1;
}


sub scan_pkeys {
      my $self = shift;
      my $table = shift;  # undef for all
      #print "SCAN_PKEYS called with table=[$table]\n";

      my $dbh = $self->{scan_instance}->connect('dbh') || die "failed to connect to scanned db";

      my $sth;
      local $dbh->{PrintError} = 0;
      local $^W = 0;
      eval { $sth= $dbh->primary_key_info(undef,undef,$table); };
      return $self->_error('failed call to primary_key_info') unless $sth;
      
      my %map = ();
      while (my $row = $sth->fetchrow_hashref()) {
            next unless $row->{PK_NAME} eq 'PRIMARY KEY';
	    my $table = $row->{TABLE_NAME} or return $self->_error('no TABLE_NAME!');
	    my $field = $row->{COLUMN_NAME} or return $self->_error('no COLUMN_NAME!');
            $map{$table}->{$field} = 1;
      }

      $sth->finish();

      return \%map;
}

sub scan_tables{
      my $self = shift;
      my $dbh = $self->{scan_instance}->connect('dbh') || die "failed to connect to scanned db";

      return $self->_error('failed call to table_info') unless
	my $sth = $dbh->table_info;

      my @tables;
      while (my $row = $sth->fetchrow_hashref()) {
	    my $name = $row->{TABLE_NAME} or return $self->_error('Table entry has no name!');

	    next if ($name eq 'sqlite_sequence'); # Ugly

	    if($row->{TABLE_TYPE} eq 'TABLE'){
		  push @tables, $name;
	    }
      }

      $sth->finish();

      return \@tables;
}

sub scan_fields{
      my $self = shift;
      my $table = shift;

      my $dbh = $self->{scan_instance}->connect('dbh') || die "failed to connect to scanned db";

      return $self->_error('failed call to column_info') unless
	my $sth = $dbh->column_info( undef, undef, $table, undef );

      my @rows;
      while (my $row = $sth->fetchrow_hashref()) {
	    push @rows, $row;
      }

      $sth->finish();

      return \@rows;
}

sub update_table{
      my $self   = shift;
      my $fields = shift;
      my $name   = shift;
      my $pkey   = shift;

      my $dbh = $self->{conf_instance}->connect || die "failed to connect to config db";

      return $self->_error('failed to select from dbr_tables') unless
 	my $tables = $dbh->select(
 				  -table  => 'dbr_tables',
 				  -fields => 'table_id schema_id name',
 				  -where  => {
 					      schema_id => ['d',$self->{schema_id}],
 					      name      => $name,
 					     }
 				 );

      my $table = $tables->[0];

      my $table_id;
      if($table){ # update
 	    $table_id = $table->{table_id};
      }else{
 	    return $self->_error('failed to insert into dbr_tables') unless
 	      $table_id = $dbh->insert(
 				       -table  => 'dbr_tables',
 				       -fields => {
 						   schema_id => ['d',$self->{schema_id}],
 						   name      => $name,
 						  }
 				      );
      }

      $self->update_fields($fields,$table_id,$pkey) or return $self->_error('Failed to update fields');

      return 1;
}


sub update_fields{
      my $self = shift;
      my $fields = shift;
      my $table_id = shift;
      my $pkey_map = shift;

      my $dbh = $self->{conf_instance}->connect || die "failed to connect to config db";

      return $self->_error('failed to select from dbr_fields') unless
 	my $records = $dbh->select(
				   -table  => 'dbr_fields',
				   -fields => 'field_id table_id name data_type is_nullable is_signed max_value',
				   -where  => {
					       table_id  => ['d',$table_id]
					      }
				  );

      my %fieldmap;
      map {$fieldmap{$_->{name}} = $_} @{$records};

      foreach my $field (@{$fields}) {
 	    my $name = $field->{'COLUMN_NAME'} or return $self->_error('No COLUMN_NAME is present');
	    my $type = $field->{'TYPE_NAME'}   or return $self->_error('No TYPE_NAME is present'  );
	    my $size = $field->{'COLUMN_SIZE'};

	    my $nullable = $field->{'NULLABLE'};
	    return $self->_error('No NULLABLE is present'  ) unless defined($nullable);

	    my $pkey = $field->{'mysql_is_pri_key'} || $pkey_map->{$name};
	    my $extra = $field->{'mysql_type_name'};

	    my $is_signed = 0;
	    if(defined $extra){
		  $is_signed = ($extra =~ / unsigned/i)?0:1;
		  $is_signed = 0 if $type =~ /unsigned/i; #Lame... SQLite sometimes returns the data type as 'int unsigned'
	    }
	    $type =~ /^\s+|\s+$/g;
	    ($type) = split (/\s+/,$type);
	    my $typeid = DBR::Config::Field->get_type_id($type) or die( "Invalid type '$type'" );

 	    my $record = $fieldmap{$name};

 	    my $ref = {
 		       is_nullable => ['d',  $nullable ? 1:0 ],
 		       is_signed   => ['d',  $is_signed      ],
 		       data_type   => ['d',  $typeid         ],
 		       max_value   => ['d',  $size || 0      ],
 		      };

	    if(defined($pkey)){
		  $ref->{is_pkey} = ['d',  $pkey ? 1:0  ],
	    }

 	    if ($record) {	# update
 		  return $self->_error('failed to insert into dbr_tables') unless
 		    $dbh->update(
 				 -table  => 'dbr_fields',
 				 -fields => $ref,
 				 -where  => { field_id => ['d',$record->{field_id}] },
 				);
 	    } else {
 		  $ref->{name}     = $name;
 		  $ref->{table_id} = ['d', $table_id ];

 		  return $self->_error('failed to insert into dbr_tables') unless
 		    my $field_id = $dbh->insert(
 						-table  => 'dbr_fields',
 						-fields => $ref,
 					       );
 	    }

 	    delete $fieldmap{$name};

      }

      foreach my $name (keys %fieldmap) {
 	    my $record = $fieldmap{$name};

 	    return $self->_error('failed to delete from dbr_tables') unless
 	      $dbh->delete(
 			   -table  => 'dbr_fields',
 			   -where  => { field_id => ['d',$record->{field_id}] },
 			  );
      }

      return 1;
}

1;
