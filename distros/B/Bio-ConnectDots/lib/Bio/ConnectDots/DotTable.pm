package Bio::ConnectDots::DotTable;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
#use lib "/users/ywang/temp";
use Bio::ConnectDots::Connector;
use Bio::ConnectDots::Dot;
use Bio::ConnectDots::DotQuery;
use Bio::ConnectDots::DotQuery::InnerCt;
use Bio::ConnectDots::DotQuery::InnerCs;
use Bio::ConnectDots::DotQuery::OuterCt;
use Bio::ConnectDots::DotQuery::OuterCs;
use Class::AutoClass;
use HTML::Entities;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(db db_id connectdots name outputs alias2info preview preview_limit);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=(query_type=>'inner',input_type=>'ConnectorTable');
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->alias2info || $self->alias2info({});
  my $cd=$self->connectdots;
  $self->throw("Required parameter -name missing") unless $self->name;
  $self->throw("Required parameter -connectdots missing") unless $cd;
  my($drop,$create,$query)=$args->get_args(qw(drop create query));
  Bio::ConnectDots::DB::DotTable->drop($self) if $drop || $create;
	$self->preview($args->get_args('preview'));
 	$self->preview_limit(500);

  my $saved=Bio::ConnectDots::DB::DotTable->get($self,$cd);
  if ($saved) {		    # copy relevant attributes from db object to self
    $self->throw("DotTable ".$self->name." already exists") if $query;
    $self->db_id($saved->db_id);
    $self->alias2info($saved->alias2info);
  }
  $self->query($query) if $query;

}
sub dotsets {
  my($self)=@_;
  my @dotsets;
  foreach my $alias (keys %{$self->{alias2info}}) {
  	push @dotsets, $self->{alias2info}->{$alias}->{dotset};
  }
  wantarray? @dotsets: \@dotsets;
}
sub put {
  my($self)=@_;
  Bio::ConnectDots::DB::DotTable->put($self);
}

sub query {
  my($self,$args)=@_;
  if ($self->db_id) {
    $self->throw("Connectortable ".$self->name." already exists. Use -create to overwrite")
      unless $args->create;
    Bio::ConnectDots::DB::DotTable->drop($self); 
  }
  my $query_type=$args->query_type || $self->DEFAULTS_ARGS->query_type;
  my $input_type=$args->input_type || $self->DEFAULTS_ARGS->input_type;
  $self->throw("Unrecognized query type: $query_type") unless $query_type=~/inner|full|outer/i;
  $self->throw("Unrecognized input type: $input_type") unless $input_type=~/table|set/i;
  $args->set_args(-dottable=>$self);
  # create correct query object for query_type and input_type
  my $query;
  if ($query_type=~/inner/i && $input_type=~/table/i) {
    $query=new Bio::ConnectDots::DotQuery::InnerCt($args);
  } elsif ($query_type=~/inner/i && $input_type=~/set/i) {
    $query=new Bio::ConnectDots::DotQuery::InnerCs($args);
  } elsif ($query_type=~/full|outer/i && $input_type=~/table/i) {
    $query=new Bio::ConnectDots::DotQuery::OuterCt($args);
  } elsif ($query_type=~/full|outer/i && $input_type=~/set/i) {
    $query=new Bio::ConnectDots::DotQuery::OuterCs($args);
  }
  $query->execute;
  $self->outputs($query->outputs);
  $self->put;

  # copy to outfile 
  my $outfile_name = $args->get_args('outfile');
  $self->output_file($outfile_name) if $outfile_name;
    
  # check for collapse
  my $collapse = $args->get_args('collapse');
  my $delimiter = $args->get_args('collapse_seperator');
  $self->collapse($collapse,$delimiter) if $collapse;
  
  # check for XML output
  my $xml_file = $args->get_args('xml_file');
  my $xml_root = $args->get_args('xml_root');
  
  if($xml_file && $xml_root) { # collapse xml
	$self->output_xml($xml_file,$xml_root);
  } elsif ($xml_file) { # by row xml
  	$self->xml_rows($xml_file);  
  }
}

### outputs the table to a flat file
sub output_file {
	my ($self, $filename) = @_;
	my $tablename = $self->name;
	$self->{db}->do_sql("COPY $tablename TO '$filename'");	
}

