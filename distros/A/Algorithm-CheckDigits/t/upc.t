use Test;
BEGIN {
	plan(tests => 1); 
};
use Algorithm::CheckDigits;

my $upc = CheckDigits('upc');

# there was an error exposed with that number, so I include it here to
# avoid making that error again.
#
# Thanks to Aaron W. West
#
ok($upc->is_valid("724358016420"));
