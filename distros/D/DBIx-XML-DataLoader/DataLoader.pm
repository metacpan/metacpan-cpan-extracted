package DBIx::XML::DataLoader;
my $VERSION="1.0b";


use warnings;
use strict;

use XML::XPath;
use LWP::UserAgent;
use Storable qw(dclone);


use DBIx::XML::DataLoader::MapIt;
use DBIx::XML::DataLoader::DB;
use DBIx::XML::DataLoader::IsDefined;

###########
sub new{
########

my $class=shift;
my $self={};
my %args=@_;
my $map=$args{map};
#if(!$map){die "a map file is required for creating a new object\n";}

$self->{dbmode}=$args{dbmode}||"insertupdate";
$self->{dbprint}=$args{dbprint}||undef;
my $dbprint=$args{dbprint}||$self->{dbprint}||undef;
my $dbmode=$args{dbmode}||$self->{dbmode}||"insertupdate";

$self->{map}=$args{map}||undef;
$self->{xml}=$args{xml}||undef;

my  @classmap=DBIx::XML::DataLoader::MapIt->mapclasses($map);
my @tables=@{$classmap[4]};
my $dbinfo=$classmap[1];
my $db_connections;
my $db=DBIx::XML::DataLoader::DB->new(dbmode=>$dbmode, dbprint=>$dbprint);
$self->{db}=$db;
if($dbinfo){
for my $keys (keys %{$dbinfo}){
my $dbuser=$dbinfo->{$keys}->{dbuser};
my $dbpass=$dbinfo->{$keys}->{dbpass};
my $dbsource=$dbinfo->{$keys}->{dbsource};
my $dbh;
$dbh=$db->DBConnect($dbuser,$dbpass,$dbsource);
$db_connections->{$keys}=$dbh;
}
}
$self->{db_connections}=$db_connections;
$self->{classmap}=\@classmap;
$self->{tables}=\@tables;
bless ($self, $class);

###############
} # end sub new
#######################

