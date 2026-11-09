# DBD::Oracle: INSERT/UPDATE binding a LOB with ora_type dies when the table or LOB column is a quoted lower-case identifier

Draft for the DBD::Oracle issue tracker. Not sent (karr k50).

## Summary

Binding a BLOB/CLOB value with `ora_type => ORA_BLOB` / `ORA_CLOB` to an
`INSERT` or `UPDATE` fails with `ORA-01741: illegal zero-length identifier`
(or `ORA-00904: "BLOB": invalid identifier`) when the table or the LOB column
was created with a quoted lower-case or mixed-case name. The SQL is valid on
its own. The error text ends in `(DBD SUCCESS: OCIDescribeAny(view)/LOB refetch)`,
so the failure is in the post-execute LOB refetch, which looks the table and
column up by their upper-cased names.

Without `ora_type` the same statement fails too (`ORA-01465: invalid hex
number` for a BLOB, `ORA-24816` for a long CLOB), so there is no way to write a
LOB into such a column through a plain `INSERT ... VALUES (?)`.

## Versions

DBD::Oracle 1.95, DBI 1.651, Oracle Database 23ai Free 23.26.3 (FREEPDB1).
Not checked against older servers.

## Reproducer

```perl
use strict; use warnings;
use DBI; use DBD::Oracle qw(:ora_types);

my $dbh = DBI->connect($ENV{DSN}, $ENV{USER}, $ENV{PASS},
  { RaiseError => 0, PrintError => 0, AutoCommit => 1 });

$dbh->do('CREATE TABLE "lt" ("id" integer primary key, "blob" blob)');

my $sql = 'INSERT INTO "lt" ("id","blob") VALUES (?, ?)';

for my $wrap (0, 1) {
  my $sth = $dbh->prepare($wrap ? "BEGIN $sql; END;" : $sql);
  $sth->bind_param(1, $wrap);
  $sth->bind_param(2, 'x' x 100, { ora_type => ORA_BLOB });
  print $wrap ? 'in BEGIN..END: ' : 'plain INSERT:  ',
    $sth->execute ? "ok\n" : "FAILED: " . $sth->errstr . "\n";
}
$dbh->do('DROP TABLE "lt"');
```

Observed: the plain `INSERT` fails with ORA-01741, the one inside an
anonymous block succeeds and stores the 100 bytes.

Matrix, all with `ora_type` set:

| table / column                  | INSERT text                         | result      |
|---------------------------------|-------------------------------------|-------------|
| `t (id, blob)` (unquoted)       | `INSERT INTO t (id,blob) ...`       | ok          |
| `"t" ("id", "BLOB")` (upper)    | `INSERT INTO t ("id","BLOB") ...`   | ok          |
| `"id", "blob"` (lower-case)     | `INSERT INTO t ("id","blob") ...`   | ORA-00904 `"BLOB"` |
| `"lt"` table, lower-case        | `INSERT INTO "lt" (...)`            | ORA-01741   |
| `"Blob"` (mixed case)           | `INSERT INTO t (id,"Blob") ...`     | ORA-00904 `"BLOB"` |

Passing `ora_field` (bare, quoted or upper-cased) changes nothing.

## Expected

A quoted identifier is a name as it is; the refetch must not upper-case it
(or must keep the quotes the statement used). Failing that, the refetch is not
needed for a value bound from a Perl scalar and could be skipped.

## Workaround

Send the statement inside an anonymous block, `BEGIN INSERT ...; END;`. The LOB
is bound with `ora_type` as before and no refetch is attempted. DBIO::Oracle
does this (karr k50).
