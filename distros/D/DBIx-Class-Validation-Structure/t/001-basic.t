use strict;
use Test::More;

use lib './local/lib/perl5';
use lib qw{ ./t/lib };

ok 1;
use_ok('DBIx::Class::Validation::Structure');

done_testing;
