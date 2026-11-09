use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Introspect::Columns;
use DBIO::MySQL::Diff::Column;

# OFFLINE half of karr k87: what DBIO::MySQL::Introspect::Columns makes of
# COLUMN_DEFAULT, which the two servers fill in two different ways.
#
# WHY IT MATTERS. default_value of an introspected column is what a diff
# compares and what it writes behind DEFAULT. MySQL reports the value itself
# and SQL NULL where a column has no default. MariaDB reports an expression:
# a string in quotes, and the keyword NULL -- as a text of four letters -- for
# a nullable column without a default. Taken as it comes, that text was the
# default 'NULL': every nullable column an upgrade added or changed on MariaDB
# got DEFAULT 'NULL', which the server refuses for a number (1067) and which
# is the wrong default for a string. t/88 has the live half.
#
# The same four letters are a real default on the other side: a column with
# DEFAULT 'NULL' is reported by MySQL as the text NULL, and by MariaDB as
# 'NULL' in quotes. So this file claims both directions:
#   1. MariaDB: the text NULL is no default, for a column that never had a
#      DEFAULT clause, for one with DEFAULT NULL, and for a generated column;
#   2. MariaDB: 'NULL' in quotes stays, and so does everything else;
#   3. MySQL: the text NULL stays -- there it is the string a column defaults
#      to -- and SQL NULL is no default, as before;
#   4. a MariaDB from before 10.2.7 is read as a MySQL is;
#   5. the statement a diff writes for a column read from MariaDB has no
#      DEFAULT in it.
#
# The rows below are what the servers answered on 2026-10-08, MySQL 8.0.30 and
# MariaDB 11.8.9, each through DBD::mysql 4.055 and through DBD::MariaDB 1.24.
# The two DBDs hand on the same values, so the server alone decides, and the
# handle here stands for either. Claim 4 is not measured: MariaDB reports
# COLUMN_DEFAULT as an expression since 10.2.7 (MDEV-13132, release notes of
# 10.2.7), and no older server was at hand.
#
# NOT claimed: what a diff writes for a default that is there (karr k78) --
# the quotes MariaDB reports around a string, current_timestamp(), an
# expression default of MySQL.

{
  # The handle Columns->fetch works on: VERSION() and the rows of
  # information_schema.columns, keyed in lowercase as the reader asks.
  package ColDefault::DBH;

  sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
  }

  sub selectrow_array {
    my ($self, $sql) = @_;
    die "the fake handle has no answer to: $sql" unless $sql =~ /\A\s*SELECT\s+VERSION\(\)\s*\z/i;
    return ($self->{version});
  }

  sub prepare {
    my ($self, $sql) = @_;
    # is_pk is read from information_schema.statistics (karr k83); these tables have no index
    return ColDefault::STH->new() if $sql =~ /\binformation_schema\.statistics\b/i;
    die "the fake handle has no answer to: $sql" unless $sql =~ /\binformation_schema\.columns\b/i;
    return ColDefault::STH->new(@{ $self->{rows} });
  }

  package ColDefault::STH;

  sub new { my $class = shift; return bless { rows => [@_] }, $class }
  sub execute { 1 }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
}

# One row of information_schema.columns for a column of table `t`:
# name, column_type, is_nullable, column_default, extra.
sub rows {
  my $position = 0;
  return [ map {
    my ($name, $type, $nullable, $default, $extra) = @$_;
    {
      table_name         => 't',
      column_name        => $name,
      ordinal_position   => ++$position,
      data_type          => ($type =~ /\A(\w+)/)[0],
      column_type        => $type,
      is_nullable        => $nullable,
      column_default     => $default,
      column_key         => '',
      extra              => $extra // '',
      character_set_name => undef,
      collation_name     => undef,
      column_comment     => '',
    }
  } @_ ];
}

# What the reader makes of a server: the columns of `t` by name.
sub read_columns {
  my ($version, $rows) = @_;
  my $dbh     = ColDefault::DBH->new(version => $version, rows => $rows);
  my $columns = DBIO::MySQL::Introspect::Columns->fetch($dbh, { t => { table_name => 't' } });
  return { map { $_->{column_name} => $_ } @{ $columns->{t} } };
}
sub defaults {
  my ($columns) = @_;
  return { map { $_ => $columns->{$_}{default_value} } keys %$columns };
}

