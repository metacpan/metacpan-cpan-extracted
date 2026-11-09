use strict;
use warnings;
use Test::More;

# t/36-ddl-refusals.t -- what DBIO::ClickHouse::DDL->install_ddl refuses
# instead of leaving out (karr k43, conformance ddl list).
#
# WHY: ClickHouse has no foreign key and no enforced UNIQUE. A declaration
# that asks for either and gets a table without it is a table that lies about
# its guarantees, so install_ddl throws -- before the first statement,
# naming table and column -- and the author states "no constraint" with
# is_foreign_key_constraint => 0. A table name that names nothing (a.b.c)
# is refused as well; database.table is made in that database (t/48). Offline: no DBD, no DSN, no server.

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::ClickHouse::DDL;

my $n = 0;
# a schema class of one or two tables; $decl->($class) declares the extras
sub schema_of {
  my @spec = @_;
  my $id = ++$n;
  my $schema = "My::CH::Ref$id";
  {
    no strict 'refs';
    @{"${schema}::ISA"} = ('DBIO::Schema');
  }
  while (my ($name, $code) = splice @spec, 0, 2) {
    my $class = "${schema}::Result::$name";
    {
      no strict 'refs';
      @{"${class}::ISA"} = ('DBIO::Core');
    }
    $code->($class, $schema);
    $schema->register_class($name => $class);
  }
  return $schema;
}

my $parent = sub {
  my ($class) = @_;
  $class->table('parent');
  $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
  $class->set_primary_key('id');
};
my $child = sub {
  my ($attrs) = @_;
  return sub {
    my ($class, $schema) = @_;
    $class->table('child');
    $class->add_columns(
      id        => { data_type => 'integer', is_nullable => 0 },
      parent_id => { data_type => 'integer', is_nullable => 0 },
    );
    $class->set_primary_key('id');
    $class->belongs_to(parent => "${schema}::Result::Parent", 'parent_id', $attrs);
  };
};

# --- foreign keys -----------------------------------------------------------
{
  my $schema = schema_of(Parent => $parent, Child => $child->({}));
  my $err = do { local $@; eval { DBIO::ClickHouse::DDL->install_ddl($schema); 1 } ? '' : "$@" };
  like $err, qr/refus/i, 'a belongs_to that is a foreign key constraint is refused';
  like $err, qr/\bchild\b/, '... naming the table';
  like $err, qr/\bparent_id\b/, '... and the column';
  like $err, qr/is_foreign_key_constraint => 0/, '... and the way out';
}
{
  my $schema = schema_of(Parent => $parent, Child => $child->({ is_foreign_key_constraint => 1 }));
  eval { DBIO::ClickHouse::DDL->install_ddl($schema) };
  like "$@", qr/refus.*\bparent_id\b/is, 'an explicit foreign key constraint is refused as well';
}
{
  my $schema = schema_of(Parent => $parent, Child => $child->({ is_foreign_key_constraint => 0 }));
  my $ddl = eval { DBIO::ClickHouse::DDL->install_ddl($schema) };
  is "$@", '', 'a belongs_to declared without a constraint is accepted';
  unlike $ddl, qr/FOREIGN|REFERENCES/i, '... and no foreign key reaches the DDL';
}

# --- unique constraints -----------------------------------------------------
{
  my $schema = schema_of(Pair => sub {
    my ($class) = @_;
    $class->table('pair');
    $class->add_columns(
      id => { data_type => 'integer', is_nullable => 0 },
      a  => { data_type => 'integer', is_nullable => 0 },
      b  => { data_type => 'integer', is_nullable => 0 },
    );
    $class->set_primary_key('id');
    $class->add_unique_constraint(pair_ab => [qw(a b)]);
  });
  eval { DBIO::ClickHouse::DDL->install_ddl($schema) };
  my $err = "$@";
  like $err, qr/refus/i, 'a unique constraint is refused';
  like $err, qr/\bpair\b/, '... naming the table';
  like $err, qr/\ba\b.*\bb\b/s, '... and the columns';
  like $err, qr/ReplacingMergeTree/, '... and pointing at the engine that deduplicates';
}
{
  my $schema = schema_of(One => sub {
    my ($class) = @_;
    $class->table('one');
    $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
    $class->set_primary_key('id');
  });
  my $ddl = eval { DBIO::ClickHouse::DDL->install_ddl($schema) };
  is "$@", '', 'the primary key alone is no unique constraint to refuse';
}

