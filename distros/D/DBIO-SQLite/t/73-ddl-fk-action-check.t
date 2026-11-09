use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;
use DBIO::SQLite::DDL ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k88 -- a typo in the action of a foreign key is refused loudly when the
# schema is deployed.
#
# on_delete / on_update went into the CREATE TABLE statement unchecked, so
# "cascades" for "cascade" was found only when SQLite choked on the statement
# -- a syntax error that names neither the relationship nor the attribute. The
# claim of this file is the user-facing one: a wrong action word does not
# deploy, the message names the word, and the five real actions (in any letter
# case or spacing) still do and are written the same way every time.

my $n = 0;

# A schema with one belongs_to carrying the given attributes.
sub schema_with {
  my ($attrs) = @_;
  my $pkg = 'FK88::S' . ++$n;
  eval qq{
    package $pkg;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');

    package ${pkg}::Result::Parent;
    use base 'DBIO::Core';
    __PACKAGE__->table('parent');
    __PACKAGE__->add_columns(id => { data_type => 'integer' });
    __PACKAGE__->set_primary_key('id');

    package ${pkg}::Result::Child;
    use base 'DBIO::Core';
    __PACKAGE__->table('child');
    __PACKAGE__->add_columns(
      id        => { data_type => 'integer' },
      parent_id => { data_type => 'integer', is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');
    1;
  } or die $@;
  no strict 'refs';
  ("${pkg}::Result::Child")->belongs_to(
    parent => "${pkg}::Result::Parent", 'parent_id', $attrs);
  $pkg->register_class(Parent => "${pkg}::Result::Parent");
  $pkg->register_class(Child  => "${pkg}::Result::Child");
  return $pkg;
}

sub fk_line {
  my ($pkg) = @_;
  my ($line) = DBIO::SQLite::DDL->install_ddl($pkg) =~ /^\s*(FOREIGN KEY.*?),?$/m;
  return $line;
}

# 1. A word that is not an action does not deploy -- on either attribute.
for my $attr (qw(on_delete on_update)) {
  my $pkg = schema_with({ $attr => 'cascades' });
  throws_ok { DBIO::SQLite::DDL->install_ddl($pkg) } qr/cascades/,
    "$attr => 'cascades' is refused when the DDL is generated, naming the word";
  throws_ok { DBIO::SQLite::DDL->install_ddl($pkg) } qr/SET DEFAULT/,
    "$attr: and names the actions that are allowed";
  throws_ok { DBIO::SQLite::DDL->install_ddl($pkg) } qr/parent/,
    "$attr: and the relationship it was declared on";
}

# 2. Real actions are accepted whatever the case or spacing, written as
# declared with the white space collapsed.
my $REF = 'FOREIGN KEY ("parent_id") REFERENCES "parent"("id")';
for my $case (
  [ { on_delete => 'cascade' },      "$REF ON DELETE cascade" ],
  [ { on_delete => 'set null' },     "$REF ON DELETE set null" ],
  [ { on_update => 'SET  DEFAULT' }, "$REF ON UPDATE SET DEFAULT" ],
  [ { on_delete => ' restrict ' },   "$REF ON DELETE restrict" ],
) {
  my ($attrs, $expect) = @$case;
  my ($k, $v) = %$attrs;
  is(fk_line(schema_with($attrs)), $expect, "$k => '$v' is written as '$expect'");
}

# 3. Not declared, and NO ACTION, write no clause: it is the default of a key.
is(fk_line(schema_with({ on_delete => 'NO ACTION', on_update => 'no action' })),
  $REF, 'NO ACTION is not written');
is(fk_line(schema_with({ on_delete => undef, on_update => '' })),
  $REF, 'an undeclared action is not written either');

# 4. The diff refuses a target model whose foreign key has a bogus action.
{
  my $model = sub {
    my ($fk) = @_;
    return {
      # The foreign keys of a table are compared where the target states it
      # (it carries a CREATE statement).
      tables  => { child => { table_name => 'child',
        sql => 'CREATE TABLE child (id INTEGER PRIMARY KEY NOT NULL, parent_id INTEGER)' } },
      columns => { child => [
        { column_name => 'id', data_type => 'INTEGER', is_pk => 1, pk_position => 1, not_null => 1 },
        { column_name => 'parent_id', data_type => 'INTEGER' },
      ] },
      indexes => {},
      foreign_keys => { child => [ {
        from_columns => ['parent_id'], to_table => 'parent', to_columns => ['id'], %$fk,
      } ] },
    };
  };
  # Compared against the same table without actions.
  my $existing = $model->({});

  for my $attr (qw(on_delete on_update)) {
    throws_ok {
      DBIO::SQLite::Diff->new(source => $existing, target => $model->({ $attr => 'bogus' }))->as_sql;
    } qr/bogus/, "the diff refuses $attr => 'bogus' in the target model, naming the word";
  }

  lives_ok {
    DBIO::SQLite::Diff->new(source => $existing,
      target => $model->({ on_delete => 'NO ACTION', on_update => 'SET NULL' }))->as_sql;
  } 'the diff takes the five real actions';
}

# 5. A deploy with valid actions: the catalog of the installed database
# carries them.
{
  my $pkg = schema_with({ on_delete => 'set null', on_update => 'Cascade' });
  my $schema = $pkg->connect('dbi:SQLite::memory:');
  DBIO::SQLite::Deploy->new(schema => $schema)->install;
  my $fk = $schema->storage->dbh->selectall_arrayref(
    'PRAGMA foreign_key_list(child)', { Slice => {} });
  is(scalar @$fk, 1, 'one foreign key is installed');
  is($fk->[0]{on_delete}, 'SET NULL', 'its ON DELETE is in the catalog');
  is($fk->[0]{on_update}, 'CASCADE',  'its ON UPDATE is in the catalog');
}

done_testing;