# The columns, and behind each the clause it was created with.
my @MARIADB = (
  [ n_nodef      => 'int(11)',     'YES', 'NULL'                ],  # int NULL
  [ n_defnull    => 'int(11)',     'YES', 'NULL'                ],  # int NULL DEFAULT NULL
  [ nn_nodef     => 'int(11)',     'NO',  undef                 ],  # int NOT NULL
  [ n_def0       => 'int(11)',     'YES', '0'                   ],  # int NULL DEFAULT 0
  [ s_nodef      => 'varchar(20)', 'YES', 'NULL'                ],  # varchar(20) NULL
  [ s_strNULL    => 'varchar(20)', 'YES', q{'NULL'}             ],  # varchar(20) NULL DEFAULT 'NULL'
  [ nn_s_strNULL => 'varchar(20)', 'NO',  q{'NULL'}             ],  # varchar(20) NOT NULL DEFAULT 'NULL'
  [ s_strnull_lc => 'varchar(20)', 'YES', q{'null'}             ],  # varchar(20) NULL DEFAULT 'null'
  [ s_empty      => 'varchar(20)', 'YES', q{''}                 ],  # varchar(20) NULL DEFAULT ''
  [ ts_now       => 'timestamp',   'YES', 'current_timestamp()' ],  # timestamp NULL DEFAULT CURRENT_TIMESTAMP
  [ gen_virtual  => 'int(11)',     'YES', 'NULL', 'VIRTUAL GENERATED' ],  # int GENERATED ALWAYS AS (id + 1) VIRTUAL
);
my @MYSQL = (
  [ n_nodef      => 'int',         'YES', undef               ],
  [ n_defnull    => 'int',         'YES', undef               ],
  [ nn_nodef     => 'int',         'NO',  undef               ],
  [ n_def0       => 'int',         'YES', '0'                 ],
  [ s_nodef      => 'varchar(20)', 'YES', undef               ],
  [ s_strNULL    => 'varchar(20)', 'YES', 'NULL'              ],
  [ nn_s_strNULL => 'varchar(20)', 'NO',  'NULL'              ],
  [ s_strnull_lc => 'varchar(20)', 'YES', 'null'              ],
  [ s_empty      => 'varchar(20)', 'YES', ''                  ],
  [ ts_now       => 'timestamp',   'YES', 'CURRENT_TIMESTAMP', 'DEFAULT_GENERATED' ],
  [ gen_virtual  => 'int',         'YES', undef,               'VIRTUAL GENERATED' ],
);

# --- MariaDB ---------------------------------------------------------------

my $mariadb = read_columns('11.8.9-MariaDB-ubu2404', rows(@MARIADB));

is_deeply defaults($mariadb), {
  n_nodef      => undef,
  n_defnull    => undef,
  nn_nodef     => undef,
  n_def0       => '0',
  s_nodef      => undef,
  s_strNULL    => 'NULL',
  nn_s_strNULL => 'NULL',
  s_strnull_lc => 'null',
  s_empty      => '',
  ts_now       => 'current_timestamp()',
  gen_virtual  => undef,
}, 'MariaDB: the keyword NULL is no default, and a default that is there is its value, without the quotes the server reports it in';

is $mariadb->{n_nodef}{default_value}, undef,
  '... a nullable number without a DEFAULT clause has none';
is $mariadb->{s_strNULL}{default_value}, 'NULL',
  '... and the string NULL, which MariaDB reports in quotes, is still a default (a literal, not the keyword)';
is $mariadb->{n_nodef}{not_null}, 0, '... the column without a default is still nullable';

# --- MySQL -----------------------------------------------------------------

my $mysql = read_columns('8.0.30', rows(@MYSQL));

is_deeply defaults($mysql), {
  n_nodef      => undef,
  n_defnull    => undef,
  nn_nodef     => undef,
  n_def0       => '0',
  s_nodef      => undef,
  s_strNULL    => 'NULL',
  nn_s_strNULL => 'NULL',
  s_strnull_lc => 'null',
  s_empty      => '',
  ts_now       => 'CURRENT_TIMESTAMP',
  gen_virtual  => undef,
}, 'MySQL: SQL NULL is no default, and every text is the default itself';

is $mysql->{s_strNULL}{default_value}, 'NULL',
  '... the text NULL is the string the column defaults to, and stays';

# --- a MariaDB from before COLUMN_DEFAULT became an expression -------------

{
  my $old = read_columns('10.1.48-MariaDB', rows(@MYSQL));
  is $old->{s_strNULL}{default_value}, 'NULL',
    'MariaDB before 10.2.7 reports the value itself: the text NULL is a default there';
  is $old->{n_nodef}{default_value}, undef, '... and SQL NULL is none';

  my $first = read_columns('10.2.7-MariaDB', rows(@MARIADB));
  is $first->{n_nodef}{default_value}, undef, 'MariaDB 10.2.7 is the first to report the keyword';
  is $first->{s_strNULL}{default_value}, 'NULL', '... and the string in quotes, which is unquoted';
}

