use strict;
use warnings;
use Test::More;

# is_auto_increment is compared by the core (DBIO::Diff::Compare, when the
# target defines it), but SQLite can express it only as the INTEGER PRIMARY
# KEY of a table with a rowid. In a WITHOUT ROWID table a difference is no
# change (t/59 "WITHOUT ROWID: only the database has it" claims that such a
# table stays untouched when the target does not name WITHOUT ROWID).

use DBIO::SQLite::Diff::Column;

sub ops {
  my ($src_ai, $tgt_ai, $src_wr, $tgt_wr) = @_;
  my $col = sub { my ($ai) = @_; +{
    column_name => 'id', data_type => 'INTEGER', not_null => 1,
    (defined $ai ? (is_auto_increment => $ai) : ()),
  } };
  my $tables = sub { +{ t => { table_name => 't', kind => 'table', without_rowid => $_[0] } } };
  return DBIO::SQLite::Diff::Column->diff(
    { t => [ $col->($src_ai) ] }, { t => [ $col->($tgt_ai) ] },
    $tables->($src_wr), $tables->($tgt_wr),
  );
}

is(scalar ops(undef, 1, 1, 0), 0, 'WITHOUT ROWID only in the source: no change');
is(scalar ops(undef, 1, 0, 1), 0, 'WITHOUT ROWID only in the target: no change');
is(scalar ops(undef, 1, 1, 1), 0, 'WITHOUT ROWID in both: no change');

# Whether it is a change in a rowid table is the core's say; a core that does
# not compare is_auto_increment yet has nothing to hold on to here.
use DBIO::Diff::Compare qw(changed_column_fields);
SKIP: {
  skip 'this core does not compare is_auto_increment', 2
    unless changed_column_fields({ column_name => 'id' },
                                 { column_name => 'id', is_auto_increment => 1 });
  my @ops = ops(undef, 1, 0, 0);
  is(scalar @ops, 1, 'rowid table, auto increment gained: still a change');
  is($ops[0]->action, 'alter', '... an alter');
}

# a real difference in a WITHOUT ROWID table is still seen
{
  my @real = DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'TEXT' } ] },
    { t => [ { column_name => 'id', data_type => 'INTEGER', is_auto_increment => 1 } ] },
    { t => { without_rowid => 1 } }, { t => { without_rowid => 1 } },
  );
  is(scalar @real, 1, 'WITHOUT ROWID: a type change is still a change');
}

done_testing;