#############################
sub processxml{
################
if(scalar @_ < 3){die "failed to provide the proper arguments of xml, and map file @_\n";}


##################
no strict 'refs';

my $self=shift;
my %args=@_;
$XML::XPath::Namespaces=0;
my $dbprint=$args{dbprint}||$self->{dbprint}||undef;
my $dbmode=$args{dbmode}||$self->{dbmode}||"insertupdate";
my $file_count=$args{count};
my @classmap = @{$self->{classmap}};
my $xml=$args{xml};
if($xml){$self->{xml}=$xml;}
#my $map=$args{map}||$self->{map};
my @allxmlfiles;
my @allxmldocs_processed;
my @everybitofdata;
my @errors;

my $suberrors;
my $dbmessage;
my $message;
my @sqlload;
my $dberror;

##################################################################
### here we process our map file and get the db and xml document 
### structure information we need to continue
### 
my $tables=$classmap[4];
my $table_ref=$classmap[3];
my $rootelement=$classmap[2];
my $dbinfo=$classmap[1];
####### here we make all the needed database connections
my $db_connections=$self->{db_connections};
my $db=$self->{db};
my $thesubs=$classmap[0];
my @tables=@{$tables};
#######################################################
## here we run the pre parse subroutines
{no warnings; #warnings are turned off so that we will not get complaints
              # if runsubs returns no value;
my ($serror, undef)=_runsubs($db_connections,$thesubs, 'prexml');
$suberrors.=$serror;
}
##################################################

#$XML::XPath::SafeMod;
### we now start looping through our xml files
###we do subroutine and db inserts one xml file at a time
my $all_xml;

my $current_xml;

my @arrayofallinserts;


#############################################################################
## here we will check to make sure the files and directories requested
## exists
if(!$xml){warn "we had no xml sent in";return;}
if($xml =~ /^http:/){

my         $ua = new LWP::UserAgent;
         $ua->agent("DBIx_XML_DataLoader/1.0b " . $ua->agent);
my $req = new HTTP::Request(GET=>$xml);
my $res = $ua->request($req);
if ($res->is_success){
             $xml=$res->content;
         }
}

if($xml =~ /^http:/){die "we did not get the remote xml map file you requested";}



if($xml !~ /\</gm){
my $xmltype=(stat($xml))[2];
if($xmltype=~ /^1/){die "ERROR: The file is a directory not a regular file";}
if(!$xmltype){die "ERROR: The file you entered does not exist";}
return unless (eval{$all_xml = XML::XPath->new(filename => $xml);});
}

if($xml =~ /\</gm){
return unless (eval{$all_xml = XML::XPath->new(xml => $xml);});
}
##########################################################################################
## below we loop through each table
## and loop through the input xml file looking for items that belong in this table
## once we fill all the required columns in the table we execute our SQL and empty
## our colection of values and try to fill the required fields again we continue
## through the document until we have no more value we can use. Then we start a new table.
###########################################################################################
my $loopcount;

TABLE: for my $table (@tables){

$message.= "working with table $table\n";
my @table_info=@{$table_ref->{$table}};
my $table_details=pop @table_info;
my @cols=@{$table_details->{columns}};
my @hashof_thekeys=@{$table_details->{keys}};
my @thekeys;
for my $hash_thekey (@hashof_thekeys){
for my $key (keys %{$hash_thekey}){push @thekeys, $hash_thekey->{$key};}
}
my $keyelement=$table_details->{xpath};
my $dbname=$table_details->{dbname};
my $handlers=$table_details->{handlers};
my @tabprep;
my %table;
my $table_ref;
my @incols;
&_runtablesubs($db_connections,$handlers, 'TABLE', 'prexml'); 

my $count=scalar @cols;
my @insdbh;
my @upddbh;
my @upkeys;
my $date;
### we are going to try to do this looping through the map file calssmap array
### looking for values that match up in the $all_xmlmap hash referance.
### 
my @currentkeys=@thekeys;
my $current_class;
my $current;
my @allglobals;
my @allresults;
my %array_count;
my $section_count;
my $subsection_count;
my $element_count;
my $nodecounter;
my $newloop="yes";
if(!$rootelement){$rootelement="/*";}
my @allnodes;
return unless (eval{ @allnodes = $all_xml->findnodes("$rootelement");});
BASENODE: while (@allnodes){
my $thenode=pop @allnodes;
my @all_tab_nodes;
next  unless (eval { @all_tab_nodes= $thenode->findnodes("$keyelement");});
NODES: while (@all_tab_nodes){
my $node =shift @all_tab_nodes;

CLASSLOOP: for my $class (@table_info){

my $xpath=$class->{xpath};
my $default = $class->{default};
my $item=$default;
my $itemvalue=$node->findvalue($xpath);

$itemvalue=~s/\s+/ /g;
## added for testing comment out when in production
#if($class->{col} eq "computer_name"){$itemvalue="Comp $file_count";}
## new routine in module IsDefined.pm will check to make sure a avriable has a value
if(defined DBIx::XML::DataLoader::IsDefined->verify($itemvalue)){$item = $itemvalue;}

if($handlers->{$class->{col}}){
HANDLERS: 
for my $key (sort keys %{$handlers->{$class->{col}}}){
my $sub;
my $handler=$handlers->{$class->{col}}->{$key}->{handler};
if($handler !~ /^sub/){
$handler=~s/&gt;/>/;
my ($package, $subroutine)=split /\-\>/, $handler;
my $mod_name=$package.".pm";
&_printsuberror($mod_name, $@) unless eval {require $mod_name};
my @substuff;
push @substuff, $item,$handlers->{$class->{col}}->{$key}->{args},$db_connections->{$handlers->{$class->{col}}->{$key}->{dbname}};
&_printsuberror("$package->$subroutine", $@) unless (eval{$item=$package->$subroutine($item,$handlers->{$class->{col}}->{$key}->{args},$db_connections->{$handlers->{$class->{col}}->{$key}->{dbname}})});
}
if($handler=~ /^sub\{/){
$handler=~s/\&amp;/\&/g;
$handler=~s/\&quot;/\"/g;
my $subroutine=$handler;
$sub=eval "$subroutine";
{
no warnings;
&_printsuberror($sub, $@) unless (eval {$item= &$sub($item,$handlers->{$class->{col}}->{$key}->{args},$db_connections->{$handlers->{$class->{col}}->{$key}->{dbname}})});
}
}
} # end loop HANDLERS
} # if handlers

if($class->{col}=~ /^UPDATE_DTTM$|^CREATE_DTTM$/){$item="SYSDATE";}
my $key;
KEYS: for  my $ckeys(@currentkeys){
if($ckeys eq $class->{col}){$key="yes";last KEYS;}
} # end loop for keys;

if($class->{date}){
my $conv_item=$db->sqldate($db_connections->{$dbname}, $item, $class->{date},$table);
$item=$conv_item;}
if(not defined  $item){undef @allresults; next NODES;}
#{undef @allresults; next NODES;} unless (defined $item);
#print "Col: ",$class->{col}," Val: $item\n";
if(!$key){push @allresults, {val=>$item, col=>$class->{col}};}
if($key){push @allresults, {val=>$item, col=>$class->{col}, key=>$key};}
	if((scalar @allresults) eq (scalar @cols)){
my ($tserror, $results)=_runtablesubs($db_connections,$handlers, 'TABLE', 'predb',\@allresults); 
if($tserror){$suberrors.=$tserror;}
if($results){@allresults=@{$results};}


	push @arrayofallinserts, {results=>[@allresults], table=>$table, keys=>\@hashof_thekeys,
cols=>\@cols, dbname=>$dbname};
	undef @allresults;
next NODES;
	} # end if (scalar @allresults eq scalar @thecols) and (scalar @currentkeys) <= 0) 

} # end loop CLASSLOOP
} # end NODES
} # end BASENODE
} # end TABLE loop


#############################################################################################
## we have all of our data organized now we will prepare to run
## any subs that have been passed to us from the map file and
## do the database insertion or update
############################################################################################
# we will do this so tah our subs have access to the db
############################################################################
## here we will walk through our extra subroutines listed in the map file###
############################################################################
{no warnings; #warnings are turned off so that we will not get complaints
              # if runsubs returns no value;
my ($serror, $allinserts)=_runsubs($db_connections,$thesubs, 'predb', \@arrayofallinserts);
if($allinserts =~ /^ARRAY/){
@arrayofallinserts=@{$allinserts};
}
$suberrors.=$serror;

}
#####################################################################
## we now run the actual database insertion/update subroutine dosql##
#####################################################################
if($dbinfo){
my ($response, $error,$load)=$db->DBInsertUpdate(datainfo=>\@arrayofallinserts, dbprint=>$dbprint,
dbconnections=>$db_connections, dbmode=>$dbmode);
if($response){$dbmessage.=$response;}
if($error){ $dberror.=$error;}
if($load){push @sqlload, $load;}
}


############################ All Done ##############################
#&runsubs("postdb",\@subs, \@arrayofallinserts);

#my $olddbh=pop @arrayofallinserts;
push @everybitofdata, \@arrayofallinserts;


$all_xml->cleanup();


{no warnings; #warnings are turned off so that we will not get complaints
              # if runsubs returns no value;
my ($serror, $allinserts)=_runsubs($db_connections,$thesubs, 'postdb', \@everybitofdata);
$suberrors.=$serror;
}
#"We Attempted to Process the XML Document ".(join "\n", @allxmlfiles).
$message .=
"\nThe Following XML Document had data suitable for insertion into our database\n".
(join "\n", @allxmldocs_processed).
"\n____________________________________________________________\n";
#my %stuff=(message=>$message, dbmessage=>$dbmessage, suberrors=>$suberrors,dberrors=>$dberror, sqlload=>[@sqlload]);
return ($self,{message=>$message, dbmessage=>$dbmessage,suberrors=>$suberrors,dberrors=>$dberror,sqlload=>[@sqlload]});
} # end sub processxml;






sub _printsuberror{
no warnings; # here incase we do not pass all the vars we are expecting
my $package=shift;
my $error=shift;
my $theerrors= "We had a problem running $package, the error reported was $error\n";
return($theerrors);
}


sub _runsubs{

no warnings; # used to keep any subs from causing warnings.
             # errors actually generated by the subroutine that runsub will be calling 
	     # are returned by runsubs
my $thesuberrors;
#my $self=shift;
my $db_connections=shift;
my $insubs=shift;
my $when=shift;
my $data=shift;
my $sub_response=$data;
if(!$insubs){return;} # chnaged here;
my %subs=%{$insubs->{$when}};
		for my $key (sort keys %subs){
		$data=$sub_response;
		my $handler=$subs{$key}->{name};
		my $args=$subs{$key}->{args};
		my $dbname=$subs{$key}->{dbname};
		my $dbconnect;
			if($dbname){$dbconnect=$db_connections->{$dbname};}

			if($handler !~ /^sub/){
			$handler=~s/&gt;/>/;
			my ($package, $subroutine)=split /\-\>/, $handler;
			my $mod_name=$package.".pm";
			
		$thesuberrors.=_printsuberror($mod_name, $@) 
		unless eval {require $mod_name};
		$thesuberrors.=_printsuberror("$package->$subroutine",$@) unless  
		(eval {$sub_response=$package->$subroutine($args, $data,
$dbconnect);});
 			}

			if($handler=~ /^sub\{/){
			$handler=~s/\&amp;/\&/g;
			$handler=~s/\&quot;/\"/g;
			my $subroutine=$handler;
			my $sub=eval "$subroutine";
			$thesuberrors.=_printsuberror($sub, $@) 
			unless (eval {$sub_response= &$sub($args, $data, $dbconnect);});
			}

		}
		

return($thesuberrors, $sub_response);

}



sub _runtablesubs{
no warnings; # used to keep any subs from causing warnings.
             # errors actually generated by the subroutine that runtablesub will be calling 
	     # are returned by runsubs

#my $self=shift;
my $db_connections=shift;
my $handlers=shift;
my $place=shift;
my $when=shift;
my $indata=shift;
my $data=$indata;
my $subresponse=$data;
my $suberrors;
if($handlers->{$place}){
HANDLERS: 
for my $key (sort keys %{$handlers->{$place}->{$when}}){
if($subresponse){$data=$subresponse;}

my $sub;
my $handler=$handlers->{$place}->{$when}->{$key}->{handler};
if($handler !~ /^sub/){
$handler=~s/&gt;/>/;
my ($package, $subroutine)=split /\-\>/, $handler;
my $mod_name=$package.".pm";
$suberrors.=_printsuberror($mod_name, $@) unless eval {require $mod_name};
$suberrors.=_printsuberror("$package->$subroutine", $@) unless  (eval
{$subresponse=$package->$subroutine($handlers->{$place}->{$when}->{$key}->{args},$db_connections->{$handlers->{$place}->{$when}->{$key}->{dbname}},$data)}); 
}
if($handler=~ /^sub\{/){
$handler=~s/\&amp;/\&/g;
$handler=~s/\&quot;/\"/g;
my $subroutine=$handler;
$sub=eval "$subroutine";
$suberrors.=_printsuberror($sub, $@) unless 
(eval
{$subresponse=&$sub($handlers->{$place}->{$when}->{$key}->{args},$db_connections->{$handlers->{$place}->{$when}->{$key}->{dbname}},$data)}); 
if(!$subresponse){$subresponse=$data;}
}


} # end loop HANDLERS
} # if handlers
if(!$subresponse){$subresponse=$data;}

return($suberrors,$subresponse);
#################
} # end sub _runtablesubs
#######################

1;

__END__


=head1  NAME

	DBIx::XML::DataLoader

=head1  SYNOPSIS

	use DBIx::XML::DataLoader;

	my $mapper=DBIx::XML::DataLoader->new(map=>"map.xml");
	my $response=$mapper->processxml(xml=>"data.xml");

=head1  DESCRIPTION

	DBIx::XML::DataLoader contains a set of modules that are meant to work together.
	DBIx::XML::DataLoader.pm the core for this package
	DB.pm which contains the sql specific stuff
	MapIt.pm handles parsing the xml mapping file		
	IsDefined.pm a simple module for making sure empty data sets are defined

	dataloader uses a external map(see map instructions below) file written 
	in xml to find its instructions for handling the data contained in the 
	xml data files that will be imported. 

=head1  SIMPLE EXAMPLE	

	use DBIx::XML::DataLoader;

	#Create a new object
	my $mapper=DBIx::XML::DataLoader->new(map=>"map.xml");

	my $response=$mapper->processxml(xml=>"data.xml");
	
	#$response will contain a hash referance with the information outputted by the module.

	$response->{mesage};	# The message generated by module
	$response->{dbmessage};	# the message generated by DBIx::XML::DataLoader::DB.pm
	$response->{suberrors}; # errors generated by the subroutines
	$response->{dberrors};	# errors generated by DBIx::XML::DataLoader::DB.pm
	$responce->{sqlload};	# data formatted to be suitable for inserting using sqllaoder
			# requires you set the dbmode to sqlloader

=head1  OPTIONAL USAGE

	new()   can be passed serveral other options besides "map"
		Required 
		map: The map file to be used. This can be a xml fragment
		a xml file on the local machine or a url to a xml map file.

		Optional
		dbmode: this can be set to insert, update, insertupdate, or
		sqlloader

			insert: will have db.pm only do inserts
			update: will have db.pm only do updates
			insert/update: the default setting will attempt to insert data
			and then it will try to do a update.
			sqlloader: will generate data formatted in a way so it can be
			written to a DAT file for sqlloader(Oracle). This data will be 
			returned in $response->{sqlload}.
 


		dbprint: this is used to control whether we actually do the database
		work or simulate it by printing the statements to $response->{dbmessage}.
		This can be set to db, print, or dbprint.

			db: will tell DBIx::XML::DataLoader::DB.pm to just do the assinged dbmode
			print: will tell DBIx::XML::DataLoader::DB.pm to simulate the dbmode and return in
			dbmessage the sql statement that would have been created.
			dbprint: will cause the db.pm module to do both the actual 
			assigned dbmode and the printed output.


	processxml() Needs to have a xml file containing the data. 

			xml: This can be a xml fragment of xml, a xml file on the server,
			or a url to a xml file.
		     

=head1  EXAMPLE SIMPLE MAPFILE

	<XMLtoDB>
		<dbinfo dbuser="db_user_login" dbpass="db_pass_login" 
		dbsource="data_source" name="a_identifier"/>
		<RootElement name="name_of_xml_doc_root"/>
		<Table name="db_table_name"  db_name="a valid dbinfo name attribute value"
		xpath="./xpath_of_tables_root_node">
			<KeyColumn name="a db query 
			key" order="The more common a key values should be given a higher number"/>
			<Element xpath="./xpath_to_node" toColumn="sql db column name"/>
		</Table>
	</XMLtoDB>






=head1  MAP FILE RULES

=head1  Exceptable Map File Tags

=head2  dbinfo

	  Tag containing attributes with the database user name, password,
          data source, and name.
	1) Attribute name for database user is dbuser
	2) Attribute name for database password is dbpass
	3) Attribute name for database source is dbsource
	4) Attribute name for database name is name

