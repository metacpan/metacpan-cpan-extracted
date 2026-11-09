use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;
use DBIO::MySQL::Diff;

# OFFLINE half of karr k110 (t/129 has the live half): views are created in the
# order of what they read, and dropped in the reverse, in install_ddl and in the
# diff alike.
#
# WHY IT MATTERS. Both wrote the views in name order, so a view `a` that reads
# the view `b` came out as CREATE VIEW a ... before CREATE VIEW b and the server
# refused it (1146, the table does not exist). Dropping had the mirror problem.
# What this file claims:
#   1. view_reads finds the names a definition reads in table position, and
#      only those: not a name in a string or a comment, not a column, an alias
#      or a function of that name, not the FROM inside TRIM(); the spelling of
#      the server (`db`.`b`, joins in parentheses) and the spelling of a person
#      (b, B, no backticks, comma list, subquery) alike;
#   2. install_ddl writes a reader after what it reads: reader sorting first,
#      last, a chain, a diamond; views free of each other stay in name order,
#      and all views stay after all tables;
#   3. the diff creates in the same order and drops in the reverse; a view
#      unchanged beside a changed one it reads is replaced with it (karr k113);
#   4. the order of install_ddl and the order of the diff are one order;
#   5. views that read each other in a cycle: a DBIO::Exception naming them,
#      from install_ddl and from the diff, no statement written.

# 1. what a definition reads
my @READS = (
  [ 'plain',               'SELECT id FROM b',                                   [qw(b)] ],
  [ 'server spelling',     'select `db`.`b`.`id` AS `id` from `db`.`b` where (`db`.`b`.`n` > 1)', [qw(b)] ],
  [ 'MariaDB spelling',    'select `b`.`id` AS `id` from `d`.`b` where `b`.`n` > 1', [qw(b)] ],
  [ 'join group',          'select `a`.`id` AS `id` from (`d`.`a` join `d`.`t` on((`d`.`t`.`id` = `d`.`a`.`id`)))', [qw(a t)] ],
  [ 'comma list',          'SELECT * FROM x, y z, w',                            [qw(x y w)] ],
  [ 'joins',               'SELECT * FROM x LEFT JOIN y ON x.i = y.i STRAIGHT_JOIN w ON 1', [qw(x y w)] ],
  [ 'subquery',            'SELECT * FROM x WHERE id IN (SELECT id FROM y)',     [qw(x y)] ],
  [ 'derived table',       'SELECT * FROM (SELECT * FROM y) q, x',               [qw(y x)] ],
  [ 'union',               'SELECT id FROM x UNION ALL SELECT id FROM y',        [qw(x y)] ],
  [ 'string literal',      q{SELECT 'from b' AS s, "from c" AS t FROM x},        [qw(x)] ],
  [ 'escaped string',      q{SELECT 'it\'s from b', 'it''s from c' FROM x},      [qw(x)] ],
  [ 'comments',            "SELECT id /* from b */ FROM x -- from c\n# from d\n", [qw(x)] ],
  [ 'column of that name', 'SELECT b, `c` FROM x WHERE d = 1 ORDER BY e',        [qw(x)] ],
  [ 'alias of that name',  'SELECT x.id FROM x AS b JOIN y c ON 1',              [qw(x y)] ],
  [ 'TRIM/EXTRACT FROM',   q{SELECT TRIM(LEADING 'x' FROM b), EXTRACT(YEAR FROM d) FROM x}, [qw(x)] ],
  [ 'function as source',  'SELECT * FROM x, JSON_TABLE(j, "$[*]" COLUMNS (a INT PATH "$")) jt', [qw(x)] ],
  [ 'dot in backticks',    'SELECT * FROM `a.b`',                                [ 'a.b' ] ],
  [ 'keyword as name',     'SELECT * FROM `from` JOIN `select` ON 1',            [qw(from select)] ],
  [ 'lower case keywords', 'select * from x join y on 1 where z in (select 1 from w)', [qw(x y w)] ],
  [ 'no table',            'SELECT 1 AS id',                                     [] ],
);
for my $case (@READS) {
  my ($label, $def, $want) = @$case;
  is_deeply [ DBIO::MySQL::DDL::view_reads($def) ], $want, "view_reads: $label" or diag $def;
}
is_deeply [ DBIO::MySQL::DDL::view_reads(undef) ], [], 'view_reads: no definition reads nothing';

