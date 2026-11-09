use strict;
use warnings;
use Test::More;

use DBIO::Deploy::Base;
use DBIO::Diff::Base;
use DBIO::MySQL::Deploy;
use DBIO::MySQL::Diff::Column;
use DBIO::MySQL::Diff::Index;
use DBIO::MySQL::Diff::ForeignKey;

# WHY (core k399, ADR 0080): apply and upgrade are DBIO::Deploy::Base's alone.
# The destructive/lossy guard, dry_run and the extension protocol live there, so
# a driver that wrote its own apply would run a diff past all three. The driver
# takes part through the two seams _check_before_apply (its checks against the
# live tables) and _execute_diff. Claims:
#   a. the Deploy class has no apply and no upgrade of its own;
#   b. a released diff is checked (missing database, unfillable) before the
#      first statement, and a check that refuses leaves nothing run;
#   c. dry_run asks the server nothing and runs nothing;
#   d. a lossy column change, a destructive diff, needs allow_destructive and
#      is refused before the server is asked; the lossless ones run;
#   e. the lossless pairs of the driver are the ones the engine converts
#      without loss, everything else is lossy;
#   f. the drop half of a changed index or foreign key is no removal.

# --- a
for my $m (qw(apply upgrade)) {
  is(DBIO::MySQL::Deploy->can($m), DBIO::Deploy::Base->can($m),
    "a: $m is the very sub of DBIO::Deploy::Base");
}
ok !defined &DBIO::MySQL::Deploy::apply,   'a: no apply in the package of the driver';
ok !defined &DBIO::MySQL::Deploy::upgrade, 'a: no upgrade in the package of the driver';

# --- the harness: a deploy that runs against nothing and records
{
  package FakeDBH;
  sub new { my ($c, %rows) = @_; bless { rows => \%rows, asked => [] }, $c }
  sub selectrow_array {
    my ($self, $sql) = @_;
    push @{ $self->{asked} }, $sql;
    return $self->{rows}{$sql} ? 1 : ();
  }
  package SpyDeploy;
  our @ISA = ('DBIO::MySQL::Deploy');
  sub _dbh { $_[0]{dbh} }
  sub _refuse_missing_databases { push @{ $_[0]{dbh}{asked} }, 'missing-databases'; return }
  sub _execute_ddl { my ($self, $dbh, @sql) = @_; push @{ $self->{ran} }, @sql; return }
}

sub deploy {
  my (%rows) = @_;
  return SpyDeploy->new(schema => undef, dbh => FakeDBH->new(%rows));
}

sub diff_of { DBIO::Diff::Base->new(operations => [@_]) }

sub column {
  my ($action, $new, $old) = @_;
  return DBIO::MySQL::Diff::Column->new(action => $action, table_name => 'base',
    column_name => 'code', new_info => $new, ($old ? (old_info => $old) : ()));
}

# --- b
{
  my $d = deploy();
  my $diff = diff_of(column(add => { data_type => 'int', column_type => 'int', not_null => 0 }));
  ok $d->apply($diff), 'b: a plain additive diff is applied';
  is_deeply $d->{dbh}{asked}, ['missing-databases'],
    'b: the check for missing databases ran before the statements, the unfillable check had nothing to ask';
  is scalar(@{ $d->{ran} }), 1, 'b: ... and the statement ran';
}
{
  my $d = deploy('SELECT 1 FROM `base` LIMIT 1' => 1);
  my $diff = diff_of(column(add => { data_type => 'varchar', column_type => 'varchar(10)', not_null => 1 }));
  eval { $d->apply($diff) };
  like $@, qr/refuses to add the column base\.code/, 'b: apply refuses an unfillable column through the seam';
  ok !$d->{ran}, 'b: ... and no statement ran';
}

# --- c
{
  my $d = deploy('SELECT 1 FROM `base` LIMIT 1' => 1);
  my $diff = diff_of(column(add => { data_type => 'varchar', column_type => 'varchar(10)', not_null => 1 }));
  my $got = eval { $d->apply($diff, dry_run => 1) };
  is $@, '', 'c: dry_run does not run the checks (the unfillable column does not throw)';
  is $got, $diff, 'c: ... and returns the diff';
  ok !$d->{ran} && !@{ $d->{dbh}{asked} }, 'c: ... without a statement and without asking the server';
}

# --- d
my $narrow = column("modify",
  { data_type => 'varchar', column_type => 'varchar(10)' },
  { data_type => 'varchar', column_type => 'varchar(50)' });
{
  my $d = deploy();
  eval { $d->apply(diff_of($narrow)) };
  like $@, qr/allow_destructive/, 'd: a shrinking column is refused without allow_destructive';
  ok !$d->{ran} && !@{ $d->{dbh}{asked} }, 'd: ... before any statement and before the server is asked';
  ok eval { $d->apply(diff_of($narrow), allow_destructive => 1) }, 'd: allow_destructive releases it';
  is scalar(@{ $d->{ran} }), 1, 'd: ... and the statement ran';
}
{
  my $d = deploy();
  my $widen = column("modify",
    { data_type => 'varchar', column_type => 'varchar(80)' },
    { data_type => 'varchar', column_type => 'varchar(50)' });
  ok eval { $d->apply(diff_of($widen)) }, 'd: a widening column runs without allow_destructive' or diag $@;
}

