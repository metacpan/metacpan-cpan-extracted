package Bio::ConnectDots::DB;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use DBI;
use File::Path;
use Class::AutoClass;
use Class::AutoClass::Args;
use Bio::ConnectDots::DotSet;
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(dsn dbh dbd database host port user password 
		    read_only read_only_schema
		    _needs_disconnect _db_cursor _exists
		    load_name load_save load_chunksize load_cid_base
		    _ext_directory _load_fh _load_count _load_chunk sql_log
		   );
@OTHER_ATTRIBUTES=qw(ext_directory);
%SYNONYMS=(server=>'host');
Class::AutoClass::declare(__PACKAGE__);

# use 'double quotations to get case-sensitivity in label
# use 'not null' wherever possible to help query optimizier use indexes better
# denormalized connector to cut down the number of joins in big queries
my %SCHEMA=
  (connectorset=>
   qq(connectorset_id SERIAL,
      "name" VARCHAR(255) NOT NULL,
      "file_name" TEXT,
      "version" VARCHAR(255) NOT NULL,
      "source_date" VARCHAR(255),
      "source_version" VARCHAR(255),
      "download_date" VARCHAR(255),
      "ftp" TEXT,
      "ftp_files" TEXT,
      "comment" TEXT,
      PRIMARY KEY("connectorset_id"),UNIQUE("name","version")),
   dotset=>
   qq(dotset_id SERIAL,
      "name" VARCHAR(255) NOT NULL,
      PRIMARY KEY(dotset_id),UNIQUE("name")),
   connectdotset=>
   qq(connectdotset_id SERIAL,
      connectorset_id INT NOT NULL,
      dotset_id INT NOT NULL,
      label_id INT NOT NULL,
      PRIMARY KEY(connectdotset_id)),
   label=>
   qq(label_id SERIAL,
      "label" VARCHAR(255) NOT NULL,
			"source_label" VARCHAR(255),
      "description" TEXT,      
      PRIMARY KEY(label_id),UNIQUE("label")),
   connectortable=>
   qq(connectortable_id SERIAL,
      "name" VARCHAR(255) NOT NULL,
      PRIMARY KEY(connectortable_id),UNIQUE("name")),
   connectortableset=>
   qq(connectortable_id INT NOT NULL,
      connectorset_id INT NOT NULL,
      "alias" VARCHAR(255) NOT NULL,
      UNIQUE(connectortable_id,"alias")),
   dottable=>
   qq(dottable_id SERIAL,
      "name" VARCHAR(255) NOT NULL,
      PRIMARY KEY(dottable_id),UNIQUE("name")),
   dottableset=>
   qq(dottable_id INT NOT NULL,
      dotset_id INT NOT NULL,
      label_id INT NOT NULL,
      cs_id INT NOT NULL,
      "alias" VARCHAR(255) NOT NULL,
      UNIQUE(dottable_id,"alias")),

   connectdot=>
   qq(connector_id INT NOT NULL,
      connectorset_id INT NOT NULL,
      dot_id INT NOT NULL,
      label_id INT NOT NULL,
      "id" TEXT NOT NULL),      
   dot=>
   qq(dot_id SERIAL,
      dotset_id INT NOT NULL,
      "id" TEXT NOT NULL,
      PRIMARY KEY(dot_id),UNIQUE("id",dotset_id)),  

   cdload=>
   qq(connector_id INT NOT NULL,
      connectorset_id INT NOT NULL,
      dotset_id INT NOT NULL,
      label_id INT NOT NULL,
      "id" TEXT NOT NULL),
  );

my %INDICIES = (
	connectdot=>
	['connectorset_id,connector_id,label_id', 
	 'connectorset_id,dot_id,label_id',
	 'connectorset_id,label_id',
	 '"id"']
);

my @INDEX_NAMES;

my @TABLES=keys %SCHEMA;
# maximum number of rows loaded in one 'load infile' operation
my $LOAD_CHUNKSIZE=150000;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->_connect;
  return unless $self->is_connected;
  $self->_manage_schema($args);
	if(!$self->ext_directory) {
	 $self->ext_directory("/usr/tmp/$ENV{USER}") if $ENV{USER};
	}
  $self->load_chunksize or $self->load_chunksize($LOAD_CHUNKSIZE);
}

sub is_connected {
	$_[0]->dbh;
}

