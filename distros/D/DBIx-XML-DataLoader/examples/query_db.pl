#!/usr/bin/perl -w


use strict;
use warnings;


#########################################################################################
##  this script demonstrates how to construct a xml document based on sql queries that	
##  are built based on a xml map file.
##
##  This script can be called with command line arguments or user will be prompted for 
##  needed information.
##
##  The command line options are path_to/map_file.xml path_to/output.xml
##  If map file is not supplied then the output file should not be supplied either.
##
##  If no command line arguments then the script will prompt you for a map file
##  and then a optional outfile. If no outfile is provided then the output file 
##  will be ./sql_to_xml.xml
##
## 
##  Basic Operation: 
##
##  this script will first pass the fullpath of the map file to the MapIt module
##  Then using the data structure returned by MapIt, this script will request
##  the user for query information for any keyelements in the map file.
##  
##  The DB module will be used for making data connections
##  With a connection made to the database the script passes a custom query based on 
##  the map file information.
##
##  The resulting data will be passed to the XMLWriter module
##  
##  Other Modules in the DBIx::XML::DataLoader packaged that are used directly from this script
##  are Date
##
##
#########################################################################################

my @info;

use DBIx::XML::DataLoader::XMLWriter;
use DBIx::XML::DataLoader::DB;
use DBIx::XML::DataLoader::Date;
use DBIx::XML::DataLoader::MapIt;

my $date=DBIx::XML::DataLoader::Date->now();
my $all_stuff;
my %all_data;
my $map="./maps/map.xml";
my $outdoc="outdoc.xml";

if(!$map){
	print "\nPlease Enter the map file you will be using:";
	$map=<STDIN>;
	chomp $map;
}

if(!$map){print "You did not enter a map file name. Goodbye\n";exit;}

if(!$outdoc){
	print "\nPlease Enter a name for the outputdoc(optional):";
	$outdoc=<STDIN>;
	chomp $outdoc;
}
if(!$outdoc){$outdoc="sqltoxml.xml";}
my $doc_root="ROOT";
my  @classmap=DBIx::XML::DataLoader::MapIt->mapclasses($map);
my @tables=@{$classmap[4]};
my $dbinfo=$classmap[1];
my $doc_key=$classmap[5];
if($classmap[2]){$doc_root=$classmap[2];}
my $db_connections;
my $db=DBIx::XML::DataLoader::DB->new();
$doc_root=~s[^/][];
my %doc=($doc_root=>[{}]);

my $rootcnt;
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
my %dbstatements;
my $dbstatements;
my %table_info;
if($classmap[3]){%table_info=%{$classmap[3]};}
my %doc_key_hash;

if($doc_key){
	print qq[\nThis document has a global key of ],$doc_key, 
	      qq[.\nSet a value for ],$doc_key,"(optional):";
	my $doc_key_value=<STDIN>;
	chomp $doc_key_value;
	if($doc_key_value){$doc_key_hash{$doc_key}=$doc_key_value;}
} 

TABLE: foreach my $tab (@tables){
	my $table=$tab;
	my $table_stuff=pop @{$table_info{$tab}};
	my $table_xpath=$table_stuff->{xpath};
	my $table_child=$table_stuff->{child};
	my $table_parent=$table_stuff->{parent};
	my $table_dbh=$table_stuff->{dbname};
	my @table_path=split m[/], $table_xpath;
	my $table_node=pop @table_path;
	$all_data{$table}->{child}=$table_child;
	$all_data{$table}->{parent}=$table_parent;
	$all_data{$table}->{xpath}= $table_xpath;
	$all_data{$table}->{node}=$table_node;
	$all_data{$table}->{dbname}=$table_dbh;
	my $dbh=$db_connections->{$table_stuff->{dbname}};
	my @where;
	## here we get our keys for the db query we will need
	my @tabkeys_array=@{$table_stuff->{'keys'}};
	my $current_key=1;
	KEYS_LOOP:while (@tabkeys_array){
		my $tbkeys= shift @tabkeys_array;

		for my $keys (keys %{$tbkeys}){
			if($keys > $current_key){
				push @tabkeys_array, $tbkeys;next KEYS_LOOP;
			}
			$current_key++;
			my $tabkey;

			if($doc_key_hash{$tbkeys->{$keys}})
				{$tabkey=$doc_key_hash{$tbkeys->{$keys}};}
			if(!$doc_key_hash{$tbkeys->{$keys}}){
				print "Search $table for $tbkeys->{$keys}:";
				$tabkey=<STDIN>;
				chomp $tabkey;
			}
			if($tabkey){
				my $qtabkey=$dbh->quote($tabkey);
				push @where, "$tbkeys->{$keys}=$qtabkey";
			}
		}
	}
	my $queryinfo=join " and ",@where;
	my $qcnt=scalar @where;
	if($qcnt < 1){next TABLE;}
	if($queryinfo){
		my $fullqueryinfo=" where ".$queryinfo;
		$queryinfo=$fullqueryinfo;
	}

	my $querystring="select * from ".$tab .$queryinfo;
	my $upd=$dbh->prepare(qq{$querystring})||warn "db problem $table ", DBI::errstr;
	my %datarow;
	$upd->execute()||warn "failed to execute $table ", DBI::errstr;
	my $loopcnt;
		while(my $datarow=$upd->fetchrow_hashref('NAME_lc')){
			$loopcnt++;
			my @info;
		        for my $key (keys %{$datarow}){
				my $xpath;
				my $date;
				TEST_NODE: for my $test_node (@{$table_info{$tab}}){
					if($test_node->{col} =~ /^$key$/i){
						$xpath=$test_node->{xpath};
						$date=$test_node->{date};
						last TEST_NODE;
					}

				}
				my @item_xpath=split m[/], $xpath;
				my $item_node=pop @item_xpath;
				my $attr;
				if($item_node =~ /\@/){$item_node =~s/\@//;
					$attr=$item_node;
					if($xpath !~ /^parent::/){
						$item_node = pop @item_xpath;
						if((!$item_node) or ($item_node=".")){
							$item_node=$table_node;
						}
					}
					if($xpath =~ /^parent::/){
						$item_node=shift @item_xpath;
					}
				}
				my $value=$datarow->{$key};
				## here I am converting the date so that it matches the 
				## required format of the output xml
				if($date){
					my $conv_value=$db->conv_sqldate($dbh, 
									$value, 
									$date, 
									$table);
					$value=$conv_value;
				}

				push @info, {val=>$value, xpath=>$xpath, 
				item_node=>$item_node,  attribute=>$attr};
			}
			$all_data{$table}->{data}->{$loopcnt}=[@info];
		}
}

open(OUT, ">$outdoc");
print OUT DBIx::XML::DataLoader::XMLWriter->makexml(\%all_data, $doc_root);
close(OUT);
print "\nthe XML document $outdoc has been created\n";