# --- e
sub lossy {
  my ($old, $new) = @_;
  return column("modify", { data_type => $new->[0], column_type => $new->[1], %{ $new->[2] // {} } },
                        { data_type => $old->[0], column_type => $old->[1], %{ $old->[2] // {} } })->lossy;
}
my @lossless = (
  [ [int => 'int(11)'],             [bigint => 'bigint(20)'],       'int to bigint' ],
  [ [tinyint => 'tinyint(4)'],      [smallint => 'smallint(6)'],    'tinyint to smallint' ],
  [ [int => 'int(10) unsigned'],    [bigint => 'bigint(20) unsigned'], 'unsigned int to unsigned bigint' ],
  [ [int => 'int(11)'],             [int => 'int'],                 'the display width alone' ],
  [ [varchar => 'varchar(50)'],     [varchar => 'varchar(255)'],    'varchar wider' ],
  [ [char => 'char(5)'],            [varchar => 'varchar(5)'],      'char to varchar' ],
  [ [varchar => 'varchar(50)'],     [text => 'text'],               'varchar to text' ],
  [ [text => 'text'],               [longtext => 'longtext'],       'text to longtext' ],
  [ [blob => 'blob'],               [mediumblob => 'mediumblob'],   'blob to mediumblob' ],
  [ [decimal => 'decimal(10,2)'],   [decimal => 'decimal(12,2)'],   'decimal more digits, same scale' ],
  [ [date => 'date'],               [datetime => 'datetime'],       'date to datetime' ],
  [ [datetime => 'datetime(3)'],    [datetime => 'datetime(6)'],    'datetime finer' ],
  [ [enum => "enum('a','b')", { values => [qw(a b)] }],
    [enum => "enum('a','b','c')", { values => [qw(a b c)] }],     'enum with a value appended' ],
  [ [varchar => 'varchar(20)', { character_set => 'utf8mb4', collation => 'utf8mb4_bin' }],
    [varchar => 'varchar(20)', { character_set => 'utf8mb4', collation => 'utf8mb4_general_ci' }],
                                                                 'another collation of the same character set' ],
  [ [float => 'float'],             [float => 'float'],             'the same float' ],
);
for my $c (@lossless) {
  ok !lossy($c->[0], $c->[1]), "e: $c->[2] keeps every value";
}
my @lossy = (
  [ [bigint => 'bigint(20)'],       [int => 'int(11)'],             'bigint to int' ],
  [ [int => 'int(11)'],             [int => 'int(10) unsigned'],    'int to unsigned int' ],
  [ [int => 'int(10) unsigned'],    [int => 'int(11)'],             'unsigned int to int' ],
  [ [int => 'int(11)'],             [varchar => 'varchar(20)'],     'int to varchar' ],
  [ [varchar => 'varchar(50)'],     [int => 'int(11)'],             'varchar to int' ],
  [ [varchar => 'varchar(255)'],    [varchar => 'varchar(50)'],     'varchar shorter' ],
  [ [varchar => 'varchar(255)'],    [tinytext => 'tinytext'],       'varchar to tinytext' ],
  [ [text => 'text'],               [varchar => 'varchar(255)'],    'text to varchar' ],
  [ [float => 'float'],             [double => 'double'],           'float to double' ],
  [ [float => 'float(7,3)'],        [float => 'float(5,2)'],        'float with other parameters' ],
  [ [datetime => 'datetime'],       [timestamp => 'timestamp'],     'datetime to timestamp' ],
  [ [datetime => 'datetime(6)'],    [datetime => 'datetime(3)'],    'datetime coarser' ],
  [ [decimal => 'decimal(10,2)'],   [decimal => 'decimal(10,4)'],   'decimal with another scale' ],
  [ [enum => "enum('a','b','c')", { values => [qw(a b c)] }],
    [enum => "enum('a','b')", { values => [qw(a b)] }],            'enum with a value gone' ],
  [ [enum => "enum('a','b')", { values => [qw(a b)] }],
    [enum => "enum('b','a')", { values => [qw(b a)] }],            'enum reordered' ],
  [ [varchar => 'varchar(20)', { character_set => 'utf8mb4' }],
    [varchar => 'varchar(20)', { character_set => 'latin1' }],     'another character set' ],
);
for my $c (@lossy) {
  ok lossy($c->[0], $c->[1]), "e: $c->[2] is lossy";
}
ok !column(add => {})->lossy && !column(drop => {})->lossy, 'e: add and drop are not lossy (a drop is destructive by its action)';
ok !column(modify => { not_null => 1 }, { not_null => 0 })->lossy,
  'e: NOT NULL alone is not lossy (the unfillable check has it)';

# --- f
{
  my @ops = DBIO::MySQL::Diff::Index->diff(
    { t => { i => { index_name => 'i', columns => ['a'], is_unique => 0 } } },
    { t => { i => { index_name => 'i', columns => ['a'], is_unique => 1 } } },
    { t => {} }, { t => {} },
  );
  is_deeply [ map { $_->action } @ops ], [qw(drop create)], 'f: a changed index is a drop and a create';
  ok $ops[0]->replaced, 'f: the drop is marked replaced';
  my $class = diff_of(@ops)->classify;
  is $class->{counts}{destructive}, 0, 'f: ... and counts as no removal';
  ok !diff_of(@ops)->destructive_operations, 'f: ... and needs no allow_destructive';

  my @gone = DBIO::MySQL::Diff::Index->diff(
    { t => { i => { index_name => 'i', columns => ['a'], is_unique => 0 } } },
    { t => {} }, { t => {} }, { t => {} },
  );
  ok !$gone[0]->replaced && diff_of(@gone)->destructive_operations,
    'f: an index that leaves the schema is a removal';
}

done_testing;
