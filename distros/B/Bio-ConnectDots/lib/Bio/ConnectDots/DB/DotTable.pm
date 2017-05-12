package Bio::ConnectDots::DB::DotTable;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use DBI;
use Bio::ConnectDots::DotTable;
@ISA = qw(Class::AutoClass::Root);

# store one DotTable. store db_id in object
sub put {
  my($class,$dottable)=@_;
  return if $dottable->db_id;	# object is already in database
  my $db=$dottable->db;
  $class->throw("Cannot put data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot put data: database does not exist") unless $db->exists;
  my $name=$dottable->name;
  my $dbh=$db->dbh;
  my $sql=qq(INSERT INTO dottable (name) VALUES ('$name'));
  $db->do_sql($sql);

  my $db_id=$dbh->selectrow_array(qq(SELECT MAX(dottable_id) FROM dottable));
  $dottable->db_id($db_id);
  my $alias2info=$dottable->alias2info;
  foreach my $alias (keys %{$alias2info}) {
	  my @values;
    my $dotset_id = $alias2info->{$alias}->{dotset}->db_id;
    my $label_id = $alias2info->{$alias}->{label_id};
    my $cs_id = $alias2info->{$alias}->{cs_id};
    push(@values,qq(($db_id,$cs_id,$label_id,$dotset_id,'$alias')));
	  my $sql=qq(INSERT INTO dottableset (dottable_id,cs_id,label_id,dotset_id,alias)
		     VALUES ).join(',',@values);
	  $db->do_sql($sql) if $db_id && $cs_id && $label_id && $dotset_id;
  }
  $dottable;
}
# fetch one DotTable. return object.
sub get {
  my($class,$dottable,$cd)=@_;
  return $dottable if $dottable->db_id; # already fetched
  my $db=$cd->db;
  $class->throw("Cannot get data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot get data: database does not exist") unless $db->exists;
  my $name=$dottable->name;
  my $dbh=$db->dbh;
###
  my $sql=qq(SELECT dottable.dottable_id,dottableset.cs_id, dottableset.label_id, dottableset.dotset_id,dottableset.alias  
	     FROM dottable,dottableset
	     WHERE dottable.name='$name'
	     AND dottable.dottable_id=dottableset.dottable_id);
###
  my $rows=$dbh->selectall_arrayref($sql) or $class->throw($dbh->errstr);
  return undef unless @$rows;	        # no data. assume DotTable doesn't exist
  my ($db_id)=@{$rows->[0]};	        # pull DotTable info from first row
  $dottable->db_id($db_id);
###
  my $alias2info=$dottable->alias2info({});
  my $id2dotset=$cd->id2dotset;
  for my $row (@$rows) {
    my($dottable_id,$cs_id,$label_id,$dotset_id,$alias)=@$row;
		$alias2info->{$alias}->{cs_id} = $cs_id;
		$alias2info->{$alias}->{label_id} = $label_id;
    $alias2info->{$alias}->{dotset} = $id2dotset->{$dotset_id};
  }
###
}
# drop DotTable. Drop table and delete information from schema tables
sub drop {
  my($class,$dottable)=@_;
  my $db=$dottable->db;
  $class->throw("Cannot get data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot get data: database does not exist") unless $db->exists;
  my $name=$dottable->name;
  if($db->table_exist($name)) {
	  my $sql= "DROP TABLE $name";
	  $db->do_sql($sql);
  }
  $db->do_sql("DELETE FROM dottable WHERE name='$name'");
  
}

# fetch all DotTables
sub get_all {
  my($class,$cd)=@_;
  my $db=$cd->db;
  $class->throw("Cannot get data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot get data: database does not exist") unless $db->exists;
  my $dbh=$db->dbh;
  my $sql=qq(SELECT dottable.dottable_id,dottable.name,dottableset.cs_id ,dottableset.label_id, 
  								  dottableset.dotset_id,dottableset.alias
	     FROM dottable,dottableset
	     WHERE dottable.dottable_id=dottableset.dottable_id
	     ORDER BY dottable.dottable_id);
  my $rows=$dbh->selectall_arrayref($sql) or $class->throw($dbh->errstr);
  return undef unless @$rows;	        # no data. 
  my $dottables;
  my $row=shift @$rows;
  do {
    my ($dottable_id,$dottable_name)=@$row;
    my $alias2info={}; 
    my $id2dotset=$cd->id2dotset;
    do {
      my($skip,$skip,$cs_id, $label_id,$dotset_id,$alias)=@$row;
      my $dotset=$id2dotset->{$dotset_id} || $class->throw("DotSet with database id $dotset_id not known to ConnectDots object");
			$alias2info->{$alias}->{cs_id} = $cs_id;
			$alias2info->{$alias}->{label_id} = $label_id;      
      $alias2info->{$alias}->{dotset} = $dotset;
      $row=shift @$rows;
    } while ($row && $row->[0] == $dottable_id);
    # end of this dottable
    push(@$dottables,
	 new Bio::ConnectDots::DotTable
	 (-name=>$dottable_name,-alias2info=>$alias2info,-connectdots=>$cd,
	  -db_id=>$dottable_id,-db=>$db)); 
  } while ($row);
  wantarray? @$dottables: $dottables;
}
1;
