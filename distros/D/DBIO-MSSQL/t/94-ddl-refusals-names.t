use strict;
use warnings;
use Test::More;

# columns with a blank or a hyphen are legal in SQL Server; the accessor CAG
# cannot make for them is not what is tested
BEGIN { $ENV{CAG_ILLEGAL_ACCESSOR_NAME_OK} = 1 }

use DBIO::MSSQL::DDL qw(_mssql_column_type _constraint_name);
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Diff::Table;

# karr k71, review round 2 (offline; the live half is t/95).
#
# WHY, per block:
#  1. A table name with a dot means schema.table to SQL Server and the
#     SQLMaker renders [other].[t] at run time, so installing the table
#     [other.t] makes every query fail with "Invalid object name". The driver
#     refuses the name where it would create the table (karr k72). Since the
#     decision of 2026-10-25 the name is made in its schema instead, and only a
#     name with two dots is refused.
#  2. SQL Server refuses a foreign key that "may cause cycles or multiple
#     cascade paths" (Msg 1785). The driver says so before the server is asked,
#     naming table and relationship; the rule is the one measured in t/95.
#     What the server accepts must not be refused (false alarms are worse than
#     the server's own error).
#  3. The unique constraint core names <table>_<columns> can be the name of
#     another table (table user + unique(email), table user_email): own
#     prefix. A name over 128 characters is cut with a hash, the same way for
#     every caller.
#  4. A type is judged by its normalised name, not by the spelling it came in.
#  5. A column name with a blank or a hyphen in a key condition.

use lib 't/lib';
use K71Fixtures qw(schema_for rel @REFUSED @ALLOWED);

my $n = 1000;

# ---- 1. dotted table names
# was: install_ddl and the CREATE TABLE of the diff refused a name with a dot
# ("other.t is refused ... karr k72"), because the driver wrote every table into
# dbo and the SQLMaker would never have found [other.t]. Decided 2026-10-25
# (karr k72): schema.table is made in that schema; t/111 holds that. What
# stays refused here is a name that is no schema.table.
{
  my $class = "K94::S" . ++$n;
  eval "package $class; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); package $class\::Result::T; use base 'DBIO::Core'; __PACKAGE__->table('other.t'); __PACKAGE__->add_columns(id => { data_type => 'integer' }); __PACKAGE__->set_primary_key('id'); 1" or die $@;
  $class->register_class(T => "$class\::Result::T");
  my $ddl = eval { DBIO::MSSQL::DDL->install_ddl($class) };
  ok defined $ddl, 'install_ddl no longer refuses a table name with a dot' or diag $@;
  like $ddl // '', qr/CREATE TABLE other\.t \(/, '... it makes the table t in the schema other';

  my $sql = eval { DBIO::MSSQL::Diff::Table->new(action => 'create', table_name => 'other.t',
      columns => [ { column_name => 'id', data_type => 'int' } ])->as_sql };
  like $sql // $@, qr/^CREATE TABLE other\.t \(/, 'and so does the CREATE TABLE of the diff';
  is eval { DBIO::MSSQL::Diff::Table->new(action => 'drop', table_name => 'a.b')->as_sql },
    'DROP TABLE a.b;', 'a table of that name is dropped in its schema (was DROP TABLE [a.b] in dbo)';

  my $c3 = "K94::S" . ++$n;
  eval "package $c3; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); package $c3\::Result::T; use base 'DBIO::Core'; __PACKAGE__->table('a.b.t'); __PACKAGE__->add_columns(id => { data_type => 'integer' }); __PACKAGE__->set_primary_key('id'); 1" or die $@;
  $c3->register_class(T => "$c3\::Result::T");
  eval { DBIO::MSSQL::DDL->install_ddl($c3) };
  like $@, qr/table 'a\.b\.t' is refused.*database/s,
    'a name with two dots (qualified with a database) is refused, naming the table';
}

# ---- 2. cascades
for my $c (@REFUSED) {
  my ($label, $tables, $table, $rel) = @$c;
  my $class = schema_for(@$tables);
  eval { DBIO::MSSQL::DDL->install_ddl($class) };
  like $@, qr/refus/, "refused: $label";
  like $@, qr/table '(?:$table)'.*relationship '(?:$rel)'.*Msg 1785/s,
    "... the message names the table, the relationship and the server's Msg 1785";
}

