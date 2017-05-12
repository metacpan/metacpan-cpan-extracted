# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::SpecLoader;

use strict;

use base 'DBR::Common';

use DBR::Config::Trans;
use DBR::Config::Relation;
no warnings 'deprecated';
use DBR::Config::ScanDB;
use Switch;

my $trans_defs = DBR::Config::Trans->list_translators or die 'Failed to get translator list';
my %trans_lookup; map {$trans_lookup{ uc($_->{name}) } = $_}  @$trans_defs;

my $relationtype_defs = DBR::Config::Relation->list_types or die 'Failed to get relationship type list';
my %relationtype_lookup; map {$relationtype_lookup{ uc($_->{name}) } = $_}  @$relationtype_defs;


sub new {
      my( $package ) = shift;
      my %params = @_;
      my $self = {
		  session       => $params{session},
		  conf_instance => $params{conf_instance},
		  dbr           => $params{dbr},
		 };

      bless( $self, $package );

      return $self->_error('session object must be specified')   unless $self->{session};
      return $self->_error('conf_instance object must be specified')   unless $self->{conf_instance};

      return( $self );
}

sub process_spec{
      my $self = shift;
      my $specs = shift;

      my $dbrh = $self->{conf_instance}->connect or die "Failed to connect to config db";

      $dbrh->begin();

      my %SCANS;
      my %SCHEMA_IDS;
      my $sortval;
      foreach my $spec ( @$specs ){
	    my $oldtable = $spec->{table};
	    if ( $spec->{table} =~ s/^(.*?)\.// ){
		    $spec->{schema} ||= $1;
	    }

	    map {$spec->{ $_ } or die "Invalid Spec row: Missing $_"} qw'schema table field cmd';

	
	    if( ! $SCANS{ $spec->{schema} }++ ){
		  #                           HERE - THIS \/ is wrong. Fix it. Should be asking the schema object for an instance
		  my $scan_instance = $self->{dbr}->get_instance( $spec->{schema} ) or die "No config found for scandb $spec->{schema}";

		  my $scanner = DBR::Config::ScanDB->new(
							 session => $self->{dbr}->session,
							 conf_instance => $self->{conf_instance},
							 scan_instance => $scan_instance,
							);


		  $scanner->scan() or die "Failed to scan $spec->{schema}";
	    }

	    my $schema = new DBR::Config::Schema(session => $self->{session}, handle => $spec->{schema}) or die "Schema $spec->{schema} not found";
	    my $table = $schema->get_table( $spec->{table} ) or die "$spec->{table} not found in schema\n";
	    my $field = $table->get_field ( $spec->{field} ) or die "$spec->{table}.$spec->{field} not found\n";
        $SCHEMA_IDS{ $schema->schema_id } = 1;
	    switch ( uc($spec->{cmd}) ){
		  case 'TRANSLATOR' { $self->_do_translator( $schema, $table, $field, $spec ) }
		  case 'RELATION'   { $self->_do_relation  ( $schema, $table, $field, $spec ) }
		  case 'REGEX'      { $self->_do_regex     ( $schema, $table, $field, $spec ) }
		  case 'ENUMOPT'    { $self->_do_enumopt   ( $schema, $table, $field, $spec, ++$sortval ) }
		  case 'DEFAULT'    { $self->_do_default   ( $schema, $table, $field, $spec ) }
                  else { die "Invalid spec: unknown command $spec->{cmd}"}
	    }
      }

      $dbrh->commit();
      
      foreach my $schema_id ( keys %SCHEMA_IDS ) {
            #HACK - the SpecLoader should load up the in-memory representation at the same time
            DBR::Config::Schema->load(
                  session   => $self->{session},
                  schema_id => $schema_id,
                  instance  => $self->{conf_instance},
                ) or die "Failed to reload schema";
      }
      
      return 1;
}


# Did this one the new way cus it was easy, the rest will be redone at some point
sub _do_translator {
      my ($self, $schema, $table, $field, $spec) = @_;

      my $transname = uc($spec->{translator}) or die "Missing parameter: translator";
      my $new_trans = $trans_lookup{ uc($transname) } or die "Invalid translator '$spec->{translator}'";

      $field->update_translator($transname) or die "Failed to update field translator for $spec->{table}.$spec->{field}";

      return 1;

}

sub _do_regex {
      my ($self, $schema, $table, $field, $spec) = @_;

      $spec->{regex} or die "Missing parameter: regex";
      $field->update_regex($spec->{regex}) or die "Failed to update field regex for $spec->{table}.$spec->{field}";

      return 1;

}
sub _do_default {
      my ($self, $schema, $table, $field, $spec) = @_;

      defined($spec->{value}) or die "Missing parameter: value";
      $field->update_default($spec->{value}) or die "Failed to update field default for $spec->{table}.$spec->{field}";

      return 1;

}

