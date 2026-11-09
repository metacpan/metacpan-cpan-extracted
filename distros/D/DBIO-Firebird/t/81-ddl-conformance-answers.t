use strict;
use warnings;
use Test::More;

use DBIO::Core;
use DBIO::Schema;
use DBIO::Firebird::DDL;

# Offline (karr k55): the answers install_ddl gives to the shared DDL case
# table of DBIO::Test::Conformance (core ADR 0060), checked on the statements,
# no server needed.
#
#  1. A type keeps its size and arrives as Firebird spells it. `character`
#     lost its width (CHAR alone is CHAR(1)), the base type `double` was
#     written DOUBLE, which is a syntax error, and a handful of aliases of
#     DBIO::Schema::Type (tinyint, bool, string, mediumtext) were written as
#     names the server takes for a domain that does not exist.
#  2. bit and enum are refused. Firebird has no type for a bit string of a
#     fixed width: BOOLEAN is one bit, BINARY(n) counts bytes, so every
#     mapping would change what the size means; an enum mapped to VARCHAR
#     would lose the list of its values. A refusal names the table and the
#     column; a column quietly built as something else is the failure these
#     cases exist to catch.
#  3. A table name with a dot is refused: Firebird has no schemas before
#     version 6, so the dot would become part of a literal name, and a
#     consumer that reads `other.t` as table `t` in schema `other` finds
#     nothing. A literal name (\'...') is SQL as written and stays.
#  4. An index the server already has is not built a second time: a declared
#     index over the primary key, over a written unique constraint, or (when
#     it is not unique) over a written foreign key's columns. Firebird builds
#     an index for each of those itself. A UNIQUE index over foreign key
#     columns says something the key does not and stays.

my $n = 0;
sub schema_for {
  my ($build) = @_;
  $n++;
  my $sc = "T::K55::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my (@later, @classes);
  my $make = sub {
    my ($name, $table, $cols, $pk, $extra) = @_;
    my $rc = "T::K55::S${n}::Result::$name";
    { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); $INC{"T/K55/S${n}/Result/$name.pm"} = 1; }
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk) if $pk;
    push @later, sub { $extra->($rc) } if $extra;
    push @classes, [ $name => $rc ];
  };
  $build->($make);
  $_->() for @later;
  $sc->register_class(@$_) for @classes;
  return $sc;
}
sub ddl_of {
  my ($table, $cols) = @_;
  my $sc = schema_for(sub { $_[0]->(T => $table, [ id => { data_type => 'integer' }, @$cols ], ['id']) });
  return DBIO::Firebird::DDL->install_ddl($sc);
}

# --- 1. types ------------------------------------------------------------------
my @types = (
  [ { data_type => 'character', size => 10 },             'CHAR(10)' ],
  [ { data_type => 'character varying', size => 20 },     'VARCHAR(20)' ],
  [ { data_type => 'char', size => 5 },                   'CHAR(5)' ],
  [ { data_type => 'double' },                            'DOUBLE PRECISION' ],
  [ { data_type => 'double precision' },                  'DOUBLE PRECISION' ],
  [ { data_type => 'tinyint' },                           'SMALLINT' ],
  [ { data_type => 'int' },                               'INTEGER' ],
  [ { data_type => 'bool' },                              'BOOLEAN' ],
  [ { data_type => 'string', size => 30 },                'VARCHAR(30)' ],
  [ { data_type => 'string' },                            'BLOB SUB_TYPE TEXT' ],
  [ { data_type => 'real' },                              'DOUBLE PRECISION' ],
  [ { data_type => 'bool', default_value => 0 },          'BOOLEAN DEFAULT FALSE' ],
  [ { data_type => 'BOOL', default_value => 'true' },     'BOOLEAN DEFAULT TRUE' ],
  [ { data_type => 'mediumtext' },                        'BLOB SUB_TYPE TEXT' ],
  [ { data_type => 'longtext' },                          'BLOB SUB_TYPE TEXT' ],
  [ { data_type => 'binary', size => 4 },                 'BINARY(4)' ],
  [ { data_type => 'varbinary', size => 16 },             'VARBINARY(16)' ],
  [ { data_type => 'numeric', size => [ 10, 2 ] },        'DECIMAL(10,2)' ],
);
for my $t (@types) {
  my ($info, $want) = @$t;
  my $ddl = ddl_of('typed', [ c => { %$info, is_nullable => 1 } ]);
  like $ddl, qr/^  "c" \Q$want\E,?$/m, "$info->{data_type} is written as $want";
}

