use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use DBIx::Class::InflateColumn::Geo;
ok 1, 'Loaded';

done_testing;