=head2  Sub

	This tag is for listing subroutines you would like called prior
	to doing the main database insertion/update.
	1) Required attributes for this tag are name and rank.
	2) Modules containing the subroutines should be kept in @INC
	3) The name attribute needs to have the package name and the
	subroutine name that will be called. It needs to written as
	package->subroutine
	4) The when attribute is used to tell the program when to run the subroutine.
	The options would be prexml, predb, postdb, and postxml.
	5) The rank attribute need to be set to a number. Rank starts at 1
	and goes up from there. Subs with he lowest rank will be ran first.
	Consecutive numbers must be used for setting rank.
	6) A optional attribute of args can be used to pass arguments to the
	subroutine being called.


=head2  DocKeyColumn

	This is a Key db column that is common to multiple tables in the
	xml document.
	1) the attribute for this tag is name. This attribute should be set 
	   to the db column name that is common.

=head2  RootElement

	The base element for the document
	1) tag has a attributes of name. The name should be set to the documents root
	element name

=head2  Table

	The area containing table data inforamtion. Tag attributes are name and dbname
	1) name should be set to a db table name
	2) dbname should be set to a valid dbinfo name attribute value
	3) xpath shoud be set to the base xpath of the table

=head2  Handler

	This tag is for passing subroutines durring processing of tables or data
        contained in a Element. When Handler is outside a Element then it will be
	considered belonging to the Table. Table level handlers have three attributes.
	They are name, when, and rank. Only rank is optional. Element level handlers
	require only the name attribute but can also have a rank attribute if more than
	handler will be called on this data value.

	1) The attribute name should be set to a subroutine in @INC or code containing 
	the actual subroutine. If passing code lable it sub and wrap the code in
	brackets (ie. sub{$ _[0]="hello";} would change the value comming
	in to "hello")
	2) The value for when should be predb or postdb (table level handlers only)
	3) The value for rank should be set based on what order you want handlers with
	the same parents should be called. The lower the number the earlier it will
	be called.


