package DBIx::XML::DataLoader::DB;

use strict;
use warnings;



###########################################################################
## Description of Subs
###########################################################################
##
##  DBConnect
##
##  requires no arguments
##  returns a db connection handle
##
##  DBprepareOut
##
## arguments for this sub are the table name a array ref to the columns, 
## and the variable holding the db connection
## This sub then returns the statement handle for doing the select
##
##
###########################################################################
###########################################################################

use DBI;                    # DataBase Interface Modlule

#use DBD::Oracle;            # Oracle Specific Driver for DBI

## I am just trying to load all the DBD drivers available
## you might want to limit this in some way.
my @driver_names = DBI->available_drivers;
for my $drv (@driver_names){
eval "use DBD::$drv;"; # loading available driver
}
      

##################
sub new{
########
my $class=shift;
my $self={};
my %args=@_;
my $dbmode=$args{dbmode}||"insertupdate";
my $dbprint=$args{dbprint}||undef;
$self->{dbprint}=$dbprint;
$self->{dbmode}=$dbmode;
bless ($self, $class);
#######
} # end sub new
##################

#####################
sub DBConnect{
##############
##  requires no arguments
##  returns a db connection handle

my $self =shift;
my $DBLOG = shift;
my $DBPWD= shift;
my $DATA_SOURCE=shift;

#print $self, "+", $DBLOG, "-", $DBPWD, "[",$DATA_SOURCE,"]";
#if(!$DATA_SOURCE){die "did not get a datasource";}
# Connect to the database with auto-commit enabled
my $dbh = DBI->connect($DATA_SOURCE, $DBLOG, $DBPWD, {
    PrintError => 0,
    AutoCommit => 1,
}) || die "Could not Connect to Database! Oracle Error was: $DBI::errstr\n";

return($dbh);
############
} # end sub DBConnect;
###############################