# --- 2. bit and enum are refused -----------------------------------------------
for my $case (
  [ bit  => 'sized', 'b', { data_type => 'bit', size => 8 } ],
  [ enum => 'pick',  'kind', { data_type => 'enum', extra => { list => [ "it's", 'plain' ] } } ],
) {
  my ($what, $table, $col, $info) = @$case;
  my $ddl = eval { ddl_of($table, [ ok => { data_type => 'integer' }, $col => { %$info, is_nullable => 0 } ]) };
  my $err = $@;
  ok !defined $ddl, "$what: no DDL is written";
  isa_ok $err, 'DBIO::Exception', "$what: the refusal";
  like "$err", qr/refus/i, "$what: the text says it is a refusal";
  like "$err", qr/'\Q$table\E'/, "$what: the text names the table";
  like "$err", qr/'\Q$col\E'/, "$what: the text names the column";
  like "$err", qr/$what/, "$what: the text names the type";
}
like eval { ddl_of('sized', [ b => { data_type => 'bit', size => 8 } ]); 'x' } // $@,
  qr/BOOLEAN is one bit.*BINARY\(n\) counts bytes/s,
  'bit: the reason is the meaning of the size';

# --- 3. a dotted table name ------------------------------------------------------
{
  my $err;
  eval { ddl_of('other.t', []); 1 } or $err = $@;
  isa_ok $err, 'DBIO::Exception', 'a table name with a dot: refused';
  like "$err", qr/refus/i, 'the text says it is a refusal';
  like "$err", qr/'other\.t'/, 'the text names the table as declared';
  like "$err", qr/schema/i, 'the text says why: no schemas';

  my $sc = schema_for(sub { $_[0]->(L => \'lit.t', [ id => { data_type => 'integer' } ], ['id']) });
  my $ddl = eval { DBIO::Firebird::DDL->install_ddl($sc) };
  like $ddl // $@, qr/CREATE TABLE lit\.t /,
    'a literal name (scalar ref) is SQL as written and is not refused';
}

# --- 4. an index the server already has ------------------------------------------
sub idx_names {
  my ($ddl) = @_;
  return [ sort $ddl =~ /^CREATE (?:UNIQUE )?INDEX "([^"]+)"/mg ];
}
sub with_indexes {
  my (@decl) = @_;
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ id => { data_type => 'integer' } ], ['id']);
    $make->(Child => 'child',
      [ map { $_ => { data_type => 'integer' } } qw(id pid a b) ], ['id'], sub {
        my $rc = shift;
        $rc->belongs_to(parent => "T::K55::S${n}::Result::Parent", 'pid');
        $rc->add_unique_constraint(child_ab => [qw(a b)]);
        $rc->result_source_instance->add_index_declaration($_) for @decl;
      });
  });
  return DBIO::Firebird::DDL->install_ddl($sc);
}

is_deeply idx_names(with_indexes(
  { name => 'dup_pk',     columns => ['id'] },
  { name => 'dup_pk_u',   columns => ['id'], type => 'unique' },
  { name => 'dup_unique', columns => [qw(a b)] },
  { name => 'dup_unique_u', columns => [qw(a b)], type => 'unique' },
  { name => 'dup_fk',     columns => ['pid'] },
)), [], 'declared indexes over the primary key, a unique constraint and a foreign key are not built';

is_deeply idx_names(with_indexes(
  { name => 'fk_unique', columns => ['pid'], type => 'unique' },
  { name => 'ba',        columns => [qw(b a)] },
  { name => 'just_a',    columns => ['a'] },
  { name => 'pid_a',     columns => [qw(pid a)] },
)), [qw(ba fk_unique just_a pid_a)],
  'a unique index over a foreign key, another column order, a prefix and a longer list are built';

{
  # a declaration without a key is still built, with no foreign key written
  my $sc = schema_for(sub {
    $_[0]->(T => 't', [ map { $_ => { data_type => 'integer' } } qw(id pid) ], ['id'], sub {
      $_[0]->result_source_instance->add_index_declaration({ name => 'on_pid', columns => ['pid'] });
    });
  });
  is_deeply idx_names(DBIO::Firebird::DDL->install_ddl($sc)), ['on_pid'],
    'a column that is no foreign key keeps its declared index';
}

# --- 5. the time zone types are refused (t/88 measures why) ---------------------
for my $type ('timestamptz', 'timestamp with time zone', 'time with time zone') {
  my $err;
  eval { ddl_of('zoned', [ at => { data_type => $type, is_nullable => 1 } ]); 1 } or $err = $@;
  isa_ok $err, 'DBIO::Exception', "$type: refused";
  like "$err", qr/refus/i, "$type: the text says it is a refusal";
  like "$err", qr/'zoned'/, "$type: the text names the table";
  like "$err", qr/'at'/, "$type: the text names the column";
  like "$err", qr/DBD::Firebird.*\*\* unknown \*\*/s, "$type: the text says why";
}

