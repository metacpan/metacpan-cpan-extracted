package Bio::ConnectDots::DB::ConnectDots;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use DBI;
use Bio::ConnectDots::DotSet;
use Bio::ConnectDots::ConnectorSet;
use Bio::ConnectDots::DB::DotTable;
use Bio::ConnectDots::DB::ConnectorTable;
use Bio::ConnectDots::ConnectDots;
@ISA = qw(Class::AutoClass::Root);

# get ConnectDots
sub get {
  my($class,$cd)=@_;
  my $db=$cd->db;
  my ($connectorsets,$dotsets)=$class->get_sets($cd);
  $cd->set(connectorsets=>$connectorsets,dotsets=>$dotsets);
  my $dottables=Bio::ConnectDots::DB::DotTable->get_all($cd);
  my $connectortables=Bio::ConnectDots::DB::ConnectorTable->get_all($cd);
  $cd->set(connectortables=>$connectortables,dottables=>$dottables);
}

# fetch all ConnectorSets, connected DotSets
# return ARRAYs of ConnectorSets, connected DotSets
sub get_sets {
  my($class,$cd)=@_;
  my $db=$cd->db;
  $class->throw("Cannot get data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot get data: database does not exist") unless $db->exists;
  my $dbh=$db->dbh;
  my $sql=qq(SELECT connectorset.connectorset_id,connectorset.name,connectorset.file_name,connectorset.version,connectorset.ftp,connectorset.ftp_files,dotset.dotset_id,dotset.name,label.label_id,label.label
	     FROM connectorset,dotset,connectdotset,label
	     WHERE connectorset.connectorset_id=connectdotset.connectorset_id
	     AND dotset.dotset_id=connectdotset.dotset_id
	     AND label.label_id=connectdotset.label_id
	     ORDER BY connectorset.connectorset_id);
  my $rows=$dbh->selectall_arrayref($sql) or $class->throw($dbh->errstr);
  return undef unless @$rows;	        # no data. 
  my ($id2dotset,$connectorsets);
  my $row=shift @$rows;
  do {
    my ($connectorset_id,$connectorset_name,$connectorset_filename,$version,$ftp,$ftp_files)=@$row;
    my $label2dotset={}; 
    my $label2labelid={}; 
    do {
      my($skip,$skip,$skip,$skip,$skip,$skip,$dotset_id,$dotset_name,$label_id,$label)=@$row;
      my $dotset=$id2dotset->{$dotset_id} || 
	($id2dotset->{$dotset_id}=new Bio::ConnectDots::DotSet
	 (-name=>$dotset_name,-db_id=>$dotset_id,-db=>$db));
      $label2dotset->{$label}=$dotset;
      $label2labelid->{$label}=$label_id;
      $row=shift @$rows;
    } while ($row && $row->[0] == $connectorset_id);
    # end of this connector
    push(@$connectorsets,
	 new Bio::ConnectDots::ConnectorSet
	 (-name=>$connectorset_name,-cs_version=>$version,-ftp=>$ftp,-ftp_files=>$ftp_files,-file=>$connectorset_filename,
	  -db_id=>$connectorset_id,-db=>$db,
	  -dotsets=>$label2dotset,-label2labelid=>$label2labelid));
  } while ($row);
  my($dotsets);
  @$dotsets=values %$id2dotset;
  ($connectorsets,$dotsets);
}


1;
