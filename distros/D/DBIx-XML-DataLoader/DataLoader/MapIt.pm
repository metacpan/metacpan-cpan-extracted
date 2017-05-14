package DBIx::XML::DataLoader::MapIt;

use strict;
use warnings;

###############
sub new{
########
my $self = shift;

bless \$self;
########
} # end sub new
################


#######################
sub mapclasses{
###############

use XML::XPath;
use LWP::UserAgent;

my @mapclasses;

my $self=shift;
my $filename=shift;
my $all_tables;
my @globals;
my @tables;
my @loc_globals;
my @subs;
my $thesubs;
my $rootelement;
my $data_sources;
my $doc_key;
my $xp;
{
no warnings;  # warnings are turned off because the XML::XPath 
	      #	generates warnings when we attempt to find node values


# added http requests for map files
if($filename =~ /http/){
my         $ua = new LWP::UserAgent;
         $ua->agent("DBIx::XML::DataLoader/1.0b " . $ua->agent);
my $req = new HTTP::Request(GET=>$filename);
my $res = $ua->request($req);

if ($res->is_success){
             $filename=$res->content;
         }
}
if($filename =~ /^http:/){die "we did not get the remote xml map file you requested";}

if($filename !~ /\</mg){$xp = XML::XPath->new(filename => $filename);}
if($filename =~ /\</mg){$xp = XML::XPath->new(xml => $filename);}


my ($mapcol,$maptable,$mappath,$mapvar,$maptag,
        $mapkeys, $mapele, $mapsec, $mapatt,
        $mapsub, $mapglb,$maplglb);
my $path;
my $nodeset = $xp->findnodes('/XMLtoDB/*');
NODE: foreach my $node ($nodeset->get_nodelist) {

	my $elename=XML::XPath::Node::Element::getName($node);
if(($elename) and ($elename eq "DocKeyColumn")){
my @attributes= XML::XPath::Node::Element::getAttributes($node);
for my  $att_nodes (@attributes){
my $att=XML::XPath::Node::Attribute::getData($att_nodes);
my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
if(($att_name) and ($att_name eq "name")){$doc_key=$att;}
}
}
############## here we get the Sub tag(subroutine) info and the db, and rootelement.
###################################################################################
	if(($elename) and ($elename eq "dbinfo")){
my ($dbuser, $dbpass, $dbsource, $name);

		my @attributes= XML::XPath::Node::Element::getAttributes($node);
		for my $att_nodes (@attributes){
			my $att=XML::XPath::Node::Attribute::getData($att_nodes);
			my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
			if($att_name){
			if($att_name eq "dbpass"){$dbpass=$att;}
			if($att_name eq "dbuser"){$dbuser=$att;}
			if($att_name eq "dbsource"){$dbsource=$att;}
			if($att_name eq "name"){$name=$att;}
		}
		} # end for @attributes
$data_sources->{$name}={dbuser=>$dbuser, dbpass=>$dbpass, dbsource=>$dbsource};
	} # end dbinfo
	if(($elename) and (($elename eq "Handler")or($elename eq "Sub"))){
		my $subname;
		my $subrank;
		my $subargs;
		my $subwhen;
		my $dbname;
		my @attributes= XML::XPath::Node::Element::getAttributes($node);
		for my $att_nodes (@attributes){
			my $att=XML::XPath::Node::Attribute::getData($att_nodes);
			my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
			if($att_name){
			if($att_name eq "name"){$subname=$att;}
			if($att_name eq "args"){$subargs=$att;}
			if($att_name eq "rank"){$subrank=$att;}
			if($att_name eq "when"){$subwhen=$att;}
			if($att_name eq "dbname"){$dbname=$att;}
		}
		}
$subname=~s/\&amp;/\&/g;
$subname=~s/\&quot;/\"/g;
$subname=~s/\&lt;/\</g;
$subname=~s/\&gt;/\>/g;
if(!$subrank){$subrank=1;}
		#my $thehandler;
		$thesubs->{$subwhen}->{$subrank}={name=>$subname, args=>$subargs,when=>$subwhen, dbname=>$dbname};
	#push @subs, $thehandler;
	} # end if Handler
	if(($elename) and ($elename eq "RootElement")){
		my @attributes= XML::XPath::Node::Element::getAttributes($node);
		for my $att_nodes (@attributes){
			my $att=XML::XPath::Node::Attribute::getData($att_nodes);
			my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
			if($att_name){
			if($att_name eq "name"){$rootelement=$att;}
		}
		}
	} # end RootElement
###########################################################################################################
############  below we get our table info
##########################################################################################################
if(($elename) and ($elename eq "Table")){
my @table_keys;
my $table;
my $allkeys;
my @keys;				
my @cols;
my $keyelement;
my $handlers;
my $dbname;
my $base_xpath;
my $table_child;
my $table_parent;

my @attributes=XML::XPath::Node::Element::getAttributes($node);
	for my $attribute (@attributes){
	my $att_value=XML::XPath::Node::Attribute::getData($attribute);
	my $att_name=XML::XPath::Node::Attribute::getName($attribute);
		if($att_name){
		if($att_name eq "name"){$table=$att_value;}
		if($att_name eq "dbname"){$dbname=$att_value;}
		if($att_name eq "xpath"){$base_xpath=$att_value;}
		if($att_name eq "parent"){$table_parent=$att_value;}
		if($att_name eq "child"){$table_child=$att_value;}
		}
	} # end @attributes
	my @child_nodes=XML::XPath::Node::Element::getChildNodes($node);
push @tables, $table;
CHILD_NODE: for my $child_node (@child_nodes){
my $child_elename=XML::XPath::Node::Element::getName($child_node);
if(($child_elename) and (($child_elename eq "Handler")or($child_elename eq "Sub"))){
my $rank;
my $when;
my $args;
my $name;
my $dbname;
my @attributes= XML::XPath::Node::Element::getAttributes($child_node);
                                
for my $att_nodes (@attributes){
                                        my $att_value=XML::XPath::Node::Attribute::getData($att_nodes);
                                        my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
					   if($att_name eq "name"){$name=$att_value;}
                        if($att_name eq "args"){$args=$att_value;}
                        if($att_name eq "rank"){$rank=$att_value;}
                        if($att_name eq "when"){$when=$att_value;}
		if($att_name eq "dbname"){$dbname=$att_value;}

                                } # end for @attributes
$name=~s/\&amp;/\&/g;
$name=~s/\&quot;/\"/g;
$name=~s/\&lt;/\</g;
$name=~s/\&gt;/\>/g;
if(!$rank){$rank=1;}

$handlers->{TABLE}->{$when}->{$rank}={handler=>$name, args=>$args, dbname=>$dbname};
} # end if Handler
if(($child_elename) and ($child_elename eq "KeyElement")){
my @attributes= XML::XPath::Node::Element::getAttributes($child_node);
                                for my $att_nodes (@attributes){
                                        my $att_value=XML::XPath::Node::Attribute::getData($att_nodes);
                                        my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
                                        if($att_name eq "xpath"){$keyelement=$att_value;}
				} # end for @attributes
if(!$base_xpath){$base_xpath=$keyelement;}
} #end if KeyElement
if($base_xpath){$keyelement=$base_xpath;}
if(($child_elename)and ($child_elename eq "KeyColumn")){
my $keyname;
my $keyorder;
my @attributes= XML::XPath::Node::Element::getAttributes($child_node);
                                for my $att_nodes (@attributes){
                                        my $att_value=XML::XPath::Node::Attribute::getData($att_nodes);
                                        my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
                                        if($att_name eq "name"){$keyname=$att_value;}
                                        if($att_name eq "order"){$keyorder=$att_value;}
                                } # end for @attributes
push @keys, {$keyorder=>$keyname};
} # end if KeyColumn
############################################################################
my $handler;
my %keyhash;
my @ele_handlers;
my $column;

if(($child_elename) and ($child_elename eq "Element")){
my $xpath;
my $default;
my $date;

				my @attributes= XML::XPath::Node::Element::getAttributes($child_node);
				for my $att_nodes (@attributes){
					my $att_value=XML::XPath::Node::Attribute::getData($att_nodes);
					my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
					if($att_name eq "xpath"){$xpath=$att_value;}
					if($att_name eq "toColumn"){$column=$att_value;}
					if($att_name eq "default"){$default=$att_value;}
					if($att_name eq "date"){$date=$att_value;}
										
				} # end for @attributes
push @cols, $column;
push @table_keys, {xpath=>$xpath,col=>$column, default=>$default , date=>$date};

my @element_nodes=XML::XPath::Node::Element::getChildNodes($child_node);
ELEMENT_NODE: for my $element_node (@element_nodes){
my $node_name=XML::XPath::Node::Element::getName($element_node);
			if(($node_name) and (($node_name eq "Handler")or($node_name eq "Sub"))){
	my $subname;
	my $subargs;
	my $subrank;
			 my @attributes= XML::XPath::Node::Element::getAttributes($element_node);
                                for my $att_nodes (@attributes){
                                        my $att_value=XML::XPath::Node::Attribute::getData($att_nodes);
                                        my $att_name=XML::XPath::Node::Attribute::getName($att_nodes);
		         		if($att_name eq "name"){$subname=$att_value;}
		                        if($att_name eq "args"){$subargs=$att_value;}
                		        if($att_name eq "rank"){$subrank=$att_value;}
                                } # end for @attributes
if(!$subrank){$subrank=1;}
$subname=~s/\&amp;/\&/g;
$subname=~s/\&quot;/\"/g;
$subname=~s/\&lt;/\</g;
$subname=~s/\&gt;/\>/g;
if(!$subrank){$subrank=1;}

$handlers->{$column}->{$subrank}={handler=>$subname, args=>$subargs}; 				}
} #end if $node_name eq Handler
} # end ELEMENT_NODE

#$handlers->{$column}=[@ele_handlers];
} #end if Element

push @table_keys,{ columns=>\@cols, keys=>\@keys, dbname=>$dbname, handlers=>$handlers,
xpath=>$base_xpath, parent=>$table_parent, child=>$table_child}; 
$all_tables->{$table}=\@table_keys;
} #end if Table
} # end  for child_node 


push @mapclasses, $thesubs;
push @mapclasses,$data_sources;
push @mapclasses, $rootelement;
push @mapclasses, $all_tables;
push @mapclasses, \@tables;
push @mapclasses, $doc_key;

my $temp="/tmp";

=pod
## just messing around here  disreguard for now
if($filename !~ /\</){
my @fname=split m[/], $filename;
my $file=pop @fname;
my $temp="/tmp/".$file.".map";
open(TMP, ">$temp")||die "could not open temp $temp $@";
use Data::Dumper;
#$Data::Dumper::Purity=1;
#$Data::Dumper::Terse =1;
print TMP Data::Dumper->Dump(\@mapclasses);
}
=cut

return (@mapclasses);
}
############
} # end sub mapclasses
##########################

