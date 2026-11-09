use strict;
use warnings;
use Test::More;

# Offline (core k399, ADR 0080): the Informix deploy takes part in the core
# apply/upgrade through its seams and overrides neither entry point. The
# unfillable-column checks run in _check_before_apply, once the diff is
# released; a column change reports through `lossy` whether it can alter or
# lose stored values, so apply asks for allow_destructive only then.

use DBIO::Deploy::Base;
use DBIO::Informix::Deploy;
use DBIO::Informix::Diff;
use DBIO::Informix::Diff::Column;

# --- apply and upgrade are the base class's -----------------------------------

for my $m (qw(apply upgrade)) {
  ok !defined &{"DBIO::Informix::Deploy::$m"}, "Deploy defines no $m of its own";
  is(DBIO::Informix::Deploy->can($m), DBIO::Deploy::Base->can($m), "$m is the one of DBIO::Deploy::Base");
}
ok defined &DBIO::Informix::Deploy::_check_before_apply, 'Deploy takes part through _check_before_apply';

# --- lossy ------------------------------------------------------------------------

sub op {
  my ($from, $to, $action) = @_;
  return DBIO::Informix::Diff::Column->new(
    action => $action // 'alter', table_name => 't',
    from_info => { column_name => 'c', not_null => 0, %$from },
    column_info => { column_name => 'c', not_null => 0, %$to },
  );
}

for my $pair ([qw(smallint integer)], [qw(smallint int8)], [qw(smallint bigint)],
              [qw(integer int8)], [qw(integer bigint)], [qw(int8 bigint)], [qw(bigint int8)]) {
  ok !op({ data_type => $pair->[0] }, { data_type => $pair->[1] })->lossy,
    "$pair->[0] -> $pair->[1] keeps every value";
}
for my $pair ([qw(integer smallint)], [qw(bigint integer)], [qw(integer varchar)],
              [qw(float decimal)], [qw(varchar integer)], [qw(smallfloat float)]) {
  ok op({ data_type => $pair->[0] }, { data_type => $pair->[1] })->lossy,
    "$pair->[0] -> $pair->[1] may lose values";
}
ok !op({ data_type => 'varchar', size => 20 }, { data_type => 'varchar', size => 40 })->lossy,
  'a varchar made longer keeps every value';
ok op({ data_type => 'varchar', size => 40 }, { data_type => 'varchar', size => 20 })->lossy,
  'a varchar made shorter may cut values';
ok !op({ data_type => 'integer' }, { data_type => 'integer', not_null => 1 })->lossy,
  'NOT NULL alone is not lossy';
ok !op({ data_type => 'integer' }, { data_type => 'integer', default_value => \'0' })->lossy,
  'a changed default alone is not lossy';
ok !op({ data_type => 'integer' }, { data_type => 'varchar' }, 'add')->lossy,
  'an add is not a column change';

# --- the guard of apply ----------------------------------------------------------

sub model {
  my ($type) = @_;
  return {
    tables  => { t => { table_name => 't', kind => 'table' } },
    columns => { t => [ { column_name => 'c', data_type => $type, size => undef, not_null => 0, default_value => undef } ] },
    indexes => {}, unique_constraints => {}, foreign_keys => {},
  };
}

my @ran;
my $refuse_unfillable = \&DBIO::Informix::Deploy::_refuse_unfillable;
my $dbh;
{
  no warnings 'redefine';
  *DBIO::Informix::Deploy::_dbh = sub { $dbh };
  *DBIO::Informix::Deploy::_execute_diff = sub { push @ran, $_[1]->as_sql; 1 };
  *DBIO::Informix::Deploy::_refuse_unfillable = sub { push @ran, 'checked'; return };
}
my $deploy = DBIO::Informix::Deploy->new(schema => bless({}, 'T::Schema'));

my $widen  = DBIO::Informix::Diff->new(source => model('smallint'), target => model('integer'));
my $narrow = DBIO::Informix::Diff->new(source => model('integer'),  target => model('smallint'));

