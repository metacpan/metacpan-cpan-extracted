use strict;
use warnings;
use Test::More;

# Focused offline test pinning the real behaviour of the column-comparison
# used in DBIO::SQLite::Diff::Column->diff.
#
# The underlying core helper DBIO::Diff::Compare::changed_column_fields is
# MISLEADINGLY NAMED: despite the name it returns the LIST OF CHANGED FIELDS
# (empty list = identical). DBIO::SQLite::Diff::Column consumes it as
# `changed_column_fields($src, $tgt) ? 1 : 0` -- truthy (changed) => emit an `alter`.
#
# This test asserts the OBSERVABLE behaviour through the public diff() entry
# point so the meaning is locked regardless of the helper's name:
#   * identical column info  => NO alter op
#   * differing column info  => an alter op
# It also directly pins changed_column_fields's "non-empty = different" contract.

use_ok 'DBIO::SQLite::Diff::Column';
use DBIO::Diff::Compare qw(changed_column_fields);

my $src_tables = { t => { table_name => 't', kind => 'table' } };
my $tgt_tables = { t => { table_name => 't', kind => 'table' } };

# --- identical column => no alter ---
{
  my $col = { column_name => 'name', data_type => 'TEXT', not_null => 1, default_value => undef };
  my @ops = DBIO::SQLite::Diff::Column->diff(
    { t => [ { %$col } ] },
    { t => [ { %$col } ] },
    $src_tables, $tgt_tables,
  );
  is(scalar(@ops), 0, 'identical column produces no diff op');
}

# --- changed data_type => one alter op ---
{
  my @ops = DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'name', data_type => 'TEXT',    not_null => 1 } ] },
    { t => [ { column_name => 'name', data_type => 'INTEGER', not_null => 1 } ] },
    $src_tables, $tgt_tables,
  );
  is(scalar(@ops), 1, 'changed data_type produces one op');
  is($ops[0]->action, 'alter', 'op is an alter');
  is($ops[0]->column_name, 'name', 'op targets the right column');
}

# --- changed not_null => one alter op ---
{
  my @ops = DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'name', data_type => 'TEXT', not_null => 0 } ] },
    { t => [ { column_name => 'name', data_type => 'TEXT', not_null => 1 } ] },
    $src_tables, $tgt_tables,
  );
  is(scalar(@ops), 1, 'changed not_null produces one op');
  is($ops[0]->action, 'alter', 'op is an alter');
}

# --- direct contract of the misleadingly-named helper ---
{
  my @same = changed_column_fields(
    { data_type => 'TEXT', not_null => 1 },
    { data_type => 'TEXT', not_null => 1 },
  );
  is(scalar(@same), 0, 'changed_column_fields returns empty list for identical columns');

  my @diff = changed_column_fields(
    { data_type => 'TEXT',    not_null => 1 },
    { data_type => 'INTEGER', not_null => 1 },
  );
  ok(scalar(@diff) >= 1, 'changed_column_fields returns non-empty list (changed fields) when different');
  ok((grep { $_ eq 'data_type' } @diff), 'data_type reported as the changed field');
}

done_testing;
