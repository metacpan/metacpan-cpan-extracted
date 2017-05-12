
package CL;

use vars (@ISA);

@ISA = qw(App::CCSV);

use App::CCSV;

sub PV () { 0 }
sub IV () { 1 }
sub NV () { 2 }

1;
