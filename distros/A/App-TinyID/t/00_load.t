use Test::More tests => 3;

use_ok('Getopt::Long', qw(GetOptions));
use_ok('Integer::Tiny');
use_ok('Scalar::Util', qw(looks_like_number));

done_testing();
