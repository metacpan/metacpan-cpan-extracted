use strict;
use warnings;
use Test::More;

BEGIN { $ENV{CAG_ILLEGAL_ACCESSOR_NAME_OK} = 1 }

use DBIO::MSSQL::DDL qw(_mssql_column_type);
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Diff::Column;
use DBIO::Test::Schema;

use lib 't/lib';
use K71Fixtures qw(schema_for rel);

# karr k71, review round 3 (offline; the live half is t/101).
#
# WHY, per block:
#  1. SQL Server keeps constraint names and object names (tables, views) in one
#     namespace per schema (Msg 2714). A constraint named like a table of the
#     deploy fails only at the server; the driver refuses before, also when the
#     name was chosen on purpose.
#  2. A parameter of a standard type spelling that is neither digits nor max
#     was thrown away ('character varying(x)' became a bare varchar, one
#     character); a parameter and a size that disagree have no right reading.
#  3. 'true'/'false' are the booleans of the family and mean 1/0 on a bit
#     column; '1e5' is no integer to the server and is refused on integer
#     types before the server says so.
#  4. Every refusal is a DBIO::Exception, says "refus" and names the table and
#     the column or the relationship (house convention).
#  5. A virtual view is not deployed, so install_ddl and the sort that runs
#     before it leave it alone; a refused name says "view" for a view.

sub refusal {
  my ($code, $label, @res) = @_;
  my $r = eval { $code->(); 1 };
  my $e = $@;
  ok !$r, "$label: refused" or return;
  isa_ok $e, 'DBIO::Exception', "$label: the exception";
  like "$e", qr/refus/, "$label: says refus";
  like "$e", $_, "$label: $_" for @res;
}

sub ddl { my $c = shift; sub { DBIO::MSSQL::DDL->install_ddl($c) } }