@ran = ();
ok eval { $deploy->apply($widen); 1 }, 'a widening integer runs without a release' or diag $@;
is_deeply [ grep { !/^-- / && length } map { split /\n/ } @ran ], [ 'checked', 'ALTER TABLE t MODIFY (c integer);' ],
  'the check ran, then the statement';

@ran = ();
ok !eval { $deploy->apply($narrow); 1 }, 'a narrowing integer is refused without allow_destructive';
like $@, qr/\bc\b/, 'the refusal names the column';
is_deeply \@ran, [], 'no check and no statement ran';

ok eval { $deploy->apply($narrow, allow_destructive => 1); 1 }, 'allow_destructive releases it' or diag $@;
is $ran[0], 'checked', 'the check of the driver runs for the released diff';

@ran = ();
ok $deploy->apply($narrow, dry_run => 1), 'dry_run returns the diff';
is_deeply \@ran, [], 'dry_run checks nothing and executes nothing';

# --- _check_before_apply refuses as the driver always did -------------------------

{
  package T::Dbh;
  sub new { bless { rows => $_[1] }, $_[0] }
  sub selectrow_array { return $_[0]{rows} ? 1 : undef }
}
{
  no warnings 'redefine';
  *DBIO::Informix::Deploy::_refuse_unfillable = $refuse_unfillable;
}

my $with_new = model('integer');
push @{ $with_new->{columns}{t} }, { column_name => 'n', data_type => 'integer', size => undef, not_null => 1, default_value => undef };
my $add_not_null = DBIO::Informix::Diff->new(source => model('integer'), target => $with_new);

@ran = ();
$dbh = T::Dbh->new(1);
ok !eval { $deploy->apply($add_not_null); 1 }, 'NOT NULL added without a default to a table with rows: refused';
like $@, qr/\bt\.n: added NOT NULL without a default, and the table holds rows/, 'naming table and column';
like $@, qr/No statement was run/, 'before the first statement';
is_deeply \@ran, [], 'nothing executed';

$dbh = T::Dbh->new(0);
ok eval { $deploy->apply($add_not_null); 1 }, 'the same over an empty table runs' or diag $@;
is scalar(@ran), 1, 'and executes the diff';

my $became_not_null = model('integer');
$became_not_null->{columns}{t}[0]{not_null} = 1;
@ran = ();
$dbh = T::Dbh->new(1);
ok !eval { $deploy->apply(DBIO::Informix::Diff->new(source => model('integer'), target => $became_not_null)); 1 },
  'a column that becomes NOT NULL over NULLs: refused';
like $@, qr/\bt\.c: becomes NOT NULL, and the table holds rows where it is NULL/, 'naming table and column';

# --- a drop that is the first half of a replacement is no destructive drop ---------

use DBIO::Informix::Diff::Index;
use DBIO::Informix::Diff::PrimaryKey;
use DBIO::Informix::Diff::Table;

my @ix = DBIO::Informix::Diff::Index->diff(
  { t => { i => { unique => 0, columns => ['a'] }, j => { unique => 0, columns => ['a'] } } },
  { t => { i => { unique => 1, columns => ['a'] } } },
);
is_deeply [ map { join ':', $_->action, $_->index_name, ($_->replaced ? 'replaced' : 'plain') } @ix ],
  [ 'drop:i:replaced', 'create:i:plain', 'drop:j:plain' ],
  'an index of another definition is replaced; an index the schema lacks is dropped';

my $vdef = sub { +{ kind => 'view', definition => $_[0] } };
my @vw = DBIO::Informix::Diff::Table->diff({ v => $vdef->('a') }, { v => $vdef->('b') }, {});
is_deeply [ map { join ':', $_->action, ($_->replaced ? 'replaced' : 'plain') } @vw ],
  [ 'drop:replaced', 'create:plain' ], 'a view of another definition is replaced';
@vw = DBIO::Informix::Diff::Table->diff({ v => $vdef->('a') }, {}, {});
ok !$vw[0]->replaced, 'a view the schema lacks is dropped';