my @allowed = (
  [ 'a parent with a CASCADE child',
    [ ['p'], ['c', [ rel(p => 'p', 'p_id', on_delete => 'cascade', on_update => 'cascade') ]] ] ],
  [ 'a self-reference with NO ACTION (and RESTRICT)',
    [ ['node', [ rel(up => 'node', 'up_id'), rel(up2 => 'node', 'up2_id', on_delete => 'restrict') ]] ] ],
  [ 'two keys to one parent, CASCADE and NO ACTION',
    [ ['p'], ['c', [ rel(a => 'p', 'a_id', on_delete => 'cascade'), rel(b => 'p', 'b_id') ]] ] ],
  [ 'ON DELETE CASCADE on one key, ON UPDATE CASCADE on the other',
    [ ['p'], ['c', [ rel(a => 'p', 'a_id', on_delete => 'cascade'), rel(b => 'p', 'b_id', on_update => 'cascade') ]] ] ],
  [ 'a cycle of two tables, one key NO ACTION',
    [ ['a', [ rel(to_b => 'b', 'b_id', on_delete => 'cascade') ]],
      ['b', [ rel(to_a => 'a', 'a_id') ]] ] ],
  [ 'a cycle of SET NULL keys (the update reaches no referenced column)',
    [ ['a', [ rel(to_b => 'b', 'b_id', on_delete => 'set null') ]],
      ['b', [ rel(to_a => 'a', 'a_id', on_delete => 'set null') ]] ] ],
  [ 'a CASCADE chain',
    [ ['r'], ['x', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['y', [ rel(x => 'x', 'x_id', on_delete => 'cascade') ]] ] ],
  [ 'a diamond with one leg NO ACTION',
    [ ['r'], ['x', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['y', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['z', [ rel(x => 'x', 'x_id', on_delete => 'cascade'), rel(y => 'y', 'y_id') ]] ] ],
  [ 'a diamond whose legs are SET NULL on columns nothing references',
    [ ['r'], ['x', [ rel(r => 'r', 'r_id', on_delete => 'set null') ]],
      ['y', [ rel(r => 'r', 'r_id', on_delete => 'set null') ]],
      ['z', [ rel(x => 'x', 'x_id', on_delete => 'cascade'), rel(y => 'y', 'y_id', on_delete => 'cascade') ]] ] ],
);
for my $c (@ALLOWED) {
  my ($label, $tables) = @$c;
  my $ok = eval { DBIO::MSSQL::DDL->install_ddl(schema_for(@$tables)); 1 };
  ok $ok, "accepted: $label" or diag $@;
}

# the diff asks the same question of the target model it is given
{
  my $fk = sub { +{ constraint_name => $_[0], from_columns => [$_[1]], to_table => $_[2],
                    to_columns => ['id'], on_delete => $_[3], on_update => 'NO ACTION' } };
  my $tables = { map { $_ => { kind => 'table' } } qw(p c) };
  my $target = {
    tables  => $tables,
    columns => {},
    indexes => {},
    foreign_keys => { c => [ $fk->('FK_c_a_id', 'a_id', 'p', 'CASCADE'),
                             $fk->('FK_c_b_id', 'b_id', 'p', 'SET NULL') ] },
  };
  my $diff = DBIO::MSSQL::Diff->new(
    source => { tables => $tables, columns => {}, indexes => {}, foreign_keys => {} },
    target => $target);
  eval { $diff->operations };
  like $@, qr/table 'c'.*constraint 'FK_c_b_id'.*refused.*Msg 1785/s,
    'the diff refuses a target model that cascades twice onto one table';

  # the keys are there already on the source: nothing is added, nothing asked
  my $same = DBIO::MSSQL::Diff->new(
    source => { %$target }, target => { %$target });
  ok eval { $same->operations; 1 }, 'a model the server holds already is not judged' or diag $@;
}

# ---- 3. constraint names
{
  my $class = schema_for(
    ['user', undef, { email => { data_type => 'varchar', size => 50 } },
      sub { $_[0]->add_unique_constraint([qw(email)]) }],
    ['user_email'],
    ['gadget', undef, { code => { data_type => 'varchar', size => 20 } },
      sub { $_[0]->add_unique_constraint(my_own => [qw(code)]) }],
  );
  my $ddl = DBIO::MSSQL::DDL->install_ddl($class);
  like $ddl, qr/CONSTRAINT UQ_user_email UNIQUE \(email\)/,
    'the unique constraint of user(email) is not called user_email, the name of a table';
  like $ddl, qr/CREATE TABLE user_email /, '... which exists';
  like $ddl, qr/CONSTRAINT my_own UNIQUE \(code\)/, 'a declared name stays';

  my $long = join '_', 'a' x 60, 'b' x 60;
  my @cols = ('c' x 40);
  my $name = _constraint_name('FK', $long, @cols);
  is length $name, 128, 'a name over 128 characters is cut to 128';
  like $name, qr/_[0-9a-f]{8}\z/, '... ending in 8 hex digits of its hash';
  is _constraint_name('FK', $long, @cols), $name, '... the same every time';
  isnt _constraint_name('FK', $long, 'c' x 39, 'd'), $name,
    '... and another name with the same start keeps another hash';
  is _constraint_name('UQ', 't', 'a', 'b'), 'UQ_t_a_b', 'a short name is as it is';
  is length _constraint_name('FK', 'x' x 200), 128, 'also when the table alone is too long';

  # the DDL uses it, for a key and for a unique constraint
  my $lt = 'lt' x 50;
  my $lc = 'lc' x 20;
  my $class2 = schema_for(
    ['parent'],
    [$lt, [ rel(p => 'parent', $lc, on_delete => 'cascade') ], undef,
      sub { $_[0]->add_unique_constraint([$lc]) }],
  );
  my $ddl2 = DBIO::MSSQL::DDL->install_ddl($class2);
  my @names = $ddl2 =~ /CONSTRAINT (\S+) (?:FOREIGN KEY|UNIQUE)/g;
  is scalar(@names), 2, 'one key and one unique constraint';
  ok !(grep { length $_ > 128 } @names), 'none is over 128 characters' or diag "@names";
    is_deeply [ sort @names ], [ sort(_constraint_name('FK', $lt, $lc), _constraint_name('UQ', $lt, $lc)) ],
    'the key and the unique constraint are named by the one function';
}

# ---- 4. types
{
  my $t = sub { my ($type, %i) = @_; eval { _mssql_column_type({ data_type => $type, %i }, 'tb', 'c') } // "ERR: $@" };
  for my $alias ('char varying', 'character varying', 'CHAR VARYING', 'Character  Varying') {
    is $t->($alias, size => 10), 'nvarchar(10)', "'$alias' keeps its size";
  }
  is $t->('char varying(20)'), 'nvarchar(20)', 'a size in the type name is the size';
  for my $alias ('nchar varying', 'national character varying', 'national char varying') {
    is $t->($alias, size => 10), 'nvarchar(10)', "'$alias' keeps its size";
  }
  is $t->('national character', size => 10), 'nchar(10)', "'national character' keeps its size";
  is $t->('national char', size => 10),       'nchar(10)', "'national char' keeps its size";
  is $t->('binary varying', size => 10),      'varbinary(10)', "'binary varying' keeps its size";
  is $t->('binary varying', size => -1),      'varbinary(max)', "'binary varying' with -1 is (max)";
  for my $bit ('bit', 'BIT', 'bool', 'BOOLEAN') {
    my $lcbit = lc $bit;
    like $t->($bit, size => 8), qr/size '8' on type '\Q$lcbit\E' .*is refused: bit has no length/s,
      "'$bit' with a size of 8 is refused";
    is $t->($bit), 'bit', "'$bit' alone is bit";
  }
  like $t->('bit(8)'),  qr/size '8' on type 'bit' .*is refused/s, "'bit(8)' is refused";
  like $t->('BOOL(8)'), qr/size '8' on type 'bool' .*is refused/s, "'BOOL(8)' is refused";
  is $t->('bit(1)'), 'bit', "'bit(1)' is bit";
  for my $e ('enum', 'ENUM', 'Enum', 'enum(a,b)', 'ENUM (a, b)') {
    like $t->($e), qr/type 'enum' \(table 'tb', column 'c'\) is refused/, "'$e' is refused";
  }
  is $t->('numeric(10,2)'), 'numeric(10,2)', 'a parameterised native type passes through';
}

# ---- 5. a column name with a blank or a hyphen in a key
{
  my $c2 = "K94::S" . ++$n;
  local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /illegal accessor/ };
  eval "package $c2; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL');
        package $c2\::Result::Par; use base 'DBIO::Core'; __PACKAGE__->table('par');
        __PACKAGE__->add_columns('par id' => { data_type => 'integer' });
        __PACKAGE__->set_primary_key('par id');
        package $c2\::Result::Kid; use base 'DBIO::Core'; __PACKAGE__->table('kid');
        __PACKAGE__->add_columns(id => { data_type => 'integer' }, 'my-par' => { data_type => 'integer' });
        __PACKAGE__->set_primary_key('id');
        __PACKAGE__->belongs_to(par => '$c2\::Result::Par', { 'foreign.par id' => 'self.my-par' });
        1" or die $@;
  $c2->register_class(Par => "$c2\::Result::Par");
  $c2->register_class(Kid => "$c2\::Result::Kid");
  my $ddl = DBIO::MSSQL::DDL->install_ddl($c2);
  like $ddl, qr/FOREIGN KEY \(\[my-par\]\) REFERENCES par \(\[par id\]\)/,
    'a key over columns with a blank and a hyphen is written, quoted';
}

done_testing;
