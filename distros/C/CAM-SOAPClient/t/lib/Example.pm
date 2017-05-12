package Example;

use warnings;
use strict;
use CAM::SOAPApp;

our @ISA = qw(SOAP::Server::Parameters);

sub getEmployeeData {
   my $pkg = shift;
   my $app = CAM::SOAPApp->new(soapdata => \@_);
   my %data = $app->getSOAPData();
   if (!$data{ssn} || $data{ssn} ne '111-11-1111') {
      $app->error('BadSSN', 'Never heard of that employee');
   }
   return $app->response(name => 'John Smith',
                         birthdate => '1969-01-01',
                         phone => '212-555-1212');
}

sub fail {
   # Used to test client's handling of faults
   die 'Test fault handling';
}

sub abort {
   # Used to test client's handling of abrupt server departure
   exit(0);
}

1;
