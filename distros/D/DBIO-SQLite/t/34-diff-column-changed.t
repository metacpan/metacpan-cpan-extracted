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

# --- one default in two spellings (follow-up to karr k57 / karr k68) ---
#
# install_ddl used to write a default of digits bare into every column, and
# writes it as a string literal into a column with TEXT affinity now. A database
# deployed before that holds `code VARCHAR(10) DEFAULT 10`, the schema now says
# DEFAULT '10' -- and both give every new row the text '10': the number 10 goes
# into a TEXT column as that text. Compared as text the two differ, and SQLite
# changes a default by rebuilding the table, so every such table would be
# rebuilt for nothing. Diff::Column takes the two for the same default.
#
# Only these two, and only there. What it must NOT take for the same is the
# longer list, and each line of it stores another value bare than quoted
# (measured against SQLite, see t/50) or is given up on purpose.
sub column_ops {
  my ($old, $new) = @_;
  return DBIO::SQLite::Diff::Column->diff(
    { t => [ { column_name => 'c', not_null => 0, %$old } ] },
    { t => [ { column_name => 'c', not_null => 0, %$new } ] },
    $src_tables, $tgt_tables,
  );
}

for my $case (
  # type           one       other
  [ 'TEXT',        '10',     q{'10'}   ],
  [ 'VARCHAR(10)', '10',     q{'10'}   ],
  [ 'char(3)',     '0',      q{'0'}    ],
  [ 'CLOB',        '-5',     q{'-5'}   ],
  [ 'TEXT',        '7',      q{'7'}    ],
  [ 'TEXT',        '999999999999999999',  q{'999999999999999999'}  ],  # 18 digits
  [ 'TEXT',        '-999999999999999999', q{'-999999999999999999'} ],
) {
  my ($type, $bare, $quoted) = @$case;
  is(scalar(column_ops(
      { data_type => $type, default_value => $bare   },
      { data_type => $type, default_value => $quoted },
    )), 0, "$type: DEFAULT $bare in the database and $quoted in the target are one default");
  is(scalar(column_ops(
      { data_type => $type, default_value => $quoted },
      { data_type => $type, default_value => $bare   },
    )), 0, "$type: and so are $quoted in the database and $bare in the target");
}

for my $case (
  # type       one       other      why they are two defaults
  [ 'TEXT',    '007',    q{'007'},  'bare it is the number 7, stored as 7' ],
  [ 'TEXT',    '00',     q{'00'},   'bare it is 0'                         ],
  [ 'TEXT',    '-0',     q{'-0'},   'bare it is 0'                         ],
  [ 'TEXT',    '+5',     q{'+5'},   'bare it is 5'                         ],
  [ 'TEXT',    '1.50',   q{'1.50'}, 'bare it is 1.5'                       ],
  # These two store alike. Saying so would take SQLite's rules for writing a
  # float; a decimal spelled in the other way is reported, which costs a
  # rebuild and loses nothing.
  [ 'TEXT',    '1.5',    q{'1.5'},  'a decimal is not looked at'           ],
  [ 'TEXT',    '-1.0',   q{'-1.0'}, 'a decimal is not looked at'           ],
  [ 'TEXT',    '1e3',    q{'1e3'},  'bare it is 1000.0'                    ],
  [ 'TEXT',    '0x10',   q{'0x10'}, 'bare it is 16'                        ],
  # Past 64 bit SQLite reads a bare integer as a REAL: 9223372036854775808
  # is stored as 9.22337203685478e+18.
  [ 'TEXT',    '9223372036854775808',     q{'9223372036854775808'},     'past int64, bare it is a REAL' ],
  [ 'TEXT',    '12345678901234567890123', q{'12345678901234567890123'}, 'past int64, bare it is a REAL' ],
  # Given up on purpose: 19 digits that do fit into 64 bit, and store alike.
  # The rule is 18 digits, which needs no arithmetic on a string.
  [ 'TEXT',    '1000000000000000000', q{'1000000000000000000'}, '19 digits are not looked at' ],
  [ 'TEXT',    '9223372036854775807', q{'9223372036854775807'}, '19 digits are not looked at' ],
  [ 'TEXT',    '10',     q{"10"},   'not an apostrophe'                    ],
  [ 'TEXT',    '10',     q{'010'},  'other digits'                         ],
  [ 'TEXT',    '10',     q{' 10'},  'other characters'                     ],
  [ 'TEXT',    '10',     q{'11'},   'another value'                        ],
  [ 'TEXT',    q{'10'},  q{'11'},   'another value, both strings'          ],
  # No TEXT affinity, no such rule: an INTEGER or NUMERIC column makes the
  # number 10 of both, but that is another rule and another question, and in
  # a column without affinity one is the integer and one the text.
  [ 'INTEGER', '10',     q{'10'},   'INTEGER affinity'                     ],
  [ 'NUMERIC', '10',     q{'10'},   'NUMERIC affinity'                     ],
  [ 'REAL',    '10',     q{'10'},   'REAL affinity'                        ],
  [ 'BLOB',    '10',     q{'10'},   'BLOB affinity'                        ],
  [ 'CHARINT', '10',     q{'10'},   'INT comes before CHAR'                ],
  [ '',        '10',     q{'10'},   'no type, BLOB affinity'               ],
  [ undef,     '10',     q{'10'},   'no type in the model'                 ],
) {
  my ($type, $one, $other, $why) = @$case;
  my $named = defined $type ? "<$type>" : 'undef';
  for my $pair ([ $one, $other ], [ $other, $one ]) {
    my @ops = column_ops(
      { data_type => $type, default_value => $pair->[0] },
      { data_type => $type, default_value => $pair->[1] },
    );
    is(join(' ', map { $_->action } @ops), 'alter',
      "$named: $pair->[0] and $pair->[1] are two defaults ($why)");
  }
}

# TEXT affinity on both sides is the condition, not on one.
{
  my @ops = column_ops(
    { data_type => 'INTEGER', default_value => '10'     },
    { data_type => 'TEXT',    default_value => q{'10'}  },
  );
  is(scalar(@ops), 1, 'INTEGER -> TEXT is a change');
  my $message = eval { $ops[0]->as_sql; '' } // $@;
  like($message, qr/type INTEGER -> TEXT/, 'which names the type');
  like($message, qr/default 10 -> '10'/,
    'and the default: in the INTEGER column it was the number');
}

# The same answer where the change is named. A column that changed otherwise is
# still an alter, and what the refusal lists is what changed -- not a default
# that is the same one.
{
  my @ops = column_ops(
    { data_type => 'TEXT', not_null => 0, default_value => '10'    },
    { data_type => 'TEXT', not_null => 1, default_value => q{'10'} },
  );
  is(scalar(@ops), 1, 'NOT NULL changed beside a default spelled the other way: one op');
  my $message = eval { $ops[0]->as_sql; '' } // $@;
  like($message, qr/\(NOT NULL no -> yes\)/,
    'the refusal names NOT NULL and nothing else');
  unlike($message, qr/default/, 'the default is not among the changes');
}

done_testing;
