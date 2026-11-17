use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;
use DBIO::MySQL::Diff;
use DBIO::MySQL::Deploy;

sub order { return [ DBIO::MySQL::DDL::order_views({ @_ }) ] }
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

# OFFLINE half of karr k110 (subtest diff-view-order of t/122-diff-view-live.t has the live half): views are created in the
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
subtest 'ddl-view-order' => sub {
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
  is_deeply order(a => 'SELECT 1 FROM b', b => 'SELECT 1 FROM t'), [qw(b a)], 'order_views: the reader after what it reads, though it sorts first';
  is_deeply order(a => 'SELECT 1 FROM t', b => 'SELECT 1 FROM a'), [qw(a b)], '... and the other way round';
  is_deeply order(a => 'SELECT 1 FROM t', b => 'SELECT 1 FROM t'), [qw(a b)], '... views free of each other stay in name order';
  is_deeply order(a => 'SELECT 1 FROM a'), [qw(a)], '... a read of itself is no dependency';
  is_deeply order(A => 'SELECT 1', b => 'SELECT 1 FROM a'), [qw(A b)], '... a name is matched without case when only one view has it so';
  is_deeply order(a => 'SELECT 1', A => 'SELECT 1', b => 'SELECT 1 FROM A'), [qw(A a b)], '... and exactly when two differ in case only';

  # 2. install_ddl

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
      '... two changed views of a chain: dropped reader first, created reader last, the unchanged top view a is replaced with them';
  }
  {
    my %old = (a => 'select `b`.`id` AS `id` from `b`', b => 'select `t`.`id` AS `id` from `t`');
    my %new = (a => 'select `b`.`id` AS `id` from `b`', b => 'select `t`.`id` AS `id`,1 AS `one` from `t`');
    is_deeply sql_of(diff_ops(\%old, \%new)), ['DROP VIEW a', 'DROP VIEW b', 'CREATE VIEW b', 'CREATE VIEW a'],
      '... a view that stays beside a changed view it reads is dropped and created again around it (t/121-diff-view.t)';
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
};

