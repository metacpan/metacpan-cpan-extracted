use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Diff::Column;

# karr k97 (conformance case diff-default-removed), core karr k367. Core's
# comparator reports a default the target no longer declares as a change (the
# live DEFAULT NULL counts as none), so the diff has an op for it; the op
# removes the default with the statement the Reference Manual gives for it,
#   alter table t replace c default null
# and nothing else (a default-only change is the replace alone, karr k42).

sub col {
  my ($name, %o) = @_;
  +{ column_name => $name, data_type => $o{type} // 'varchar', size => $o{size} // 10,
     not_null => $o{not_null} // 0, default_value => $o{default}, is_pk => 0 };
}

for my $case (
  [ 'a literal default'    => 'x'          ],
  [ 'an expression default' => \'getdate()' ],
) {
  my ($label, $default) = @$case;
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id', type => 'integer', size => undef), col('c', default => $default) ] },
    { t => [ col('id', type => 'integer', size => undef), col('c') ] },
    { t => {} }, { t => {} },
  );
  is scalar(@ops), 1, "$label removed: one op";
  is $ops[0] && $ops[0]->as_sql, 'ALTER TABLE t REPLACE c DEFAULT NULL;',
    '... the replace to NULL, and nothing else';
}

{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('c', default => 'x', not_null => 1) ] },
    { t => [ col('c', not_null => 1) ] },
    { t => {} }, { t => {} },
  );
  is $ops[0] && $ops[0]->as_sql, 'ALTER TABLE t REPLACE c DEFAULT NULL;',
    'a NOT NULL column loses its default the same way';
}

{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('c') ] }, { t => [ col('c') ] }, { t => {} }, { t => {} });
  is scalar(@ops), 0, 'no default on either side: no op';
}

done_testing;