# --- 6. BINARY / VARBINARY need Firebird 4; the version is a seam ----------------
{
  no warnings 'redefine';
  for my $type (qw(binary varbinary)) {
    my $col = [ b => { data_type => $type, size => 4, is_nullable => 1 } ];

    {
      local *DBIO::Firebird::DDL::server_major_version = sub { 3 };
      my $err;
      eval { ddl_of('bin', $col); 1 } or $err = $@;
      isa_ok $err, 'DBIO::Exception', "$type on Firebird 3: refused";
      like "$err", qr/refus/i, "$type on Firebird 3: the text says it is a refusal";
      like "$err", qr/'bin'/, "$type on Firebird 3: the text names the table";
      like "$err", qr/'b'/, "$type on Firebird 3: the text names the column";
      like "$err", qr/Firebird 4/, "$type on Firebird 3: the text names the version needed";
      like eval { ddl_of('plain', [ c => { data_type => 'varchar', size => 4, is_nullable => 1 } ]) } // $@,
        qr/VARCHAR\(4\)/, 'a type Firebird 3 has is not touched';
    }
    for my $major (4, 5, undef) {
      local *DBIO::Firebird::DDL::server_major_version = sub { $major };
      like eval { ddl_of('bin', $col) } // $@, qr/^  "b" \U$type\E\(4\),?$/m,
        "$type on " . (defined $major ? "Firebird $major" : 'a server that cannot be asked') . ': written';
    }
  }
}

# --- 7. a view with a dot in its name --------------------------------------------
{
  my $view = sub {
    my ($name) = @_;
    $n++;
    my $sc = "T::K55::V$n";
    my $rc = "T::K55::V${n}::Result::V";
    { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); @{"${rc}::ISA"} = ('DBIO::Core'); }
    $rc->table_class('DBIO::ResultSource::View');
    $rc->table($name);
    $rc->add_columns(id => { data_type => 'integer' });
    $rc->result_source_instance->is_virtual(0);
    $rc->result_source_instance->view_definition('SELECT 1 AS "id" FROM rdb$database');
    $sc->register_class(V => $rc);
    return $sc;
  };
  my $err;
  eval { DBIO::Firebird::DDL->install_ddl($view->('other.v')); 1 } or $err = $@;
  isa_ok $err, 'DBIO::Exception', 'a view name with a dot: refused';
  like "$err", qr/refus/i, 'the text says it is a refusal';
  like "$err", qr/'other\.v'/, 'the text names the view as declared';
  like eval { DBIO::Firebird::DDL->install_ddl($view->('plain_v')) } // $@,
    qr/CREATE VIEW "plain_v" AS/, 'a plain view name is written';
  like eval { DBIO::Firebird::DDL->install_ddl($view->(\'lit.v')) } // $@,
    qr/CREATE VIEW lit\.v AS/, 'a literal view name is SQL as written';
}

# --- 8. is_unique beside a unique constraint over the same column ----------------
{
  my $count = sub {
    my ($column_extra, $constraint) = @_;
    my $sc = schema_for(sub {
      $_[0]->(U => 'u', [ id => { data_type => 'integer' },
                          code => { data_type => 'integer', %$column_extra } ], ['id'],
        ($constraint ? sub { $_[0]->add_unique_constraint(u_code => ['code']) } : undef));
    });
    my $ddl = DBIO::Firebird::DDL->install_ddl($sc);
    return (scalar(() = $ddl =~ /CREATE UNIQUE INDEX/g), scalar(() = $ddl =~ /ADD CONSTRAINT "u_code" UNIQUE/g));
  };
  is_deeply [ $count->({ is_unique => 1 }, 1) ], [ 0, 1 ],
    'is_unique plus a unique constraint over the column: the constraint only, one index';
  is_deeply [ $count->({ is_unique => 1 }, 0) ], [ 1, 0 ],
    'is_unique alone is still a unique index';
  is_deeply [ $count->({}, 1) ], [ 0, 1 ], 'the constraint alone is the constraint';
}

# --- 9. the one question the boolean guards ask -----------------------------------
{
  require DBIO::Firebird::Type;
  ok DBIO::Firebird::Type::is_boolean_type($_), "$_ is a boolean type" for qw(boolean BOOLEAN bool Bool);
  ok !DBIO::Firebird::Type::is_boolean_type($_), "$_ is not" for qw(smallint integer bit);
  ok !DBIO::Firebird::Type::is_boolean_type(undef), 'undef is not';
}

done_testing;
