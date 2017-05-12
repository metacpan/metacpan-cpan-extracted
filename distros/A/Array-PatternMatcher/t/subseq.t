use strict;
use Test;

use Array::PatternMatcher qw(:all) ;
use Data::Dumper;

BEGIN { plan tests => 1 }

my $aref = [ 1..10 ];

# Variables

my $result = subseq $aref, 0, 2;

warn sprintf "RESULT: %s", Data::Dumper::Dumper($result);
ok("@$result","1 2 3");