sub _do_relation   {
      my ($self, $schema, $table, $field, $spec) = @_;

      map { $spec->{$_} or die("Parameter '$_' must be specified") } qw'relname reltable relfield type reverse_name';


      my ($toschema_name) = $spec->{reltable} =~ /^(.*?)\./;

      my $toschema = $schema;
      if ( $spec->{reltable} =~ s/^(.*?)\.// ){
	   my $toschema_name = $1;
	   $toschema = new DBR::Config::Schema(session => $self->{session}, handle => $toschema_name )
              or die "Schema $spec->{schema} not found";
      }

      my $totable = $toschema->get_table( $spec->{reltable} ) or die "$spec->{reltable} not found in schema\n";
      my $tofield = $totable ->get_field( $spec->{relfield} ) or die "$spec->{reltable}.$spec->{relfield} not found\n";

      my $type = $relationtype_lookup{ uc ($spec->{type}) } or die "Invalid relationship type '$spec->{type}'";
      my $type_id = $type->{type_id};

      my $dbrh = $self->{conf_instance}->connect or die "Failed to connect to config db";

      my $relationship = $dbrh->select(
				       -table => 'dbr_relationships',
				       -fields => 'relationship_id from_name from_table_id from_field_id to_name to_table_id to_field_id type',
				       -where  => {
						   from_table_id => ['d',$table->table_id],
						   to_name       => $spec->{relname}
						  },
				       -single => 1,
				      );
      defined $relationship or die('Failed to select relationships');

      if ($relationship){
	    $dbrh->update(
			  -table => 'dbr_relationships',
			  -fields => {
				      from_field_id => ['d',$field->field_id],
				      from_name     => $spec->{reverse_name},

				      to_table_id   => ['d',$totable->table_id],
				      to_field_id   => ['d',$tofield->field_id],

				      type          => ['d',$type_id],
				     },
			  -where  => { relationship_id => ['d', $relationship->{relationship_id} ]},
			 ) or die "Failed to update relationship";
      }else{
	    $dbrh->insert(
			  -table => 'dbr_relationships',
			  -fields => {
				      from_table_id => ['d',$table->table_id],
				      from_field_id => ['d',$field->field_id],
				      from_name     => $spec->{reverse_name},

				      to_field_id   => ['d',$tofield->field_id],
				      to_table_id   => ['d',$totable->table_id],
				      to_name       => $spec->{relname},

				      type          => ['d',$type_id],
				     },
			 ) or die "Failed to insert relationship";
      }

      return 1;
}


#This needs to be made smarter
sub _do_enumopt    {
      my ($self, $schema, $table, $field, $spec, $sortval) = @_;

      map { length($spec->{$_}) or die("Parameter '$_' must be specified") } qw'handle name';

      my $override;

      if (!length($spec->{override_id}) or uc($spec->{override_id}) eq 'NULL'){
	    $override = undef;
      }else{
	    $override = [ 'd' => $spec->{override_id} ];
      }

      my %where = (
		   handle      => $spec->{handle},
		   override_id => $override
		  );

      my $dbrh = $self->{conf_instance}->connect or die "Failed to connect to config db";

      my $enum = $dbrh->select(
			       -table => 'enum',
			       -fields => 'enum_id handle name override_id',
			       -where  => \%where,
			       -single => 1,
			      );
      defined $enum or die "Failed to select from enum";

      my $enum_id;
      my $map;
      if($enum){
	    $enum_id = $enum->{enum_id};
	    $dbrh->update(
			  -table => 'enum',
			  -fields => { name    => $spec->{name} },
			  -where  => { enum_id => ['d', $enum->{enum_id} ] },
			  -single => 1,
			 ) or die "Failed to update enum";

	    $map = $dbrh->select(
				 -table => 'enum_map',
				 -fields => 'row_id field_id enum_id sortval',
				 -where  => {
					     enum_id  => [ 'd', $enum_id         ],
					     field_id => [ 'd', $field->field_id ]
					    },
				 -single => 1,
				);
	    defined ($map) or die "Failed to select from enum_map";
      }else{
	    $enum_id = $dbrh->insert(
				     -table => 'enum',
				     -fields => {
						 handle      => $spec->{handle},
						 override_id => $override,
						 name        => $spec->{name}
						},
				    ) or die "Failed to insert into enum";
      }



      if($map){
	    $dbrh->update(
			  -table => 'enum_map',
			  -fields => { sortval => ['d',$sortval] },
			  -where  => { row_id => ['d', $map->{row_id} ] },
			 ) or die "Failed to update enum_map";
      }else{
	    $dbrh->insert(
			  -table => 'enum_map',
			  -fields => {
				      enum_id  => [ 'd', $enum_id         ],
				      field_id => [ 'd', $field->field_id ],
				      sortval  => [ 'd', $sortval         ]
				     },
			 ) or die "Failed to insert into enum";
      }

      return 1;
}


sub parse_file{
      my $self = shift;
      my $filename = shift;
      open (my $fh, "<$filename") or die "Failed to open $filename";
      my @out;
      while( my $line = <$fh>){
	    $self->_parse_line(\@out,$line);
      }

      return \@out;
}

sub _parse_line{
      my $self = shift;
      my $out = shift;
      my $line = shift;
      chomp $line;

      next if $line =~ /^\s*\#/; # skip comments

      my @parts = split(/\t/,$line);
      return 1 unless @parts;

      my %params;
      foreach my $part (@parts){
	    my ($field,$value) = $part =~ /^(.*?)\s*\=\s*(.*)$/;

	    if ( length($field) ){
		  $params { lc($field) } = $value;
	    }
      }
      if (%params){ # did we get anything?
	    push @$out, \%params;
      }

      return 1;
}


1;
