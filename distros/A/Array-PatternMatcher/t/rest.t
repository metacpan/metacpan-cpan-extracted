use strict;
use Test;

use Array::PatternMatcher qw(:all) ;
use Data::Dumper;

BEGIN { plan tests => 2 }

my $aref1 = [ 12 ];

my $aref2 = [ 1,2,3 ];

# Variables

my $result1 = rest $aref1 ;
my $result2 = rest $aref2 ;

my $undefined;

ok($result1,$undefined);
ok("@$result2", "2 3");