### collapses all rows into one on the given identifier
sub collapse {
	my ($self, $centric, $delimiter) = @_;
	my $db = $self->{db};
	my $dbh = $self->{db}->dbh();
	my $name = $self->name;
	$delimiter = ',' if !$delimiter;
	my $centricIdx = -1;
	my $outlists = []; # lists on column of identifiers
	
	# get the column names for the table and find column number for centric
	my @columns;
	my $i=0;
	foreach my $output (@{$self->outputs}) { 
		push @columns, $output->{output_name};
		$centricIdx = $i if $output->{output_name} eq $centric;
		$i++;
	} 

	$self->throw ("Unknown column in collapse option: $centric") if $centricIdx == -1; # centric column not found.
	my $tmp_name = '__'. $name .'_temp';
	$db->do_sql("DROP TABLE $tmp_name") if $db->table_exist($tmp_name);
	$db->do_sql("SELECT * INTO $tmp_name FROM $name LIMIT 1"); # create temp table with identical columns
	$db->do_sql("TRUNCATE TABLE $tmp_name");

	my $iterator = $dbh->prepare("SELECT * FROM $name ORDER BY $centric");
	$iterator->execute();
	my $currentID;
	while (my @cols = $iterator->fetchrow_array()) {
		next unless @cols;
		if($cols[$centricIdx] ne $currentID && defined($currentID)) { # clear out lists and insert row
			$self->_collapse_insert($outlists,$tmp_name,$centricIdx,$delimiter);
			$outlists = [];
		}
			
		# add columns to lists
		for(my $c=0; $c<@cols; $c++) { # push identifiers onto their columns
			$outlists->[$c]->{$cols[$c]} = 1;
		}
		
		$currentID = $cols[$centricIdx];			
	}
	$self->_collapse_insert($outlists,$tmp_name,$centricIdx,$delimiter); # insert last case
	
	$db->do_sql("DROP TABLE $name");
	$db->do_sql("ALTER TABLE $tmp_name RENAME TO $name");
}

# form lists into an insert statement and insert it into tmp_table
sub _collapse_insert {
	my ($self,$outlists, $tmp_name,$centricIdx,$delimiter) = @_;	
	my $db = $self->{db};
	return unless $outlists->[0];
	my $sql = "INSERT INTO $tmp_name VALUES(";
	my $i=0;
	foreach my $val_list (@$outlists) {
		if($i == $centricIdx) {
			my ($id) = keys %{$val_list};
			$sql .= "'". $id ."',";	
		}
		else {
			my $addstr;
			foreach my $val (keys %{$val_list}) {
				$addstr .= $val . $delimiter unless $val eq '';
			}
			if($addstr) { # cleanup extra delimiter
				$addstr = substr($addstr,0,length($addstr)-length($delimiter));
				$sql .= "'". $addstr ."',";
			}
			else {
				$sql .= "'". "',";					
			}
		}	
		$i++;
	}
	chop($sql); # remove extra comma
	$sql .= ")";
	$db->do_sql($sql);
	
}

