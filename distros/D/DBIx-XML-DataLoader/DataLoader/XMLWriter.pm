


package DBIx::XML::DataLoader::XMLWriter;

use strict;
use warnings;

my $VERSION="1.0b";
###########
sub new{
#########
my $self=shift;

bless \$self;

##########
} # end sub new
#################

##################
sub makexml{
############

###############################################################
####   this sub will expect 2 variables to be passed to it
####   $data:		should be a hash_ref to our data
####   $doc_root:	should be set to the document_root 
###############################################################


##
my $self=shift;
my $data=shift;
my %all_data=%{$data}; 
my $doc_root=shift;
my %doc=($doc_root=>[{}]);

############

use XML::Simple;
my $parser = new XML::Simple(noescape=>1,keeproot=>1);
use DBIx::XML::DataLoader::Date;
my $date=DBIx::XML::DataLoader::Date->now();

my $rootcnt="0";
##############################################
### here we walk though all the db results
## building our xml doc as we go.
###############################################
my @all_finished_tables;
my @allthekeys;
KEY_LOOP: for my $keys (sort keys %all_data){push @allthekeys, $keys;}
my @testkeys=@allthekeys;

TABLE_LOOP: 
while (@allthekeys){
my $keys= shift @allthekeys;
my $table_node=$all_data{$keys}->{node};
my %table_pass;
my $fparent;
if($all_data{$keys}->{parent}){

	PARENTCHECK:for my $finished_tables (@all_finished_tables){
		if($finished_tables eq $all_data{$keys}->{parent}){
		$fparent="yes";
		last PARENTCHECK;
		}
	}

if(!$fparent){
$fparent="yes";
BPARENTCHECK: for my $test_table (@allthekeys){
if($test_table eq $all_data{$keys}->{parent}){
	$fparent=undef;last BPARENTCHECK;
	}
	}
}

if(!$fparent){push @allthekeys, $keys;next TABLE_LOOP;}
}


push @all_finished_tables, $keys;
$table_pass{parent}->{hasone}="no";
my $dbname=$all_data{$keys}->{dbname};
if($all_data{$keys}->{data}){
LOOPCNT: for my $lpcnt (sort keys %{$all_data{$keys}->{data}}){

my $table_xpath=$all_data{$keys}->{xpath};
$table_xpath=~ s[^\./][];
my $the_root=$doc_root;
my @info=@{$all_data{$keys}->{data}->{$lpcnt}};
my $tableroot=$all_data{$keys}->{node};
my %table_doc;
INFO: for my $info (@info){
my $value=$info->{val};
### here we set any values that have xpaths starting from the document root
## this seems to work
if($info->{xpath} =~ m[^/]){
## do root doc stuff here
my $xpath=$info->{xpath};
$xpath =~ s[^/+][];
my @path=split m[/], $xpath;
my $the_root=shift @path;
my $path_cnt=scalar @path;
#my $value=$info->{val};
	if($path_cnt==1){
	if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[0]){
	$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[0]=$value;
	next INFO;}
	 if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[0]){
        if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[0] ne $value){
	$rootcnt++;
	$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[0]=$value;
	next INFO;
	}

      	}

	} 

if($path_cnt==2){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0] ne $value){
$rootcnt++;
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
}

}
if($path_cnt==3){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0] ne $value){
$rootcnt++;
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
}

}
if($path_cnt==4){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0] ne $value){
$rootcnt++;
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
}
}
if($path_cnt==5){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0] 
ne $value){
$rootcnt++;
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
}
}
if($path_cnt==6){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]){
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0] 
ne $value){
$rootcnt++;
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]=$value;
next INFO;
}
}
}
next INFO;
}
##################################

