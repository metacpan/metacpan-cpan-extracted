use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Diff::Index;
use DBIO::MSSQL::Introspect::Indexes;

# karr k76. A filtered index (CREATE [UNIQUE] INDEX ... WHERE <predicate>) is a
# different object from the unfiltered index over the same columns: the model
# carries the filter, the DDL writes it, the diff compares it and replaces the
# index when it changes. The forms the server hands back for filter_definition
# were measured on MSSQL 2022 (t/108-index-filter-live.t):
#   a = 1                 ->  ([a]=(1))
#   a IS NOT NULL         ->  ([a] IS NOT NULL)
#   a > 5 AND b = N'x'    ->  ([a]>(5) AND [b]=N'x')
#   a IN (1,2,3)          ->  ([a] IN ((1), (2), (3)))
#   a >= -1               ->  ([a]>=(-1))
# The server accepts only simple comparisons joined by AND, IN and IS [NOT]
# NULL in a filter (OR, NOT and BETWEEN are syntax errors) and refuses a filter
# on a CLUSTERED index and on a unique constraint.

# --- 1. Introspect: the filter is read -------------------------------------
{
  package MockSTH;
  sub new { bless { rows => $_[1], i => 0 }, $_[0] }
  sub execute { 1 }
  sub fetchrow_hashref { $_[0]{rows}[ $_[0]{i}++ ] }
  package MockDBH;
  our @SQL;
  sub new { bless { rows => $_[1] }, $_[0] }
  sub prepare { push @SQL, $_[1]; MockSTH->new($_[0]{rows}) }
}
{
  my $row = sub { +{ table_name => 't', is_unique => 0, is_unique_constraint => 0,
    index_type => 2, index_kind => 'NONCLUSTERED', key_ordinal => 1, @_ } };
  my $dbh = MockDBH->new([
    $row->(index_name => 'ix_f', column_name => 'id', has_filter => 1,
           filter_definition => '([a]=(1))'),
    $row->(index_name => 'ix_p', column_name => 'id', has_filter => 0,
           filter_definition => undef),
  ]);
  my $idx = DBIO::MSSQL::Introspect::Indexes->fetch($dbh, 'dbo', { t => {} });
  like $MockDBH::SQL[0], qr/has_filter/, 'introspect: the query asks for has_filter';
  like $MockDBH::SQL[0], qr/filter_definition/, '... and for filter_definition';
  is $idx->{t}{ix_f}{filter}, '([a]=(1))', 'a filtered index carries its filter';
  is $idx->{t}{ix_p}{filter}, undef, 'an unfiltered index carries none';
}

# --- 2. DDL ----------------------------------------------------------------
my $n = 0;
sub ddl_for {
  my (%o) = @_;
  my $schema = 'K76::S' . ++$n;
  my $pk = $o{pk} ? q{__PACKAGE__->set_primary_key('id');} : '';
  eval qq{
    package $schema; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL');
    package ${schema}::Result::T; use base 'DBIO::Core';
    __PACKAGE__->load_components('MSSQL::Result');
    __PACKAGE__->table('t');
    __PACKAGE__->add_columns(id => { data_type => 'integer' },
      a => { data_type => 'integer', is_nullable => 1 },
      b => { data_type => 'varchar', size => 20, is_nullable => 1 });
    $pk
    1;
  } or die $@;
  my $rc = "${schema}::Result::T";
  $rc->mssql_index($_ => $o{hand}{$_}) for sort keys %{ $o{hand} || {} };
  $rc->result_source_instance->add_index_declaration($_) for @{ $o{idx} || [] };
  $schema->register_class(T => $rc);
  my $ddl = eval { DBIO::MSSQL::DDL->install_ddl($schema) };
  return ($ddl, $@);
}
sub index_sql {
  my ($ddl, $name) = @_;
  my ($s) = grep { /^CREATE\b.*?\bINDEX\s+\W*\Q$name\E\W/ } split /\n\n+/, $ddl;
  return $s;
}

