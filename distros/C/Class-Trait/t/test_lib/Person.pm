package Person;
use strict;
use warnings;

sub name { 'George Richardson' }

sub new { bless({}, shift())  }

1;