# --- every constraint of a table in one text ---------------------------------
# The text of a refusal is the one place that tells the author what a table
# asked for: a foreign key and a unique constraint of the same table stand in
# the same exception, each with the table's columns (karr k43, conformance
# case diff-constraint-changed, whose subject is the column of the unique
# constraint).
{
  my $schema = schema_of(Parent => $parent, Child => sub {
    my ($class, $schema) = @_;
    $class->table('child');
    $class->add_columns(
      id        => { data_type => 'integer', is_nullable => 0 },
      parent_id => { data_type => 'integer', is_nullable => 0 },
      code      => { data_type => 'varchar', size => 20, is_nullable => 0 },
    );
    $class->set_primary_key('id');
    $class->add_unique_constraint(child_code => ['code']);
    $class->belongs_to(parent => "${schema}::Result::Parent", 'parent_id');
  });
  eval { DBIO::ClickHouse::DDL->install_ddl($schema) };
  my $err = "$@";
  like $err, qr/foreign key constraint/, 'a table with both: the foreign key is in the text';
  like $err, qr/unique constraint 'child_code' on \(code\)/, '... and the unique constraint, in the same text';
  like $err, qr/table 'child' \(columns id, parent_id, code\)/, '... each with the columns of its table';
}

# --- a table name that names nothing -----------------------------------------
# A name of the form database.table is made in that database (t/48); one with
# two dots or an empty half names nothing and is refused.
for my $bad ('a.b.c', '.t', 'db.') {
  my $schema = schema_of(Q => sub {
    my ($class) = @_;
    $class->table($bad);
    $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
    $class->set_primary_key('id');
  });
  eval { DBIO::ClickHouse::DDL->install_ddl($schema) };
  like "$@", qr/refus.*\Q$bad\E/is, "the table name '$bad' is refused";
}

# --- a portable default expression ------------------------------------------
{
  my $schema = schema_of(Stamp => sub {
    my ($class) = @_;
    $class->table('stamp');
    $class->add_columns(
      id      => { data_type => 'integer', is_nullable => 0 },
      created => { data_type => 'timestamp', is_nullable => 0,
                   default_value => \'CURRENT_TIMESTAMP' },
    );
    $class->set_primary_key('id');
  });
  my $ddl = DBIO::ClickHouse::DDL->install_ddl($schema);
  like $ddl, qr/`created` DateTime64\(3\) DEFAULT now\(\)/,
    'the bare CURRENT_TIMESTAMP, which ClickHouse rejects as a DEFAULT, is written now()';
}

# --- auto-increment on a type with no generator ---------------------------
# WHY: ClickHouse has no AUTO_INCREMENT and no identity column
# (https://clickhouse.com/docs/sql-reference/statements/create/table); a table
# built from an integer is_auto_increment column would silently lack the
# behaviour the declaration promises, so it is refused. A UUID column keeps its
# generateUUIDv4() default -- that one is real.
{
  my $schema = schema_of(Counter => sub {
    my ($class) = @_;
    $class->table('counter');
    $class->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'varchar', size => 20, is_nullable => 1 },
    );
    $class->set_primary_key('id');
  });
  my $err = do { local $@; eval { DBIO::ClickHouse::DDL->install_ddl($schema); 1 } ? '' : "$@" };
  like $err, qr/refus/i, 'is_auto_increment on an integer column is refused';
  like $err, qr/\bcounter\b/, '... naming the table';
  like $err, qr/column 'id'/, '... and the column';
  like $err, qr/no auto-increment and no identity column/, '... and the reason';
  like $err, qr/generateUUIDv4\(\)/, '... and the alternative';
  like $err, qr/table 'counter' \(columns id, name\)/, '... with the columns of its table';
}
{
  my $schema = schema_of(U => sub {
    my ($class) = @_;
    $class->table('u');
    $class->add_columns(id => { data_type => 'uuid', is_auto_increment => 1, is_nullable => 0 });
    $class->set_primary_key('id');
  });
  my $ddl = eval { DBIO::ClickHouse::DDL->install_ddl($schema) };
  is "$@", '', 'is_auto_increment on a UUID column is still accepted';
  like $ddl, qr/DEFAULT generateUUIDv4\(\)/, '... and gets its generator';
}

# --- bit with a size --------------------------------------------------------
{
  my $schema = schema_of(Sized => sub {
    my ($class) = @_;
    $class->table('sized');
    $class->add_columns(
      id => { data_type => 'integer', is_nullable => 0 },
      b  => { data_type => 'bit', size => 8, is_nullable => 1 },
    );
    $class->set_primary_key('id');
  });
  my $err = do { local $@; eval { DBIO::ClickHouse::DDL->install_ddl($schema); 1 } ? '' : "$@" };
  like $err, qr/refus/i, 'a bit column with a size is refused';
  like $err, qr/\bsized\b/, '... naming the table';
  like $err, qr/column 'b'/, '... and the column';
  like $err, qr/size '8' on type 'bit'.*ClickHouse has no BIT type/s, '... and the size and the reason';
  like $err, qr/table 'sized' \(columns id, b\)/, '... with the columns of its table';
}

done_testing;