sub connect {
  my($self,@args)=@_;
  my $args=new Bio::ISB::AutoArgs(@args);
  $self->Class::AutoClass::set_attributes([qw(dbh dsn dbd host server user password)],$args);
  $self->_connect;
}
sub _connect {
  my($self)=@_;
  return $self->dbh if $self->dbh;		# if dbh set, then already connected
  my $dbd=lc($self->dbd)||'Pg';
  $self->throw("-dbd must be 'Pg' at present") if $dbd && $dbd ne 'Pg';
  my $dsn=$self->dsn;
  if ($dsn) {			# parse off the dbd, database, host elements
    $dsn = "DBI:$dsn" unless $dsn=~ /^dbi/i;
  } else {
    my $database=$self->database;
    my $host=$self->host;
    my $port=$self->port;
    return undef unless $database;
    $dsn="DBI:$dbd:dbname=$database;";
    $dsn .= "host=$host;" if $host;
    $dsn .= "port=$port;" if $port;
  }
  # Try to establish connection with data source.
  my $user=$self->user;
  my $password = $self->password;
  my $dbh = DBI->connect($dsn,$user,$password,
			 {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, Warn=>0,});
  $self->dsn($dsn);
  $self->dbh($dbh);
  $self->_needs_disconnect(1);
  $self->throw("DBI::connect failed for dsn=$dsn, username=$user: ".DBI->errstr) unless $dbh;
  return $dbh;
}
sub _manage_schema {
  my($self,$args)=@_;
  # grab schema modification parameters
  my $read_only_schema=$self->read_only_schema || $self->read_only;
  my $drop=$args->drop;
  my $create=$args->create;
  $self->throw("Schema changes not allowed by -read_only or -read_only_schema setting") if ($drop||$create) && $read_only_schema;
  $self->drop if $drop;
  $self->create if $create || !($self->exists && !defined $create);
}

# returns 1 if all tables exist, -1 if some exist, 0 if none exist
# note that Perl treats -1 as 'true' 
sub exists {
  my($self,$doit)=@_;
  return $self->_exists if !$doit && defined $self->_exists;
  $self->throw("Cannot check schema: database is not connected") unless $self->is_connected;
  my $dbh=$self->dbh;
  my $tables=$dbh->selectall_arrayref(qq(select tablename from pg_tables where schemaname='public'));
  my $count;
  for my $table (@TABLES) {
    $count++ if grep {$table eq $_->[0]} @$tables;
  }
  my $exists;
  $exists=0 if $count==0;
  $exists=1 if $count==@TABLES;
  $exists=-1 if $count>0 && $count!=@TABLES;
  $self->_exists($exists);
}
sub drop {
  my $self=shift;
  $self->throw("Cannot drop database: database is not connected") unless $self->is_connected;
  my @sql;
  foreach my $tbl (@TABLES) {
  	push ( @sql, qq(DROP TABLE $tbl) ) if table_exist($tbl);
  }
  foreach my $indx (@INDEX_NAMES) {
  	push(@sql, qq(DROP INDEX $indx));

  }
  $self->do_sql(@sql);
  $self->exists('DOIT');	# make sure schema was really dropped
}

### Returns true (1) if table exists in database, 0 otherwise
sub table_exist {
	my ($self, $table_name)=@_;
	$self->throw("Cannot create database: database is not connected") unless $self->is_connected;
	$table_name = lc($table_name); 
	my $query = "SELECT tablename FROM pg_tables WHERE tablename='$table_name'";
	my $dbh=$self->dbh;
	my $rslt = $dbh->selectrow_arrayref($query);
	return $rslt ? 1 : 0;
}

