package Example::Server;

use warnings;
use strict;
use CAM::SOAPApp;

our @ISA = qw(SOAP::Server::Parameters);

sub quit
{
   #print "exiting real soon...\n";
   alarm(1);
   return 1;
}

sub isLeapYear {
   my $pkg = shift;
   alarm(2); # give us a time boost
   my $app = CAM::SOAPApp->new(soapdata => \@_);
   unless ($app) {
      CAM::SOAPApp->error("Internal", "Failed to initialize the SOAP app");
   }
   my %data = $app->getSOAPData();
   unless (defined $data{year}) {
      $app->error("NoYear", "No year specified in the query");
   }
   unless ($data{year} =~ /^\d+$/) {
      $app->error("BadYear", "The year must be an integer");
   }
   my $leapyear = ($data{year} % 4 == 0 &&
                   ($data{year} % 100 != 0 ||
                    $data{year} % 400 == 0));
   return $app->response(leapyear => $leapyear ? 1 : 0);
}

1;