## here we check to see if this table has a parent in the xml output document
my $xpath=$info->{xpath};
if(($xpath =~ /^parent/i)or($xpath =~ m[^\.\./])){
$table_pass{parent}->{$lpcnt}->{value}=$value;
$table_pass{parent}->{$lpcnt}->{xpath}=$info->{xpath};
$table_pass{parent}->{$lpcnt}->{attribute}=$info->{attribute};
$table_pass{parent}->{hasone}="yes";
next INFO;
}
$info->{xpath} =~ s[^\./][];
my @current_xpath=split m[/], $info->{xpath};
my $path_cnt=scalar  @current_xpath;
if($table_node ne $doc_root){
#######################################################
if($path_cnt == 1){
if($table_node ne $info->{item_node}){
if($info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){
if($value){
$table_doc{$current_xpath[0]}[0]->{content}.=$value;}
next INFO;
}
}
if($table_node eq $info->{item_node}){
if($info->{attribute}){
$table_doc{$info->{attribute}}=$value;
#print $parser->XMLout(\%table_doc, rootname=>$table_node);
next INFO;
} # end if
if(!$info->{attribute}){

$table_doc{content}.=$value;
next INFO;
}
}
} #if $path_cnt==1
#######################################################
if($path_cnt == 2){

if($table_node ne $info->{item_node}){

if($info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{content}.=$value;
next INFO;
}
}
if($table_node eq $info->{item_node}){

if($info->{attribute}){
$table_doc{$info->{attribute}}=$value;
next INFO;
}
if(!$info->{attribute}){
$table_doc{$current_xpath[1]}[0]->{content}.=$value;
next INFO;
}
}
} #if $path_cnt==2
#######################################################
if($path_cnt == 3){
if($table_node ne $info->{item_node}){
if($info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$current_xpath[2]}[0]->{content}.=$value;
next INFO;
}
}
if($table_node eq $info->{item_node}){
if($info->{attribute}){
$table_doc{$info->{attribute}}=$value;
next INFO;
}
if(!$info->{attribute}){
$table_doc{$current_xpath[1]}[0]->{content}.=$value;
next INFO;
}
}
} #if $path_cnt==3
################################################

#######################################################
if($path_cnt == 4){
if($table_node ne $info->{item_node}){
if($info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$current_xpath[2]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$current_xpath[2]}[0]->{$current_xpath[3]}[0]->{content}.=$value;
next INFO;
}
}

} #if $path_cnt==4
###################################################
if($path_cnt == 5){
if($table_node ne $info->{item_node}){
if($info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$current_xpath[2]}[0]->{$current_xpath[3]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$current_xpath[2]}[0]->{$current_xpath[3]}[0]->{$current_xpath[4]}[0]->{content}.=$value;
next INFO;
}
}

} #if $path_cnt==5
#######################################################
if($path_cnt == 6){
if($table_node ne $info->{item_node}){
if($info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$current_xpath[2]}[0]->{$current_xpath[3]}[0]->{$current_xpath[4]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){
$table_doc{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$current_xpath[2]}[0]->{$current_xpath[3]}[0]->{$current_xpath[4]}[0]->{$current_xpath[5]}[0]->{content}.=$value;
next INFO;
}
}

} #if $path_cnt==6

#######################################################


} # end if n$table_node ne doc_root



##################################################
##################################################
##################################################
##################################################

if($table_node eq $doc_root){
if($path_cnt == 1){
## if scalar split [/], $info->{xpath} == 1
if($info->{attribute}){
$doc{$doc_root}[$rootcnt]->{$current_xpath[0]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){
$doc{$doc_root}[$rootcnt]->{$current_xpath[0]}[0]->{content}.=$value;
next INFO;
}
} #if $path_cnt==1
################################################

#######################################################
if($path_cnt == 2){
if($info->{attribute}){
$doc{$doc_root}[$rootcnt]->{$current_xpath[0]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){

$doc{$doc_root}[$rootcnt]->{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{content}.=$value;
next INFO;
}
} #if $path_cnt==2
################################################


#######################################################
if($path_cnt == 3){
if($info->{attribute}){
$doc{$doc_root}[$rootcnt]->{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$info->{attribute}}=$value;
next INFO;
} # end if
if(!$info->{attribute}){
$doc{$doc_root}[$rootcnt]->{$current_xpath[0]}[0]->{$current_xpath[1]}[0]->{$current_xpath[2]}[0]->{content}.=$value;
next INFO;
}
} #if $path_cnt==3
################################################

} # end if $table_node eq doc_root

}  ## end INFO loop
############ here we start to rconstruct the rest of our doc;
if(!%table_doc){next LOOPCNT;}
my $table_data=\%table_doc;

if($table_pass{parent}->{hasone} eq "no"){ 
my @path=split m[/], $table_xpath;
my $path_cnt=scalar @path;
# we have no parent so lets just add the table our doc hash
my $depth=0;

if($path_cnt == 1){

if($doc{$the_root}[$rootcnt]->{$table_node}){$depth=scalar @{$doc{$the_root}[$rootcnt]->{$table_node}};}

$doc{$doc_root}[$rootcnt]->{$table_node}[$depth]=$table_data;
next LOOPCNT;
}
if($path_cnt == 2){
if($doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$table_node}){$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$table_node}};}

$doc{$doc_root}[$rootcnt]->{$path[0]}[0]->{$table_node}[$depth]=$table_data;
next LOOPCNT;
}