sub create {
  my $self=shift;
  $self->throw("Cannot create database: database is not connected") unless $self->is_connected;
  $self->drop if $self->exists;
  my @sql;
  while(my($table,$schema)=each %SCHEMA) {
    push(@sql,qq(CREATE TABLE $table ($schema)));
    if ($INDICIES{$table}) {
		my $num=0;
    	foreach my $tbl_index (@{ $INDICIES{$table} }) {
    		my $index_name = $table .'_index_'. ($num+1);
    		push( @INDEX_NAMES, $index_name );
    		$INDICIES{$table}->[$num] eq 'id'? 
    			push( @sql, qq(CREATE INDEX $index_name ON $table USING BTREE ($INDICIES{$table}->[$num])) ) :
	    		push( @sql, qq(CREATE INDEX $index_name ON $table ($INDICIES{$table}->[$num])) );	
    		$num++;
    	}
    }
  }
  $self->do_sql(@sql);
  $self->exists('DOIT');	# make sure schema was really created
}
sub analyze {
  my $self=shift;
  $self->throw("Cannot analyze database: database is not connected") unless $self->is_connected;
  my @sql=map {qq(ANALYZE $_)} @TABLES;
  $self->do_sql(@sql);
}
# load dots and connectdots
sub load_init {
  my($self,$load_name,$load_save,$load_chunksize)=@_;
  my $max=$self->dbh->selectrow_array
    (qq(select max(connector_id) from connectdot)) || 0;
  $self->set
    (load_name=>$load_name,
     load_save=>$load_save,
     load_chunksize=>$load_chunksize||$LOAD_CHUNKSIZE,
     load_cid_base=>$max,
     _load_fh=>undef,_load_count=>0,_load_chunk=>0);
}
sub load_row {
  my($self,$connector_id,$connectorset_id,$id,$dotset_id,$label_id)=@_;
  my($ext_directory,$load_name,$load_fh,$load_count,$load_chunk)=
    $self->get(qw(ext_directory load_name _load_fh _load_count _load_chunk));
  my $load_file="$ext_directory/load.$load_name.$load_chunk";
  if (!defined $load_fh) {
    open($load_fh, "> $load_file") || $self->throw("Cannot open load file $load_file: $!");
    $self->_load_fh($load_fh);
  } elsif ($load_count>=$self->load_chunksize) {
    close $load_fh;
    $self->load($load_file);
    $load_chunk++;
    $load_count=0;
    my $load_file="$ext_directory/load.$load_name.$load_chunk"; # bug found by YW 04-01-15
    open($load_fh, "> $load_file") || $self->throw("Cannot open load file $load_file: $!");
    $self->set(_load_fh=>$load_fh,_load_chunk=>$load_chunk);
  }
  $connector_id+=$self->load_cid_base;
  $id=$self->escape($id);	# escape special chars
  print $load_fh join("\t",$connector_id,$connectorset_id,$dotset_id,$label_id,$id),"\n";
  $self->_load_count($load_count+1);
}
sub load_finish {
  my($self)=@_;
  my($ext_directory,$load_name,$load_fh,$load_count,$load_chunk)=
    $self->get(qw(ext_directory load_name _load_fh _load_count _load_chunk));
  if (defined $load_fh) {
    close $load_fh;
    my $load_file="$ext_directory/load.$load_name.$load_chunk";
    $self->load($load_file,'last');
  }
}
sub load {
  my($self,$load_file,$last)=@_;
  my $dbh=$self->dbh;
  my @sql;
  push(@sql,
       qq(set enable_hashjoin to off),
       qq(set enable_mergejoin to off));
  push(@sql,			# load data
       qq(COPY cdload (connector_id,connectorset_id,dotset_id,label_id,id) FROM '$load_file'));  
  push(@sql, qq(SELECT cdload.connector_id,cdload.connectorset_id,cdload.dotset_id,dot.dot_id,cdload.label_id,cdload.id 
  							INTO TABLE cdload_dot 
  							FROM cdload LEFT JOIN dot ON cdload.id=dot.id));
  push(@sql,qq(INSERT INTO dot (dotset_id,id) SELECT DISTINCT dotset_id,id FROM cdload_dot WHERE dot_id IS NULL));
  push(@sql,qq(INSERT INTO connectdot (connector_id,connectorset_id,dot_id,label_id,id) 
  						 SELECT connector_id,connectorset_id,dot_id,label_id,id FROM cdload_dot WHERE dot_id IS NOT NULL));
  push(@sql,qq(INSERT INTO connectdot (connector_id,connectorset_id,dot_id,label_id,id) 
  						 SELECT cdload_dot.connector_id,cdload_dot.connectorset_id,dot.dot_id,cdload_dot.label_id,cdload_dot.id 
  						 FROM cdload_dot,dot 
  						 WHERE cdload_dot.dot_id IS NULL AND cdload_dot.id=dot.id));
  push(@sql,qq(DROP TABLE cdload));
  push(@sql,qq(CREATE TABLE cdload ($SCHEMA{'cdload'})));
  push(@sql,qq(DROP TABLE cdload_dot));
  push(@sql,qq(ANALYZE));
  $self->do_sql(@sql);
  $self->do_sql(qq(set enable_hashjoin to on));
  $self->do_sql(qq(set enable_mergejoin to on));
  unlink($load_file) unless $self->load_save eq 'all' || ($last && $self->load_save eq $last) ;
}

