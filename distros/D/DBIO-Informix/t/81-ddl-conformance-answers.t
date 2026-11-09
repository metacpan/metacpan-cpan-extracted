use strict;
use warnings;
use Test::More;

use DBIO::Core;
use DBIO::Schema;
use DBIO::Informix::DDL;

# Offline (karr k24): the answers install_ddl gives to the shared DDL case
# table of DBIO::Test::Conformance (core ADR 0060), checked on the statements,
# no server needed. Each answer was measured on Informix 15.0.1.
#
#  1. A type keeps its size and arrives as Informix spells it (character lost
#     its width, double was DOUBLE, timestamp and CURRENT_TIMESTAMP are not
#     Informix words, a VARCHAR holds 255 characters at most).
#  2. A name that is not all lower case is quoted: Informix folds an unquoted
#     name to lower case, so MixedCase would have been created as mixedcase.
#  3. bit, enum, a dotted table or view name are refused: Informix has no such
#     type, and no schemas (owner.name names a user).
#  4. A default keeps its apostrophe, and the expression defaults are the
#     Informix words.
#  5. Informix answers -350 to a second index over the columns an index
#     covers already (a primary key, a unique constraint, a foreign key):
#     such an index is not written again.
#  6. A foreign key knows ON DELETE CASCADE and nothing else.

my $n = 0;
sub schema_for {
  my ($build) = @_;
  $n++;
  my $sc = "T::K24::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my (@later, @classes);
  my $make = sub {
    my ($name, $table, $cols, $pk, $extra) = @_;
    my $rc = "T::K24::S${n}::Result::$name";
    { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); $INC{"T/K24/S${n}/Result/$name.pm"} = 1; }
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
  return DBIO::Informix::DDL->install_ddl($sc);
}
sub refusal {
  my ($code) = @_;
  my $err;
  eval { $code->(); 1 } or $err = $@;
  return $err;
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
  [ { data_type => 'string' },                            'TEXT' ],
  [ { data_type => 'varchar', size => 300 },              'LVARCHAR(300)' ],
  [ { data_type => 'mediumtext' },                        'TEXT' ],
  [ { data_type => 'blob' },                              'BYTE' ],
  [ { data_type => 'timestamp' },                         'DATETIME YEAR TO FRACTION(5)' ],
  [ { data_type => 'numeric', size => [ 10, 2 ] },        'NUMERIC(10,2)' ],
  [ { data_type => 'bool', default_value => 0 },          'BOOLEAN DEFAULT \'0\'' ],
);
for my $t (@types) {
  my ($info, $want) = @$t;
  my $ddl = ddl_of('typed', [ c => { %$info, is_nullable => 1 } ]);
  like $ddl, qr/^  c \Q$want\E,?$/m, "$info->{data_type} is written as $want";
}

