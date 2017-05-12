#!perl
use 5.010;
use strict;
use warnings;

use Acme::StringFormat;

for my $n(1 .. 100){
	say 'sqrt(%3d) = %5.02f %s' % $n % sqrt($n) % ('*' x (sqrt $n));
}