# the order function itself
sub order { return [ DBIO::MySQL::DDL::order_views({ @_ }) ] }
is_deeply order(a => 'SELECT 1 FROM b', b => 'SELECT 1 FROM t'), [qw(b a)], 'order_views: the reader after what it reads, though it sorts first';
is_deeply order(a => 'SELECT 1 FROM t', b => 'SELECT 1 FROM a'), [qw(a b)], '... and the other way round';
is_deeply order(a => 'SELECT 1 FROM t', b => 'SELECT 1 FROM t'), [qw(a b)], '... views free of each other stay in name order';
is_deeply order(a => 'SELECT 1 FROM a'), [qw(a)], '... a read of itself is no dependency';
is_deeply order(A => 'SELECT 1', b => 'SELECT 1 FROM a'), [qw(A b)], '... a name is matched without case when only one view has it so';
is_deeply order(a => 'SELECT 1', A => 'SELECT 1', b => 'SELECT 1 FROM A'), [qw(A a b)], '... and exactly when two differ in case only';

# 2. install_ddl
my $n = 0;
# %v: view name => definition; @tables: table names
sub schema_for {
  my ($tables, %v) = @_;
  my $ns = 'K110Off::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $t (@$tables) {
    my $class = "${ns}::Result::T_$t";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($t);
    $class->add_columns(id => { data_type => 'integer' });
    $class->set_primary_key('id');
    $ns->register_class("T_$t" => $class);
  }
  # the monikers run against the view names, so source order and view order differ
  my $k = 0;
  for my $name (sort keys %v) {
    my $moniker = sprintf 'V%02d_%s', 90 - $k++, $name;
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table_class('DBIO::ResultSource::View');
    $class->table($name);
    $class->result_source_instance->view_definition($v{$name});
    $class->add_columns(id => { data_type => 'integer' });
    $ns->register_class($moniker => $class);
  }
  return $ns;
}
sub view_names_in {
  my ($ddl) = @_;
  return [ $ddl =~ /^CREATE VIEW `([^`]+)`/mg ];
}
sub install_order { my ($tables, %v) = @_; return view_names_in(DBIO::MySQL::DDL->install_ddl(schema_for($tables, %v))) }

is_deeply install_order(['t'], a => 'SELECT id FROM b', b => 'SELECT id FROM t'), [qw(b a)],
  'install_ddl: a view that sorts first but reads a later one is written after it';
is_deeply install_order(['t'], a => 'SELECT id FROM t', b => 'SELECT id FROM a'), [qw(a b)],
  '... the reader that sorts last stays last';
is_deeply install_order(['t'], a => 'SELECT id FROM b', b => 'SELECT id FROM c', c => 'SELECT id FROM d', d => 'SELECT id FROM t'),
  [qw(d c b a)], '... a chain, back to front';
is_deeply install_order(['t'],
  a => 'SELECT id FROM b JOIN c USING (id)', b => 'SELECT id FROM d', c => 'SELECT id FROM d', d => 'SELECT id FROM t'),
  [qw(d b c a)], '... a diamond: the shared view first, the two middles by name, the top last';
is_deeply install_order(['t'], z => 'SELECT id FROM t', m => 'SELECT id FROM t', c => 'SELECT id FROM t'),
  [qw(c m z)], '... views free of each other in name order';
{
  my $ddl = DBIO::MySQL::DDL->install_ddl(schema_for(['t', 'u'], a => 'SELECT id FROM u'));
  like $ddl, qr/CREATE TABLE `t`.*CREATE TABLE `u`.*CREATE VIEW `a`/s, '... all tables still before the views';
}

# 3. the diff
sub tbl  { return { table_name => $_[0], kind => 'table', engine => 'InnoDB' } }
sub view { return { table_name => $_[0], kind => 'view', view_definition => $_[1] } }
sub model {
  my (%m) = @_;
  return { tables => {}, columns => {}, indexes => {}, foreign_keys => {}, %m };
}
sub views_of { return { map { $_ => view($_, $_[0]{$_}) } keys %{ $_[0] } } }
sub diff_ops {
  my ($from, $to) = @_;
  return DBIO::MySQL::Diff->new(
    source => model(tables => { t => tbl('t'), %{ views_of($from) } }),
    target => model(tables => { t => tbl('t'), %{ views_of($to) } }),
  )->operations;
}
sub sql_of { return [ map { $_->as_sql =~ /^(\w+ VIEW) `([^`]+)`/ ? "$1 $2" : () } @{ $_[0] } ] }

