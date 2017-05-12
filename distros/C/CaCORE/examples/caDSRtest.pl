#!/usr/bin/perl -w

use strict;

use LWP::UserAgent;
use HTTP::Request::Common;
use CaCORE::ApplicationService;
use CaCORE::CaBIO;
use CaCORE::CaDSR;

#
# ApplicationService is a utility classs that encapsulates webservice invocation to caCORE server.
# ApplicationService object follows the Singleton pattern, in that each program will ONLY contain one instance
# of such class.
# The URL being passed to the intance method is the service endpoint of the caCORE webservice.
# If no such URL is provided in the program, it will default to the caCORE production server, "http://cabio.nci.nih.gov/cacore30/ws/caCOREService"
#
my $appsvc = CaCORE::ApplicationService->instance("http://cabio.nci.nih.gov/cacore32/ws/caCOREService");

# test CaDSR 1 test
print "test CaDSR 1: retrieve caDSR object ObjectClass\n";
my $oc = new CaCORE::CaDSR::ObjectClass;
$oc->setWorkflowStatusName("RELEASED");
my @resultList;
eval{
	#
	# This call encapsulates the webservice invocation to the caCORE server, and converts
	# the returned XML into list of ObjectClass objects
	# Parameter 1 indicates target class, ObjectClass, to be retrieved
	# Parameter 2 indicates search criteria. In this case, ObjectClass with workflowStatusName of "RELEASED".
	#
	@resultList = $appsvc->queryObject("CaCORE::CaDSR::ObjectClass", $oc);

	foreach my $objCls (@resultList) {
		print "ObjectClass: id=" . $objCls->getId . "\n";
	}
	my $num2 = $#resultList + 1;
	print "number of result: " . $num2 . "\n";
};
warn "Test CaDSR 1 failed. Error:\n" . $@ if $@;

# test CaDSR 2 test
print "test CaDSR 2: retrieve caDSR object DataElementConcept given object ObjectClass\n";
my $dec = new CaCORE::CaDSR::DataElementConcept;
eval{
	#
	# This call encapsulates the webservice invocation to the caCORE server, and converts
	# the returned XML into list of DataElementConcept objects
	# Parameter 1 indicates target class, DataElementConcept, to be retrieved
	# Parameter 2 indicates search criteria. In this case, ObjectClass with workflowStatusName of "RELEASED".
	#
	@resultList = $appsvc->queryObject("CaCORE::CaDSR::DataElementConcept", $oc);

	foreach my $dataEC (@resultList) {
		print "DataElementConcept: id=" . $dataEC->getId . "\n";
	}
	my $num2 = $#resultList + 1;
	print "number of result: " . $num2 . "\n";
};
warn "Test CaDSR 2 failed. Error:\n" . $@ if $@;

print "Test completed.\n";


