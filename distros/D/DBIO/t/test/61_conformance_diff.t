use strict;
use warnings;

use Test::More;
use lib 't/lib';
use Storable ();

# The Diff list of DBIO::Test::Conformance (ADR 0060, karr k330): the case
# table and the runner's upgrade flow, tested against a mock server and never
# a database. The mock (t/lib/MockConformanceServer.pm) answers every case
# correctly; a scenario bends one thing and asserts which answer the runner
# reports. Each scenario that expects red proves the test can go red.

use DBIO::Test::Conformance;
use DBIO::Test::Conformance::Cases::Diff;
use DBIO::Exception;
use MockConformanceServer;

my $MOCK = 'MockConformanceServer';

# ------------------------------------------------------------ the case table

my $cases = DBIO::Test::Conformance::Cases::Diff->cases;
is scalar(@$cases), 23, 'the Diff list holds 23 cases: U1..U17, U19, U20, U13 split in two, three deploy cases';
is(DBIO::Test::Conformance->table_version('Diff'), 4, 'table version 4 for Diff (the deploy cases, karr k399)');
is(DBIO::Test::Conformance->table_version, 2, 'DDL (version 2, D15 split) without an argument');
is(DBIO::Test::Conformance->table_version, DBIO::Test::Conformance->table_version('DDL'),
  'no argument means DDL');
like(eval { DBIO::Test::Conformance->table_version('Nope'); 1 } ? '' : "$@", qr/no table version/,
  'an unknown area has no table version');

is_deeply [ map { $_->{name} } @$cases ], [qw(
  diff-view-added diff-view-dropped diff-view-definition-changed
  diff-table-added-complete diff-column-added-not-null-populated
  diff-column-added-expression-default diff-default-changed-apostrophe
  diff-default-expression-kept diff-default-removed
  diff-indexed-column-dropped diff-fk-dropped diff-fk-added-to-new-unique
  diff-constraint-changed diff-fk-action-changed diff-ident-drop diff-not-null-over-nulls
  diff-column-type-change diff-table-with-dependent-view
  diff-auto-increment-kept diff-primary-key-order
  diff-deploy-inherited diff-deploy-dry-run diff-deploy-destructive-guard
)], 'U1..U17, U19, U20 in the order of the ADR appendix, the FK action after U13 (U18 needs driver SQL)';

