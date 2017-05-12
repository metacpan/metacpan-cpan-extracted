package DBR::ResultSet::Empty;

use strict;
#use base 'DBR::Common';
use DBR::Misc::Dummy;
use Carp;
use constant ({
	       DUMMY => bless([],'DBR::Misc::Dummy')
	      });
sub new { bless( [], shift ) } # minimal reference

sub delete {croak "Mass delete is not allowed. No cookie for you!"}
sub each { 1 }
sub split { {} }
sub values { wantarray?():[]; }

sub dummy_record{ DUMMY }
sub hashmap_multi { wantarray?():{} }
sub hashmap_single{ wantarray?():{} }

sub next     { DUMMY }
sub where    { DUMMY }
sub count    { 0     }

sub TO_JSON { [] }

1;