sub pkcols { +{ t => [ map { +{ column_name => $_->[0], is_pk => $_->[1] ? 1 : 0, pk_position => $_->[1] } } @_ ] } }
my %tabs = (t => { kind => 'table', primary_key_name => 'u1_2' });
my @pk = DBIO::Informix::Diff::PrimaryKey->diff(pkcols(['a', 1], ['b']), pkcols(['a'], ['b', 1]), \%tabs, \%tabs);
is_deeply [ map { join ':', $_->action, ($_->replaced ? 'replaced' : 'plain') } @pk ],
  [ 'drop:replaced', 'add:plain' ], 'a primary key over other columns is replaced';
@pk = DBIO::Informix::Diff::PrimaryKey->diff(pkcols(['a', 1]), pkcols(['a']), \%tabs, \%tabs);
ok !$pk[0]->replaced, 'a primary key the schema lacks is dropped';

# --- a constraint or key that comes back is replaced, one that goes is dropped ----

use DBIO::Informix::Diff::UniqueConstraint;
use DBIO::Informix::Diff::ForeignKey;

my %two = (t => { kind => 'table' });
sub uq { +{ t => [ map { +{ constraint_name => $_->[0], columns => $_->[1] } } @_ ] } }
my @uq = DBIO::Informix::Diff::UniqueConstraint->diff(
  uq([ u => ['a'] ], [ gone => ['c'] ], [ u136_41 => ['d'] ]), uq([ u => ['a', 'b'] ]), \%two, \%two);
is_deeply [ sort map { join ':', $_->action, $_->constraint_name, ($_->replaced ? 'replaced' : 'plain') } @uq ],
  [ sort 'drop:u:replaced', 'drop:gone:plain', 'drop:u136_41:plain', 'add:u:plain' ],
  'a unique constraint of another definition is replaced; one that disappears is dropped';

sub fkm { my ($name, $cols, $to) = @_; +{ t => [ +{ constraint_name => $name, from_columns => $cols, to_table => $to, to_columns => ['id'] } ] } }
my @fk = DBIO::Informix::Diff::ForeignKey->diff(fkm('f', ['a'], 'x'), fkm('f', ['a'], 'y'), \%two, \%two);
is_deeply [ map { join ':', $_->action, ($_->replaced ? 'replaced' : 'plain') } @fk ],
  [ 'drop:replaced', 'add:plain' ], 'a foreign key of the same name with another target is replaced';
@fk = DBIO::Informix::Diff::ForeignKey->diff(fkm('r12_3', ['a'], 'x'), fkm(undef, ['a'], 'y'), \%two, \%two);
is_deeply [ map { join ':', $_->action, ($_->replaced ? 'replaced' : 'plain') } @fk ],
  [ 'drop:replaced', 'add:plain' ], 'a server-named key comes back as a key over the same columns';
@fk = DBIO::Informix::Diff::ForeignKey->diff(fkm('f', ['a'], 'x'), {}, \%two, \%two);
ok !$fk[0]->replaced, 'a foreign key the schema lacks is dropped';
@fk = DBIO::Informix::Diff::ForeignKey->diff(fkm('f', ['a'], 'x'), fkm('g', ['b'], 'x'), \%two, \%two);
ok !(grep { $_->replaced } @fk), 'a key over other columns under another name is a removal and a new key';

# through classify: replaced ones run without allow_destructive
my $with_uq = sub { my $m = model('integer'); $m->{unique_constraints} = uq(@_); $m };
my $chg = DBIO::Informix::Diff->new(source => $with_uq->([ u => ['c'] ]), target => $with_uq->([ u => ['c', 'd'] ]));
@ran = ();
ok eval { $deploy->apply($chg); 1 }, 'a changed unique constraint runs without allow_destructive' or diag $@;
my $del = DBIO::Informix::Diff->new(source => $with_uq->([ u => ['c'] ]), target => model('integer'));
ok !eval { $deploy->apply($del); 1 }, 'a disappearing unique constraint needs allow_destructive';

done_testing;

