use strict;
use warnings;
use Test::More;

use lib 't/plugins_test';
use Bio::Chado::Schema;

my $schema = Bio::Chado::Schema->connect('dbi:SQLite::memory:');
isa_ok( $schema, 'DBIx::Class::Schema' );

$schema->deploy;
ok 1, 'deployed OK';

is $schema->resultset('MyPlugin::Foo')->count, 0,
   'got MyPlugin::Foo resultset, no rows';

is $schema->resultset('Organism::Organism')->search_related('myplugin_foos')->count, 0,
   'successfully injected rel';

done_testing;