##############################
sub DBInsertUpdate{
##################
my $self=shift;

my %args=@_;
my $dbprint=$args{dbprint}||$self->{dbprint}||undef;
my $dbmode=$args{dbmode}||$self->{dbmode}||"insertupdate";

my $dbhstuff=$args{dbconnections};
my @arrayoftableinfo=@{$args{datainfo}};
my $message;
my $error;
my $sqlload;
TABLE: for my $tabinfo (@arrayoftableinfo){
my $update;
my @upkeys;
my @insert_vals;
my @insert_cols;
my @update;
my @upkeystring;
my $results=$tabinfo->{results};
my @thecols=@{$tabinfo->{cols}};
my $table=$tabinfo->{table};

@{$sqlload->{$table}->{cols}}=@thecols;
#### added to order update keys
####
my @hashed_upkeys=@{$tabinfo->{keys}};
my $keyorder=1;
HASHED_KEYS:for (@hashed_upkeys){
for my $key (keys %{$_}){
#print $key, ":", $_->{$key},":",$keyorder,"\n";
if($key == $keyorder){
push @upkeys, $_->{$key};
$keyorder++;next HASHED_KEYS;
}
push @hashed_upkeys, $_;
} # end keylop
} # end loop HASHED_KEYS
##################################################
my @results=@{$results};
my $dbh=$dbhstuff->{$tabinfo->{dbname}};
if($dbh !~ /DBI::/){next TABLE;}
for my $result (@results){
my $q_value=$result->{val};

if(($result->{val} ne "SYSDATE")and($dbmode ne "sqlloader")){
#$q_value=qq[\'$result->{val}\'];}
$q_value=$dbh->quote($result->{val});}
push @insert_cols, $result->{col};
push @insert_vals, $q_value;
if($result->{key}){
my $upk=$result->{col}."=".$q_value;
push @upkeystring, $upk;
}
if((!$result->{key})and($result->{col} !~ /^CREATE/)){
my $up=$result->{col}."=".$q_value;
push @update, $up;}
} # end for @results;

my $updateset=join ", ", @update;
my $upkeysstring=join " and ", @upkeystring;
my $inscols=join ", ", @insert_cols;
my $insertstuff=join ", ", @insert_vals; 

if(($dbprint eq "print")or($dbprint eq "dbandprint")){
$message.="\nHere is what would be placed in the table $table\n";
if($dbmode =~ /update/){
$message.= "UPDATE $table SET\n".$updateset. "\nWHERE\n". $upkeysstring."\n";
}
if($dbmode =~ /insert/){
$message.="\nINSERT\n(".$insertstuff.")\nVALUES\n(".$inscols.")\nINTO $table\n";
}
}

if($dbprint ne "print"){
if($dbmode eq "insertupdate"){
$message.="\nAttempting to insert into table $table\n";

my  $local_error;
$dbh->do(qq{insert INTO $table ($inscols) VALUES($insertstuff)})
or $local_error=$DBI::errstr;
if(!$local_error){$message .= "\nInsert was successful for table $table\n";}
if($local_error){
$message.="\nInsert did not succeed. Now trying to update table $table instead\n";
if($local_error =~ /unique constraint/){
$dbh->do(qq{update $table set $updateset where $upkeysstring})
or my $uperror="db error when working with table $table:\n$DBI::errstr\n";
if(!$uperror){$message.="\nUpdate did succeed for Table $table";}
if($uperror){$error.=$uperror;}
}
if($local_error !~ /unique constraint/){
$error.="db error when working with table $table:\n$local_error\n";
}
}
}
if($dbmode eq "update"){
$message.="\nAttempting to make updates in table $table\n";
$dbh->do(qq{update $table set $updateset where $upkeysstring})
or
my $uperror="db error when working with table $table:\n$DBI::errstr\n";
if(!$uperror){$message.="\nUpdate did succeed for Table $table";}
if($uperror){$error.=$uperror;}

}
if($dbmode eq "insert"){
$message.="\nAttempting to insert rows in table $table\n";
$dbh->do(qq{insert INTO $table ($inscols) VALUES($insertstuff)})
or
my $inerror="db error when working with table $table:\n$DBI::errstr\n";
if(!$inerror){$message.="\nInsert was successful for Table $table";}
if($inerror){$error.=$inerror;}

}
if($dbmode eq "sqlloader"){
$message.="\nAdding to sqlload for table $table\n";
$sqlload->{$table}->{values}.=(join "::", @insert_vals)."::\n";
}
}
}
 # end for $tabinfo

return ($message, $error, $sqlload);
######################
} # end DBInsertUpdate
#######################################

###############
sub sqldate{
###########
## this sub take 4 arguments passed as variables
## $dbh a open db handle
## $date which should be the actual date you want converted
## $format the current format the date helf in $date is in (yy-mm-dd yyyy-mm-dd dd-mm-yy etc)
## $table a valid table in your sql view
##  returned is a date that will conform to the SQL database format for dates
my $self=shift;
if((scalar @_) < 4){return;}
my $dbh=shift;
my $date=shift;
my $format=shift;
my $table=shift;
my $qdate=$dbh->quote($date);
my $qformat=$dbh->quote($format);
my $converted_date;
my $datekey=qq{TO_DATE($qdate, $qformat)};
my $datetest=$dbh->prepare(qq{select UNIQUE $datekey from $table})||warn "dbi error  $DBI::errstr";
#my $datetest=$dbh->prepare(qq{select UNIQUE SYSDATE from rod_trans_request});
#if($datetest){
$datetest->execute()||warn "dbi error  $DBI::errstr";;
while(my $hash_ref=$datetest->fetchrow_hashref()){
for (keys %{$hash_ref}){
$converted_date=$hash_ref->{$_};last;}
#}
}
return $converted_date;
############
} # end sqldate
#################