{
  my ($ddl, $err) = ddl_for(hand => {
    ix_hand => { columns => ['b'], where => 'a IS NOT NULL' },
    ix_uniq => { columns => ['b'], unique => 1, where => 'a = 1 AND b IS NOT NULL' },
    ix_plain => { columns => ['a'] },
  });
  is $err, '', 'DDL: mssql_indexes with where is accepted';
  like index_sql($ddl, 'ix_hand'), qr/^CREATE INDEX \W*ix_hand\W* ON \W*t\W* \(\W*b\W*\) WHERE a IS NOT NULL;$/,
    'DDL: the predicate is written as WHERE after the column list';
  like index_sql($ddl, 'ix_uniq'),
    qr/^CREATE UNIQUE INDEX \W*ix_uniq\W* ON \W*t\W* \(\W*b\W*\) WHERE a = 1 AND b IS NOT NULL;$/,
    'DDL: a unique filtered index';
  unlike index_sql($ddl, 'ix_plain'), qr/WHERE/, 'DDL: an index without where has no WHERE';
}
{
  my ($ddl, $err) = ddl_for(idx => [
    { name => 'ix_c', columns => ['b'], unique => 1,
      driver => { mssql => { where => 'a IS NOT NULL' } } },
    { name => 'ix_ck', columns => ['b'],
      driver => { mssql => { kind => 'nonclustered', where => 'a > 5' } } },
  ]);
  is $err, '', 'DDL: the canonical declaration takes where in its mssql block';
  like index_sql($ddl, 'ix_c'), qr/^CREATE UNIQUE INDEX .* WHERE a IS NOT NULL;$/,
    '... and writes it';
  like index_sql($ddl, 'ix_ck'), qr/^CREATE NONCLUSTERED INDEX .* WHERE a > 5;$/,
    '... together with kind';
}
{
  # over exactly the columns of the key: a plain one is a duplicate and left
  # out, a filtered one is a different object and is written
  my ($ddl, $err) = ddl_for(pk => 1, hand => {
    ix_dup  => { columns => ['id'] },
    ix_filt => { columns => ['id'], where => 'a = 1' },
  });
  is $err, '', 'DDL: filtered index over the key columns is accepted';
  ok !defined index_sql($ddl, 'ix_dup'), 'DDL: the unfiltered duplicate of the key is not written';
  like index_sql($ddl, 'ix_filt'), qr/WHERE a = 1;$/, '... the filtered one is';
}

sub refused_ok {
  my ($name, $re, %o) = @_;
  my ($ddl, $err) = ddl_for(%o);
  isa_ok $err, 'DBIO::Exception', "$name: refused with" ;
  like "$err", $re, "$name: message names index and reason";
}
refused_ok('clustered + where', qr/ix_cw.*clustered.*filter|ix_cw.*filter.*clustered/is,
  hand => { ix_cw => { columns => ['b'], kind => 'clustered', where => 'a = 1' } });
refused_ok('empty where', qr/ix_e.*where/is,
  hand => { ix_e => { columns => ['b'], where => '' } });
refused_ok('blank where', qr/ix_e.*where/is,
  hand => { ix_e => { columns => ['b'], where => "  \n " } });
refused_ok('ref where', qr/ix_r.*where/is,
  hand => { ix_r => { columns => ['b'], where => \'a = 1' } });
refused_ok('canonical empty where', qr/ix_ce.*where/is,
  idx => [ { name => 'ix_ce', columns => ['b'], driver => { mssql => { where => '' } } } ]);
refused_ok('canonical ref where', qr/ix_cr.*where/is,
  idx => [ { name => 'ix_cr', columns => ['b'], driver => { mssql => { where => [1] } } } ]);
refused_ok('canonical clustered + where', qr/ix_cc.*clustered/is,
  idx => [ { name => 'ix_cc', columns => ['b'],
             driver => { mssql => { kind => 'clustered', where => 'a = 1' } } } ]);

