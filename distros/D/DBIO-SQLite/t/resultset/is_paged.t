use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

my $tkfks = $schema->resultset('Artist');

ok !$tkfks->is_paged, 'vanilla resultset is not paginated';

my $paginated = $tkfks->search(undef, { page => 5 });
ok $paginated->is_paged, 'resultset is paginated now';

done_testing;
