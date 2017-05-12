package Bio::ConnectDots::DB::ConnectorTable;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use DBI;
use Bio::ConnectDots::ConnectorTable;
@ISA = qw(Class::AutoClass::Root);

# store one ConnectorTable. store db_id in object
sub put {
  my($class,$connectortable)=@_;
  return if $connectortable->db_id;	# object is already in database

  my $db=$connectortable->db;
  $class->throw("Cannot put data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot put data: database does not exist") unless $db->exists;
  my $name=$connectortable->name;
  my $dbh=$db->dbh;
  my $sql=qq(INSERT INTO connectortable (name) VALUES ('$name'));
  $db->do_sql($sql);
  my $db_id=$dbh->selectrow_array(qq(SELECT MAX(connectortable_id) FROM connectortable));
  $connectortable->db_id($db_id);
  my $column2cs=$connectortable->column2cs;
  my @values;
  while (my($alias,$connectorset)=each %$column2cs) {
    my $connectorset_id=$connectorset->db_id;
    push(@values,qq(($db_id,$connectorset_id,'$alias')));
  }
  my @sql;
  foreach (@values) {
	push (@sql, 'INSERT INTO connectortableset (connectortable_id,connectorset_id,alias) VALUES '. $_);
  }
  $db->do_sql(@sql) if @values;
  $connectortable;
}
# fetch one ConnectorTable. return object.
sub get {
  my($class,$connectortable,$cd)=@_;
  return $connectortable if $connectortable->db_id; # already fetched
  my $db=$cd->db;
  $class->throw("Cannot get data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot get data: database does not exist") unless $db->exists;
  my $name=$connectortable->name;
  my $dbh=$db->dbh;
  my $sql=qq(SELECT connectortable.connectortable_id,connectortableset.connectorset_id,connectortableset.alias
	     FROM connectortable LEFT JOIN connectortableset 
	     ON connectortable.connectortable_id=connectortableset.connectortable_id
	     WHERE connectortable.name='$name');
  my $rows=$dbh->selectall_arrayref($sql) or $class->throw($dbh->errstr);
  return undef unless @$rows;	        # no data. assume ConnectorTable doesn't exist
  my ($db_id)=@{$rows->[0]};	        # pull ConnectorTable info from first row
  $connectortable->db_id($db_id);
  my $column2cs=$connectortable->column2cs({});
  my $id2cs=$cd->id2cs;
  for my $row (@$rows) {
    my($connectortable_id,$connectorset_id,$alias)=@$row;
    next unless defined $connectorset_id && defined $alias;
    $column2cs->{$alias}=$id2cs->{$connectorset_id};
  }
}
# drop ConnectorTable. Drop table and delete information from schema tables
sub drop {
  my($class,$connectortable)=@_;
  my $db=$connectortable->db;
  $class->throw("Cannot get data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot get data: database does not exist") unless $db->exists;
  my $name=$connectortable->name;
  my @sql;
  push (@sql, "DROP TABLE $name") if $db->table_exist($name);

  # allow people to delete the table in the DB manager
  my $connectortable_id = $db->dbh->selectrow_arrayref("SELECT connectortable_id FROM connectortable WHERE name='$name'");
  push (@sql,qq(DELETE FROM connectortable 
  				WHERE connectortable.name='$name' 
  				AND connectortable.connectortable_id=$connectortable_id->[0])) 
  				if $connectortable_id;
  $db->do_sql(@sql);
}

# fetch all ConnectorTables
sub get_all {
  my($class,$cd)=@_;
  my $db=$cd->db;
  $class->throw("Cannot get data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot get data: database does not exist") unless $db->exists;
  my $dbh=$db->dbh;
  my $sql=qq(SELECT connectortable.connectortable_id,connectortable.name,
	     connectortableset.connectorset_id,connectortableset.alias
	     FROM connectortable,connectortableset
	     WHERE connectortable.connectortable_id=connectortableset.connectortable_id
	     ORDER BY connectortable.connectortable_id);
  my $rows=$dbh->selectall_arrayref($sql) or $class->throw($dbh->errstr);
  return undef unless @$rows;	        # no data. 
  my $connectortables;
  my $row=shift @$rows;
  do {
    my ($connectortable_id,$connectortable_name)=@$row;
    my $column2cs={}; 
    my $id2cs=$cd->id2cs;
    do {
      my($skip,$skip,$connectorset_id,$alias)=@$row;
      my $connectorset=$id2cs->{$connectorset_id} || $class->throw("ConnectorSet with database id $connectorset_id not known to ConnectDots object");
      $column2cs->{$alias}=$connectorset;
      $row=shift @$rows;
    } while ($row && $row->[0] == $connectortable_id);
    # end of this connectortable
    push(@$connectortables,
	 new Bio::ConnectDots::ConnectorTable
	 (-name=>$connectortable_name,-column2cs=>$column2cs,-connectdots=>$cd,
	  -db_id=>$connectortable_id,-db=>$db)); 
  } while ($row);
  wantarray? @$connectortables: $connectortables;
}


1;
