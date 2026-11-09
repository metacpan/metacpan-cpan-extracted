use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::AsyncHarness;
use DBIO::Test::AsyncParity;
use DBIO::Test::Future ();
use DBIO::Test::Storage;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::Exception;
use DBIO::Exception::Server;

# DBIO::Test::AsyncParity drives one list of ResultSet cases twice on the same
# connected schema, once through the synchronous method and once through its
# *_async twin, and compares what came out (karr k344).
#
# Core has no database, so what is exercised here is the RUNNER: that both
# ways of every case really run, that a way which deviates is caught and named
# by its case number, that a declared deviation is a test, that a stale
# declaration is a failure and that bad declarations are refused. The mock
# transport below is the synchronous fake of t/resultset/with_context.t
# (a real DBIO::Storage::Async whose statement seam answers from a table) and
# the synchronous mock storage answers the same table, so the two ways of a
# case see one "database". It keeps no state: a write is not seen by a later
# read, which is why a case that needs the server to enforce something (a
# unique constraint) is declared and not softened.

# ------------------------------------------------------------------ the data

my @ARTIST = (
  { artistid => 1, name => 'Caterwauler McCrae', rank => 10, charfield => undef },
  { artistid => 2, name => 'Random Boy Band',    rank => 20, charfield => undef },
  { artistid => 3, name => 'We Are Goth',        rank => 30, charfield => undef },
);
my @CD = (
  { cdid => 1, artist => 1, title => 'Spoonful of bees',             year => 1999, genreid => undef, single_track => undef },
  { cdid => 2, artist => 1, title => 'Forkful of chips',             year => 2001, genreid => undef, single_track => undef },
  { cdid => 3, artist => 2, title => "Caterwaulin' Blues",           year => 1997, genreid => undef, single_track => undef },
  { cdid => 4, artist => 3, title => 'Generic Manufactured Singles', year => 2001, genreid => undef, single_track => undef },
);
my @TRACK = (
  { trackid => 1, cd => 1, position => 1, title => 'Boring Name',   last_updated_on => undef, last_updated_at => undef },
  { trackid => 2, cd => 1, position => 2, title => 'Boring Song',   last_updated_on => undef, last_updated_at => undef },
  { trackid => 3, cd => 1, position => 3, title => 'No More Ideas', last_updated_on => undef, last_updated_at => undef },
  { trackid => 4, cd => 2, position => 1, title => 'Stripy',        last_updated_on => undef, last_updated_at => undef },
);
my %TABLE = (artist => \@ARTIST, cd => \@CD, track => \@TRACK, onekey => []);
my %PK    = (artist => 'artistid', cd => 'cdid', track => 'trackid', onekey => 'id');

