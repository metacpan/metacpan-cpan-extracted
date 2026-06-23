use strict;
use warnings;

use Test::More;

use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $tkfks = $schema->resultset('Artist');

ok !$tkfks->is_paged, 'vanilla resultset is not paginated';

my $paginated = $tkfks->search(undef, { page => 5 });
ok $paginated->is_paged, 'resultset is paginated now';

done_testing;
