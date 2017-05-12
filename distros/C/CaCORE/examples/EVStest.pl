#!/usr/bin/perl -w

use strict;

use LWP::UserAgent;
use HTTP::Request::Common;
use CaCORE::ApplicationService;
use CaCORE::EVS;

#
# ApplicationService is a utility classs that encapsulates webservice invocation to caCORE server.
# ApplicationService object follows the Singleton pattern, in that each program will ONLY contain one instance
# of such class.
# The URL being passed to the intance method is the service endpoint of the caCORE webservice.
# If no such URL is provided in the program, it will default to the caCORE production server, "http://cabio.nci.nih.gov/cacore30/ws/caCOREService"
#
my $appsvc = CaCORE::ApplicationService->instance("http://cabio.nci.nih.gov/cacore32/ws/caCOREService");

my $num2 = 0;

# test EVS 1: Search Metaphrase by Atom and Source
#
# This test case retrieves a MetaThesaurusConcept with a atom with code "1256-5501", and a source with abbrieviation "CSP2004"
#
print "test EVS 1 -- Search Metaphrase by Atom and Source\n";
# contruct search criteria
# First create an Atom object and sets its code attribute
my $atom = new CaCORE::EVS::Atom;
$atom->setCode("1256-5501");
my @atoms = ();
push @atoms, $atom;
# Second create a Source object and sets its abbreviation attributes
my $source = new CaCORE::EVS::Source;
$source->setAbbreviation("CSP2005");
my @sources = ($source);
# create a MetaThesaurusConcept instance and sets its Atom and Source relations
my $mtc = new CaCORE::EVS::MetaThesaurusConcept;
$mtc->setAtomCollection(@atoms);
$mtc->setSourceCollection(@sources);
my @mtcResults;
# the eval...warn... construct is recommended, if error is encountered during webservice call, this will
# trap the exception and allows for error handling, and prevent the program from exiting.
eval{
	#
	# This call encapsulates the webservice invocation to the caCORE server, and converts
	# the returned XML into list of MetaThesaurusConcept objects
	# Parameter 1 indicates target class, MetaThesaurusConcept, to be retrieved
	# Parameter 2 indicates search criteria. In this case, MetaThesaurusConcept with cetain Atoms and Sources.
	#
	@mtcResults = $appsvc->queryObject("CaCORE::EVS::MetaThesaurusConcept", $mtc);
};
warn "Test EVS 1 failed. Error:\n" . $@ if $@;
# iterate through results
foreach my $metaConcept (@mtcResults) {
	print "MetaThesaurusConcept: cui=" . $metaConcept->getCui . ", name=" . $metaConcept->getName . "\n";
}
$num2 = $#mtcResults + 1;
print "number of result: " . $num2 . "\n";

# test EVS 2: Search matching DescLogicConcepts for a MetaThesaurusConcept.
#
# This test case searches for matching DescLogicConcepts given a MetaThesaurusConcept.
#
print "test EVS 2 -- Search matching DescLogicConcepts for a MetaThesaurusConcept.\n";
my @dlcSet;
eval{
	@dlcSet = $appsvc->queryObject("CaCORE::EVS::DescLogicConcept", $mtc);
};
warn "Test EVS 2 failed. Error:\n" . $@ if $@;
foreach my $dlc (@dlcSet) {
	print "DescLogicConcept: code=" . $dlc->getCode . ", name=" . $dlc->getName . "\n";
}
$num2 = $#dlcSet + 1;
print "number of result: " . $num2 . "\n";

# test EVS 3: Search DescLogicConcept by code
#
# This test searches for all DescLogicConcepts with a given code
#
print "test EVS 3 -- Search DescLogicConcept by code.\n";
my $dlConcept = new CaCORE::EVS::DescLogicConcept;
$dlConcept->setCode("C12756");
eval{
	@dlcSet = $appsvc->queryObject("CaCORE::EVS::DescLogicConcept", $dlConcept);
};
warn "Test EVS 3 failed. Error:\n" . $@ if $@;
foreach my $dlc (@dlcSet) {
	print "DescLogicConcept: code=" . $dlc->getCode . ", name=" . $dlc->getName . "\n";
}
$num2 = $#dlcSet + 1;
print "number of result: " . $num2 . "\n";

# test EVS 4: Search for a matching MetaThesaurusConcept based on a DescLogicConcept
#
# This test searches for matching MetaThesaurusConcepts given a DescLogicConcept
#
print "test EVS 4: Search for a matching MetaThesaurusConcept based on a DescLogicConcept\n";
eval{
	@mtcResults = $appsvc->queryObject("CaCORE::EVS::MetaThesaurusConcept", $dlConcept);
};
warn "Test EVS 4 failed. Error:\n" . $@ if $@;
foreach my $metaConcept (@mtcResults) {
	print "MetaThesaurusConcept: cui=" . $metaConcept->getCui . ", name=" . $metaConcept->getName . "\n";
}
$num2 = $#mtcResults + 1;
print "number of result: " . $num2 . "\n";

print "Test completed.\n";