sub output_xml {
	my ($self, $xml_file, $xml_root) = @_;
	$self->throw("You must define -xml_file to output data to XML.") if !$xml_file;
	$self->throw("You must define -xml_root to output data to XML.") if !$xml_root;

	open(OUT, ">$xml_file") or $self->throw("Can not open output xml_file: $xml_file");

	my $db = $self->{db};
	my $dbh = $self->{db}->dbh();
	my $name = $self->name;
	my $rootIdx = -1;
	
	# get the column names for the table and find column number for centric
	my @columns;
	my @internal_tags;
	my $i=0;
	foreach my $output (@{$self->outputs}) { 
		push @columns, $output->{output_name};
		if ($output->{output_name} eq $xml_root) {
			$rootIdx = $i;
		} else {
			push @internal_tags, $output->{output_name} 
		}
		$i++;
	} 
	$self->throw ("Unknown column as XML output root: $xml_root") if $rootIdx == -1; # root column not found.

	# create the DTD
	my $DTD = "<!DOCTYPE DotTable [";
	$DTD .= "<!ELEMENT DotTable ($xml_root*)>";
	$DTD .= "<!ATTLIST DotTable name CDATA #REQUIRED>";
	$DTD .= "<!ELEMENT $xml_root (". join('*,',@internal_tags) ."*)>";
	$DTD .= "<!ATTLIST $xml_root id CDATA #REQUIRED>";
	foreach my $tagname (@internal_tags) {
		$DTD .= "<!ELEMENT $tagname (#PCDATA)>";
	}
	$DTD .= "]>\n";	
	print OUT $DTD;	

	print OUT "<DotTable name='$name'>\n";

	# iterate over the ids and output XML
	my $sql = "SELECT $xml_root,". join(',',@internal_tags) ." FROM $name ORDER BY $xml_root";
	my $iterator = $dbh->prepare($sql);
	$iterator->execute();
	my $currentID;
	my $outcols;
	while (my @cols = $iterator->fetchrow_array()) {
		if($cols[0] ne $currentID && defined($currentID)) { # close out tags and start new tag
			my $entry = _create_xml_entry($outcols,\@internal_tags,$xml_root,$currentID);
			print OUT $entry;
			$outcols = [];
		}
		
		# save data by column for this id
		for(my $i=1; $i<@cols; $i++) {
			$outcols->[$i-1]->{$cols[$i]} = 1;
		}
			
		$currentID = $cols[0];
	}
	my $entry = _create_xml_entry($outcols,\@internal_tags,$xml_root,$currentID);
	print OUT $entry;

	print OUT "</DotTable>";
	close(OUT);
}

# returns an xml entry based off the structure of the passed in ...
sub _create_xml_entry {
	my ($outcols, $internal_tags, $xml_root, $keyid) = @_;
	return unless $outcols && defined($keyid);
	$keyid = _encode($keyid);
	my $entry;
	$entry = "<$xml_root id='$keyid'>";
	for(my $c=0; $c<@$outcols; $c++) {
		my $hash = $outcols->[$c];
		my $tag = $internal_tags->[$c];
		foreach my $data (keys %$hash) {			
			$data = _encode($data);
			$entry .= "<$tag>$data</$tag>" if $data;
		}
	}
	$entry .= "</$xml_root>\n";
	return $entry;	
}



# exports xml by row
sub xml_rows {
	my ($self, $xml_file) = @_;
	$self->throw("You must define -xmlrows_file to output data to XML.") if !$xml_file;

	open(OUT, ">$xml_file") or $self->throw("Can not open output xml_file: $xml_file");

	my $db = $self->{db};
	my $dbh = $self->{db}->dbh();
	my $name = $self->name;

	# get the column names for the table and find column number for centric
	my @columns;
	foreach my $output (@{$self->outputs}) { 
		push @columns, $output->{output_name};
	}

	# create the DTD
	my $DTD = "<!DOCTYPE DotTable [";
	$DTD .= "<!ELEMENT DotTable (row*)>";
	$DTD .= "<!ATTLIST DotTable name CDATA #REQUIRED>";
	$DTD .= "<!ELEMENT row (". join('*,',@columns) ."*)>";
	$DTD .= "<!ATTLIST row line CDATA #REQUIRED>";
	foreach my $tagname (@columns) {
		$DTD .= "<!ELEMENT $tagname (#PCDATA)>";
	}
	$DTD .= "]>\n";	
	print OUT $DTD;	
	print OUT "<DotTable name='$name'>\n";

	my $sql = "SELECT ". join(',',@columns) ." FROM $name";
	my $iterator = $dbh->prepare($sql);
	$iterator->execute();
	my $linenum=1;
	while (my @cols = $iterator->fetchrow_array()) {
		my $entry = "<row line='$linenum'>";
		for (my $i=0; $i<@cols; $i++) {
			my $tag = $columns[$i];
			my $data = _encode($cols[$i]);
			$entry .= "<$tag>$data</$tag>" if defined($cols[$i]);
		}
		$entry .= "</row>\n";
		print OUT $entry;
		$linenum++;			
	}

	print OUT "</DotTable>\n";
	close(OUT);	
}

sub _encode() {
	my ($string) = @_;
	$string = encode_entities($string);
	$string =~ s/\'/&apos;/g;
	return $string;
}

1;

