if($path_cnt == 3){
if($doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$table_node}){
$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$table_node}};}
$doc{$doc_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$table_node}[$depth]=$table_data;
next LOOPCNT;
}
if($path_cnt == 4){
if($doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$path[2]}[0]->{$table_node}){
$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$path[2]}[0]->{$table_node}};}

$doc{$doc_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$path[2]}[0]->{$table_node}[$lpcnt-1]=$table_data;
next LOOPCNT;
}
if($path_cnt == 5){
if($doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$path[2]}[0]->{$path[3]}[0]->{$table_node}){
$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$path[2]}[0]->{$path[3]}[0]->{$table_node}};}

$doc{$doc_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$path[2]}[0]->{$path[3]}[0]->{$table_node}[$lpcnt-1]=$table_data;
next LOOPCNT;
}
if($path_cnt == 6){
if($doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$path[2]}[0]->{$path[3]}[0]->{$path[4]}[0]->{$table_node}){
$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[0]}[0]->{$path[2]}[0]->{$path[1]}[0]->{$path[3]}[0]->{$path[4]}[0]->{$table_node}};}

$doc{$doc_root}[$rootcnt]->{$path[0]}[0]->{$path[1]}[0]->{$path[2]}[0]->{$path[3]}[0]->{$path[4]}[0]->{$table_node}[$lpcnt-1]=$table_data;
next LOOPCNT;
}



}

## below we try to find a xml segments parents
if($table_pass{parent}->{hasone} eq "yes"){

my $xpath=$table_pass{parent}->{$lpcnt}->{xpath};
my $value=$table_pass{parent}->{$lpcnt}->{value};
my $node_type="content";
if($table_pass{parent}->{$lpcnt}->{attribute}){
$node_type=$table_pass{parent}->{$lpcnt}->{attribute};
}


my @xpath_array=split m[/], $xpath;
my $xpath_node=pop @xpath_array;
my $parent_node=unshift @xpath_array;
$parent_node=~s/parent:://;

# here we check to see if this is a attribute or element content
my $element;
my $attribute;

if($xpath_node !~ /\@/){$element=$xpath_node;}
if($xpath_node =~ /\@/){$attribute=$xpath_node;$attribute =~ s/\@//;}

my @path=split m[/], $table_xpath;
my $table_node=pop @path;
my $path_cnt=scalar @path;

my $p_node_location_cnt;
PNODE: for my $pnode (@path){
$p_node_location_cnt++;
if($pnode eq $parent_node){last PNODE;}
}

if($path_cnt==1){

	if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}){
	my $cnt;
	# here we have a value so we loop through the nodes
		for my $node (@{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}}){
my $depth=0;
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}){
$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}};
}

		$cnt++;
		my $node_type;
		if($element){$node_type="content";}
		if($attribute){$node_type=$attribute;}
			if($node->{$node_type} eq $value){
			# 
			# node found;  
			# $doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[$cnt-1]
			## here we go ahead and add our table to this node
			$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}[$depth]=$table_data;
			next LOOPCNT;
			}
		
                ## here we look ahead in the array for a value for the next item
                        if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[$cnt]){
                        $doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[$cnt]->{$node_type}=$value;
                        ## here we add the rest of the table stuff on
                        $doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[$cnt]->{$tableroot}[0]=$table_data;
                                                next LOOPCNT;

                        }
}
	}
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[0]->{$node_type}=$value;
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-1]}[0]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}
}  # end if pacth_cnt == 1

if($path_cnt == 2){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$node_type}=$value;
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}
	if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){

	my $cnt;
		for my $node (@{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}}){	
		$cnt++;
			if($node->{$node_type} eq $value){
			## here we go ahead and add our table to this node
			my $depth=0;
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}){
$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}};
}

			$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}[$depth]=$table_data;
			next LOOPCNT;
			}
}

if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$node_type}=$value;
## here we add the rest of the table stuff on
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$tableroot}[0]=$table_data;

next LOOPCNT;
}

}  
} # end if  ==2

if($path_cnt == 3){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$node_type}=$value;
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
my $cnt;
for my $node (@{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}}){
$cnt++;
if($node->{$node_type} eq $value){
my $depth=0;
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}){
$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}};
}
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}[$depth]=$table_data;
next LOOPCNT;
}
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$node_type}=$value;
## here we add the rest of the table stuff on
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}
}
}
} # end if == 3