1;


__END__


=head1  NAME

        DBIx::XML::DataLoader::MapIt

=head1  SYNOPSIS

	use DBIx::XML::DataLoader::MapIt;

	my  @classmap=DBIx::XML::DataLoader::MapIt->mapclasses('map.xml');

=for man or

=for text or

=for html <b>or</b>

	use DBIx::XML::DataLoader::::MapIt;

	my $m=DBIx::XML::DataLoader::MapIt->new();
	my @classmap=$m->mapclasses('map.xml');


=for man or

=for text or

=for html <b>or</b>
	
	use DBIx::XML::DataLoader::MapIt;

	my $m=DBIx::XML::DataLoader::MapIt->new();

	my $map=qq{
	<XMLtoDB>
		<RootElement name="/Users"/> 
		<dbinfo dbuser="user" dbpass="pass" dbsource="dbi:mysql:userdata" name="userdata"/> 
		<Table name="userinfo" dbname="userdata" xpath="./user">
			<KeyColumn name="USER_ID" order="1"/>
			<KeyColumn name="USER_LAST_NAME" order="2"/>
			<KeyColumn name="USER_FIRST_NAME" order="3"/>
			<Element xpath="./id" toColumn="USER_ID"/> 
			<Element xpath="./last_name" toColumn="USER_LAST_NAME"/> 
			<Element xpath="./first_name" toColumn="USER_FIRST_NAME"/>
			<Element xpath="./phone_number" toColumn="PHONE_NUMBER"/>
		</Table>
	</XMLtoDB>};
	
	my @classmap=$m->mapclasses($map);

