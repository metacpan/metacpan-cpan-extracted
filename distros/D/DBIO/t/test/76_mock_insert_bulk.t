use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

# karr k394, cursor invariant k55: the fake storage's _insert_bulk checks the
# columns exactly like Storage::DBI::_insert_bulk and renders the INSERT with
# the SQLMaker, so a populate that is wrong live is wrong in the mock too.

my $schema  = DBIO::Test->init_schema;
my $storage = $schema->storage;

sub last_insert { (grep { $_->{op} eq 'insert' } @{ $storage->_captured_queries })[-1] }

# unknown column: same exception as the live path, names the column, no value
throws_ok {
  $schema->resultset('Artist')->populate([ { name => 'a', nonexist => 'SECRETVALUE' } ]);
} qr/nonexist/, 'populate with an unknown column throws in the mock';
unlike($@, qr/SECRETVALUE/, 'the message names the column, never the value');

# a hostile key never reaches the SQL raw
dies_ok {
  $schema->resultset('Artist')->populate([ { name => 'a', 'name) VALUES (1); --' => 1 } ]);
} 'a key that is no column is refused';

# known case: the captured SQL is what the SQLMaker renders
$schema->resultset('Artist')->populate([ { name => 'a' }, { name => 'b' } ]);

my $source = $schema->source('Artist');
my ($expect) = $storage->sql_maker->insert($source->from, { name => \'?' });
is(last_insert()->{sql}, $expect, 'captured bulk INSERT equals the SQLMaker output (quoting included)');

done_testing;