if($path_cnt == 4){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$node_type}=$value;
## here we add the rest of the table stuff on
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}

if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
my $cnt;
for my $node
(@{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}}){
$cnt++;
if($node->{$node_type} eq $value){
my $depth=0;
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[$cnt-1]->{$tableroot}){
$depth=scalar @{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[$cnt-1]->{$tableroot}};
}
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[$cnt-1]->{$tableroot}[$depth]=$table_data;
next LOOPCNT;
}
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$node_type}=$value;
## here we add the rest of the table stuff on
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}

}
}
} # end if == 4

if($path_cnt == 5){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$node_type}=$value;
## here we add the rest of the table stuff on
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}


if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
my $cnt;
for my $node
(@{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}}){
$cnt++;
if($node->{$node_type} eq $value){
my $depth=0;
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}){
$depth=scalar
@{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}};
}
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}[$depth]=$table_data;
next LOOPCNT;
}
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$node_type}=$value;
## here we add the rest of the table stuff on
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}

}
}
} ## end if == 5

if($path_cnt == 6){
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$node_type}=$value;
## here we add the rest of the table stuff on
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[0]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}

if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}){
my $cnt;
# here we have a value so we loop through the nodes
for my $node
(@{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}}){
$cnt++;
if($node->{$node_type} eq $value){
my $depth=0;
if($doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}){
$depth=scalar  @{$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}};
}
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-1]}[$cnt-1]->{$tableroot}[$depth]=$table_data;
next LOOPCNT;
}
if(!$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]){
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$node_type}=$value;
## here we add the rest of the table stuff on
$doc{$the_root}[$rootcnt]->{$path[$path_cnt-6]}[0]->{$path[$path_cnt-5]}[0]->{$path[$path_cnt-4]}[0]->{$path[$path_cnt-3]}[0]->{$path[$path_cnt-2]}[0]->{$path[$path_cnt-1]}[$cnt]->{$tableroot}[0]=$table_data;
next LOOPCNT;
}
}
}
} # end if ==6 

}
}  # end lpcnt;
}  # end if all_data
}  # end keys (ie table level loop)

my $thexml;
if($rootcnt <= 0){
my $xmldoc=\%doc;
$thexml=$parser->XMLout($xmldoc,
xmldecl=>qq[
<!-- document created using XMLWriter $VERSION at $date -->]);
}
if($rootcnt > 0){
my $xmldoc=\%doc;
my %predoc;
$predoc{MultiQueryDoc}->{content}="\n".$parser->XMLout($xmldoc);
$xmldoc=\%predoc;
$thexml=$parser->XMLout($xmldoc, 
xmldecl=>qq[<?xml version='1.0' standalone='yes'?>\n
<!-- document created using XMLWriter $VERSION  at $date -->]);
}

return($thexml);

#############
} # end sub makexml
######################

1;

__END__


=head1  NAME 

	DBIx::XML::DataLoader::XMLWriter

=head1  SYNOPSIS

	use DBIx::XML::DataLoader::XMLWriter;

	my $doc=DBIx::XML::DataLoader::XMLWriter->makexml(\%all_data, $doc_root);

=for text or

=for man .SH "\tor"

=for man .IX Subsection "\tor"

=for html <b>or</b>

	use DBIx::XML::DataLoader::XMLWriter;

	my $w=DBIx::XML::DataLoader::XMLWriter->new();
        my $doc=$w->makexml(\%all_data, $doc_root);

=head1  DESCRIPTION

	XMLWriter is packaged as part of the DBIx::XML::DataLoader module.
        XMLWriter.pm will take a referance to a data structure and
	output xml based upon the contents of the referanced data.
	

=head1  SIMPLE EXAMPLE
	

	The data sent to XMLWriter needs to be in the following structure.
	XMLWriter expects to get hash referance to a hash that contains
	a hash keyed to table names, with each table key's value is a hash
	containing a data hash and keys for (parent, xpath, and node);
	
	The data hash will contain all data for a given segment of xml.
	The hash is keyed by numbers that are based on the number of iterations
	of data contained in the hash. Each number key points to a array of hash which
	contain the actual data, item_node, xpath, and a attribute. Only the attribute node is
	optional.