sub ext_directory {
  my $self=shift;
  if (@_) {
    my $ext_directory=shift;
    mkpath([$ext_directory]) if $ext_directory;
    return $self->_ext_directory($ext_directory);
  }
  $self->_ext_directory;
}

sub create_table_sql {
  my($self,$name,$sql,$indexed_columns,$sql_columns)=@_;
  $name = lc($name); # Postgres has inconsistent support for capitalization of table names
  my @sql;
  push (@sql, "DROP TABLE $name") if $self->table_exist($name);
  push (@sql, "CREATE TABLE $name AS $sql");
  
  my $num=0;
  foreach (@$indexed_columns) {
  	my $index_name = $name ."_index_".$_ . $num ;
  	push( @INDEX_NAMES, $index_name );
  	push( @sql, qq(CREATE INDEX $index_name ON $name ($_)) );
  	$num++;
  }
  push (@sql, "ANALYZE $name");
  $self->do_sql(@sql);
}


sub create_file_sql {
  my($self,$file,$sql)=@_;
  unlink($file);
#  print "$sql ",`date`;
  my $dbh=$self->dbh;
  $dbh->do($sql) || $self->throw($dbh->errstr);
}
sub do_sql {
  my $self=shift;
  my @sql=_flatten(@_);
  $self->throw("Cannot run SQL: database is not connected") unless $self->is_connected;
  my $dbh=$self->dbh;
  for my $sql (@sql) {
	  if($self->sql_log) {
	  	my $file = $self->sql_log;
	  	open (LOG, ">>$file") or $self->throw("Can not open SQL log file: $file");
	  	print LOG "#", `date`;
	  	print LOG "$sql\n\n";
	  	close(LOG);
	  }
    $dbh->do($sql) || do { print "### SQL: $sql\n"; $self->throw($dbh->errstr); }
  }
}

sub quote {
  my($self,$value)=@_;
  $self->dbh->quote($value);
}
sub quote_dot {
  my($self,$value)=@_;
  $self->dbh->quote($value);  
}

sub escape {
  my($self,$field)=@_;
  my $q_field=$self->dbh->quote($field);
  $q_field=~s/^\'|\'$//g;
  $q_field;
}
sub _flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}



1;
__END__

=head1 NAME

Bio::ConnectDots::DB -- Database adapter for 'connect-the-dots'

=head1 SYNOPSIS

  use Bio::ConnectDots::DB;

  my $db=new Bio::ConnectDots::DB
    (-database=>'test',-host=>'socks',-user=>'ngoodman',-password=>'secret');

=head1 DESCRIPTION

This class manages database connections and encapsulates all database
access for 'connect-the-dots'.

=head1 AUTHOR - David Burdick, Nat Goodman

Email dburdick@systemsbiology.org, natg@shore.net

=head1 COPYRIGHT

Copyright (c) 2005 Institute for Systems Biology (ISB). All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 APPENDIX

The rest of the documentation describes the methods.

=head2 Constructors

 Title   : new
 Usage   : $db=new Bio::ConnectDots::DB
             (-database=>'test',-host=>'socks',-user=>'ngoodman',-password=>'secret');

 Function: Connects to database

 Args    : -database => name of PostgreSQL database to use
           -host => hostname of PostgreSQL database server
           -server => synonym for host
           -user => name of PostgreSQL user
           -password => password of PostgreSQL user

           -ext_directory => directory for temporary files used for loading and fetching data
              default /usr/tmp/<user>, eg, /usr/tmp/ngoodman
           -load_save => controls whether load files are saved after use.  Helpful
              for debugging
              default - files not saved
              'all' -- files are saved
              'last' -- only last file is saved
           -load_chunksize => number of Dots loaded at a time.  Tuning parameter.
              default 100000

 Returns : Bio::ConnectDots::DB object

=head2 Methods to manage database

 Title   : exists
 Usage   : print "Database exists" if $db->exists
 Function: Tells whether the 'connect-the-dots' database exists
 Returns : boolean

 Title   : drop
 Usage   : $db->drop;
 Function: Drop all 'connect-the-dots' tables
 Returns : Nothing
 Note    : Only drops the built-in tables, not the ones created by queries

 Title   : create
 Usage   : $db->create;
 Function: Create all 'connect-the-dots' tables
 Returns : Nothing

 Title   : analyze
 Usage   : $db->analyze;
 Function: Run ANALYZE TABLE on all built-in 'connect-the-dots' tables
 Returns : Nothing

=cut