# ---- 1. constraint names against object names
{
  # core's Artist class no longer declares a unique constraint named like its
  # table (it is artist_artistid since core k351): the core test schema is no
  # case of this refusal any more and installs; the refusal itself is held by
  # the schemas below.
  my $core = eval { DBIO::MSSQL::DDL->install_ddl('DBIO::Test::Schema') };
  ok defined $core, 'core test schema: no constraint named like its table, installs'
    or diag "$@";
  unlike $core // '', qr/CONSTRAINT \[?artist\]? /i,
    '... and writes no constraint named artist';

  my $own = schema_for(
    ['artist', undef, undef, sub { $_[0]->add_unique_constraint(artist => ['id']) }],
  );
  refusal(ddl($own), 'unique constraint named like its own table',
    qr/table 'artist'/, qr/constraint 'artist'/, qr/\bid\b/, qr/Msg 2714/);

  my $other = schema_for(
    ['p', undef, { code => { data_type => 'varchar', size => 5 } },
      sub { $_[0]->add_unique_constraint(q_t => ['code']) }],
    ['q_t'],
  );
  refusal(ddl($other), 'unique constraint named like another table',
    qr/table 'p'/, qr/constraint 'q_t'/, qr/\bcode\b/);

  # the derived names collide with a table of that very name
  my $fk = schema_for(['p'], ['FK_c_p_id'], ['c', [ rel(p => 'p', 'p_id') ]]);
  refusal(ddl($fk), 'foreign key FK_c_p_id against a table of that name',
    qr/table 'c'/, qr/relationship 'p'/, qr/FK_c_p_id/, qr/Msg 2714/);

  my $uq = schema_for(
    ['user', undef, { email => { data_type => 'varchar', size => 9 } },
      sub { $_[0]->add_unique_constraint([qw(email)]) }],
    ['UQ_user_email'],
  );
  refusal(ddl($uq), 'derived UQ_ name against a table of that name',
    qr/table 'user'/, qr/UQ_user_email/, qr/\bemail\b/);

  # against a view that is deployed
  my $view = schema_for(
    ['p', undef, { code => { data_type => 'varchar', size => 5 } },
      sub { $_[0]->add_unique_constraint(v_x => ['code']) }],
  );
  {
    my $rc = "$view\::Result::VX";
    eval "package $rc; use base 'DBIO::Core'; 1" or die $@;
    $rc->table_class('DBIO::ResultSource::View');
    $rc->table('v_x');
    $rc->result_source_instance->view_definition('SELECT id FROM p');
    $rc->add_columns(id => { data_type => 'integer' });
    $view->register_class(VX => $rc);
  }
  refusal(ddl($view), 'unique constraint named like a deployed view',
    qr/table 'p'/, qr/constraint 'v_x'/, qr/\bcode\b/);

  # not deployed, not in the namespace: a virtual view of that name is fine
  $view->source('VX')->is_virtual(1);
  ok eval { DBIO::MSSQL::DDL->install_ddl($view); 1 },
    'a virtual view is no object of the server: no collision' or diag $@;

  # the diff asks the same of the target model it is given
  my $fkm = sub { +{ constraint_name => $_[0], from_columns => ['p_id'], to_table => 'p',
                     to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION' } };
  my $tables = { map { $_ => { kind => 'table' } } qw(p c FK_c_p_id) };
  my $mk = sub {
    my (%t) = @_;
    DBIO::MSSQL::Diff->new(
      source => { tables => {}, columns => {}, indexes => {}, foreign_keys => {} },
      target => { tables => $tables, columns => {}, indexes => {}, foreign_keys => {}, %t });
  };
  refusal(sub { $mk->(foreign_keys => { c => [ $fkm->('FK_c_p_id') ] })->operations },
    'diff: target foreign key named like a table', qr/table 'c'/, qr/FK_c_p_id/, qr/Msg 2714/);
  refusal(sub { $mk->(indexes => { p => { c => {
        index_name => 'c', columns => ['code'], is_unique => 1, is_unique_constraint => 1 } } })->operations },
    'diff: target unique constraint named like a table', qr/table 'p'/, qr/constraint 'c'/, qr/\bcode\b/);
  ok eval { $mk->(indexes => { p => { ix_c => {
        index_name => 'ix_c', columns => ['code'], is_unique => 1, is_unique_constraint => 0 } },
        c => { p => { index_name => 'p', columns => ['x'], is_unique => 0 } } })->operations; 1 },
    'diff: an index (own namespace per table) may be named like a table' or diag $@;
}

# ---- 2. type parameters
refusal(sub { _mssql_column_type({ data_type => 'character varying(x)' }, 'tt', 'cc') },
  'character varying(x)', qr/table 'tt'/, qr/column 'cc'/, qr/character varying\(x\)/);
refusal(sub { _mssql_column_type({ data_type => 'national character varying(10,2)' }, 'tt', 'cc') },
  'national character varying(10,2)', qr/table 'tt'/, qr/column 'cc'/);
refusal(sub { _mssql_column_type({ data_type => 'character varying(10)', size => 20 }, 'tt', 'cc') },
  'parameter and size disagree', qr/table 'tt'/, qr/column 'cc'/, qr/10/, qr/20/);
refusal(sub { _mssql_column_type({ data_type => 'character varying(max)', size => 20 }, 'tt', 'cc') },
  'max and a size', qr/column 'cc'/);
is _mssql_column_type({ data_type => 'character varying(10)', size => 10 }), 'nvarchar(10)',
  'parameter and the same size are fine';
is _mssql_column_type({ data_type => 'character varying(10)', size => '10' }), 'nvarchar(10)',
  'the same size as a string is the same';
is _mssql_column_type({ data_type => 'character varying(max)', size => -1 }), 'nvarchar(max)',
  'max and -1 agree';
is _mssql_column_type({ data_type => 'character varying( 12 )' }), 'nvarchar(12)',
  'blanks inside the parameter are fine';
is _mssql_column_type({ data_type => 'national character varying(7)' }), 'nvarchar(7)',
  'a good parameter still works';

# ---- 3. defaults
sub dflt {
  my ($type, $dv) = @_;
  my $c = schema_for(['t', undef, { v => { data_type => $type, default_value => $dv, is_nullable => 1 } }]);
  my $ddl = eval { DBIO::MSSQL::DDL->install_ddl($c) };
  return ($ddl, $@);
}
for my $t (qw(bit boolean bool)) {
  for my $w (qw(true TRUE True false FALSE False)) {
    my ($ddl, $err) = dflt($t, $w);
    my $want = lc $w eq 'true' ? 1 : 0;
    like $ddl // $err, qr/\bv bit DEFAULT $want\b/, "$t DEFAULT '$w' is written as $want";
  }
}
{
  my ($ddl, $err) = dflt('varchar', 'true');
  like $ddl // $err, qr/DEFAULT N?'true'/, "'true' on a string type stays a string";
}
for my $t (qw(int bigint smallint tinyint bit)) {
  my $c = schema_for(['t', undef, { v => { data_type => $t, default_value => '1e5', is_nullable => 1 } }]);
  refusal(ddl($c), "1e5 on $t", qr/table 't'/, qr/column 'v'/, qr/1e5/);
}
{
  my ($ddl, $err) = dflt('float', '1e5');
  ok defined $ddl, "1e5 on float is a number the server takes" or diag $err;
  my ($d2) = dflt('int', 100000);
  like $d2, qr/DEFAULT 100000\b/, 'an integer is written as it is';
}

# ---- 4. the other refusals
{
  my $pk = schema_for(['p', undef, undef, sub { $_[0]->add_unique_constraint(same => ['id']) }],
    ['q', undef, undef, sub { $_[0]->add_unique_constraint(same => ['id']) }]);
  refusal(ddl($pk), 'a constraint name on two tables',
    qr/table 'q'/, qr/constraint 'same'/, qr/\bid\b/, qr/another table/);

  my $idx = sub {
    my ($decl) = @_;
    my $c = schema_for(['docs', undef, { name => { data_type => 'varchar', size => 64 } },
      sub { $_[0]->result_source_instance->add_index_declaration($decl) }]);
    return ddl($c);
  };
  refusal($idx->({ name => 'ft', columns => ['name'], type => 'fulltext' }),
    'index type', qr/table 'docs'/, qr/index 'ft'/, qr/\bname\b/);
  refusal($idx->({ name => 'op', columns => ['name'], options => { fillfactor => 70 } }),
    'index options', qr/table 'docs'/, qr/index 'op'/, qr/\bname\b/);
  refusal($idx->({ name => 'bk', columns => ['name'], driver => { mssql => { kind => 'columnstore' } } }),
    'index kind', qr/table 'docs'/, qr/index 'bk'.*invalid kind 'columnstore'/s, qr/\bname\b/);

  refusal(ddl(schema_for(['p'], ['c', [ rel(p => 'p', 'p_id', on_delete => 'frobnicate') ]])),
    'unknown action', qr/table 'c'/, qr/relationship 'p'/,
    qr/ON DELETE frobnicate is not an action of SQL Server/);

  # a key to a class that is not part of the deploy
  my $c = schema_for(['p'], ['c', [ rel(p => 'p', 'p_id') ]]);
  $c->unregister_source('P');
  refusal(ddl($c), 'a key to a table outside the deploy', qr/table 'c'/, qr/relationship 'p'/);

  # two declarations of one key, another target
  my $two = schema_for(['p'], ['r'], ['c', [ rel(a => 'p', 'p_id'), rel(b => 'r', 'p_id') ]]);
  refusal(ddl($two), 'two keys of one name', qr/table 'c'/, qr/relationships 'a' and 'b'/,
    qr/declare the foreign key on \(p_id\) twice, as constraint FK_c_p_id/);

  refusal(sub { _mssql_column_type({ data_type => 'nvarchar', size => 0 }, 'tt', 'cc') },
    'size 0', qr/table 'tt'/, qr/column 'cc'/, qr/size '0'/);
  refusal(sub { _mssql_column_type({ data_type => 'nchar', size => -1 }, 'tt', 'cc') },
    'nchar(max)', qr/table 'tt'/, qr/column 'cc'/, qr/nchar/);

  my $alter = sub {
    my ($old, $new) = @_;
    sub {
      my @ops = DBIO::MSSQL::Diff::Column->diff(
        { t => [ { column_name => 'a', %$old } ] }, { t => [ { column_name => 'a', %$new } ] },
        { t => {} }, { t => {} });
      $_->as_sql for @ops;
    };
  };
  refusal($alter->({ data_type => 'int', default_value => '((0))' },
                   { data_type => 'int', default_value => '((1))' }),
    'a default replaced without its constraint name',
    qr/table 't'/, qr/column 'a'/, qr/default_constraint_name/);
  refusal($alter->({ not_null => 0 }, { not_null => 1 }),
    'a nullability change without a type', qr/table 't'/, qr/column 'a'/, qr/\bt\.a\b/);
  refusal($alter->({ data_type => 'nvarchar', size => 64 }, { data_type => 'nvarchar', size => 0 }),
    'an unrenderable type for ALTER COLUMN', qr/table 't'/, qr/column 'a'/, qr/\bt\.a\b/);
}

# ---- 5. views
{
  my $c = schema_for(['p']);
  my $mkview = sub {
    my ($name, $virtual) = @_;
    my $tag = $virtual ? 'Virt' : 'Real';
    my $rc = "$c\::Result::V$tag";
    eval "package $rc; use base 'DBIO::Core'; 1" or die $@;
    $rc->table_class('DBIO::ResultSource::View');
    $rc->table($name);
    $rc->result_source_instance->is_virtual($virtual);
    $rc->result_source_instance->view_definition('SELECT id FROM p');
    $rc->add_columns(id => { data_type => 'integer' });
    $c->register_class("V$tag" => $rc);
  };
  $mkview->('other.virt', 1);
  ok eval { DBIO::MSSQL::DDL->install_ddl($c); 1 },
    'a virtual view with a dotted name is not deployed and not judged' or diag $@;
  ok eval { DBIO::MSSQL::DDL::_topo_sort_sources($c); 1 },
    '... also by the sort' or diag $@;

  $mkview->('other.real', 0);
  # was: refused ("a deployed view with a dotted name"). Since karr k72 a view
  # "schema.view" is made in that schema, like a table (t/111).
  my $vddl = eval { DBIO::MSSQL::DDL->install_ddl($c) };
  ok defined $vddl, 'a deployed view with a dotted name is installed (karr k72)' or diag $@;
  like $vddl // '', qr/^CREATE SCHEMA other;/m, '... its schema is created';
  like $vddl // '', qr/^CREATE VIEW other\.real AS SELECT id FROM p;/m, '... and the view made in it';
  unlike $vddl // '', qr/other\.virt/, '... the virtual view is still not deployed';
}

done_testing;
