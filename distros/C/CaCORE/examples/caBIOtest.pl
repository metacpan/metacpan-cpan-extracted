#!/usr/bin/perl -w

# works with Axis 1.2

use strict;

use LWP::UserAgent;
use HTTP::Request::Common;
use CaCORE::ApplicationService;
use CaCORE::CaBIO;
use CaCORE::Security;
use CaCORE::CaDSR;

#
# ApplicationService is a utility classs that encapsulates webservice invocation to caCORE server.
# ApplicationService object follows the Singleton pattern, in that each program will ONLY contain one instance
# of such class.
# The URL being passed to the intance method is the service endpoint of the caCORE webservice.
# If no such URL is provided in the program, it will default to the caCORE production server, "http://cabio.nci.nih.gov/cacore30/ws/caCOREService"
#
my $appsvc = CaCORE::ApplicationService->instance("http://cabio.nci.nih.gov/cacore32/ws/caCOREService");

# test CaBIO 1: use ApplicationService
# 
# This test retrieves all Chromosomes whoses associated genes have a symbol of "NAT2" using the direct
# and basic search function of ApplicationService->queryObject
#
print "test CaBIO 1: use ApplicationService to search Gene given a gene symbol attribute\n";

# instantiate a Gene domain object and sets the value of symbol attribute to NAT2.
my $gene = new CaCORE::CaBIO::Gene;
$gene->setSymbol("NAT2");

my @chromos;
# the eval...warn... construct is recommended, if error is encountered during webservice call, this will
# trap the exception and allows for error handling, and prevent the program from exiting.
eval{
	#
	# This call encapsulates the webservice invocation to the caCORE server, and converts
	# the returned XML into list of Chromosome objects
	# Parameter 1 indicates target class, Chromosome, to be retrieved
	# Parameter 2 indicates search criteria. In this case, is the genes associated with the chromosome.
	#
	@chromos = $appsvc->queryObject("CaCORE::CaBIO::Chromosome", $gene);
};
warn "Test CaBIO 1 failed. Error:\n" . $@ if $@; # some exception handling

# iterate thru results
foreach my $chromo (@chromos){
	print "id= " . $chromo->getId . "  number=" . $chromo->getNumber . "\n";
}

# test CaBIO 2: use association: many to one
# 
# This test retrieves the Taxon object that is associated with a Chromosome object via a get method
#
print "test CaBIO 2: navigation by association: many to one\n";
print "\tSearch for the associated taxon given a chromosome object.\n";

# Our starting point is a chromosome object obtained from test 1
my $chromo1 = $chromos[0];
print "start chromosome id=" . $chromo1->getId . "\n";
my $taxon;
eval{
	#
	# The Taxon is associated with Chromosome via a one to many relationship
	# i.e., one taxon is associated with many chromosomes
	# The Chromosome->getTaxon is implemented as a ApplicationService->queryObject as in test 1
	# 
	$taxon = $chromo1->getTaxon;
};
warn "Test CaBIO 2 failed. Error:\n" . $@ if $@;
print "find taxon: id= " . $taxon->getId . " scientificName=" . $taxon->getScientificName ."\n";

# test CaBIO 3: use association: one to many
# 
# This test retrieves all Gene objects that are associated with a Chromosome object via a get method
#
print "test CaBIO 3: navigation by association: one to many\n";
print "\tSearch for all associated genes given a chromosome object.\n";
my @genes;
eval{
	#
	# The Gene is associated with Chromosome via a many to one relationship
	# i.e., many genes are associated with one chromosome
	# The Chromosome->getGeneCollection is implemented as a ApplicationService->queryObject as in test 1
	# 
	@genes = $chromo1->getGeneCollection;
};
warn "Test CaBIO 3 failed. Error:\n" . $@ if $@;
foreach my $gn (@genes) {
	print "Gene: id= " . $gn->getId;
	if( defined($gn->getSymbol) ) { print "  symbol=" . $gn->getSymbol . "\n"; }
	else { print "\n"; }
}
my $num = $#genes + 1;
print "number of result: " . $num . "\n";

# test CaBIO 4: nested search
# 
# For objects that are indirectly associated, they can be retrieved by providing the navigation
# path that reflect how they are related.
# In this test, you can retrieve Taxon that are associated with chromosome, which in turn are associated
# with a gene
#
print "test CaBIO 4: nested search\n";
print "\tSearch for all genes that is associated with taxons that are associated with a given chromosome.\n";
my @taxons;