=for man or

=for text or

=for html <b>or</b>

	use DBIx::XML::DataLoader::MapIt;

        my $m=MapIt->new();

=for html &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;	my $map="http://urltomap.com/map.xml";

=for man	my $map="http://urltomap.com/map.xml";

=for text	my $map="http://urltomap.com/map.xml";

	my @classmap=$m->mapclasses($map);

=head1	DESCRIPTION
	
	MapIt.pm is used primarily by DataLoader.pm for extracting mapping information from
	a xml map file. The mapping information can be used for querying a database for
	the purpose of reconstructing a xml document(see the sample script query_sql.cb).

=head1  Map Rules

=for man 
	see man page DBIx::XML::DataLoader::DB for complete map rules and sample map file.

=for html see man page <a href="DataLoader.html#example simple mapfile">DBIx::XML::DataLoader<a/> for complete map rules and sample map file.

=head1  Also see man page for


=for man
	DBIx::XML::DataLoader and DBIx::XML::DataLoader::XMLWriter


=for html
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a
href="DataLoader.html">DBIx::XML::DataLoader</a> and <a href="XMLWriter.html">DBIx::XML::DataLoader::XMLWriter</a>	


=head1  Sample Scripts

=for man
	query_db.pl	
=for man
	test_mapit.pl.pl	

=for html
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
query_db.pl, and test_mapit.pl

=for html
<p><hr><p><p><P>