# --- 3. Diff: normalisation ------------------------------------------------
my $norm = sub { DBIO::MSSQL::Diff::Index->normalize_filter($_[0]) };
is $norm->('([a]=(1))'), $norm->('a = 1'), 'normalize: server form of a = 1';
is $norm->('([a] IS NOT NULL)'), $norm->('a is not null'), 'normalize: IS NOT NULL, case, brackets';
is $norm->("([a]>(5) AND [b]=N'x')"), $norm->("a>5 and b = N'x'"), 'normalize: AND, N literal';
is $norm->('([a] IN ((1), (2), (3)))'), $norm->('a IN (1,2,3)'), 'normalize: IN list';
is $norm->('([a]>=(-1))'), $norm->('a >= -1'), 'normalize: negative number';
is $norm->("([b]='it''s')"), $norm->("b = 'it''s'"), 'normalize: quote doubling';
is $norm->('([a] IN ((1)))'), $norm->('a in (1)'), 'normalize: IN with one element';
isnt $norm->("b = 'X'"), $norm->("b = 'x'"), 'normalize: a literal keeps its case';
isnt $norm->('a = 1'), $norm->('a = 2'), 'normalize: different numbers differ';
isnt $norm->('a = 1'), $norm->('a <> 1'), 'normalize: different operators differ';
is $norm->(undef), '', 'normalize: none is empty';

# --- 4. Diff: operations ---------------------------------------------------
sub tbl { +{ t => { table_name => 't', kind => 'table' } } }
sub model { +{ tables => tbl(), columns => {}, foreign_keys => {}, indexes => { t => { @_ } } } }
sub ix { +{ index_name => $_[0], columns => ['b'], is_unique => 0, is_unique_constraint => 0,
            kind => 'nonclustered', @_[1 .. $#_] } }
sub stmts {
  my ($src, $tgt) = @_;
  my $d = DBIO::MSSQL::Diff->new(source => $src, target => $tgt);
  return grep { length } map { split /\n(?=\S)/, $_->as_sql } @{ $d->operations };
}

is_deeply [ stmts(model(), model(ix_f => ix('ix_f', filter => 'a IS NOT NULL'))) ],
  [ 'CREATE NONCLUSTERED INDEX ix_f ON t (b) WHERE a IS NOT NULL;' ],
  'diff: a new filtered index is created with its WHERE';
is_deeply [ stmts(model(ix_f => ix('ix_f', is_unique => 1, filter => '([a]=(1))')), model()) ],
  [ 'DROP INDEX ix_f ON t;' ], 'diff: a filtered index is dropped like another';

my @same = stmts(model(ix_f => ix('ix_f', filter => '([a]=(1))')),
                 model(ix_f => ix('ix_f', filter => 'a = 1')));
is_deeply \@same, [], 'diff: the server form and the declared form of one filter do not differ';

is_deeply [ stmts(model(ix_f => ix('ix_f', filter => '([a]=(1))')),
                  model(ix_f => ix('ix_f', filter => 'a = 2'))) ],
  [ 'DROP INDEX ix_f ON t;', 'CREATE NONCLUSTERED INDEX ix_f ON t (b) WHERE a = 2;' ],
  'diff: a changed filter is a drop and a create';
is_deeply [ stmts(model(ix_f => ix('ix_f')),
                  model(ix_f => ix('ix_f', filter => 'a = 2'))) ],
  [ 'DROP INDEX ix_f ON t;', 'CREATE NONCLUSTERED INDEX ix_f ON t (b) WHERE a = 2;' ],
  'diff: a filter added is a drop and a create';
is_deeply [ stmts(model(ix_f => ix('ix_f', filter => 'a = 2')),
                  model(ix_f => ix('ix_f'))) ],
  [ 'DROP INDEX ix_f ON t;', 'CREATE NONCLUSTERED INDEX ix_f ON t (b);' ],
  'diff: a filter removed (target undeclared) is a drop and a create without WHERE';

done_testing;
