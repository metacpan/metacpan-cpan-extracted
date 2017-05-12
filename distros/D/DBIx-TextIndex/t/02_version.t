use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('DBIx::TextIndex') };

is(DBIx::TextIndex->VERSION, '0.28');
