use warnings;
use strict;

use Test::More;
use DBIO::Test;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

plan tests => 3;

# bug in 0.07000 caused attr (join/prefetch) to be modifed by search
# so we check the search & attr arrays are not modified
my $search = { 'artist.name' => 'Caterwauler McCrae' };
my $attr = { prefetch => [ qw/artist liner_notes/ ],
             order_by => 'me.cdid' };
my $search_str = Dumper($search);
my $attr_str = Dumper($attr);

my $rs = $schema->resultset("CD")->search($search, $attr);

is(Dumper($search), $search_str, 'Search hash untouched after search()');
is(Dumper($attr), $attr_str, 'Attribute hash untouched after search()');

# $rs + 0 triggers count() via overloaded numification
$schema->storage->mock_persistent(qr/SELECT COUNT/i, [[3]]);
cmp_ok($rs + 0, '==', 3, 'Correct number of records returned');
