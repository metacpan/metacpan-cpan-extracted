use strict;
use warnings;
use Test::More;

# t/49-ddl-qualified-view.t -- a view named database.view (karr k43, the view
# half of t/48-ddl-qualified-name.t). Offline: no DBD, no DSN, no server; the
# live half is t/49-ddl-qualified-view-live.t.
#
# WHY IT MATTERS. view('other.v') became ONE identifier `other.v` in the
# connected database, while the SQLMaker reads `other`.`v`: a view nobody could
# reach. A view follows the table: it is made in the database its name gives.
#
# Claims:
#   1. install_ddl writes CREATE VIEW `other`.`v`, never `other.v` as one
#      identifier; a view without a dot is untouched;
#   2. local_only leaves it out, and so do the declared views handed to the
#      diff: the diff reads the current database alone, so a qualified view
#      is installed, never compared, replaced or dropped;
#   3. qualified_tables lists views next to tables, once each, with their
#      database, so the install asks the server for a missing database before
#      its first statement;
#   4. a view name that names nothing (a.b.c, .v, db.) is refused by
#      install_ddl, naming it;
#   5. create_view and drop_view take the database apart from the name.

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::ClickHouse::DDL;
use DBIO::ClickHouse::DDL::Emit qw(create_view drop_view);

my $n = 0;
sub schema_of {
  my @spec = @_;
  my $schema = 'My::CH::QualView' . ++$n;
  { no strict 'refs'; @{"${schema}::ISA"} = ('DBIO::Schema'); }
  while (my ($name, $code) = splice @spec, 0, 2) {
    my $class = "${schema}::Result::$name";
    { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Core'); }
    $code->($class);
    $schema->register_class($name => $class);
  }
  return $schema;
}
my $table = sub {
  my ($name) = @_;
  return sub {
    my ($class) = @_;
    $class->table($name);
    $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
    $class->set_primary_key('id');
  };
};
my $view = sub {
  my ($name) = @_;
  return sub {
    my ($class) = @_;
    $class->table_class('DBIO::ResultSource::View');
    $class->table($name);
    $class->result_source_instance->view_definition('SELECT id FROM plain');
    $class->result_source_instance->is_virtual(0);
    $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
  };
};

# --- 1. the statement --------------------------------------------------------
my $schema = schema_of(Plain => $table->('plain'), Q => $view->('other.v'), L => $view->('lv'));
my $ddl = DBIO::ClickHouse::DDL->install_ddl($schema);
like $ddl, qr/CREATE VIEW `other`\.`v` AS SELECT id FROM plain/, 'database.view is written `other`.`v`';
unlike $ddl, qr/`other\.v`/, '... and never as one identifier with a dot in it';
like $ddl, qr/CREATE VIEW `lv` AS/, 'a view without a dot is untouched';

# --- 2. local_only, declared views -------------------------------------------
my $local = DBIO::ClickHouse::DDL->install_ddl($schema, { local_only => 1 });
unlike $local, qr/other/, 'local_only leaves the view of another database out';
like $local, qr/CREATE VIEW `lv`/, '... and keeps the others';
is_deeply [ sort keys %{ DBIO::ClickHouse::DDL->declared_views($schema) } ], [ 'lv', 'other.v' ],
  'declared_views names every view the install makes';
is_deeply [ sort keys %{ DBIO::ClickHouse::DDL->declared_views($schema, { local_only => 1 }) } ], ['lv'],
  '... and local_only only those the diff may compare';

# --- 3. qualified_tables -----------------------------------------------------
my $two = schema_of(A => $table->('db1.a'), V => $view->('db1.v'), W => $view->('db2.w'),
                    X => $view->('db2.w'), P => $view->('pv'));
is_deeply [ DBIO::ClickHouse::DDL->qualified_tables($two) ],
  [ [ 'db1.a', 'db1' ], [ 'db1.v', 'db1' ], [ 'db2.w', 'db2' ] ],
  'tables and views with a database, once each, in source order';

# --- 4. names that name nothing ----------------------------------------------
for my $bad ('a.b.c', '.v', 'db.') {
  my $s = schema_of(Bad => $view->($bad));
  my $err = do { local $@; eval { DBIO::ClickHouse::DDL->install_ddl($s); 1 } ? '' : "$@" };
  like $err, qr/view '\Q$bad\E' is refused.*database\.view/s, "view '$bad' names nothing and is refused";
}

# --- 5. the Emit functions ---------------------------------------------------
is create_view(database => 'other', name => 'v', definition => 'SELECT 1'),
  'CREATE VIEW `other`.`v` AS SELECT 1;', 'create_view takes the database apart from the name';
is create_view(database => 'other', name => 'v', definition => 'SELECT 1', or_replace => 1),
  'CREATE OR REPLACE VIEW `other`.`v` AS SELECT 1;', '... with OR REPLACE too';
is drop_view(database => 'other', name => 'v', if_exists => 1),
  'DROP VIEW IF EXISTS `other`.`v`;', 'drop_view likewise';

done_testing;