=head1  SAMPLE CODE


	use DBIx::XML::DataLoader::XMLWriter;

        $rootnode="docroot";
        %sample=(
        xml_a=>(
                data=>(
                1=>[{
                        val='hello',
                        item_node='first',
                        xpath=>'./message',
                        attribute=>undef
                   },

                {
                        val='world',
                        item_node='second',
                        xpath=>'./message',
                        attribute=>undef
                   }],
        parent=> undef,
        xpath=>'./welcome/message',
        node=>'welcome'
        );

        print  DBIx::XML::DataLoader::XMLWriter->makexml(\%sample, $doc_root);

=for text or

=for man or

=for html <b>or</b>
	
	use DBIx::XML::DataLoader::XMLWriter;
	
	my $w=DBIx::XML::DataLoader::XMLWriter->new();
        $rootnode="docroot";
        %sample=(
        xml_a=>(
                data=>(
                1=>[{
                        val='hello',
                        item_node='first',
                        xpath=>'./message',
                        attribute=>undef
                   },

                {
                        val='world',
                        item_node='second',
                        xpath=>'./message',
                        attribute=>undef
                   }],
        parent=> undef,
        xpath=>'./welcome/message',
        node=>'welcome'
        );

        print  $w->makexml(\%sample, $doc_root);


=head2  The results would be


	<?xml version='1.0' standalone='yes'?>
	<!-- document created using XMLWriter 1.0 at Time 11:11:00 Date 11/20/2002 -->
	<docroot>
	  <welcome>
	    <message>
	      <first>hello</first>
	      <second>world</second>
	    </message>
	  </welcome>
	</docroot>


=head1  MORE COMPLEX SAMPLE CODE


	use DBIx::XML::DataLoader::XMLWriter;

        $rootnode="family_tree";
        %sample=(
        	xml_a=>{
                	data=>{
                	1=>[{
                        val=>'Tom',
                        xpath=>'./first',
                        item_node=>'first',
                        attribute=>undef
                   	},

                	{
                        val=>'brother',
                        xpath=>'./type',
                        item_node=>'type',
                        attribute=>undef
                   	},
						{
			val=>'Ann',
			xpath=>'parent::maternal/@mother',
			node=>'parent::maternal',
			attribute=>'mother'
			}],
                	
			2=>[{
                        val=>'Chris',
                        xpath=>'./first',
                        item_node=>'first',
                        attribute=>undef
                   	},

                	{
                        val=>'brother',
                        xpath=>'./type',
                        item_node=>'type',
                        attribute=>undef
                   	},
			{
			val=>'Ann',
			xpath=>'parent::maternal/@mother',
			item_node=>'parent::maternal',
			attribute=>'mother'
			}
			]},
        	parent=> 'mother',
        	xpath=>'./family/maternal/sybling',
        	node=>'sybling'},

        	mother=>{
                	data=>{
                	1=>[{
                        val=>'Ann',
                        xpath=>'./maternal/@mother',
                        item_node=>'maternal',
                        attribute=>'mother'
                   	},

                	{
                        val=>'Shumm',
                        xpath=>'./maternal/@maiden',
                        item_node=>'maternal',
                        attribute=>'maiden'
                   	}]},
        	parent=> undef,
        	xpath=>'./family',
        	node=>'family'}

        );

	$xmlref=\%sample;
        print  DBIx::XML::DataLoader::XMLWriter->makexml($xmlref, $rootnode);


=head2	The results would be 
 

	<?xml version='1.0' standalone='yes'?>
	<!-- document created using XMLWriter at Time 11:14:50 Date 11/22/2002 -->
	<family_tree>
	  <family>
	    <maternal mother="Ann" maiden="Shumm">
	      <sybling>
	        <first>Tom</first>
	        <type>brother</type>
	      </sybling>
	      <sybling>
	        <first>Chris</first>
	        <type>brother</type>
	      </sybling>
	    </maternal>
	  </family>
	</family_tree>




=head1  Also see man page for

=for man DBIx::XML::DataLoader::XMLWriter,  DBIx::XML::DataLoader::MapIt, and DBIx::XML::DataLoader::DB

=for text DBIx::XML::DataLoader::XMLWriter,  DBIx::XML::DataLoader::MapIt, and DBIx::XML::DataLoader::DB


=for html
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

=for html
 <a href="XMLWriter.html">DBIx::XML::DataLoader::XMLWriter</a>,&nbsp

=for html
 <a href="MapIt.html">DBIx::XML::DataLoader::MapIt<a/>,&nbsp and &nbsp;<a href="DB.html">DBIx::XML::DataLoader::DB</a>,&nbsp

=for html
<p><hr><p>



