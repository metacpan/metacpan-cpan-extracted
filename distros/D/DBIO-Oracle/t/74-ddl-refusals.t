use strict;
use warnings;
use Test::More;

use DBIO::Test::Conformance ();
use DBIO::Oracle::DDL ();
use DBIO::Oracle::Type ();

# OFFLINE (karr k56, core ADR 0060). What DBIO::Oracle::DDL does with a
# declaration Oracle cannot hold: it throws a DBIO exception of its own,
# before any statement is sent, naming the table and the column, instead of
# writing SQL the server then rejects (ORA-00902, ORA-25716, ORA-03060,
# ORA-00942). And the two type mappings the shared case table found wrong:
# double, which Oracle does not have under that name, and bit.
#
# CLAIM: every one of these used to leave install_ddl with a statement the
# server answers with an error of its own (DBIO::Exception::Server on a real
# deploy), or, for the table named 'other.t', with a table whose name is
# literally that. After: a DBIO exception whose text says "refus", names the
# object and says why. The live half is t/73-conformance-ddl-live.t.

# A schema class from sources written the way the shared case table writes
# them (core's runner builds the classes).
sub schema_of {
  my (@sources) = @_;
  return DBIO::Test::Conformance->_build_schema_class(
    { name => 't74', input => { sources => \@sources } });
}

sub ddl_error {
  my ($schema_class) = @_;
  my $ddl = eval { DBIO::Oracle::DDL->install_ddl($schema_class) };
  return $@ ? $@ : undef if !defined $ddl;
  return undef;
}

