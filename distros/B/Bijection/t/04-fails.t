use Test::More;
use Bijection qw/all/;

my $bi = eval { biject(0.1) };
like($@, qr/id to encode must be an integer and non-negative: 0.1/, 'error 0.1');

$bi = eval { biject(-1) };
like($@, qr/id to encode must be an integer and non-negative: -1/, 'error -1');

$bi = eval { biject('a') };
like($@, qr/id to encode must be an integer and non-negative: a/, 'error a');

$bi = eval { inverse('FU') };
like($@, qr/invalid character U in FU/, 'error FU');

done_testing(4);

1;
