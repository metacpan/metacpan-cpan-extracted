use strict;
use warnings;

use Test::More tests => 2;
use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Test::Schema::Artist;

DBIO::Test::Schema::Artist->source_name('MyArtist');
DBIO::Test::Schema->register_class('FooA', 'DBIO::Test::Schema::Artist');

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# Mock the count query for FooA (artists table)
$schema->storage->mock_persistent(qr/SELECT COUNT/i, [[3]]);

my $a = $schema->resultset('FooA')->search;
is($a->count, 3, 'have 3 artists');
is($schema->class('FooA'), 'DBIO::Test::Schema::Artist', 'Correct artist class');

# clean up
DBIO::Test::Schema->_unregister_source('FooA');
