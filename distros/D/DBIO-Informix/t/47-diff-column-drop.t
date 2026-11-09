use strict;
use warnings;
use Test::More;

# Informix drops a column with ALTER TABLE t DROP col / DROP (col, ...); it has
# no DROP COLUMN keyword pair there. Source: HCL OneDB/Informix SQL Syntax,
# ALTER TABLE, "DROP Column clause" (ids_sqs_0086), and the ADD / MODIFY clauses
# (ids_sqs_0077 / ids_sqs_0078). Live unmeasured (no server, karr k14).

use DBIO::Informix::Diff::Column;

my @ops = DBIO::Informix::Diff::Column->diff(
  { t => [ { column_name => 'id',  data_type => 'integer' },
           { column_name => 'old', data_type => 'varchar(255)' } ] },
  { t => [ { column_name => 'id', data_type => 'integer' } ] },
  { t => 1 }, { t => 1 },
);

is(scalar @ops, 1, 'one drop op');
is($ops[0]->as_sql, 'ALTER TABLE t DROP (old);', 'DROP (col), no COLUMN keyword');
unlike($ops[0]->as_sql, qr/DROP COLUMN/, 'no DROP COLUMN');

done_testing;