# The message without the " at FILE line N" of the throw: this file's own name
# says "refus" and must not satisfy the check for the text.
sub msg { (my $t = "$_[0]") =~ s/ at \S+ line \d+.*\z//s; $t }

my $id = sub { +{ data_type => 'integer', is_nullable => 0 } };

# --- double --------------------------------------------------------------

is(DBIO::Oracle::Type::map_dbio_type_to_oracle('double'), 'BINARY_DOUBLE',
  'double is BINARY_DOUBLE, as double precision is; DOUBLE is no Oracle type');
is(DBIO::Oracle::Type::map_dbio_type_to_oracle('double precision'), 'BINARY_DOUBLE',
  '... and double precision stays BINARY_DOUBLE');

# --- enum ----------------------------------------------------------------

{
  my $err = ddl_error(schema_of({
    name => 'Pick', table => 'pick',
    columns => [ id => $id->(),
      kind => { data_type => 'enum', extra => { list => [ "it's", 'plain' ] } } ],
    primary_key => ['id'],
  }));
  ok $err, 'an enum column is refused at the DDL, not sent to the server';
  isa_ok $err, 'DBIO::Exception';
  isnt ref $err, 'DBIO::Exception::Server', '... not a server error';
  like msg($err), qr/refus/i,       '... the text says refus';
  like "$err", qr/\bpick\b/,     '... it names the table';
  like "$err", qr/\bkind\b/,     '... it names the column';
  like "$err", qr/no enum type/, '... it says why';
}

# --- bit -----------------------------------------------------------------

{
  my $err = ddl_error(schema_of({
    name => 'Sized', table => 'sized',
    columns => [ id => $id->(), b => { data_type => 'bit', size => 8 } ],
    primary_key => ['id'],
  }));
  ok $err, 'a bit column is refused at the DDL (Oracle has no BIT type)';
  like msg($err), qr/refus/i,       '... the text says refus';
  like "$err", qr/\bsized\b/,    '... it names the table';
  like "$err", qr/\bb\b/,        '... it names the column';
  like "$err", qr/no BIT type/,  '... it says why';
}

# --- names Oracle cannot hold -------------------------------------------

{
  my $err = ddl_error(schema_of({
    name => 'Odd', table => 'odd "t" `n`',
    columns => [ id => $id->(), 'odd "c" `n`' => { data_type => 'varchar', size => 20, accessor => 'odd_c' } ],
    primary_key => ['id'],
  }));
  ok $err, 'a name with a double quote is refused at the DDL';
  isa_ok $err, 'DBIO::Exception';
  like msg($err), qr/refus/i,             '... the text says refus';
  like "$err", qr/\Qodd "t" `n`\E/,    '... it names the table';
  like "$err", qr/\Qodd "c" `n`\E/,    '... and the column, both in one message';
  like "$err", qr/double quote/,       '... it says why';
}
{
  my $err = ddl_error(schema_of({
    name => 'Fine', table => 'fine',
    columns => [ id => $id->(), 'odd `c` n' => { data_type => 'varchar', size => 20, accessor => 'odd_c' },
                 'with space' => { data_type => 'varchar', size => 20, accessor => 'ws' } ],
    primary_key => ['id'],
  }));
  is $err, undef, 'a space, a backtick or any other character but the double quote is a name';
}

# --- a name qualified with a schema --------------------------------------

# a table other.t is a table t in the schema other (karr k58, t/85 has the
# rest); only a name with an empty half is refused
{
  my $q = schema_of({
    name => 'Qualified', table => 'other.t',
    columns => [ id => $id->() ], primary_key => ['id'],
  });
  is ddl_error($q), undef, 'a table named other.t is not refused: it is t in the schema other';
  like(DBIO::Oracle::DDL->install_ddl($q), qr/CREATE TABLE "other"\."t" \(/,
    '... it is created there, not with a dot in its name');
  my $err = ddl_error(schema_of({
    name => 'Half', table => 'other.',
    columns => [ id => $id->() ], primary_key => ['id'],
  }));
  ok $err, 'a name with an empty half is refused';
  like msg($err), qr/refus/i,  '... the text says refus';
  like "$err", qr/other\./,    '... it names the table';
}
{
  my $ddl = DBIO::Oracle::DDL->install_ddl(schema_of({
    name => 'Lit', table => \'lit',
    columns => [ id => $id->() ], primary_key => ['id'],
  }));
  like $ddl, qr/CREATE TABLE lit \(/, 'a literal table name (a scalar reference) is still the user\'s own SQL';
}

# --- the type is compared as it means, not as it is spelled ----------------

sub ddl_text { my $d = eval { DBIO::Oracle::DDL->install_ddl($_[0]) }; return defined $d ? $d : "ERROR: $@" }

for my $spelled (' enum', 'ENUM ', 'Enum', 'set', ' SET ', 'enum(a,b)') {
  my $err = ddl_error(schema_of({
    name => 'Sp', table => 'sp',
    columns => [ id => $id->(), kind => { data_type => $spelled } ],
    primary_key => ['id'],
  }));
  ok $err, "a column of type '$spelled' is refused";
  like msg($err), qr/refus/i, '... the text says refus';
  like "$err", qr/\bsp\b.*\bkind\b/s, '... it names the table and the column';
}
for my $spelled ('bit(8)', ' BIT ', 'bit  varying', 'bit varying (8)', 'VARBIT', 'varbit(3)') {
  my $err = ddl_error(schema_of({
    name => 'Sb', table => 'sb',
    columns => [ id => $id->(), b => { data_type => $spelled } ],
    primary_key => ['id'],
  }));
  ok $err, "a column of type '$spelled' is refused";
  like msg($err), qr/refus/i, '... the text says refus';
  like "$err", qr/\bsb\b.*\bb\b/s, '... it names the table and the column';
}
is(DBIO::Oracle::Type::map_dbio_type_to_oracle('double  precision'), 'BINARY_DOUBLE',
  'double precision with two blanks is double precision (not DOUBLE  PRECISION, which Oracle reads as FLOAT(126))');
is(DBIO::Oracle::Type::map_dbio_type_to_oracle(' Double Precision '), 'BINARY_DOUBLE',
  '... and so are the outer blanks and the letter case');
like ddl_text(schema_of({
    name => 'Dd', table => 'dd',
    columns => [ id => $id->(), x => { data_type => 'double  precision' } ],
    primary_key => ['id'],
  })), qr/"x" BINARY_DOUBLE/,
  'the DDL writes it as BINARY_DOUBLE';

# --- a view definition is the user's own SQL ------------------------------

# The driver does not guess at the SQL of a view: a definition is sent as it
# is, and the server answers for a name it cannot find (ORA-00942). A
# fully quoted definition is valid whatever the shape of its FROM clause.
my @base = (
  { name => 'Artist', table => 'artist',
    columns => [ id => $id->(), name => { data_type => 'varchar', size => 20 } ],
    primary_key => ['id'] },
  { name => 'Cd', table => 'cd',
    columns => [ id => $id->(), title => { data_type => 'varchar', size => 20 },
                 artist_id => { data_type => 'integer' } ],
    primary_key => ['id'] },
);
sub view_of {
  my ($def) = @_;
  return schema_of(@base, {
    name => 'V', table => 'v',
    columns => [ id => { data_type => 'integer' } ],
    view => { definition => $def, virtual => 0 },
  });
}

for my $def (
  'SELECT cd."title" FROM "cd" cd JOIN "artist" a ON a."id" = cd."artist_id"',
  'SELECT "id" FROM "artist" artist',
  'SELECT "id" FROM "artist", "cd" cd WHERE cd."artist_id" = "artist"."id"',
  'SELECT "id" FROM "artist" /* from artist */ WHERE "name" = \'from artist\'',
) {
  my $ddl = ddl_text(view_of($def));
  like $ddl, qr/CREATE VIEW "v" AS \Q$def\E;/, "a quoted view definition is written: $def";
}
like ddl_text(view_of('SELECT id, name FROM artist')),
  qr/CREATE VIEW "v" AS SELECT id, name FROM artist;/,
  'an unquoted definition is the user\'s own SQL too: written, the server answers ORA-00942';

# --- every refusal says refus, and names the table and the column -----------

{
  package T74::R;
  my $n = 0;
  # a result class of table 'rt' with the given columns; $extra declares more
  sub build {
    my ($columns, $extra) = @_;
    my $schema = 'T74::R::S' . ++$n;
    my $kid    = "$schema\::Result::Kid";
    my $parent = "$schema\::Result::Parent";
    eval qq{
      package $schema; use base 'DBIO::Schema'; __PACKAGE__->load_components('Oracle');
      package $parent; use base 'DBIO::Core';
      $parent->table('rp');
      $parent->add_columns(id => { data_type => 'integer' });
      $parent->set_primary_key('id');
      package $kid; use base 'DBIO::Core';
      $kid->table('rt');
      1;
    } or die $@;
    $kid->add_columns(@$columns);
    $kid->set_primary_key('id');
    $extra->($kid, $parent) if $extra;
    $schema->register_class(Parent => $parent);
    $schema->register_class(Kid => $kid);
    return $schema;
  }
}

sub refused_ok {
  my ($label, $schema, @must) = @_;
  my $err = ddl_error($schema);
  ok $err, "$label: refused";
  isa_ok $err, 'DBIO::Exception';
  isnt ref $err, 'DBIO::Exception::Server', '... not a server error';
  like msg($err), qr/refus/i, '... the text says refus';
  like "$err", qr/\brt\b/, '... it names the table';
  like "$err", $_, "... and matches $_" for @must;
}

my @kid = (id => { data_type => 'integer' }, p => { data_type => 'integer' });

refused_ok('an index of a type other than unique',
  T74::R::build(\@kid, sub { $_[0]->result_source_instance->add_index_declaration(
    { name => 'h_idx', columns => ['p'], type => 'hash' }) }),
  qr/\bh_idx\b/, qr/type 'hash'/);
refused_ok('an index with options',
  T74::R::build(\@kid, sub { $_[0]->result_source_instance->add_index_declaration(
    { name => 'o_idx', columns => ['p'], options => { fillfactor => 70 } }) }),
  qr/\bo_idx\b/, qr/options/);
refused_ok('an on_delete Oracle does not have',
  T74::R::build(\@kid, sub { $_[0]->belongs_to(parent => $_[1], 'p', { on_delete => 'SET DEFAULT' }) }),
  qr/relationship 'parent'/, qr/SET DEFAULT/);
refused_ok('an on_update Oracle does not have',
  T74::R::build(\@kid, sub { $_[0]->belongs_to(parent => $_[1], 'p', { on_update => 'CASCADE' }) }),
  qr/relationship 'parent'/, qr/CASCADE/);
refused_ok('two relationships to one key with other actions',
  T74::R::build(\@kid, sub {
    $_[0]->belongs_to(a_parent => $_[1], 'p', { on_delete => 'CASCADE' });
    $_[0]->belongs_to(b_parent => $_[1], 'p', { on_delete => 'SET NULL' });
  }),
  qr/'a_parent' and 'b_parent'/);
refused_ok('an index over the columns of a unique constraint',
  T74::R::build(\@kid, sub {
    $_[0]->add_unique_constraint(uq_p => ['p']);
    $_[0]->result_source_instance->add_index_declaration({ name => 'by_p', columns => ['p'] });
  }),
  qr/\bp\b/, qr/uq_p/);
refused_ok('a float with a precision Oracle does not have',
  T74::R::build([ id => { data_type => 'integer' }, f => { data_type => 'float', size => 200 } ]),
  qr/\bf\b/, qr/binary precision/);

done_testing;
