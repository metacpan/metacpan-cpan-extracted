# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CaCORE.t'

#########################

use Test::Simple tests => 11;
use CaCORE::ApplicationService;
use CaCORE::CaBIO;
use CaCORE::EVS;
use CaCORE::CaDSR;
use CaCORE::Common;

# test create ApplicationService instance
my $appsvc = CaCORE::ApplicationService->instance("http://cabio.nci.nih.gov/cacore30/ws/caCOREService");
ok( defined $appsvc, " ApplicationSerice constructor" );
ok( $appsvc->isa('CaCORE::ApplicationService'), " Validate class for CaCORE::ApplicationService" );

# test create a CaBIO domain object
my $gene = new CaCORE::CaBIO::Gene;
$gene->setSymbol("NAT2");
ok( defined $gene, " Domain object CaCORE::CaBIO::Gene constructor" );
ok( $gene->isa('CaCORE::CaBIO::Gene'), " Validate class for Gene"  );
ok( $gene->getSymbol eq "NAT2", " Correct Gene getter and setter methods" );

# test create an EVS domain object
my $dlConcept = new CaCORE::EVS::DescLogicConcept;
$dlConcept->setCode("C12756");
ok( defined $dlConcept, " Domain object CaCORE::EVS::DescLogicConcept constructor" );
ok( $dlConcept->isa('CaCORE::EVS::DescLogicConcept'), " Validate class for DescLogicConcept"  );
ok( $dlConcept->getCode eq "C12756", " Correct DescLogicConcept getter and setter methods" );

# test create a CaDSR domain object
print "test CaDSR 1: retrieve caDSR object AdministeredComponent\n";
my $ac = new CaCORE::CaDSR::AdministeredComponent;
$ac->setPublicID(2178629);
ok( defined $ac, " Domain object CaCORE::CaDSR::AdministeredComponent constructor" );
ok( $ac->isa('CaCORE::CaDSR::AdministeredComponent'), " Validate class for AdministeredComponent"  );
ok( $ac->getPublicID eq 2178629, " Correct AdministeredComponent getter and setter methods" );

# test create a Common domain object