# --- 2. quoting ------------------------------------------------------------------
{
  my $ddl = ddl_of('MixedCase', [ camelCol => { data_type => 'integer', is_nullable => 1 } ]);
  like $ddl, qr/CREATE TABLE "MixedCase" \(/, 'a mixed case table name is quoted';
  like $ddl, qr/^  "camelCol" INTEGER,$/m, 'a mixed case column name is quoted';
  like ddl_of('plain_t', []), qr/CREATE TABLE plain_t \(/, 'a lower case name stays bare';
  like ddl_of('odd "t"', [ 'odd "c"' => { data_type => 'integer', is_nullable => 1, accessor => 'odd_c' } ]),
    qr/CREATE TABLE "odd ""t""" \(.*^  "odd ""c""" INTEGER,$/ms, 'a quote in a name is doubled';
}

# --- 3. refusals -----------------------------------------------------------------
for my $case (
  [ bit  => 'sized', 'b', { data_type => 'bit', size => 8 } ],
  [ enum => 'pick',  'kind', { data_type => 'enum', extra => { list => [ "it's", 'plain' ] } } ],
) {
  my ($what, $table, $col, $info) = @$case;
  my $err = refusal(sub { ddl_of($table, [ ok => { data_type => 'integer' }, $col => { %$info, is_nullable => 0 } ]) });
  isa_ok $err, 'DBIO::Exception', "$what: the refusal";
  like "$err", qr/refus/i, "$what: the text says it is a refusal";
  like "$err", qr/'\Q$table\E'/, "$what: the text names the table";
  like "$err", qr/'\Q$col\E'/, "$what: the text names the column";
  like "$err", qr/$what/, "$what: the text names the type";
}
{
  my $err = refusal(sub { ddl_of('other.t', []) });
  isa_ok $err, 'DBIO::Exception', 'a table name with a dot: refused';
  like "$err", qr/refus/i, 'the text says it is a refusal';
  like "$err", qr/'other\.t'/, 'the text names the table as declared';
  like "$err", qr/no schemas/i, 'the text says why: no schemas';

  my $sc = schema_for(sub { $_[0]->(L => \'lit.t', [ id => { data_type => 'integer' } ], ['id']) });
  like eval { DBIO::Informix::DDL->install_ddl($sc) } // $@, qr/CREATE TABLE lit\.t /,
    'a literal name (scalar ref) is SQL as written and is not refused';
}
{
  my $view = sub {
    my ($name) = @_;
    $n++;
    my $sc = "T::K24::V$n";
    my $rc = "T::K24::V${n}::Result::V";
    { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); @{"${rc}::ISA"} = ('DBIO::Core'); }
    $rc->table_class('DBIO::ResultSource::View');
    $rc->table($name);
    $rc->add_columns(id => { data_type => 'integer' });
    $rc->result_source_instance->is_virtual(0);
    $rc->result_source_instance->view_definition('SELECT 1 AS id FROM systables WHERE tabid = 1');
    $sc->register_class(V => $rc);
    return $sc;
  };
  my $err = refusal(sub { DBIO::Informix::DDL->install_ddl($view->('other.v')) });
  isa_ok $err, 'DBIO::Exception', 'a view name with a dot: refused';
  like "$err", qr/'other\.v'/, 'the text names the view as declared';
  like eval { DBIO::Informix::DDL->install_ddl($view->('plain_v')) } // $@,
    qr/CREATE VIEW plain_v AS/, 'a plain view name is written';
}

# --- 4. defaults -----------------------------------------------------------------
like ddl_of('d', [ note => { data_type => 'varchar', size => 20, default_value => "it's" } ]),
  qr/^  note VARCHAR\(20\) DEFAULT 'it''s' NOT NULL,$/m, 'a default keeps its apostrophe (doubled)';
for my $e (
  [ 'CURRENT_TIMESTAMP', 'CURRENT YEAR TO FRACTION(5)' ],
  [ 'now()',             'CURRENT YEAR TO FRACTION(5)' ],
  [ 'CURRENT_DATE',      'TODAY' ],
  [ 'CURRENT_USER',      'USER' ],
  [ 'CURRENT HOUR TO SECOND', 'CURRENT HOUR TO SECOND' ],
) {
  my ($in, $out) = @$e;
  like ddl_of('d', [ at => { data_type => 'timestamp', default_value => \$in } ]),
    qr/^  at DATETIME YEAR TO FRACTION\(5\) DEFAULT \Q$out\E NOT NULL,$/m,
    "default \\'$in' is written as $out";
}

# --- 5. indexes the server already has --------------------------------------------
sub idx_names {
  my ($ddl) = @_;
  return [ sort $ddl =~ /^CREATE (?:UNIQUE )?INDEX (\S+)/mg ];
}
sub with_indexes {
  my (@decl) = @_;
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ id => { data_type => 'integer' } ], ['id']);
    $make->(Child => 'child',
      [ map { $_ => { data_type => 'integer' } } qw(id pid a b) ], ['id'], sub {
        my $rc = shift;
        $rc->belongs_to(parent => "T::K24::S${n}::Result::Parent", 'pid');
        $rc->add_unique_constraint(child_ab => [qw(a b)]);
        $rc->result_source_instance->add_index_declaration($_) for @decl;
      });
  });
  return DBIO::Informix::DDL->install_ddl($sc);
}

