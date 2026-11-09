use strict;
use warnings;
use Test::More;

# Offline regression for karr k31: the tables introspector must NOT filter on
# tabname at all. The original `AND tabname NOT LIKE 'EX%'` was doubly wrong:
#   (a) it hid any user table with an EX-prefix (EXPENSES, EXPORT, EXPORTS)
#       from the model, so every diff re-created the table (SQL0601N);
#   (b) since the always-quote deploy (karr k28) driver-generated tables are
#       lowercase, the case-sensitive LIKE no longer even hit the EXPLAIN_*
#       targets it was meant for.
# The EXPLAIN_* tables live in SYSTOOLS (installed by SYSINSTALLOBJECTS,
# karr k27), a schema the introspector never queries -- fetch() scopes on
# tabschema only -- so the filter had no legitimate target left and was
# dropped entirely.
#
# Offline instrument: the SYSCAT SQL cannot run without a real DB2, so the
# dbh is a small mock that captures the SQL (the regression is a WHERE-clause
# change, which only a generated-SQL assertion can pin down) and replays
# canned SYSCAT rows for the row-mapping half.

use_ok 'DBIO::DB2::Introspect::Tables';

{
  package Mock::DB2;
  sub new     { bless { rows => $_[1] }, $_[0] }
  sub prepare { my ($self, $sql) = @_; $self->{sql} = $sql; bless { rows => $self->{rows} }, 'Mock::DB2::STH' }

  package Mock::DB2::STH;
  sub execute { my $self = shift; $self->{i} = 0; return 1 }
  sub fetchrow_hashref {
    my $self = shift;
    return $self->{rows}[ $self->{i}++ ];
  }
}

my $dbh = Mock::DB2->new([
  # A user table with an EX-prefix: the case the old filter got wrong.
  { tabname => 'EXPORTS',         type => 'T', tabschema => 'USER' },
  # An EXPLAIN table name, upper-case, for documentation: even if one ever
  # surfaced in the introspected schema it must pass through unmolested.
  { tabname => 'EXPLAIN_STATEMENT', type => 'T', tabschema => 'SYSTOOLS' },
  { tabname => 'artist',          type => 'T', tabschema => 'USER' },
  { tabname => 'artist_list',     type => 'V', tabschema => 'USER',
    view_text => 'CREATE VIEW "artist_list" AS SELECT id, name FROM "artist"' },
  { tabname => 'with_cols',       type => 'V', tabschema => 'USER',
    view_text => 'CREATE VIEW USER."with_cols" (x, y) AS SELECT id, name FROM "artist";' },
  { tabname => 'odd_view',        type => 'V', tabschema => 'USER', view_text => 'something else' },
]);

my $tables = DBIO::DB2::Introspect::Tables->fetch($dbh, 'USER');

# --- generated SQL: the filter is gone, tabschema is the only scope ---
my $sql = $dbh->{sql};
like($sql, qr/FROM syscat\.tables t\b/,  'introspect reads syscat.tables');
like($sql, qr/WHERE t\.tabschema = \?/, 'introspect scopes on tabschema only');
like($sql, qr/syscat\.views/, 'a view\'s text is read from syscat.views (karr k45)');
unlike($sql, qr/NOT LIKE/,
  'no tabname NOT LIKE filter: an EX-prefix user table must stay in the model');
unlike($sql, qr/\btabname\b\s*(?:=|\bLIKE\b|\bNOT\b)/i,
  'tabname appears only as a selected column / sort key, never as a predicate');

# --- row mapping: every row passes through, EX-* included -------------------
is_deeply(
  [ sort keys %$tables ],
  [ qw/EXPLAIN_STATEMENT EXPORTS artist artist_list odd_view with_cols/ ],
  'EXPORTS (the phantom-CREATE trigger) and EXPLAIN_STATEMENT are both in the model',
);
is $tables->{EXPORTS}{kind}, 'table', 'EXPORTS maps type T to kind table';
is $tables->{artist_list}{kind}, 'view', 'artist_list maps type V to kind view';
is $tables->{EXPORTS}{schema}, 'USER', 'row schema is carried through';

# --- view_definition (karr k45, ADR 0011): the text after the view's name ----
is $tables->{artist_list}{view_definition}, 'AS SELECT id, name FROM "artist"',
  'a view carries its definition, the name cut off';
is $tables->{with_cols}{view_definition}, '(x, y) AS SELECT id, name FROM "artist"',
  '... the schema in front of the name and the closing semicolon too, the column list kept';
is $tables->{odd_view}{view_definition}, undef, 'a text of another shape gives no definition';
ok !exists $tables->{artist}{view_definition}, 'a table has none';

done_testing;
