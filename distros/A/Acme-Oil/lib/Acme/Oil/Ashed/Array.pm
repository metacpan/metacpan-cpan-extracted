
##############################################################################
package Acme::Oil::Ashed::Array;

use warnings;
use strict;
use Carp;
use Tie::Array;
use base qw(Tie::StdArray Acme::Oil::ed);


sub FETCH { 'ASH'; }


sub STORE     {  }

sub FETCHSIZE { 0 }
sub STORESIZE {  }
sub CLEAR     {  }
sub POP       {  }
sub PUSH      {  }
sub SHIFT     {  }
sub UNSHIFT   {  }
sub EXISTS    { 0 }
sub DELETE    {  }



1;