# What the "server" answers to a SELECT, from the statement and its binds.
# Equality conditions on the base table narrow the rows; everything else
# answers the whole table. Joined tables answer the row at the same position.
sub answer_select {
  my ($sql, $bind) = @_;
  return () if $main::EMPTY;
  my @v = map { ref $_ eq 'ARRAY' ? $_->[-1] : $_ } @{ $bind || [] };

  my %alias;
  while ($sql =~ /\b(?:FROM|JOIN)\s+"?(\w+)"?\s+"?(\w+)"?/g) { $alias{$2} = $1 }
  my ($table, $base) = $sql =~ /\bFROM\s+"?(\w+)"?\s+"?(\w+)"?/ or return ();
  return () unless $TABLE{$table};

  # equality conditions, in bind order
  my ($where) = $sql =~ /\bWHERE\b(.*)\z/s;
  my @cond;
  if (defined $where) {
    push @cond, [ $1 // $base, $2 ]
      while $where =~ /(?:"?(\w+)"?\.)?"?(\w+)"?\s*=\s*\?/g;
  }
  my @rows = @{ $TABLE{$table} };
  if (@cond and @cond == @v) {
    @rows = grep {
      my $row = $_;
      my $ok = 1;
      for my $i (0 .. $#cond) {
        my ($a, $col) = @{ $cond[$i] };
        next unless $a eq $base and exists $row->{$col};
        my ($have, $want) = ($row->{$col}, $v[$i]);
        $ok = 0 unless defined $have and defined $want and "$have" eq "$want";
      }
      $ok;
    } @rows;
  }

  if ($sql =~ /\bLIMIT\s+(\d+)(?:\s+OFFSET\s+(\d+))?/) {
    my ($limit, $offset) = ($1, $2 // 0);
    @rows = splice @rows, $offset, $limit;
  }

  my ($select) = $sql =~ /\ASELECT\s+(?:DISTINCT\s+)?(.*?)\s+FROM\b/s or return ();

  # EXISTS answers 1 or 0
  return ([ @rows ? 1 : 0 ]) if $select =~ /\bEXISTS\b/;

  my @item = split /\s*,\s*/, $select;
  my $aggregate = grep { /\b(?:COUNT|MIN|MAX|SUM)\s*\(/i } @item;

  my $value_of = sub {
    my ($item, $i, $row) = @_;
    $item =~ s/\s+AS\s+\S+\z//i;
    if ($item =~ /\A(?:"?(\w+)"?\.)?"?(\w+)"?\z/) {
      my ($a, $col) = ($1 // $base, $2);
      my $t = $alias{$a} // $table;
      my $r = $t eq $table && $a eq $base
        ? $row
        : $TABLE{$t}[ $i % @{ $TABLE{$t} } ];
      return $r->{$col};
    }
    return 1;
  };

  if ($aggregate) {
    my @out;
    for my $item (@item) {
      if ($item =~ /\bCOUNT\s*\(/i) { push @out, scalar @rows; next }
      if ($item =~ /\b(MIN|MAX|SUM)\s*\(\s*(?:"?\w+"?\.)?"?(\w+)"?\s*\)/i) {
        my ($fn, $col) = (uc $1, $2);
        my @n = map { $_->{$col} } @rows;
        push @out, !@n ? undef
          : $fn eq 'MIN' ? (sort { $a <=> $b } @n)[0]
          : $fn eq 'MAX' ? (sort { $b <=> $a } @n)[0]
          : do { my $s = 0; $s += $_ for @n; $s };
        next;
      }
      push @out, 1;
    }
    return ([ @out ]);
  }

  my @out;
  for my $i (0 .. $#rows) {
    push @out, [ map { $value_of->($_, $i, $rows[$i]) } @item ];
  }
  return @out;
}

# ---------------------------------------------------------- the fake server

# Knobs of the scenarios below; local()ised there, off otherwise.
our $IN_CASE; # true while a case runs, not while the fixture is seeded
our $EMPTY;  # true while the reset runs: nothing cascades into rows
our $BEND;   # coderef ($sql, \@rows) -> \@rows: what the ASYNC way sees
our $DUP;    # { sync => class, async => class }: a duplicate artist insert fails
our $ROLLBACK_FAILS;  # the async ROLLBACK is not confirmed (the fault of case 47)

sub duplicate_insert {
  my ($sql, $bind) = @_;
  return 0 unless $DUP and $main::IN_CASE and $sql =~ /\AINSERT INTO "?artist"?/i;
  my @v = map { ref $_ eq 'ARRAY' ? $_->[-1] : $_ } @{ $bind || [] };
  return scalar grep { defined $_ and $_ eq 'Caterwauler McCrae' } @v;
}

sub error_of {
  my ($class) = @_;
  eval {
    $class->isa('DBIO::Exception::Server')
      ? $class->throw(message => 'unique violation on artist')
      : $class->throw('unique violation on artist');
  };
  return $@;
}

{
  # The synchronous fake storage, answering from the same table.
  package Parity::MockStorage;
  use base 'DBIO::Test::Storage';

  sub _capture_sth {
    my ($self, $op, $sql, $bind) = @_;
    die main::error_of($main::DUP->{sync}) if main::duplicate_insert($sql, $bind);
    return $self->next::method($op, $sql, $bind);
  }

  # The cursor asks _find_mock with the SQL alone; the binds are remembered
  # from the statement it was just rendered with.
  sub _prep_for_execute {
    my $self = shift;
    my @r = $self->next::method(@_);
    $self->{_parity_bind} = $r[1];
    return @r;
  }

  sub _prep_rendered_for_execute {
    my $self = shift;
    my @r = $self->next::method(@_);
    $self->{_parity_bind} = $r[1];
    return @r;
  }

  sub _find_mock {
    my ($self, $sql) = @_;
    return undef unless $sql =~ /\ASELECT\b/;
    return { rows => [ main::answer_select($sql, $self->{_parity_bind}) ] };
  }
}

{
  package Parity::Pool;
  sub new { bless { txns => 0 }, shift }
  sub acquire     { DBIO::Test::Future->done('POOL') }
  sub acquire_txn { DBIO::Test::Future->done('TXN' . ++$_[0]->{txns}) }
  sub release     { 1 }
  sub shutdown    { 1 }
  sub _retire_in_use_connection { push @{ $_[0]{retired} }, $_[1]; 1 }
}

{
  package Parity::Fault;
  sub DESTROY { $main::ROLLBACK_FAILS = 0 }
}

{
  # The async transport: statements arrive at _query_async(_pinned), exactly as
  # on a real one, and are answered from the same table.
  package Parity::Backend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured} = [];
    $self->{ids}      = {};
    return $self;
  }
  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub pool { $_[0]->{pool} ||= Parity::Pool->new }

  sub _answer {
    my ($self, $sql, $bind, $on) = @_;
    push @{ $self->{captured} }, { sql => $sql, on => $on };
    my $fc = $self->future_class;

    if (main::duplicate_insert($sql, $bind)) {
      return $fc->fail(main::error_of($main::DUP->{async}));
    }
    return $fc->fail(main::error_of('DBIO::Exception')) if $main::ROLLBACK_FAILS and $sql eq 'ROLLBACK';

    if ($sql =~ /\AINSERT INTO "?(\w+)"?/) {
      my $table = $1;
      my $pk = $PK{$table};
      return $fc->done($pk ? { $pk => ++$self->{ids}{$table} } : {});
    }
    return $fc->done(1) if $sql =~ /\A(?:UPDATE|DELETE)\b/;

    my @rows = main::answer_select($sql, $bind);
    if ($main::BEND and $sql =~ /\ASELECT\b/) {
      @rows = @{ $main::BEND->($sql, [ @rows ]) };
    }
    return $fc->done(@rows);
  }
  sub _query_async        { $_[0]->_answer($_[1], $_[2], 'the pool') }
  sub _query_async_pinned { $_[0]->_answer($_[2], $_[3], $_[1]) }
}

DBIO::Storage::DBI->register_async_mode( parity_mock => 'Parity::Backend' );

# ---------------------------------------------------------------- the harness

{
  package Parity::MockHarness;
  use base 'DBIO::Test::AsyncHarness';

  __PACKAGE__->harness_env_prefix('PARITY_MOCK');
  __PACKAGE__->harness_async_mode('parity_mock');
  __PACKAGE__->harness_required_modules([]);
  __PACKAGE__->harness_schema_class('DBIO::Test::Schema');

  sub live_available { 1 }

  sub new {
    my ($class, %opts) = @_;
    my $schema = DBIO::Test->init_schema;
    $schema->storage(Parity::MockStorage->new($schema));
    $schema->storage->_async_mode('parity_mock');
    delete $schema->storage->{_async_storage_obj};
    return bless { schema => $schema, schema_class => 'DBIO::Test::Schema', timeout => 5 }, $class;
  }

  # no event loop: the transport's Futures are settled when they are returned
  sub _tick_loop { }

  sub backend { $_[0]->{schema}->storage->_async_storage }
}

# ------------------------------------------------------ the suite under test

our %LEGS;       # case name -> [ 'sync', 'async' ] in the order driven
our %WIRE;       # case name -> statements the async way sent over the backend

{
  # What a driver dist's class looks like, plus a record of what was driven.
  package Parity::Suite;
  use base 'DBIO::Test::AsyncParity';

  sub parity_deviations {{
    # the capability is the engine's; the mock storage declares none
    'upsert' => { kind => 'unsupported', reason => qr/upsert/ },
    # the mock keeps no constraint, so no violation ever comes
    'err-unique' => { kind => 'unsupported', reason => qr/exception was expected/ },
    'txn-statement-in-flight-fails' => { kind => 'unsupported', reason => qr/exception was expected/ },
  }}

  # the one fault the mock can express: a ROLLBACK the server does not confirm
  sub parity_capabilities {
    my ($class, $harness) = @_;
    return ($class->SUPER::parity_capabilities($harness), 'fault:rollback_fails');
  }

  sub parity_fault {
    my ($class, $schema, $harness, $name) = @_;
    return $class->SUPER::parity_fault($schema, $harness, $name) unless $name eq 'rollback_fails';
    $main::ROLLBACK_FAILS = 1;
    return bless {}, 'Parity::Fault';
  }

  sub parity_reset {
    my ($class, $schema) = @_;
    {
      # the default reset deletes through the ResultSet, which cascades by
      # selecting; the fake server has no rows to give it then
      local $main::EMPTY = 1;
      $class->SUPER::parity_reset($schema);
    }
    my $st = $schema->storage;
    $st->reset_captured;
    $st->_auto_increment({});
    $st->_last_insert_ids({});
    $st->_async_storage->{ids} = {};
    return;
  }

  sub parity_sync_schema {
    my ($class, $harness) = @_;
    my $schema = DBIO::Test->init_schema;
    $schema->storage->_async_mode(undef);
    return $schema;
  }

  sub _leg {
    my ($class, $case, $way, $schema, $env) = @_;
    push @{ $main::LEGS{ $case->{name} } }, $way;
    my $backend = $schema->storage->_async_storage;
    my $before  = @{ $backend->{captured} };
    local $main::IN_CASE = 1;
    my $out = $class->SUPER::_leg($case, $way, $schema, $env);
    $main::WIRE{ $case->{name} } = @{ $backend->{captured} } - $before
      if $way eq 'async';
    return $out;
  }
}

# ===========================================================================
# the table itself
# ===========================================================================

my $cases = DBIO::Test::AsyncParity->cases;

is scalar(@$cases), 56, 'the table has 56 cases: the 40 of the list, populate named, 15 of the async scaffold';
is_deeply [ map { $_->{no} } @$cases ], [ 1 .. 56 ], 'numbered 1 to 56 without a gap';
is scalar(keys %{{ map { $_->{name} => 1 } @$cases }}), 56, 'every case has a name of its own';

my %kinds;
$kinds{ $_->{kind} }++ for @$cases;
is_deeply [ map { $_ => $kinds{$_} } sort keys %kinds ],
  [ 'async-only' => 17, composed => 6, direct => 33 ],
  'kinds: direct, composed, async-only';

for my $case (@$cases) {
  my $label = sprintf '%02d %s', $case->{no}, $case->{name};
  if ($case->{kind} eq 'async-only') {
    ok !$case->{sync} && $case->{async}, "$label: async-only has an async way and no sync way";
  }
  else {
    ok $case->{sync} && $case->{async}, "$label: has both a sync and an async way";
  }
}

# ===========================================================================
# the clean run on the mock transport
# ===========================================================================

my %status;
{
  my $h = Parity::MockHarness->new;
  my @results = Parity::Suite->results(harness => $h, schema_class => 'DBIO::Test::Schema');
  is scalar(@results), 56, 'a result for every case';
  %status = map { $_->{no} => $_ } @results;

  # a failure names its number; show every failure whole when there is one
  my @fail = grep { $_->{status} eq 'fail' } @results;
  is scalar(@fail), 0, 'no case fails on the mock transport'
    or diag sprintf '%02d %s: %s', $_->{no}, $_->{case}, $_->{message} for @fail;

  my %by_status;
  push @{ $by_status{ $_->{status} } }, $_->{no} for @results;
  is_deeply $by_status{deviation}, [ 34, 39, 49 ],
    'the declared deviations are 34 upsert, 39 err-unique and 49 txn-statement-in-flight-fails';
  is_deeply $by_status{absent},    [ 41 ],     'populate is absent';
  is_deeply $by_status{skipped}, [ 42 .. 46, 50 .. 56 ],
    'the cases of capabilities the mock lacks are skipped: pipeline, cancel, disconnect, pool_queue, listen, unreachable';
  is_deeply [ grep { $_ >= 42 } @{ $by_status{pass} } ], [ 47, 48 ],
    'of the new cases the mock runs rollback-failed (its fault) and txn-statement-in-flight';
  is scalar(@{ $by_status{pass} || [] }), 40, 'the other 40 pass';
  like $status{42}{message}, qr/\Aneeds pipeline\z/, '42: a skipped case names the capability it needs';
  like $status{46}{message}, qr/\Aneeds pipeline, cancel\z/, '46: and every one that is missing';

  is $status{34}{deviation}, 'unsupported', '34: declared unsupported';
  like $status{34}{message}, qr/upsert/, '34: the failure is the capability refusal, as declared';
  like $status{39}{message}, qr/exception was expected/, '39: the mock raised nothing; that is what is declared';
  like $status{41}{message}, qr/populate has no async twin/, '41: the missing twin is what was observed';

  # both ways of every case really ran, in the order sync, async
  for my $case (@$cases) {
    my $label = sprintf '%02d %s', $case->{no}, $case->{name};
    my $legs = $LEGS{ $case->{name} } || [];
    if ($status{ $case->{no} }{status} eq 'skipped') {
      is_deeply $legs, [], "$label: skipped, so not driven at all";
      next;
    }
    is_deeply $legs, ($case->{kind} eq 'async-only' ? ['async'] : [ 'sync', 'async' ]),
      "$label: driven " . join(' and ', $case->{kind} eq 'async-only' ? 'async' : ('sync', 'async'));
  }

  # the async way of a direct case that passed went over the transport
  for my $case (grep { $_->{kind} eq 'direct' } @$cases) {
    next unless $status{ $case->{no} }{status} eq 'pass';
    my $label = sprintf '%02d %s', $case->{no}, $case->{name};
    cmp_ok $WIRE{ $case->{name} }, '>', 0, "$label: the async way used the transport";
  }

  my $line = Parity::Suite->summary_line(\@results);
  like $line, qr/\A3 deviations: 34 upsert \(unsupported\), 39 err-unique \(unsupported\), 49 txn-statement-in-flight-fails \(unsupported\); 1 absent: 41 populate; 12 skipped: 42 pipeline-commit \(needs pipeline\)/,
    'the closing line names the deviations, the absence and the skipped cases';
}

# ===========================================================================
# run() writes one test per case, none skipped
# ===========================================================================

{
  my $h = Parity::MockHarness->new;
  subtest 'run() on the mock transport' => sub {
    my $tb = Test::More->builder;
    Parity::Suite->run(harness => $h, schema_class => 'DBIO::Test::Schema');

    my $count = $tb->current_test;
    my @named = map { $_->{name} } $tb->details;
    my @skips = grep { $_->{type} eq 'skip' } $tb->details;
    is $count, 57, 'the declarations test plus one test per case';
    is scalar(@skips), 0, 'and none of them is a TAP skip';
    is_deeply [ grep { !/\A\d\d \S+: (?:pass|deviation \(unsupported\)|absent|skipped \(needs [a-z_:, ]+\))\z/ } @named[1 .. $#named] ],
      [], 'each is labelled with its number, its name and its status';
    like $named[34], qr/\A34 upsert: deviation \(unsupported\)\z/,
      'a declared deviation is one of the tests, in its place';
  };
}

# ===========================================================================
# a way that deviates is caught, and named by its case number
# ===========================================================================

{
  my $h = Parity::MockHarness->new;

  # the transport loses the last row of every multi-row artist read
  local $BEND = sub {
    my ($sql, $rows) = @_;
    pop @$rows if @$rows > 1 and $sql =~ /FROM "artist"/ and $sql !~ /COUNT/;
    return $rows;
  };

  my @r = Parity::Suite->results(harness => $h, only => [ 'find-pk', 'search-all' ]);
  my %by = map { $_->{case} => $_ } @r;

  is $by{'find-pk'}{status}, 'pass', 'a case the bend does not touch still passes';
  is $by{'search-all'}{status}, 'fail', 'the bent search-all fails';
  is $by{'search-all'}{no}, 5, 'and reports its number';
  like $by{'search-all'}{message}, qr/\Athe ways differ in the result: sync \[.*Random Boy Band.*We Are Goth.*\], async \[/s,
    'the message shows both answers, sync first';
  unlike $by{'search-all'}{message}, qr/async \[.*We Are Goth/s,
    'the async answer lacks the row the transport lost';
}

{
  # run() on a bent transport: the failing test names the number and the case.
  # It is driven under TODO with the output captured, so that it is looked at
  # and does not fail this file.
  my $h = Parity::MockHarness->new;
  local $BEND = sub { my ($sql, $rows) = @_; pop @$rows if @$rows > 1; return $rows };

  my $tb = Test::More->builder;
  my ($tap, $diag) = ('', '');
  my ($o, $f, $t) = ($tb->output, $tb->failure_output, $tb->todo_output);
  $tb->output(\$tap);
  $tb->failure_output(\$diag);
  $tb->todo_output(\$diag);
  $tb->todo_start('a bent transport, on purpose');
  Parity::Suite->run(harness => $h, only => [ 'search-all' ]);
  $tb->todo_end;
  $tb->output($o);
  $tb->failure_output($f);
  $tb->todo_output($t);
  # the tests were numbered in the stream; put them back into it
  print {$o} $tap;
  print {$t} $diag;

  like $tap, qr/^not ok \d+ - 05 search-all: fail # TODO/m,
    'run() writes the failing case as a test with its number, name and status';
  like $diag, qr/case 05 search-all: the ways differ in the result: sync \[/,
    'and its message names the case number';
}

# ===========================================================================
# a declared deviation is a test, a stale one is a failure
# ===========================================================================

{
  package Parity::Declared;
  use base 'Parity::Suite';
  sub parity_deviations {
    return +{
      %{ Parity::Suite->parity_deviations },
      'search-all' => { kind => 'unsupported', reason => qr/ways differ in the result/ },
      'count'      => { kind => 'pending', card => 'k77', reason => qr/never matches/ },
      'find-pk'    => { kind => 'unsupported', reason => qr/anything/ },
    };
  }
}

{
  my $h = Parity::MockHarness->new;
  local $BEND = sub {
    my ($sql, $rows) = @_;
    pop @$rows if @$rows > 1 and $sql =~ /FROM "artist"/ and $sql !~ /COUNT/;
    return $rows;
  };
  my @r = Parity::Declared->results(
    harness => $h, only => [ 'search-all', 'count', 'find-pk' ],
  );
  my %by = map { $_->{case} => $_ } @r;

  is $by{'search-all'}{status}, 'deviation',
    'a declared deviation that really deviates is a deviation (a test), not a skip';
  is $by{'search-all'}{deviation}, 'unsupported', 'it keeps its declared kind';

  is $by{'count'}{status}, 'fail', 'a declared deviation of a case that passes fails';
  like $by{'count'}{message}, qr/\Astale deviation: declared pending \(k77\) but the case passes\z/,
    'it says it is stale, with the card';

  is $by{'find-pk'}{status}, 'fail', 'a stale declaration fails also where the case is untouched';

  my $line = Parity::Declared->summary_line([ grep { $_->{status} ne 'fail' } @r ]);
  like $line, qr/\A1 deviation: 05 search-all \(unsupported\)\z/, 'the summary names the declared deviation';
}

{
  # a declaration whose reason is not what happened is a failure, too
  package Parity::WrongReason;
  use base 'Parity::Suite';
  sub parity_deviations {{
    'search-all' => { kind => 'unsupported', reason => qr/some other cause/ },
  }}
}
{
  my $h = Parity::MockHarness->new;
  local $BEND = sub { my ($sql, $rows) = @_; pop @$rows if @$rows > 1; return $rows };
  my ($r) = Parity::WrongReason->results(harness => $h, only => ['search-all']);
  is $r->{status}, 'fail', 'a deviation with another cause than declared fails';
  like $r->{message}, qr/does not match its declared reason/, 'and says so';
}

# ===========================================================================
# the exception class is compared
# ===========================================================================

{
  my $h = Parity::MockHarness->new;
  local $DUP = { sync => 'DBIO::Exception::Server', async => 'DBIO::Exception' };

  # not the declared-unsupported suite: the case must stand on its own
  {
    package Parity::Plain;
    use base 'Parity::Suite';
    sub parity_deviations { {} }
  }

  my ($r) = Parity::Plain->results(harness => $h, only => ['err-unique']);
  is $r->{status}, 'fail', 'sync raises a server error, async another class: fails';
  like $r->{message}, qr/exception classes differ: sync DBIO::Exception::Server, async DBIO::Exception/,
    'both classes are named';
}
{
  my $h = Parity::MockHarness->new;
  local $DUP = { sync => 'DBIO::Exception::Server', async => 'DBIO::Exception::Server' };
  my ($r) = Parity::Plain->results(harness => $h, only => ['err-unique']);
  is $r->{status}, 'pass', 'the same class on both ways passes, with nothing declared';
}

# ===========================================================================
# the declarations are checked offline
# ===========================================================================

{
  package Parity::Broken;
  use base 'DBIO::Test::AsyncParity';
  sub parity_deviations {{
    'no-such-case' => { kind => 'unsupported', reason => qr/x/ },
    'count'        => { kind => 'sometimes',   reason => qr/x/ },
    'first'        => { kind => 'unsupported', reason => 'not a regex' },
    'single'       => { kind => 'pending',     reason => qr/x/ },
    'find-pk'      => { kind => 'pending',     reason => qr/x/, card => 'soon' },
    'populate'     => { kind => 'absent',      reason => qr/x/ },
    'upsert'       => 'a string',
  }}
}

{
  my @p = Parity::Broken->check_declarations;
  like "@p", qr/'no-such-case': unknown case/, 'an unknown case name is refused';
  like "@p", qr/'count': kind must be 'unsupported', 'pending' or 'absent', not 'sometimes'/,
    'an unknown kind is refused';
  like "@p", qr/'first': reason must be a regex/, 'a reason that is no regex is refused';
  like "@p", qr/'single': a pending deviation needs a card/, 'pending without a card is refused';
  like "@p", qr/'find-pk': a pending deviation needs a card/, 'a card must be of the form k58';
  like "@p", qr/'populate': the table already marks this case absent/,
    'a case the table marks absent is not redeclared';
  like "@p", qr/'upsert': not a hash/, 'a deviation that is no hash is refused';

  is_deeply [ Parity::Suite->check_declarations ], [], 'the suite class of this file is whole';
  is_deeply [ DBIO::Test::AsyncParity->check_declarations ], [], 'and so is the default';
}

# ===========================================================================
# a schema without the fixture's sources is refused up front
# ===========================================================================

{
  package Parity::BareHarness;
  use base 'Parity::MockHarness';
  sub schema { $_[0]->{bare} }
}
{
  # no sources, and the fake driver: a schema always has one (ADR 0067)
  my $bare = DBIO::Schema->clone;
  $bare->storage_type('+DBIO::Test::Storage');
  $bare = $bare->connect(sub { });
  my $h = bless { bare => $bare }, 'Parity::BareHarness';
  eval { Parity::Suite->results(harness => $h, schema_class => 'My::Schema') };
  like $@, qr/no source 'Artist', 'CD', 'Track', 'OneKey'; the case table is written for My::Schema/,
    'the missing sources and the schema class are named';
}

# ===========================================================================
# the default synchronous schema declares the harness's driver (ADR 0067 §4)
# ===========================================================================

{
  # DBIO::Test::Schema declares no driver. A harness that runs the table on it
  # names the driver as storage_type, and the second, synchronous connection
  # is a clone of the shared class with that driver -- the class itself stays
  # undeclared, for the next suite that names another one.
  my %harness = (
    schema_class => 'DBIO::Test::Schema',
    dsn          => 'dbi:DBIO:test:parity',
    user         => '',
    pass         => '',
  );

  eval { DBIO::Test::AsyncParity->parity_sync_schema({ %harness }) };
  like $@, qr/Schema class DBIO::Test::Schema declares no driver/,
    'without storage_type the driverless schema class is refused by core';

  my $sync = DBIO::Test::AsyncParity->parity_sync_schema({
    %harness, storage_type => 'DBIO::Test::Storage',
  });
  ok ref $sync, 'with storage_type the synchronous schema is an instance (a clone)';
  isa_ok $sync, 'DBIO::Test::Schema';
  isa_ok $sync->storage, 'DBIO::Test::Storage', 'its storage, the declared driver';
  is_deeply $sync->storage->connect_info, [ 'dbi:DBIO:test:parity', '', '' ],
    'connected with the harness DSN, user and password, no async attribute';
  is(DBIO::Test::Schema->storage_type, '::DBI',
    'the shared schema class still declares no driver');
}

done_testing;