###############
sub conv_sqldate{
###########
## this sub take 4 arguments passed as variables
## $dbh a open db handle
## $date which should be the actual date you want converted
## $format the current format the date helf in $date is in (yy-mm-dd yyyy-mm-dd dd-mm-yy etc)
## $table a valid table in your sql view
##  returned is a date that will conform to the SQL database format for dates
my $self=shift;
if((scalar @_) < 4){return;}
my $dbh=shift;
my $date=shift;
my $format=shift;
my $table=shift;

my $org_format="DD-MON-YY";
my $qorg_format=$dbh->quote($org_format);
my $qdate=$dbh->quote($date);
my $qformat=$dbh->quote($format);
my $converted_date;
my $datekey=qq{TO_DATE($qdate, $qorg_format)};
## here we first alter the way time is outputted
my $datetest=$dbh->prepare(qq{alter session set nls_date_format=$qformat})||warn "dbi error  $DBI::errstr";
$datetest->execute()||warn "dbi error  $DBI::errstr";

$datetest=$dbh->prepare(qq{select UNIQUE $datekey from $table})||warn "dbi error  $DBI::errstr";
#my $datetest=$dbh->prepare(qq{select UNIQUE SYSDATE from rod_trans_request});
#if($datetest){
$datetest->execute()||warn "dbi error  $DBI::errstr";;
while(my $hash_ref=$datetest->fetchrow_hashref()){
for (keys %{$hash_ref}){
$converted_date=$hash_ref->{$_};last;}
#}

}

$datetest=$dbh->prepare(qq{alter session set nls_date_format=$qorg_format})||warn "dbi error $DBI::errstr";
$datetest->execute()||warn "dbi error  $DBI::errstr";

return $converted_date;

##############
} # end conv_sqldate
#######################

1;


__END__


=head1 NAME

	DBIx::XML::DataLoader::DB


=head1 SYNOPSIS

	use DBIx::XML::DataLoader::DB;
	my $db=DB->new(dbmode=>"insertupdate", dbprint=>"dbprint");
	
	my $dbh=$db->DBConnect($DBLOG, $DBPASS, $DATA_SOURCE);

		
	my ($response, $error,$load)=$db->DBInsertUpdate(
			datainfo=>\@inserts_data, 
			dbconnections=>$db_connections
			);

=head1 DESCRIPTION

	This module is hard coded for use with oracle. To change this setting edit the line 
	use DBI::Oracle to reflect your database choice 

=for man	
	This module is used primarily inside DataLoader.pm . It is also used in the sample script query_db.pl

=for text	
	This module is used primarily inside DataLoader.pm . It is also used in the sample script query_db.pl

=for html	
<pre>
       This module is used primarily inside DataLoader.pm. It is also used in the sample 
       script query_cb.pl</pre>

	DBInsertUpdate needs passed to a hash containing a arrayref to a array 
	of hashes containing the data that will be worked with, and dbconnections 
	a hashref to a hash of dbconnections keyed by handle names. 

	The hashes contained in the array of data should have the folowing keys
		cols: a array of the columns that are in this table
		table: the name of the table for this data
		keys: the key columns in the table
		results: a array of row hashes containing the data for each cell 
			in the a table row. The hashes are keyed by column name. 
		dbname: the name of the db handle that will be used.

	The hash containing the dbconnections contains blessed db connection objects keyed
	by handle names.

	The items returned by the module are message, errors, and load(if dbmode=>"sqlloader");
		
	

=head1 Options 
	
	These are the options you can pass to DB.pm
	
	
	dbmode:  Options are 
			insertupdate: attempts to do a update and if that fails, a insert 
				      is done
			insert: attempts to do a insert only
			update: attempts to do a update only
			sqlloader: passes back a extra varibale that will contain data 
				   suitable for writing to a file for use with sqlloader
			
		default is insertupdate

	dbprint: Options are
	
			db: tells the module to do the selected dbmode
			print: simulate doing the dbmode, and add to $response the 
			       statements that would have been passed to the database
			dbandprint: do both the operations above.

		default is db


=head1 Also see man page for

=for html 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="XMLWriter.html">DBIx::XML::DataLoader::XMLWriter</a>,&nbsp and <a
href="DataLoader.html">DBIx::XML::DataLoader<a/>


=for man 
	DBIx::XML::DataLoader::XMLWriter and DBIx::XML::DataLoader

=for text 
	DBIx::XML::DataLoader::XMLWriter and DBIx::XML::DataLoader

=head1 Sample Scripts

=for man query_db.pl

=for text query_db.pl

=for html
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;



=for html
<p><hr><p><p><P>