my %SERVER = (    # server spelling, the own database already taken out
  a => 'select `b`.`id` AS `id` from `b`',
  b => 'select `c`.`id` AS `id` from `c`',
  c => 'select `t`.`id` AS `id` from `t`',
);
is_deeply sql_of(diff_ops({}, \%SERVER)), ['CREATE VIEW c', 'CREATE VIEW b', 'CREATE VIEW a'],
  'diff: new views are created readers last';
is_deeply sql_of(diff_ops(\%SERVER, {})), ['DROP VIEW a', 'DROP VIEW b', 'DROP VIEW c'],
  '... removed views are dropped readers first, the reverse';

{
  my %new = (%SERVER, c => 'select `t`.`id` AS `id`,1 AS `one` from `t`', b => 'select `c`.`id` AS `id` from `c` where 1');
  is_deeply sql_of(diff_ops(\%SERVER, \%new)), ['DROP VIEW a', 'DROP VIEW b', 'DROP VIEW c', 'CREATE VIEW c', 'CREATE VIEW b', 'CREATE VIEW a'],
    '... two changed views of a chain: dropped reader first, created reader last, the unchanged top view a is replaced with them (karr k113)';
}
{
  my %old = (a => 'select `b`.`id` AS `id` from `b`', b => 'select `t`.`id` AS `id` from `t`');
  my %new = (a => 'select `b`.`id` AS `id` from `b`', b => 'select `t`.`id` AS `id`,1 AS `one` from `t`');
  is_deeply sql_of(diff_ops(\%old, \%new)), ['DROP VIEW a', 'DROP VIEW b', 'CREATE VIEW b', 'CREATE VIEW a'],
    '... a view that stays beside a changed view it reads is dropped and created again around it (karr k113, t/145)';
}
{
  my %old = (b => 'select `t`.`id` AS `id` from `t`', x => 'select `y`.`id` AS `id` from `y`', y => 'select `t`.`id` AS `id` from `t`');
  my %new = (a => 'select `b`.`id` AS `id` from `b`', b => 'select `t`.`id` AS `id`,1 AS `one` from `t`');
  is_deeply sql_of(diff_ops(\%old, \%new)), ['DROP VIEW x', 'DROP VIEW y', 'DROP VIEW b', 'CREATE VIEW b', 'CREATE VIEW a'],
    '... drops of removed and changed views in reverse order together, creates of new and changed views in order';
}

# 4. one order for install and diff
{
  my %v = (
    a => 'SELECT id FROM b JOIN c USING (id)', b => 'SELECT id FROM d', c => 'SELECT id FROM d',
    d => 'SELECT id FROM t', e => 'SELECT id FROM a', f => 'SELECT id FROM t',
  );
  my $installed = install_order(['t'], %v);
  # what the server hands back for each: the same reads, in its spelling
  my %served = map { my $d = $v{$_}; $d =~ s/\b(?:FROM|JOIN) (\w)/"FROM `$1`"/ge; ($_ => $d) } keys %v;
  my @created = map { /^CREATE VIEW (\w)/ ? $1 : () } @{ sql_of([ grep { $_->action eq 'create' } @{ diff_ops({}, \%served) } ]) };
  is_deeply \@created, $installed, 'install_ddl and the diff create the views in one order' or diag explain [ $installed, \@created ];
  my @dropped = map { /^DROP VIEW (\w)/ ? $1 : () } @{ sql_of(diff_ops(\%served, {})) };
  is_deeply \@dropped, [ reverse @$installed ], '... and the diff drops them in exactly the reverse';
}

# 5. cycles
{
  my %cyc = (a => 'SELECT id FROM b', b => 'SELECT id FROM c', c => 'SELECT id FROM a', d => 'SELECT id FROM t');
  my $ns = schema_for(['t'], %cyc);
  my $ddl = eval { DBIO::MySQL::DDL->install_ddl($ns) };
  my $err = $@;
  ok !defined $ddl, 'install_ddl: views in a cycle write nothing';
  ok ref $err && $err->isa('DBIO::Exception'), '... it throws a DBIO::Exception';
  like "$err", qr/`a`.*`b`.*`c`/s, '... naming the views of the cycle';
  unlike "$err", qr/`d`/, '... and not the view that merely stands beside it';

  my $ops = eval { diff_ops({}, \%cyc) };
  $err = $@;
  ok !$ops, 'the diff: views in a cycle return no operations';
  ok ref $err && $err->isa('DBIO::Exception') && "$err" =~ /`a`.*`b`.*`c`/s, '... and throw the same exception naming them';

  $ops = eval { diff_ops(\%cyc, {}) };
  ok !$ops && ref $@ && $@->isa('DBIO::Exception'), '... in the drops as well';
}

done_testing;