=head2  KeyColumn

	This is one of the key in the database for the table. The attributes for this
	tag are name and order.
	1) the attribute name should be set to the name of the column in the table.		
	2) the attribute order should be set based on the previlance of the column
	value in the database(ie. driveletter might be common but computername
	in the same row may be more unique. So the order value for computername
	would be give a lower number and driveletter a highter value for order).

=head2  Element

	A Element is how we identify xml nodes containing our data. The attributes
	that are required are xpath, toColumn.
	1) The attribute xpath should be set to the xpath of the node relative to
	the xpath of Table.
	2) The attribute toColumn should be set to the column name in the db.



=head1  Also see man page for 

=for man DBIx::XML::DataLoader::XMLWriter,  DBIx::XML::DataLoader::MapIt, DBIx::XML::DataLoader::DB, DBIx::XML::DataLoader::IsDefined, and DBIx::XML::DataLoader::Date

=for text DBIx::XML::DataLoader::XMLWriter,  DBIx::XML::DataLoader::MapIt, and DBIx::XML::DataLoader::DB, DBIx::XML::DataLoader::IsDefined, and DBIx::XML::DataLoader::Date


=for html 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

=for html 
 <a href="XMLWriter.html">DBIx::XML::DataLoader::XMLWriter</a>,&nbsp;

=for html
 <a href="MapIt.html">DBIx::XML::DataLoader::MapIt<a/>,&nbsp; <a href="DB.html">DBIx::XML::DataLoader::DB</a>,&nbsp;

=for html
 <a href="IsDefined.html">DBIx::XML::DataLoader::IsDefined<a/>,&nbsp; and &nbsp;<a href="Date.html">DBIx::XML::DataLoader::Date</a>

=for html
<p><hr><p><p><P>