# --- literal or expression (karr k78) --------------------------------------
# default_is_expression tells the diff whether to write the text as SQL or as
# a string literal. Reports measured on MySQL 8.0.30 and MariaDB 11.8.9.

sub expr_flags {
  my ($columns) = @_;
  return { map { $_ => $columns->{$_}{default_is_expression} } keys %$columns };
}

{
  my $m = read_columns('11.8.9-MariaDB-ubu2404', rows(
    [ lit_apos  => 'varchar(20)', 'YES', q{'it''s'}                  ],
    [ lit_bs    => 'varchar(20)', 'YES', q{'a\\\\b'}                 ],
    [ lit_nl    => 'varchar(20)', 'YES', q{'a\\nb'}                  ],
    [ lit_cts   => 'varchar(40)', 'YES', q{'current_timestamp()'}    ],
    [ num       => 'decimal(5,2)', 'YES', '1.50'                     ],
    [ ts        => 'timestamp',   'YES', 'current_timestamp()'       ],
    [ ts3       => 'datetime(3)', 'YES', 'current_timestamp(3)'      ],
    [ expr      => 'varchar(40)', 'YES', q{concat('a','b')}          ],
    [ nodef     => 'int(11)',     'YES', 'NULL'                      ],
  ));
  is_deeply defaults($m), {
    lit_apos => q{it's}, lit_bs => 'a\\b', lit_nl => "a\nb", lit_cts => 'current_timestamp()',
    num => '1.50', ts => 'current_timestamp()', ts3 => 'current_timestamp(3)',
    expr => q{concat('a','b')}, nodef => undef,
  }, 'MariaDB: a quoted literal is unquoted and unescaped to its value';
  is_deeply expr_flags($m), {
    lit_apos => 0, lit_bs => 0, lit_nl => 0, lit_cts => 0, num => 0,
    ts => 1, ts3 => 1, expr => 1, nodef => 0,
  }, '... and what is no quoted literal and no number is an expression (a quoted current_timestamp() is still a string)';

  my $s = read_columns('8.0.30', rows(
    [ lit_apos  => 'varchar(20)', 'YES', q{it's}                     ],
    [ lit_bs    => 'varchar(20)', 'YES', 'a\\b'                      ],
    [ lit_cts   => 'varchar(40)', 'YES', 'current_timestamp()'       ],
    [ ts        => 'timestamp',   'YES', 'CURRENT_TIMESTAMP', 'DEFAULT_GENERATED' ],
    [ expr      => 'varchar(40)', 'YES', q{concat(_utf8mb4\\'a\\',_utf8mb4\\'b\\')}, 'DEFAULT_GENERATED' ],
    [ uuid      => 'varchar(40)', 'YES', 'uuid()',                    'DEFAULT_GENERATED' ],
  ));
  is_deeply defaults($s), {
    lit_apos => q{it's}, lit_bs => 'a\\b', lit_cts => 'current_timestamp()',
    ts => 'CURRENT_TIMESTAMP', expr => q{concat(_utf8mb4'a',_utf8mb4'b')}, uuid => 'uuid()',
  }, 'MySQL: the value itself; an expression with the quote it escaped in the report restored';
  is_deeply expr_flags($s), {
    lit_apos => 0, lit_bs => 0, lit_cts => 0, ts => 1, expr => 1, uuid => 1,
  }, '... and EXTRA = DEFAULT_GENERATED makes it an expression';

  my $old = read_columns('5.7.44', rows(
    [ ts  => 'timestamp',   'NO', 'CURRENT_TIMESTAMP' ],
    [ str => 'varchar(40)', 'NO', 'CURRENT_TIMESTAMP' ],
  ));
  is_deeply expr_flags($old), { ts => 1, str => 0 },
    'MySQL before 8.0.13 (no DEFAULT_GENERATED): CURRENT_TIMESTAMP of a timestamp column is the expression, of a varchar a string';
}

# --- the statement a diff writes -------------------------------------------

for my $action (qw(add modify)) {
  my $op = DBIO::MySQL::Diff::Column->new(
    action      => $action,
    table_name  => 't',
    column_name => 'n_nodef',
    new_info    => $mariadb->{n_nodef},
  );
  my $verb = uc $action;
  is $op->as_sql, "ALTER TABLE `t` $verb COLUMN `n_nodef` int(11);",
    "$verb COLUMN of a nullable number read from MariaDB has no DEFAULT";
}

done_testing;