# OFFLINE half of karr k118 (t/148 has the live half): a relationship whose
# target is a view source writes no FOREIGN KEY.
#
# WHY IT MATTERS. install_ddl wrote a FOREIGN KEY for every belongs_to whose
# target source exists, so Track (DBIO::Test::Schema), which points at the two
# virtual views year1999cds and year2000cds, got a key on a name that is no
# table, and MySQL and MariaDB refused the CREATE TABLE (1824). A foreign key
# cannot reference a view on either server. The relationship stays valid (a
# join still works); only the key is left out, for a virtual view and for a
# real one alike. The diff builds its target by running install_ddl, so one
# fix covers install and diff. A belongs_to to a table keeps its key.
subtest 'ddl-no-foreign-key-on-view' => sub {
  {
    package K118::Schema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('MySQL');
  }
  {
    package K118::Schema::Result::Base;
    use DBIO 'Core', -mysql;
    __PACKAGE__->table('base_t');
    __PACKAGE__->add_columns(id => { data_type => 'int' });
    __PACKAGE__->set_primary_key('id');
    K118::Schema->register_class(Base => __PACKAGE__);
  }
  {
    package K118::Schema::Result::RealView;
    use DBIO 'Core', -mysql;
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->table('real_v');
    __PACKAGE__->result_source_instance->view_definition('SELECT id FROM base_t');
    __PACKAGE__->add_columns(id => { data_type => 'int' });
    __PACKAGE__->set_primary_key('id');
    K118::Schema->register_class(RealView => __PACKAGE__);
  }
  {
    package K118::Schema::Result::VirtView;
    use DBIO 'Core', -mysql;
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->table('virt_v');
    __PACKAGE__->result_source_instance->is_virtual(1);
    __PACKAGE__->result_source_instance->view_definition('SELECT id FROM base_t');
    __PACKAGE__->add_columns(id => { data_type => 'int' });
    __PACKAGE__->set_primary_key('id');
    K118::Schema->register_class(VirtView => __PACKAGE__);
  }
  {
    package K118::Schema::Result::Child;
    use DBIO 'Core', -mysql;
    __PACKAGE__->table('child_t');
    __PACKAGE__->add_columns(
      id      => { data_type => 'int' },
      base_id => { data_type => 'int' },
      real_id => { data_type => 'int' },
      virt_id => { data_type => 'int' },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(base => 'K118::Schema::Result::Base',     'base_id');
    __PACKAGE__->belongs_to(real => 'K118::Schema::Result::RealView', 'real_id');
    __PACKAGE__->belongs_to(virt => 'K118::Schema::Result::VirtView', 'virt_id');
    K118::Schema->register_class(Child => __PACKAGE__);
  }

  my $ddl = DBIO::MySQL::DDL->install_ddl('K118::Schema');

  like $ddl, qr/FOREIGN KEY \(`base_id`\) REFERENCES `base_t`/, 'a: the key to a table stays';
  unlike $ddl, qr/REFERENCES `real_v`/,  'b: no key on a real view';
  unlike $ddl, qr/REFERENCES `virt_v`/,  'c: no key on a virtual view';
  is scalar(() = $ddl =~ /FOREIGN KEY/g), 1, 'd: exactly one key is written';

  ok( K118::Schema->source('Child')->relationship_info('virt'),
    'e: the relationship itself is still there' );
};

# OFFLINE half of karr k114: add_drop_table drops the declared views before the
# tables, on the sync way (DBIO::MySQL::Deploy) and on the async way (the
# pre-pass of deploy_async), each in backticks.
#
# WHY IT MATTERS. The install DDL says CREATE VIEW, never CREATE OR REPLACE, so
# a second deploy over a database that already holds the views dies on the first
# of them -- and a table drop in front of it leaves the views behind, reading a
# table that is not there. The idempotent re-deploy add_drop_table promises has
# to take the views away first, a reader before the view it reads, and name them
# as the install DDL names them.
subtest 'ddl-drop-views' => sub {
  {
    package DropViews::Schema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('MySQL');
  }
  {
    package DropViews::Schema::Result::Order;
    use DBIO;
    __PACKAGE__->table('order');
    __PACKAGE__->add_columns(id => { data_type => 'integer' });
    __PACKAGE__->set_primary_key('id');
  }
  {
    package DropViews::Schema::Result::Line;
    use DBIO;
    __PACKAGE__->table('line');
    __PACKAGE__->add_columns(id => { data_type => 'integer' });
    __PACKAGE__->set_primary_key('id');
  }
  # a_top reads z_base, which reads `order`: name order is not read order
  {
    package DropViews::Schema::Result::ATop;
    use base 'DBIO::Core';
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->table('a_top');
    __PACKAGE__->add_columns(id => { data_type => 'integer' });
    __PACKAGE__->result_source_instance->view_definition('SELECT id FROM z_base');
    # the async pre-pass orders the views by what they declare, not by reading the SQL
    __PACKAGE__->result_source_instance->deploy_depends_on({ 'DropViews::Schema::Result::ZBase' => 1 });
  }
  {
    package DropViews::Schema::Result::ZBase;
    use base 'DBIO::Core';
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->table('z_base');
    __PACKAGE__->add_columns(id => { data_type => 'integer' });
    __PACKAGE__->result_source_instance->view_definition('SELECT id FROM `order`');
  }
  {
    package DropViews::Schema::Result::Virt;
    use base 'DBIO::Core';
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->table('virt_view');
    __PACKAGE__->add_columns(id => { data_type => 'integer' });
    __PACKAGE__->result_source_instance->view_definition('SELECT 1 AS id');
    __PACKAGE__->result_source_instance->is_virtual(1);
  }
  DropViews::Schema->register_class($_ => "DropViews::Schema::Result::$_")
    for qw(Order Line ATop ZBase Virt);

  my @views  = ('DROP VIEW IF EXISTS `a_top`;', 'DROP VIEW IF EXISTS `z_base`;');
  my @tables = ('DROP TABLE IF EXISTS `line`;', 'DROP TABLE IF EXISTS `order`;');
  my @atables = map { s{;$}{ CASCADE;}r } @tables;

  # --- the shared statement list -------------------------------------------------
  {
    my @got = split /\n\n/, DBIO::MySQL::DDL->drop_ddl('DropViews::Schema');
    is_deeply [ @got[0, 1] ], \@views,
      'drop_ddl: the views first, a reader before the view it reads';
    is_deeply [ sort @got[2 .. $#got] ], \@tables, 'then the tables, backticked';
    is scalar(@got), 4, 'nothing else: the virtual view is no object of the database';
    unlike join("\n", @got), qr/virt_view/, 'no DROP for the virtual view';
  }

  # --- the sync way: DBIO::MySQL::Deploy -----------------------------------------
  {
    package DropViews::Probe;
    our @ISA = ('DBIO::MySQL::Deploy');
    sub _dbh { $_[0]{dbh} }
    sub _execute_ddl { my ($self, $dbh, $sql) = @_; push @{ $self->{ran} }, $sql; 1 }
    package DropViews::Dbh;
    sub new { bless { did => [] }, shift }
    sub do  { push @{ $_[0]{did} }, $_[1]; 1 }
  }

  {
    my $dbh = DropViews::Dbh->new;
    my $d = DropViews::Probe->new(schema => 'DropViews::Schema', dbh => $dbh, add_drop_table => 1);
    $d->install;
    my ($drop_batch, $install_batch) = @{ $d->{ran} };
    like $install_batch // '', qr/\ACREATE TABLE/, 'the install DDL runs after the drops, as it did';
    my @drops = split /\n\n/, $drop_batch // '';
    is_deeply [ @drops[0, 1] ], \@views, 'Deploy install: the views dropped first, in read order';
    is_deeply [ sort @drops[2 .. $#drops] ], \@tables, 'Deploy install: then the tables';
    is_deeply $dbh->{did},
      [ 'SET FOREIGN_KEY_CHECKS = 0', 'SET FOREIGN_KEY_CHECKS = 1' ],
      'the foreign key checks are off for the drops only and on again after';

    my $plain = DropViews::Probe->new(schema => 'DropViews::Schema', dbh => DropViews::Dbh->new);
    $plain->install;
    is scalar(@{ $plain->{ran} }), 1, 'install without add_drop_table runs the install DDL alone';
    unlike $plain->{ran}[0], qr/DROP/, 'and drops nothing';
  }

  # --- the async way: the pre-pass of deploy_async --------------------------------
  SKIP: {
    eval { require DBIO::MySQL::Storage::Async; 1 }
      or skip 'DBIO::Async not installed (recommends only)', 4;
    for my $class (qw(DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async)) {
      eval "require $class; 1" or die $@;
      my @got = split /\n\n/, $class->new(undef)->_drop_statements_for('DropViews::Schema');
      is_deeply [ @got[0, 1] ], \@views, "$class: the views first, backticked, a reader before its view";
      is_deeply [ sort @got[2 .. $#got] ], \@atables, "$class: then the tables";
    }
  }
};

done_testing;
