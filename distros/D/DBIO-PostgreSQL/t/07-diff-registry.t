use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff;

# Default registry contains the 9 standard classes in dependency order
{
  my %reg = DBIO::PostgreSQL::Diff->_diff_registry;
  ok exists $reg{extensions}, 'extensions in registry';
  ok exists $reg{columns},    'columns in registry';
  ok exists $reg{policies},   'policies in registry';
  is $reg{extensions}, 'DBIO::PostgreSQL::Diff::Extension', 'correct class';
}

# register_diff_class adds an entry
{
  package DBIO::PostgreSQL::Diff::Fake;
  sub diff { () }
}
DBIO::PostgreSQL::Diff->register_diff_class(
  model_key => 'fake_things',
  class     => 'DBIO::PostgreSQL::Diff::Fake',
);
my %reg = DBIO::PostgreSQL::Diff->_diff_registry;
ok exists $reg{fake_things}, 'fake_things registered';
is $reg{fake_things}, 'DBIO::PostgreSQL::Diff::Fake', 'correct class stored';

# position => 'after:indexes' inserts in right slot
DBIO::PostgreSQL::Diff->register_diff_class(
  model_key => 'after_indexes_thing',
  class     => 'DBIO::PostgreSQL::Diff::Fake',
  position  => 'after:indexes',
);
my @order = DBIO::PostgreSQL::Diff->_diff_order;
my ($idx_pos)   = grep { $order[$_] eq 'indexes'           } 0..$#order;
my ($after_pos) = grep { $order[$_] eq 'after_indexes_thing' } 0..$#order;
is $after_pos, $idx_pos + 1, 'position after:indexes respected';

done_testing;
