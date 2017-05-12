
# kwalitee test

use strict ;
use warnings ;

use Test::More;
#use Test::UniqueTestNames ;

eval { require Test::Kwalitee; Test::Kwalitee->import() };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;