{
  my %kind = map { $_ => 1 } DBIO::Test::Conformance->expectation_kinds;
  my %fact = map { $_ => 1 } qw(object_kind table_name table_in_namespace column_names
    column_size column_auto_increment primary_key_columns unique_exists
    foreign_key_count index_count);
  my %seen;
  my @bad;
  for my $c (@$cases) {
    my $n = $c->{name};
    push @bad, "$n: not diff-kebab-case" unless $n =~ /^diff-[a-z0-9]+(?:-[a-z0-9]+)*$/;
    push @bad, "$n: duplicate" if $seen{$n}++;
    my %since = ('diff-fk-action-changed' => 2, 'diff-indexed-column-dropped' => 3,
      map { $_ => 4 } qw(diff-deploy-inherited diff-deploy-dry-run diff-deploy-destructive-guard));
    push @bad, "$n: since is not " . ($since{$n} // 1)
      unless ($c->{since} // '') eq ($since{$n} // 1);
    push @bad, "$n: since is newer than the table version"
      if ($c->{since} // 0) > DBIO::Test::Conformance->table_version('Diff');
    push @bad, "$n: no cards" unless ref $c->{cards} eq 'ARRAY' && @{ $c->{cards} };
    push @bad, "$n: no expect" unless ref $c->{expect} eq 'ARRAY' && @{ $c->{expect} };
    push @bad, "$n: no subject source" unless ref $c->{subject} eq 'HASH' && $c->{subject}{source};

    my $in = $c->{input};
    my %side;
    for my $s (qw(from to)) {
      push @bad, "$n: no $s sources" unless ref $in->{$s}{sources} eq 'ARRAY' && @{ $in->{$s}{sources} };
      my $schema_class = eval { DBIO::Test::Conformance->_build_schema_class($c, $in->{$s}) };
      if (!$schema_class or !$schema_class->isa('DBIO::Schema')) {
        push @bad, "$n: the $s sources do not build a schema class: " . ($@ || 'no class');
        next;
      }
      my $want = @{ $in->{$s}{sources} };
      my $got  = () = $schema_class->sources;
      push @bad, "$n: $s builds $got sources, declared $want" unless $got == $want;
      $side{$s} = { map { $_->{name} => $_ } @{ $in->{$s}{sources} } };
    }
    push @bad, "$n: from and to are the same declaration"
      if $side{from} and $side{to} and Storable::freeze({ %{ $in->{from} } }) eq Storable::freeze({ %{ $in->{to} } });

    # rows are loaded into the installed `from`
    push @bad, "$n: rows is not a list" unless ref($in->{rows} // []) eq 'ARRAY';
    for my $row (@{ $in->{rows} || [] }) {
      my $def = $side{from} && $side{from}{ $row->{source} };
      if (!$def) { push @bad, "$n: a row names source '$row->{source}', which `from` does not declare"; next }
      my %col = @{ $def->{columns} };
      push @bad, "$n: a row of $row->{source} sets the unknown column $_"
        for grep { !exists $col{$_} } keys %{ $row->{values} };
    }

    for my $e (@{ $c->{expect} }) {
      push @bad, "$n: an expect entry is not a one-key hash"
        if ref $e ne 'HASH' or keys(%$e) != 1;
      my ($k, $a) = %$e;
      push @bad, "$n: unknown expectation kind $k" unless $kind{$k};
      next if $k eq 'cascade_delete';
      for my $src (grep { defined } @$a{qw(source through)}) {
        push @bad, "$n: expectation $k names the unknown source $src"
          unless ($side{to} && $side{to}{$src}) or ($side{from} && $side{from}{$src});
      }
      push @bad, "$n: unknown fact $a->{name}" if $k eq 'fact' and !$fact{ $a->{name} };
      push @bad, "$n: rows_kept names a source the target does not keep: $a->{source}"
        if $k eq 'rows_kept' and !($side{to} && $side{to}{ $a->{source} });
    }
    push @bad, "$n: the subject source is in neither declaration"
      unless ($side{to} && $side{to}{ $c->{subject}{source} }) or ($side{from} && $side{from}{ $c->{subject}{source} });
  }
  is_deeply \@bad, [], 'every Diff case is well formed' or diag join "\n", @bad;
}

{
  my $a = DBIO::Test::Conformance::Cases::Diff->cases;
  $a->[0]{name} = 'tampered';
  $a->[1]{input}{rows} = [];
  is(DBIO::Test::Conformance::Cases::Diff->cases->[0]{name}, 'diff-view-added', 'cases() hands out a copy');
  ok(scalar @{ DBIO::Test::Conformance::Cases::Diff->cases->[1]{input}{rows} }, '... a deep one');
}

# the Diff seam has no default: a driver that does not run the list is told which
{
  my $err = eval { DBIO::Test::Conformance->conformance_upgrade(undef, undef, undef); 1 } ? '' : "$@";
  like $err, qr/conformance_upgrade.*must be provided by the driver/s,
    'conformance_upgrade dies naming itself until a driver provides it';
}

# ------------------------------------------------------------ the right server

sub statuses {
  my (%o) = @_;
  my @r = $MOCK->results('Diff', %o);
  return { map { $_->{case} => $_ } @r };
}

{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  my @r = $MOCK->results('Diff');
  is scalar(@r), 23, 'one result per case';
  is_deeply [ grep { $_->{status} ne 'pass' } @r ], [],
    'the correct mock answers every Diff case correctly'
    or diag join "\n", map { "$_->{case}: $_->{status}: $_->{message}" } grep { $_->{status} ne 'pass' } @r;
  is $MockConformanceServer::CALLS{upgrade}, 20, 'every other case went through conformance_upgrade';
  is $MockConformanceServer::CALLS{deploy}, 3, 'the deploy cases went through conformance_deploy';
  ok $MockConformanceServer::CALLS{fact} > 0, 'facts were measured through the seam';
}

# the runner hands the target schema on: expectations, diff, cleanup see it
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  my $s = statuses(only => ['diff-fk-dropped']);
  is $s->{'diff-fk-dropped'}{status}, 'pass', 'diff-fk-dropped passes on the right server';
  my @rels = $MockConformanceServer::CLEANED_WITH->source('Child')->relationships;
  is scalar(@rels), 0, 'cleanup got the upgraded (target) schema, not the one installed';
}

# ------------------------------------------- U10 replaced (karr k370)

{
  my %by = map { $_->{name} => $_ } @$cases;
  ok !$by{'diff-column-dropped-with-index'}, 'the withdrawn U10 name is no case of the table';
  my $c = $by{'diff-indexed-column-dropped'};
  is $c->{since}, 3, 'the replacement U10 carries since 3';
  my $col = $c->{subject}{column};
  ok length($col) > 1, 'the subject column is no single letter';
  like $col, qr/_/, '... and has an underscore: no English word';
  is $col, 'drop_idx_col', '... it is drop_idx_col';

  my %from = @{ $c->{input}{from}{sources}[0]{columns} };
  is $from{$_}{is_nullable}, 0, "the unique-key column $_ is NOT NULL in from"
    for qw(wide_uq_one wide_uq_two);

  MockConformanceServer::reset_state();
  $MockConformanceServer::REFUSALS{'diff-column-dropped-with-index'} = { kind => 'server', reason => qr/x/ };
  like join("\n", MockConformanceServer->check_declarations('Diff')),
    qr/diff-column-dropped-with-index.*unknown case/s, 'a declaration under the withdrawn name is an unknown case';
}

# ------------------------------------------- a server that gets it wrong: red

{
  local $ENV{AUTHOR_TESTING} = 1;

  # the upgrade changes nothing: never "no changes" while the facts are not there
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{upgrade_noop} = 1;
  my $s = statuses(only => [qw(diff-fk-dropped diff-view-added diff-indexed-column-dropped)]);
  is $s->{$_}{status}, 'fail', "$_: an upgrade that did nothing is a failure" for sort keys %$s;
  like $s->{'diff-indexed-column-dropped'}{message},
    qr/column_names of Wide: expected \['id', 'wide_uq_two'\], the server shows \['drop_idx_col', 'id', 'wide_uq_one', 'wide_uq_two'\]/,
    '... and the message says which fact is missing';

  # the rows do not survive the upgrade
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{upgrade_drops_rows} = 1;
  $s = statuses(only => ['diff-fk-dropped', 'diff-default-removed']);
  is $s->{'diff-fk-dropped'}{status}, 'fail', 'rows lost in the upgrade are a failure';
  like $s->{'diff-fk-dropped'}{message}, qr/Child row \(id = '1'\): gone after the upgrade/,
    '... and the message names the row';

  # the second diff is not empty
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{diff_nonempty} = 1;
  $s = statuses(only => ['diff-default-removed']);
  is $s->{'diff-default-removed'}{status}, 'fail', 'postcondition 2: a non-empty diff after the upgrade fails';
  like $s->{'diff-default-removed'}{message}, qr/after the upgrade.*not empty/, '... and says so';
}

# the runner's contract with the seam
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  no warnings 'redefine';
  local *MockConformanceServer::conformance_upgrade = sub { 'not a schema' };
  my $s = statuses(only => ['diff-default-removed']);
  is $s->{'diff-default-removed'}{status}, 'fail', 'an upgrade that returns no schema is a failure';
  like $s->{'diff-default-removed'}{message}, qr/must return the connected schema/, '... and says what it must return';
}

# ----------------------------------------------------------------- refusals

my $refuse = sub {
  my ($msg) = @_;
  return sub { $_[0]->throw_exception($msg) };
};

{
  local $ENV{AUTHOR_TESTING} = 1;
  my $name = 'diff-constraint-changed';
  MockConformanceServer::reset_state();
  $MockConformanceServer::REFUSALS{$name} = { kind => 'server', reason => qr/constraint changes on an existing table/ };
  $MockConformanceServer::QUIRK{throw_upgrade}{$name} = $refuse->(
    "upgrade refused for table 'child', column 'code': constraint changes on an existing table"
  );
  my $s = statuses(only => [$name]);
  is $s->{$name}{status}, 'refused', 'a declared refusal from the upgrade is refused'
    or diag $s->{$name}{message};

  # the convention: the table is named
  $MockConformanceServer::QUIRK{throw_upgrade}{$name} = $refuse->(
    "upgrade refused: constraint changes on an existing table, column 'code'"
  );
  $s = statuses(only => [$name]);
  is $s->{$name}{status}, 'fail', 'a refusal that does not name the table is a failure';
  like $s->{$name}{message}, qr/table 'child'/, '... and says which name is missing';

  # the FK action is its own case: the refusal names the FK column, not code
  MockConformanceServer::reset_state();
  my $fk = 'diff-fk-action-changed';
  $MockConformanceServer::REFUSALS{$fk} = { kind => 'server', reason => qr/foreign key actions/ };
  $MockConformanceServer::QUIRK{throw_upgrade}{$fk} = $refuse->(
    "upgrade refused for table 'child', column 'parent_id': foreign key actions are not supported"
  );
  $s = statuses(only => [$fk]);
  is $s->{$fk}{status}, 'refused', 'the FK action case is refused naming table and the FK column'
    or diag $s->{$fk}{message};
  $MockConformanceServer::QUIRK{throw_upgrade}{$fk} = $refuse->(
    "upgrade refused for table 'child', column 'code': foreign key actions are not supported"
  );
  $s = statuses(only => [$fk]);
  is $s->{$fk}{status}, 'fail', 'a refusal of the FK action case naming code instead of parent_id is a failure';
  like $s->{$fk}{message}, qr/column 'parent_id'/, '... and says which column is missing';

  # undeclared
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{throw_upgrade}{$name} = $refuse->(
    "upgrade refused for table 'child', column 'code': constraint changes on an existing table"
  );
  $s = statuses(only => [$name]);
  is $s->{$name}{status}, 'fail', 'an undeclared refusal is a failure';
  like $s->{$name}{message}, qr/no refusal is declared/, '... and says so';

  # stale
  MockConformanceServer::reset_state();
  $MockConformanceServer::REFUSALS{'diff-fk-dropped'} = { kind => 'server', reason => qr/./ };
  $s = statuses(only => ['diff-fk-dropped']);
  is $s->{'diff-fk-dropped'}{status}, 'fail', 'a refusal that runs through is a failure';
  like $s->{'diff-fk-dropped'}{message}, qr/stale refusal/, '... as a stale refusal';
}

# a refused area: every case of the list is that refusal
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  my $subject_table = sub {
    my ($case) = @_;
    my $src = $case->{subject}{source};
    my ($def) = grep { $_->{name} eq $src }
      map { @{ $case->{input}{$_}{sources} } } qw(to from);
    return $def->{table} . (defined $case->{subject}{column} ? "', column '$case->{subject}{column}" : '');
  };
  $MockConformanceServer::AREAS{Diff} = { kind => 'pending', card => 'k36', reason => qr/diff is not built yet/ };
  $MockConformanceServer::QUIRK{throw_upgrade_any} = sub {
    my ($schema, $case) = @_;
    $schema->throw_exception("upgrade refused for table '" . $subject_table->($case) . "': diff is not built yet");
  };
  is_deeply [ MockConformanceServer->check_declarations('Diff') ], [], 'the refused area declaration is whole';
  my @r = $MOCK->results('Diff');
  is_deeply [ map { $_->{status} } @r ], [ ('pending') x 23 ],
    'a driver that refuses the Diff area is green: every case is pending';
  is $r[0]{card}, 'k36', '... with the area\'s card';
  is(MockConformanceServer->summary_line(\@r), 'Diff area pending (karr k36): 23 cases',
    'the summary line is one entry for the area, not one per case');
  is $MockConformanceServer::CALLS{upgrade}, 20, '... every case was driven and refused by the seam';

  # kind server: refused
  $MockConformanceServer::AREAS{Diff} = { kind => 'server', reason => qr/diff is not built yet/ };
  is_deeply [ map { $_->{status} } $MOCK->results('Diff') ], [ ('refused') x 23 ], 'a server-kind area is refused';
  is(MockConformanceServer->summary_line([ $MOCK->results('Diff') ]),
    'Diff area refused by the server (diff is not built yet): 23 cases', '... and the line says kind and reason');

  # a case that runs through despite the declaration is stale
  $MockConformanceServer::QUIRK{throw_upgrade_any} = sub {
    my ($schema, $case) = @_;
    return if $case->{name} eq 'diff-ident-drop';
    $schema->throw_exception("upgrade refused for table '" . $subject_table->($case) . "': diff is not built yet");
  };
  my $s = statuses();
  is $s->{'diff-ident-drop'}{status}, 'fail', 'a case of a refused area that runs through fails';
  like $s->{'diff-ident-drop'}{message}, qr/stale refusal/, '... as a stale refusal';
  is $s->{'diff-view-added'}{status}, 'refused', '... the others stay refused';

  # the area does not leak into the lists it was not declared for
  MockConformanceServer::reset_state();
  $MockConformanceServer::AREAS{Bind} = { kind => 'server', reason => qr/x/ };
  is statuses(only => ['diff-fk-dropped'])->{'diff-fk-dropped'}{status}, 'pass', 'a refused Bind area does not touch Diff';
}

# ------------------------------------------------------------ answered through

{
  my $name = 'diff-fk-dropped';
  my $red = sub {
    MockConformanceServer::reset_state();
    $MockConformanceServer::QUIRK{upgrade_noop} = 1;
  };
  my %quiet = (AUTHOR_TESTING => '', RELEASE_TESTING => '');

  $red->();
  $MockConformanceServer::THROUGH = 1;   # a scalar counts for DDL only
  {
    local @ENV{keys %quiet} = values %quiet;
    my $s = statuses(only => [$name]);
    is $s->{$name}{status}, 'todo', 'a scalar answered_through 1 does not cover Diff: todo, not fail';
    like $s->{$name}{message}, qr/newer than answered_through 0/, '... Diff counts as 0';
    is(MockConformanceServer->summary_line([ $s->{$name} ]),
      "1 case newer than the answered table version: $name", '... and the summary line counts it');
  }
  for my $var (qw(AUTHOR_TESTING RELEASE_TESTING)) {
    local @ENV{keys %quiet} = values %quiet;
    local $ENV{$var} = 1;
    is statuses(only => [$name])->{$name}{status}, 'fail', "... and fails under $var";
  }

  $MockConformanceServer::THROUGH = { DDL => 1, Diff => 1 };
  {
    local @ENV{keys %quiet} = values %quiet;
    is statuses(only => [$name])->{$name}{status}, 'fail', 'a hash with Diff => 1 answers Diff: red whatever the environment';
  }
  $MockConformanceServer::THROUGH = { DDL => 1 };
  {
    local @ENV{keys %quiet} = values %quiet;
    is statuses(only => [$name])->{$name}{status}, 'todo', 'a hash that leaves Diff out counts it as 0';
  }
  $MockConformanceServer::THROUGH = 0;
  {
    local @ENV{keys %quiet} = values %quiet;
    is statuses(only => [$name])->{$name}{status}, 'todo', 'a driver that answered nothing is todo';
  }

  # a case of table version 2: a driver answered through 1 runs it as todo
  my $fk = 'diff-fk-action-changed';
  $red->();
  $MockConformanceServer::THROUGH = { Diff => 1 };
  {
    local @ENV{keys %quiet} = values %quiet;
    my $s = statuses(only => [$fk, $name]);
    is $s->{$fk}{status}, 'todo', 'diff-fk-action-changed (since 2) is todo for a driver answered through 1';
    like $s->{$fk}{message}, qr/newer than answered_through 1/, '... and says so';
    is $s->{$name}{status}, 'fail', '... while a since 1 case stays red';
  }
  $MockConformanceServer::THROUGH = { Diff => 2 };
  {
    local @ENV{keys %quiet} = values %quiet;
    is statuses(only => [$fk])->{$fk}{status}, 'fail', 'answered through 2 makes the FK action case red';
    my $s = statuses(only => ['diff-indexed-column-dropped']);
    is $s->{'diff-indexed-column-dropped'}{status}, 'todo', 'diff-indexed-column-dropped (since 3) is todo for a driver answered through 2';
    like $s->{'diff-indexed-column-dropped'}{message}, qr/newer than answered_through 2/, '... and says so';
  }
  $MockConformanceServer::THROUGH = { Diff => 3 };
  {
    local @ENV{keys %quiet} = values %quiet;
    is statuses(only => ['diff-indexed-column-dropped'])->{'diff-indexed-column-dropped'}{status}, 'fail',
      'answered through 3 makes the replacement U10 red';
  }
}

# declarations
{
  MockConformanceServer::reset_state();
  is_deeply [ MockConformanceServer->check_declarations('Diff') ], [], 'no declarations, no problems';

  $MockConformanceServer::THROUGH = { DDL => 1, Diff => 1, Bind => 1 };
  is_deeply [ MockConformanceServer->check_declarations('Diff') ], [], 'a whole hash is accepted';
  $MockConformanceServer::THROUGH = { Diff => 'x', Nope => 1 };
  my $p = join "\n", MockConformanceServer->check_declarations('Diff');
  like $p, qr/for Diff must be a non-negative integer/, 'a hash value is checked';
  like $p, qr/unknown area Nope/, '... and its keys';
  $MockConformanceServer::THROUGH = 'x';
  like join("\n", MockConformanceServer->check_declarations('Diff')), qr/must be a non-negative integer/, 'a scalar is checked';
  $MockConformanceServer::THROUGH = [];
  like join("\n", MockConformanceServer->check_declarations('Diff')), qr/must be a non-negative integer/, 'a list is not a version';

  MockConformanceServer::reset_state();
  $MockConformanceServer::REFUSALS{'diff-no-such-case'} = { kind => 'server', reason => qr/x/ };
  $MockConformanceServer::REFUSALS{'diff-fk-dropped'}   = { kind => 'pending', reason => qr/x/ };
  $MockConformanceServer::REFUSALS{'ddl-foreign-key'}   = { kind => 'pending', reason => qr/x/ };
  $p = join "\n", MockConformanceServer->check_declarations('Diff');
  like $p, qr/diff-no-such-case.*unknown case/s, 'a refusal naming no Diff case is a problem';
  like $p, qr/diff-fk-dropped.*card/s, 'pending needs a card';
  unlike $p, qr/ddl-foreign-key/, 'a refusal of the DDL list is not judged by the Diff check';
  like join("\n", MockConformanceServer->check_declarations('DDL')), qr/ddl-foreign-key.*card/s,
    '... it is judged by the DDL check';
  unlike join("\n", MockConformanceServer->check_declarations('DDL')), qr/diff-/, '... and the DDL check does not see Diff names';
}

# run() writes tests
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  $MockConformanceServer::REFUSALS{'diff-constraint-changed'} = { kind => 'pending', card => 'k72', reason => qr/not applied/ };
  $MockConformanceServer::QUIRK{throw_upgrade}{'diff-constraint-changed'} = $refuse->(
    "upgrade refused for table 'child', column 'code': constraint changes are not applied yet"
  );
  subtest 'run(Diff) over the mock' => sub {
    MockConformanceServer->run('Diff');
    done_testing;
  };
}

