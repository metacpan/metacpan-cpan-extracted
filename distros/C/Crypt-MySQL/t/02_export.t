use strict;
use Test::More tests => 2;

use Crypt::MySQL qw(password password41);

is(password("barbaz"), "5256847878f9978f");
is(password41("barbaz"), "*096C6A6F0E3B0A35BFF7794D732F2269D6BBE164");
