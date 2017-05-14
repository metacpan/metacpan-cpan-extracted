#!/usr/bin/perl -w


use strict;
use warnings;

############################################################################
##
##  This script demonstrates how to use DBIx::XML::DataLoader::XMLWriter
##  The hash %sample below is passed along with the variable $rootnode
##  directly to the XMLWriter module. The module passes xml suitable for 
##  printing also look at query_sql.cb for a more complete example including
##  the dynamic creation of the hash we send to the XMLWriter module
##
#############################################################################


use DBIx::XML::DataLoader::XMLWriter;
my $w=DBIx::XML::DataLoader::XMLWriter->new();

my        $rootnode="family_tree";
my         %sample=(
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
                        val=>'Smith',
                        xpath=>'./maternal/@maiden',
                        item_node=>'maternal',
                        attribute=>'maiden'
                   	}]},
        	parent=> undef,
        	xpath=>'./family',
        	node=>'family'}

        );

my	$xmlref=\%sample;
        print  $w->makexml($xmlref, $rootnode);



__END__


##############################################################
## below is what the output from this script would look like
###############################################################


<?xml version='1.0' standalone='yes'?>
<!-- document created using XMLWriter 1.0 -->
<family_tree>
  <family>
    <maternal mother="Ann" maiden="Smith">
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





