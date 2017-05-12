use strict;
use Test;

use Array::PatternMatcher qw(:all) ;
use Data::Dumper;

BEGIN { plan tests => 1 }

my $pattern = 'who cares' ;
my $input   = 'really dont matter' ;

# Variables

# if no bindings, add a binding between pattern and input
my $result = pat_match ($pattern, $input, undef);
ok(!defined$result);