# without a server only the declarations are checked, and the cases not run are counted
{
  package MockNoServer;
  our @ISA = ('MockConformanceServer');
  sub conformance_live_available { 0 }
}
{
  my @diag;
  no warnings 'redefine';
  local *Test::More::diag = sub { push @diag, @_; 0 };
  MockConformanceServer::reset_state();
  my $before = $MockConformanceServer::CALLS{upgrade} // 0;
  subtest 'run(Diff) without a server' => sub {
    MockNoServer->run('Diff');
    is scalar(@diag), 1, 'one line is said';
    like $diag[0], qr/\A23 cases not run: no server/, '... how many cases were not run';
    is(($MockConformanceServer::CALLS{upgrade} // 0), $before, 'no case was driven');
    done_testing;
  };
}

# ------------------------------------------------------------ the deploy cases

{
  package Quirk::OwnApply;
  our @ISA = ('MockConformanceServer::Deploy');
  sub apply { my $self = shift; $self->SUPER::apply(@_) }

  package Quirk::RunsDry;
  our @ISA = ('MockConformanceServer::Deploy');
  # a deploy whose apply is inherited but whose dry_run guard is bypassed: the hook runs anyway
  sub _apply_options { my ($self, %o) = @_; delete $o{dry_run}; $self->SUPER::_apply_options(%o) }

  package Quirk::NoGuard;
  our @ISA = ('MockConformanceServer::Deploy');
  sub _assert_diff_allowed { return }
}

my @deploy = qw(diff-deploy-inherited diff-deploy-dry-run diff-deploy-destructive-guard);

{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  my $s = statuses(only => \@deploy);
  is_deeply [ map { $s->{$_}{status} } @deploy ], [ ('pass') x 3 ], 'the deploy cases pass on the right deploy class'
    or diag join "\n", map { "$_: $s->{$_}{message}" } grep { $s->{$_}{status} ne 'pass' } @deploy;
}

{
  package Quirk::DefaultSeam;
  our @ISA = ('MockConformanceServer');
  sub conformance_deploy { DBIO::Test::Conformance::conformance_deploy(@_) }
}
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  my @r = Quirk::DefaultSeam->results('Diff', only => \@deploy);
  is_deeply [ map { $_->{status} } @r ], [ ('na') x 3 ],
    'a driver without conformance_deploy answers the deploy cases na';
  like $r[0]{message}, qr/conformance_deploy/, '... and says which seam is missing';
}

{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{deploy_class} = 'Quirk::OwnApply';
  my $s = statuses(only => ['diff-deploy-inherited']);
  is $s->{'diff-deploy-inherited'}{status}, 'fail', 'a deploy class with its own apply fails the inherited case';
  like $s->{'diff-deploy-inherited'}{message}, qr/does not inherit apply.*_execute_diff/s, '... naming the method and the hooks';

  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{deploy_class} = 'Quirk::RunsDry';
  $s = statuses(only => ['diff-deploy-dry-run']);
  is $s->{'diff-deploy-dry-run'}{status}, 'fail', 'a dry_run that executes fails the dry-run case';
  like $s->{'diff-deploy-dry-run'}{message}, qr/dry_run ran something/, '... saying so';

  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{deploy_class} = 'Quirk::NoGuard';
  $s = statuses(only => ['diff-deploy-destructive-guard']);
  is $s->{'diff-deploy-destructive-guard'}{status}, 'fail', 'a drop without release that runs fails the guard case';
  like $s->{'diff-deploy-destructive-guard'}{message}, qr/did not throw/, '... saying it did not throw';
  MockConformanceServer::reset_state();
}

{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  { package Quirk::NotADeploy; our @ISA = ('MockConformanceServer'); sub conformance_deploy { bless {}, 'Nope' } }
  my @r = Quirk::NotADeploy->results('Diff', only => ['diff-deploy-inherited']);
  is $r[0]{status}, 'fail', 'a conformance_deploy that returns no deploy object is the driver\'s error';
  like $r[0]{message}, qr/conformance_deploy must return a DBIO::Deploy::Base/, '... and says what it must return';
}

done_testing;