eval{
	#
	# In this call, we are telling the caCORE server that we have a Gene, we would like to retrieve
	# Taxons that are associated with the chromosomes that are associated with the gene.
	#
	@taxons = $appsvc->queryObject("CaCORE::CaBIO::Taxon,CaCORE::CaBIO::Chromosome", $gene);
};
warn "Test CaBIO 4 failed. Error:\n" . $@ if $@;

foreach my $tx (@taxons){
	print "id= " . $tx->getId . " scientificName=" . $tx->getScientificName ."\n";
}
my $num1 = $#taxons + 1;
print "number of taxons: " . $num1 . "\n";


# test CaBIO 5: throttle mechanism
# 
# The ApplicationService->query method is provides a mechanism to allow you to control
# the size of the resultset.
# In this test, we only retrieve 20 genes starting from number 10.
# Note: By default, when calling ApplicationService->queryObject, the caCORE server automatically
# trim the resultset to 1000 objects if the there more than 1000. So in reality, if you want to
# retrieve anything beyong 1000, you must use ApplicationService->query
#
print "test CaBIO 5: throttle search: return 20 gene objects starting from position 10.\n";
my @geneSet;
eval{
	#
	# this call is similar to that of test1, except the query method has added 2 more parameters
	# Parameter 1 indicates target class, Chromosome, to be retrieved
	# Parameter 2 indicates search criteria. In this case, is the genes associated with the chromosome.
	# Paremeter 3 indicates the requested start index
	# Parameter 4 indicates the requested size
	#
	@geneSet = $appsvc->query("CaCORE::CaBIO::Gene", $chromo1, 10, 20);
};
warn "Test CaBIO 5 failed. Error:\n" . $@ if $@;
foreach my $gne (@geneSet) {
	print "Gene: id= " . $gne->getId;
	if( defined($gne->getSymbol) ) { print "  symbol=" . $gne->getSymbol . "\n"; }
	else { print "\n"; }
}
my $num2 = $#geneSet + 1;
print "number of result: " . $num2 . "\n";

# test CaBIO 6: time data type
#
# The search criteria is a date type, the CaCORE server is rather picky on the format
# The format should be: yyyy-mm-ddTzz:00:00:000Z
#	yyyy - year
#	mm - month
#	dd - day of month
#	zz - time zone
#
print "test CaBIO 6: testing ClinicalTrialProtocol with date type criteria\n";
my $ctp = new CaCORE::CaBIO::ClinicalTrialProtocol;
$ctp->setCurrentStatusDate("2004-03-12T05:00:00.000Z");
my @ctps;
eval{
	@ctps = $appsvc->queryObject("CaCORE::CaBIO::ClinicalTrialProtocol", $ctp);
};
warn "Test CaBIO 6 failed. Error:\n" . $@ if $@;
foreach my $a (@ctps){
	if ($a->getId){ 
		print "ClinicalTrialProtocol id= " . $a->getId . "\n";

	}
}
# test CaBIO 7: Query by Big Id
#
print "test CaBIO 1: query by Big Id\n";

# instantiate a SecurityToken domain object and sets the value of symbol attribute to NAT2.
$gene = new CaCORE::CaBIO::Gene;
$gene->setBigid("hdl://2500.1.PMEUQUCCL5/ONSXKL4KEL");

# the eval...warn... construct is recommended, if error is encountered during webservice call, this will
# trap the exception and allows for error handling, and prevent the program from exiting.
eval{
	#
	# This call encapsulates the webservice invocation to the caCORE server, and converts
	# the returned XML into list of Chromosome objects
	# Parameter 1 indicates target class, Chromosome, to be retrieved
	# Parameter 2 indicates search criteria. In this case, is the genes associated with the chromosome.
	#
	@chromos = $appsvc->queryObject("CaCORE::CaBIO::Chromosome", $gene);
};
warn "Test CaBIO 1 failed. Error:\n" . $@ if $@; # some exception handling

# iterate thru results
foreach my $chromo (@chromos){
	print "Chromosome id=" . $chromo->getId . " number=" . $chromo->getNumber . "\n";
}


print "Test completed.\n";