# karr k27 changed this claim: an index over the columns of the primary key or
# of a unique constraint was left out silently; it is refused now (t/72 holds
# the full set). Over a foreign key's columns a plain index is still not built.
is_deeply idx_names(with_indexes({ name => 'dup_fk', columns => ['pid'] })), [],
  'a declared plain index over a foreign key is not built (-350)';
for my $dup (
  [ dup_pk => ['id'], '' ], [ dup_pk_u => ['id'], 'unique' ],
  [ dup_unique => [qw(a b)], '' ], [ dup_unique_u => [qw(a b)], 'unique' ],
) {
  my ($name, $cols, $type) = @$dup;
  my $err = eval { with_indexes({ name => $name, columns => $cols, ($type ? (type => $type) : ()) }); 1 } ? '' : "$@";
  like $err, qr/\Q$name\E.*-350/s, "an index over the columns of the primary key or a unique constraint ($name) is refused (-350)";
}

is_deeply idx_names(with_indexes(
  { name => 'ba',        columns => [qw(b a)] },
  { name => 'just_a',    columns => ['a'] },
  { name => 'pid_a',     columns => [qw(pid a)] },
)), [qw(ba just_a pid_a)],
  'another column order, a prefix and a longer list are built';

{
  my $ddl = with_indexes({ name => 'fk_unique', columns => ['pid'], type => 'unique' });
  is_deeply idx_names($ddl), ['fk_unique'], 'a unique index over a foreign key says more than the key and is built';
  cmp_ok index($ddl, 'CREATE UNIQUE INDEX fk_unique'), '<', index($ddl, 'FOREIGN KEY'),
    'and it goes before the key, which shares it';
}

{
  my $ddl = with_indexes();
  like $ddl, qr/^  UNIQUE \(a, b\) CONSTRAINT child_ab$/m, 'a unique constraint is written under its name, inside the table';
  like $ddl, qr/ALTER TABLE child ADD CONSTRAINT FOREIGN KEY \(pid\) REFERENCES parent\(id\);/,
    'a belongs_to is a foreign key, after the tables';
}

{
  my $sc = schema_for(sub {
    $_[0]->(T => 't', [ map { $_ => { data_type => 'integer' } } qw(id code) ], ['id'], sub {
      $_[0]->add_unique_constraint(t_id => ['id']);
    });
  });
  unlike(DBIO::Informix::DDL->install_ddl($sc), qr/UNIQUE/,
    'a unique constraint over exactly the primary key says nothing more and is not written');
}

# --- 6. foreign key actions --------------------------------------------------------
sub fk_ddl {
  my (%attrs) = @_;
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ id => { data_type => 'integer' } ], ['id']);
    $make->(Child => 'child', [ map { $_ => { data_type => 'integer' } } qw(id pid) ], ['id'], sub {
      $_[0]->belongs_to(parent => "T::K24::S${n}::Result::Parent", 'pid', \%attrs);
    });
  });
  return DBIO::Informix::DDL->install_ddl($sc);
}
like fk_ddl(on_delete => 'CASCADE'), qr/REFERENCES parent\(id\) ON DELETE CASCADE;/, 'ON DELETE CASCADE is written';
unlike fk_ddl(on_delete => 'RESTRICT', on_update => 'NO ACTION'), qr/ON (?:DELETE|UPDATE)/,
  'RESTRICT and NO ACTION are what a key without a clause does';
for my $bad (
  [ on_delete => 'SET NULL' ], [ on_update => 'CASCADE' ], [ is_deferrable => 1 ],
) {
  my $err = refusal(sub { fk_ddl(@$bad) });
  isa_ok $err, 'DBIO::Exception', "$bad->[0] $bad->[1]: refused";
  like "$err", qr/refus/i, "$bad->[0]: the text says it is a refusal";
  like "$err", qr/'child'/, "$bad->[0]: the text names the table";
}

done_testing;
