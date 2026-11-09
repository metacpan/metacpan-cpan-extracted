use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::DB2::Storage;

# core k391 / ADR 0077 -- explain_table_schema is an identifier. It reaches the
# SQL of _explain_query only through the driver's identifier quoting, as stored
# in the catalog (case counts), and a " inside it is doubled. It is never
# joined into the statement text raw.

sub read_back_sql {
  my ($name) = @_;

  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::DB2::Storage',
  );
  my $storage = $schema->storage;
  $storage->explain_table_schema($name) if defined $name;
  $storage->mock(qr/EXPLAIN_OPERATOR/, [ [ 1, 'RETURN', 0, 0, 0 ] ]);
  $storage->reset_captured;

  $storage->_explain_query('SELECT 1 FROM SYSIBM.SYSDUMMY1', []);

  return ($storage->captured_queries)[1]{sql};
}

{
  my $sql = read_back_sql();
  my @refs = $sql =~ /(\S*EXPLAIN_OPERATOR\S*)/g;
  is_deeply \@refs, [ ('"SYSTOOLS"."EXPLAIN_OPERATOR"') x 2 ],
    'the default SYSTOOLS is quoted, both references: "SYSTOOLS"."EXPLAIN_OPERATOR"';
}

for my $case (
  [ 'a"b'       => '"a""b"'        ],
  [ 'a;b'       => '"a;b"'         ],
  [ 'my schema' => '"my schema"'   ],
  [ 'MixedCase' => '"MixedCase"'   ],
) {
  my ($name, $quoted) = @$case;
  my $sql = read_back_sql($name);
  my $want = "FROM $quoted.\"EXPLAIN_OPERATOR\" ";
  is scalar(() = $sql =~ /\Q$want\E/g), 2,
    "schema name '$name' reaches the SQL as $quoted, in both references";
}

done_testing;
