package DBIO::Test::AsyncParity;
# ABSTRACT: The same ResultSet operations, synchronous and asynchronous, on one database, compared

use strict;
use warnings;

our $VERSION = '0.900005';

use Scalar::Util ();
use Test::More ();
use DBIO::Exception ();
use DBIO::Test::AsyncParity::Cases ();


# ---------------------------------------------------------------- the seams

my %KIND = map { $_ => 1 } qw(unsupported pending absent);

# The monikers the fixture and the cases use.
my @REQUIRED = qw(Artist CD Track OneKey);


sub table_version { 2 }


sub cases { return DBIO::Test::AsyncParity::Cases->cases }


sub parity_deviations { {} }


sub parity_seed {
  my ($class, $schema) = @_;
  my $fixture = DBIO::Test::AsyncParity::Cases->fixture;

  my %artist;
  for my $a (@{ $fixture->{artists} }) {
    my ($name, $rank) = @$a;
    $artist{$name} = $schema->resultset('Artist')->create({ name => $name, rank => $rank });
  }

  my %cd;
  for my $c (@{ $fixture->{cds} }) {
    my ($artist, $title, $year) = @$c;
    $cd{$title} = $artist{$artist}->create_related('cds', { title => $title, year => $year });
  }

  for my $t (@{ $fixture->{tracks} }) {
    my ($cd, $position, $title) = @$t;
    $cd{$cd}->create_related('tracks', { position => $position, title => $title });
  }

  return;
}


sub parity_reset {
  my ($class, $schema) = @_;
  $schema->resultset($_)->delete({ all => 1 }) for qw(OneKey Track CD Artist);
  return;
}


sub parity_capabilities {
  my ($class, $harness) = @_;
  my $async = $harness->async;
  my %have  = map { $_ => 1 } $async->transport_capabilities;

  if (my $refusal = $async->_pipeline_refusal) {
    $refusal->failure if $refusal->can('failure');
  }
  else {
    $have{pipeline} = 1;
  }
  $have{cancel} = 1 if $async->future_class->can('cancel');

  my $pool = $async->pool;
  $have{pool_queue} = 1
    if Scalar::Util::blessed($pool) && $pool->isa('DBIO::Storage::PoolBase');

  return sort keys %have;
}


sub parity_fault {
  my ($class, $schema, $harness, $name) = @_;
  DBIO::Exception->throw("this transport offers no fault '$name'");
}


sub parity_session_sql {
  return (
    'CREATE TEMPORARY TABLE parity_session_tmp (a INTEGER)',
    'SELECT a FROM parity_session_tmp',
  );
}


sub parity_unreachable {
  DBIO::Exception->throw('this transport offers no unreachable connection');
}


sub parity_sync_schema {
  my ($class, $harness) = @_;
  my $schema_class = $harness->{schema_class};
  DBIO::Exception->throw(
    'parity_sync_schema: the harness carries no schema_class and no DSN; '
  . 'the transport class must override parity_sync_schema'
  ) unless defined $schema_class and defined $harness->{dsn};

  # The harness's driver, declared on a clone so the shared schema class stays
  # undeclared (ADR 0067 §4); without one the class declares its own or core
  # refuses it.
  my $schema = $schema_class;
  if (defined(my $storage_type = $harness->{storage_type})) {
    $schema = $schema_class->clone;
    $schema->storage_type($storage_type);
  }
  return $schema->connect(
    $harness->{dsn}, $harness->{user} // '', $harness->{pass} // '',
  );
}

# ---------------------------------------------------- declarations, offline


sub check_declarations {
  my ($class) = @_;
  my %case = map { $_->{name} => $_ } @{ $class->cases };
  my $declared = $class->parity_deviations;
  my @problem;

  unless (ref $declared eq 'HASH') {
    return ('parity_deviations must return a hashref');
  }

  for my $name (sort keys %$declared) {
    my $decl  = $declared->{$name};
    my $label = "deviation '$name'";
    push @problem, "$label: unknown case" unless $case{$name};
    unless (ref $decl eq 'HASH') {
      push @problem, "$label: not a hash";
      next;
    }
    my $kind = $decl->{kind} // '';
    push @problem, "$label: kind must be 'unsupported', 'pending' or 'absent', not '$kind'"
      unless $KIND{$kind};
    push @problem, "$label: reason must be a regex (qr//)"
      unless ref $decl->{reason} eq 'Regexp';
    push @problem, "$label: the table already marks this case absent"
      if $case{$name} and $case{$name}{absent};
  }
  return @problem;
}

# What a case may deviate by: the transport's declarations plus the table's own
# absences, by case name.
sub _deviations {
  my ($class) = @_;
  my %dev = %{ $class->parity_deviations };
  for my $case (@{ $class->cases }) {
    $dev{ $case->{name} } = { kind => 'absent', reason => $case->{absent} }
      if $case->{absent};
  }
  return \%dev;
}

# ------------------------------------------------------------ the run itself


sub results {
  my ($class, %opt) = @_;
  my $harness = $opt{harness}
    or DBIO::Exception->throw('results() needs harness => a DBIO::Test::AsyncHarness');
  my $schema_class = $opt{schema_class} // 'DBIO::Test::Schema';
  my $schema = $harness->schema;

  my @missing = grep { !eval { $schema->source($_); 1 } } @REQUIRED;
  DBIO::Exception->throw(
    "the connected schema has no source " . join(', ', map {"'$_'"} @missing)
  . "; the case table is written for $schema_class"
  ) if @missing;

  my @cases = @{ $class->cases };
  if (my $only = $opt{only}) {
    my %want = map { $_ => 1 } @$only;
    @cases = grep { $want{ $_->{name} } } @cases;
  }

  my $deviations = $class->_deviations;

  my $sync_schema;
  my %provided = map { $_ => 1 } $class->parity_capabilities($harness);
  my $env = {
    harness      => $harness,
    capabilities => \%provided,
    sync_schema  => sub { $sync_schema ||= $class->parity_sync_schema($harness) },
    fault        => sub { $class->parity_fault($schema, $harness, @_) },
    session_sql  => [ $class->parity_session_sql($harness) ],
    unreachable  => sub {
      my $secret = 'parity-secret-' . $$;
      return ($class->parity_unreachable($harness, $secret), $secret);
    },
  };

  my @results = map { $class->_run_case($_, $deviations->{ $_->{name} }, $schema, $env) } @cases;

  if ($sync_schema) {
    eval { $sync_schema->storage->disconnect; 1 };
  }
  return @results;
}


sub summary_line {
  my ($class, $results) = @_;
  my @dev    = grep { $_->{status} eq 'deviation' } @$results;
  my @absent = grep { $_->{status} eq 'absent' } @$results;
  my @skip   = grep { $_->{status} eq 'skipped' } @$results;
  my @part;

  push @part, scalar(@dev) . ' deviation' . (@dev == 1 ? '' : 's') . ': '
    . join(', ', map {
        sprintf '%02d %s (%s)', $_->{no}, $_->{case}, $_->{deviation}
      } @dev)
    if @dev;
  push @part, scalar(@absent) . ' absent: '
    . join(', ', map { sprintf '%02d %s', $_->{no}, $_->{case} } @absent)
    if @absent;
  push @part, scalar(@skip) . ' skipped: '
    . join(', ', map { sprintf '%02d %s (%s)', $_->{no}, $_->{case}, $_->{message} } @skip)
    if @skip;

  return @part ? join('; ', @part) : undef;
}


sub run {
  my ($class, %opt) = @_;

  my @problem = $class->check_declarations;
  Test::More::ok(!@problem, 'the parity declarations are whole')
    or Test::More::diag(join "\n", @problem);

  my @results = $class->results(%opt);
  for my $r (@results) {
    my $label = sprintf '%02d %s: %s', $r->{no}, $r->{case}, $r->{status};
    $label .= " ($r->{deviation})" if $r->{status} eq 'deviation';
    $label .= " ($r->{message})"   if $r->{status} eq 'skipped';
    if ($r->{status} eq 'fail') {
      Test::More::ok(0, $label);
      Test::More::diag(sprintf 'case %02d %s: %s', $r->{no}, $r->{case}, $r->{message});
    }
    else {
      Test::More::ok(1, $label);
    }
  }

  my $line = $class->summary_line(\@results);
  Test::More::diag($line) if defined $line;
  return;
}

# One case: drive each way after a reset and a seed, compare, and turn what
# happened into one answer.
sub _run_case {
  my ($class, $case, $deviation, $schema, $env) = @_;
  my $harness = $env->{harness};
  my %r = (no => $case->{no}, case => $case->{name}, kind => $case->{kind});

  # A case that needs a capability the transport does not have is not run; it
  # is a result of its own and names what is missing (see "Capabilities").
  if (my @missing = grep { !$env->{capabilities}{$_} } @{ $case->{requires} || [] }) {
    return { %r, status => 'skipped', missing => \@missing,
             message => 'needs ' . join(', ', @missing) };
  }

  my ($sync, $async);
  my $driven = eval {
    unless ($case->{kind} eq 'async-only') {
      $class->parity_reset($schema, $harness);
      $class->parity_seed($schema, $harness);
      $sync = $class->_leg($case, 'sync', $schema, $env);
    }
    $class->parity_reset($schema, $harness);
    $class->parity_seed($schema, $harness);
    $async = $class->_leg($case, 'async', $schema, $env);
    1;
  };
  my $run_error = $driven ? undef : ($@ || 'unknown error');

  my $cleaned = eval { $class->parity_reset($schema, $harness); 1 };
  my $clean_error = $cleaned ? undef : ($@ || 'unknown error');

  return { %r, status => 'fail', message => "the run itself failed: $run_error" }
    if defined $run_error;
  return { %r, status => 'fail', message => "cleanup failed: $clean_error" }
    if defined $clean_error;

  my $verdict = $class->_judge($case, $sync, $async);

  if ($deviation) {
    my $declared = $deviation->{kind};
    return { %r, status => 'fail',
             message => "stale deviation: declared $declared"
                      . ' but the case passes' }
      unless defined $verdict;
    return { %r, status => 'fail',
             message => "the deviation does not match its declared reason $deviation->{reason}"
                      . " -- got: $verdict" }
      unless $verdict =~ $deviation->{reason};
    return {
      %r,
      status    => $declared eq 'absent' ? 'absent' : 'deviation',
      deviation => $declared,
      message   => $verdict,
    };
  }

  return { %r, status => 'fail', message => $verdict } if defined $verdict;
  return { %r, status => 'pass', message => '' };
}

# One way of one case. Never dies for what the case does: an exception is the
# outcome. The state the case left behind is read through the synchronous path
# either way.
sub _leg {
  my ($class, $case, $way, $schema, $env) = @_;
  my $harness = $env->{harness};
  my %out;

  my @raw;
  my $ok = eval {
    if ($way eq 'sync') {
      @raw = $case->{sync}->($schema, $env);
    }
    else {
      my $future = $case->{async}->($schema, $env);
      @raw = $harness->await($future);
    }
    1;
  };
  if ($ok) {
    my $norm = $case->{norm} || sub { [ @_ ] };
    my $value;
    if (eval { $value = $norm->(@raw); 1 }) {
      %out = (ok => 1, value => $value);
    }
    else {
      my $e = $@ || 'unknown error';
      %out = (error => $e, class => _class_of($e), text => _text_of($e));
    }
  }
  else {
    my $e = $@ || 'unknown error';
    %out = (error => $e, class => _class_of($e), text => _text_of($e));
  }

  if (my $observe = $case->{observe}) {
    my $seen = eval { $observe->($schema) };
    $out{observed} = $@ ? 'observe failed: ' . _text_of($@) : $seen;
  }
  return \%out;
}

# core throws every string as a DBIO::Exception; an unblessed error is that.
sub _class_of {
  my ($e) = @_;
  return Scalar::Util::blessed($e) ? ref($e) : 'DBIO::Exception';
}

sub _text_of {
  my ($e) = @_;
  my $t = "$e";
  $t =~ s/\n.*//s;
  return $t;
}

# The verdict on one case: undef when it is right, else the message.
sub _judge {
  my ($class, $case, $sync, $async) = @_;
  my $want_error = $case->{expect_error};

  if ($case->{kind} eq 'async-only') {
    return _judge_error($want_error, 'async', $async) if $want_error;
    return "the asynchronous way threw $async->{class}: $async->{text}" unless $async->{ok};
    if (exists $case->{expect}) {
      return 'the asynchronous way answered ' . _show($async->{value})
           . ', expected ' . _show($case->{expect})
        unless _same($async->{value}, $case->{expect});
    }
    return undef;
  }

  if ($want_error) {
    for my $pair ([ sync => $sync ], [ async => $async ]) {
      my $problem = _judge_error($want_error, @$pair);
      return $problem if defined $problem;
    }
    return "the exception classes differ: sync $sync->{class}, async $async->{class}"
      unless $sync->{class} eq $async->{class};
    return undef;
  }

  if (!$sync->{ok} and !$async->{ok}) {
    return "the case failed on both ways -- sync: $sync->{class}: $sync->{text}"
         . " -- async: $async->{class}: $async->{text}";
  }
  return "the ways differ: sync answered, async threw $async->{class}: $async->{text}"
    if $sync->{ok} and !$async->{ok};
  return "the ways differ: sync threw $sync->{class}: $sync->{text}, async answered"
    if !$sync->{ok} and $async->{ok};

  return 'the ways differ in the result: sync ' . _show($sync->{value})
       . ', async ' . _show($async->{value})
    unless _same($sync->{value}, $async->{value});
  return 'the ways differ in what they left behind: sync ' . _show($sync->{observed})
       . ', async ' . _show($async->{observed})
    unless _same($sync->{observed}, $async->{observed});
  return undef;
}

sub _judge_error {
  my ($want, $way, $out) = @_;
  return "the $way way threw nothing, an exception was expected (answered "
       . _show($out->{value}) . ')'
    if $out->{ok};
  return "the $way way threw '$out->{text}', which does not match $want"
    if ref $want eq 'Regexp' and $out->{text} !~ $want;
  return undef;
}

sub _show {
  my ($v) = @_;
  return 'undef' unless defined $v;
  return '[' . join(', ', map { _show($_) } @$v) . ']' if ref $v eq 'ARRAY';
  return '{' . join(', ', map { "$_ => " . _show($v->{$_}) } sort keys %$v) . '}'
    if ref $v eq 'HASH';
  return ref $v if ref $v;
  return "'$v'";
}

sub _same {
  my ($got, $want) = @_;
  return 1 if !defined $got and !defined $want;
  return 0 if !defined $got or !defined $want;
  return 0 if ref $got ne ref $want;
  if (ref $want eq 'ARRAY') {
    return 0 unless @$got == @$want;
    for my $i (0 .. $#$want) { return 0 unless _same($got->[$i], $want->[$i]) }
    return 1;
  }
  if (ref $want eq 'HASH') {
    return 0 unless keys %$got == keys %$want;
    for my $k (keys %$want) {
      return 0 unless exists $got->{$k} and _same($got->{$k}, $want->{$k});
    }
    return 1;
  }
  return 0 if ref $want;
  return $got eq $want ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::AsyncParity - The same ResultSet operations, synchronous and asynchronous, on one database, compared

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  package DBIO::PostgreSQL::EV::Test::AsyncParity;
  use base 'DBIO::Test::AsyncParity';

  sub parity_deviations {{
    'upsert' => {
      kind   => 'pending',                  # not built yet
      reason => qr/upsert/,
    },
    'row-copy' => {
      kind   => 'unsupported',              # this transport cannot do it
      reason => qr/copy_async/,
    },
  }}

  # the seams with a working default, only when the dist needs its own:
  sub parity_reset {
    my ($class, $schema, $harness) = @_;
    $class->SUPER::parity_reset($schema, $harness);
    $schema->storage->dbh_do(sub { $_[1]->do('ALTER SEQUENCE ... RESTART') });
  }

  1;

and in the test file C<< DBIO::PostgreSQL::EV::Test::AsyncParity->run(...) >>.

=head1 DESCRIPTION

An async transport (C<future_io>, C<ev>, ...) answers the same ORM surface a
blocking connection does. This module is the one list of cases that proves it,
stated once in core: every case is driven B<twice> on the B<same> connected
schema and the same database -- once through the synchronous method, once
through its C<*_async> twin -- and what the two ways produced is compared.
Compared are the rows (as plain data), the counts, the state the case left
behind, and, for the cases that are about failing, the exception class.

The suite takes the harness (L<DBIO::Test::AsyncHarness>) a transport already
has and is called by a thin test file:

  use DBIO::PostgreSQL::EV::TestHarness;
  use DBIO::Test::AsyncParity;

  DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;
  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
    schema_class => 'DBIO::Test::Schema',
    storage_type => 'DBIO::PostgreSQL::Storage',  # the driver; the schema has none
  );

  DBIO::Test::AsyncParity->run(harness => $h, schema_class => 'DBIO::Test::Schema');
  done_testing;

There are exactly three acceptable answers for a case:

=over 4

=item pass

The two ways agree, and the case's own expectation (if it has one) holds.

=item deviation

The transport states, in L</parity_deviations>, that this case does not agree
and why. A declared deviation is a B<test>, not a skip: the case is driven, it
has to fail the way the declaration says, and a declared deviation of a case
that passes is a failure -- the declaration is stale.

=item absent

Core has no asynchronous twin for the operation at all (C<populate>). The table
says so itself; the case is driven, the missing twin is observed, and it turns
red when core grows one.

=back

Anything else is a failure, and a failure names the number and the name of the
case. A case is not skipped by choice: the only exception is a missing
capability (L</Capabilities>), and then it is a test of its own, labelled
C<skipped> with the capability named, and listed on the closing line. Without
a live harness the file is skipped as a whole by the harness, which is where
that decision belongs.

The model is L<DBIO::Test::Conformance> (ADR 0060): one table in core, the
transport answers it, a deviation is declared and checked.

=head1 METHODS

=head2 table_version

The version of the case table, 2 (version 1 had the 41 cases of the
ResultSet surface; 2 adds the cases of the async scaffold, 42 to 56).

=head2 cases

  my $cases = DBIO::Test::AsyncParity->cases;

The arrayref of cases, in number order, a fresh copy.
See L<DBIO::Test::AsyncParity::Cases>.

=head2 parity_deviations

Seam with a default: none. See L</Declaring deviations>.

=head2 parity_seed

Seam with a working default, see L</WRITING A TRANSPORT'S CLASS>.

=head2 parity_reset

Seam with a working default, see L</WRITING A TRANSPORT'S CLASS>.

=head2 parity_capabilities

  my @names = $class->parity_capabilities($harness);

The capabilities of the transport under test, the names a case lists in
C<requires>. The default gives what can be read off the transport: its
C<transport_capabilities> (C<listen>, C<notify>, ...), C<pipeline> when it
overrides the pipeline seams (L<DBIO::Storage::Async/_pipeline_refusal>),
C<cancel> when its Future class can cancel, and C<pool_queue> when its pool is
a L<DBIO::Storage::PoolBase>. A transport adds what only it knows (see
L</Capabilities>) and calls this method first.

=head2 parity_fault

  my $guard = $class->parity_fault($schema, $harness, $name, @args);

Make the transport fail in the way C<$name> says, until the returned guard
goes out of scope. The default throws: a transport that offers a fault lists
C<fault:NAME> in L</parity_capabilities> and implements it here. Names:
C<rollback_fails> (a C<ROLLBACK> of a transaction is not confirmed),
C<disconnect> (the connection of the transaction context passed as the first
argument is lost).

=head2 parity_session_sql

  my ($set, $probe) = $class->parity_session_sql($harness);

Two statements for the case C<session-reset>: one that leaves state in the
session of the connection it runs on, and one that fails when that state is
gone. The default is a temporary table, C<CREATE TEMPORARY TABLE> and a
C<SELECT> from it. An engine without that syntax overrides it.

=head2 parity_unreachable

  my $schema = $class->parity_unreachable($harness, $password);

A connected schema in the harness's async mode whose connection cannot be
made, built with C<$password>; the case C<connect-error-masked> asks it for
the count of artists and checks the error does not carry the password. The
default throws; a transport that implements it lists C<unreachable_connection>
in L</parity_capabilities>.

=head2 parity_sync_schema

Seam with a working default, see L</WRITING A TRANSPORT'S CLASS>.

=head2 check_declarations

  my @problems = $class->check_declarations;

What can be checked without a server: every declared deviation names a case of
the table, has kind C<unsupported>, C<pending> or C<absent>, a regex C<reason>,
and does not redeclare a case the table itself marks
absent. Returns the problems as strings, none when the declaration is whole.
L</run> makes it the first test.

=head2 results

  my @results = $class->results(harness => $h, schema_class => 'DBIO::Test::Schema');
  my @results = $class->results(harness => $h, only => [ 'find-pk' ]);

Drive every case against the harness's schema and return one hashref per case:
C<< { no, case, kind, status, message } >> and, for C<deviation>, the
C<deviation> kind. It does not touch
L<Test::More>. C<status> is C<pass>, C<deviation>, C<absent> or C<fail>.
C<only> restricts the run to the named cases.

C<schema_class> names the schema the table was written for
(default C<DBIO::Test::Schema>); the runner only uses it to say what is
missing when the connected schema lacks a source the table needs.

=head2 summary_line

  my $line = $class->summary_line(\@results);

The one line that closes a run: the declared deviations with their kinds and
the absent operations. C<undef> when there is nothing to say.

=head2 run

  DBIO::Test::AsyncParity->run(harness => $h, schema_class => 'DBIO::Test::Schema');

Write the tests: first one for the declarations (L</check_declarations>), then
one per case, labelled with the case number, its name and its status. A
failure's message is printed with C<diag>, the closing summary line too. Does
not call C<done_testing>.

=head1 WRITING A TRANSPORT'S CLASS

Every method is a class method. Nothing must be provided: a transport that
answers every case needs no class of its own and calls
C<< DBIO::Test::AsyncParity->run >> directly.

=over 4

=item parity_deviations

Hashref keyed by case name (see L</CASES>), default C<{}>. See
L</Declaring deviations>.

=item parity_seed($schema, $harness)

Put the fixture of L<DBIO::Test::AsyncParity::Cases/fixture> into the empty
database: three artists, four CDs, four tracks. The default creates them
through the ResultSet API, without naming a key, and works on any schema built
from L<DBIO::Test::Schema>. Override when the database wants something else
(rows by C<COPY>, a different schema).

=item parity_reset($schema, $harness)

Remove everything a case could have left and everything the seed made, so the
next run starts empty. The default deletes the rows of C<OneKey>, C<Track>,
C<CD> and C<Artist>, children first, with one C<DELETE> each. It runs before each way of
each case and once more after the case, also after a failure. Override it when
the tables carry something it must not delete or when a sequence is to be put
back.

=item parity_sync_schema($harness)

A second, purely synchronous connection to the same database, for the case
that is about an C<*_async> call on a connection without an async mode. The
default connects the harness's schema class with the harness's own DSN, user
and password and no C<async> attribute. When the harness carries a
C<storage_type> (see L<DBIO::Test::AsyncHarness/new>), it connects a clone of
the schema class declaring that driver, as the harness's own schema does;
otherwise the schema class must declare its driver itself (ADR 0067).
Disconnected when the run ends.

=back

=head1 Declaring deviations

C<parity_deviations> returns a hashref keyed by case name:

  { case_name => { kind => 'unsupported' | 'pending' | 'absent',
                   reason => qr/.../ } }

=over 4

=item kind C<unsupported>

The transport cannot do it, by design. Permanent.

=item kind C<pending>

The transport does not do it yet. The C<reason> says why.

=item kind C<absent>

The operation has no asynchronous twin. Cases of the table that are absent in
core carry that themselves; a transport only uses it for its own gap.

=item reason

A regex the failure's message has to match. The message is what the runner
reports for the case: the exception the asynchronous way threw, or the
difference between the two ways.

=back

The run ends with one line, printed by L</run> and returned by
L</summary_line>:

  2 deviations: 34 upsert (pending), 27 row-copy (unsupported); 1 absent: 41 populate

=head1 Capabilities

A case may list C<< requires => [ 'name', ... ] >>. A transport that does not
have every one of them does not run the case: its result is C<skipped>, a
passing test labelled C<NN name: skipped (needs NAME)>, and the closing line
lists it. The capabilities of a transport are the names
L</parity_capabilities> answers; the default reads them off the transport:

  listen, notify, ...  the transport's transport_capabilities
  pipeline             it implements the pipeline seams
  cancel               its Future class can cancel
  pool_queue           its pool is a DBIO::Storage::PoolBase

A transport adds the ones only it knows, and implements the seams behind them:

  fault:rollback_fails       parity_fault 'rollback_fails'
  fault:disconnect           parity_fault 'disconnect'
  unreachable_connection     parity_unreachable

A skipped case is a gap of that transport, not of the table. The capability is
the single place that decides, so a case never skips by a driver name.

=head1 CASES

The table is L<DBIO::Test::AsyncParity::Cases>. A case has a number, the name a
declaration is keyed by, and a kind: C<direct> (the synchronous method has an
C<*_async> twin), C<composed> (core has none, the case composes the operation
from the ones it has) or C<async-only> (nothing to compare against; the case
states what the asynchronous way must answer).

  Reads
   1 find-pk             find by primary key
   2 find-unique         find through a named unique constraint (ADR 0034)
   3 find-miss           find that matches nothing: undef, no error
   4 find-rel-key        find whose key is a relationship value
   5 search-all          search with a condition, all rows
   6 order-rows-offset   order_by with rows and offset
   7 group-by            group_by over a column subset
   8 prefetch            has_many prefetch, collapsed
   9 join                join on a relationship
  10 search-related      related resultset of a row (composed)
  11 first               first row of an ordered set
  12 single              single row by a condition
  13 count               count of a condition
  14 count-literal       count with a literal SQL condition
  15 results-exist       the EXISTS question, hit and miss
  16 rsc-all             all values of a column
  17 rsc-single          single value of a column
  18 rsc-min-max-sum     min, max and sum of a column
  19 rsc-func            aggregate by name
  Writes
  20 create              create a row
  21 create-cascade      create with nested related rows (composed)
  22 row-insert          insert a new_result row
  23 row-update          update a fetched row
  24 row-update-rs-loop  update of a set, row by row (composed)
  25 row-delete          delete a fetched row (OneKey)
  26 row-delete-rs-loop  delete of a set, row by row (composed)
  27 row-copy            copy a row (OneKey)
  28 row-reload          get_from_storage and discard_changes
  29 update-or-insert    update_or_insert of an unstored row
  30 find-or-create      find_or_create of a missing row
  31 find-or-new         find_or_new of a missing row
  32 update-or-create    update_or_create of a present row
  33 update-or-new       update_or_new of a present row
  34 upsert              single-statement upsert (capability)
  Transactions and context
  35 txn-commit          txn_do / txn_do_async that commits
  36 txn-rollback        txn_do / txn_do_async that fails and rolls back
  37 txn-with-context    a ResultSet bound to the transaction context (composed)
  38 txn-adopts-future   the returned Future is adopted (async-only)
  Errors
  39 err-unique          a unique violation: the same exception class
  40 async-on-sync-connection   *_async without an async mode croaks (async-only)
  No async twin
  41 populate            named, not invented (absent)
  Pipeline and cancel
  42 pipeline-commit     a pipeline of two inserts (pipeline)
  43 pipeline-fail       a failing statement fails the batch, the pool serves (pipeline)
  44 cancel-txn          a cancelled transaction rolls back (cancel)
  45 cancel-statement    a cancelled statement gives its connection back (cancel)
  46 cancel-batch        a cancelled pipeline retires its connection (pipeline, cancel)
  Failure inside a transaction
  47 rollback-failed     a ROLLBACK not confirmed retires the connection (fault:rollback_fails)
  48 txn-statement-in-flight        COMMIT waits for a statement still running
  49 txn-statement-in-flight-fails  a dropped statement that fails fails the transaction
  50 disconnect-in-txn   the connection is lost mid-transaction (fault:disconnect)
  Pool and session
  51 pool-self-deadlock  a call queued for the transaction's own pool is refused (pool_queue)
  52 pool-max-waiters    the queue is bounded (pool_queue)
  53 pool-acquire-timeout  a wait is bounded (pool_queue)
  54 session-reset       session state is gone after release (pool_queue)
  Transport
  55 listen-notify       LISTEN and NOTIFY (listen, notify)
  56 connect-error-masked  a connect error carries no password (unreachable_connection)

Cases 1 to 40 cover the ResultSet surface that has an async twin; 41 names the
one operation of that surface that has no twin, so that its absence is a line
of the run and not a gap in the list. Cases 42 to 56 run the pipeline, cancel,
transaction, pool and transport behaviour of the async layer on a real
transport. Not in the table:
a disconnect in the middle of a deploy and the rotation of an AccessBroker's
credentials need a harness of their own; core covers both offline
(F<t/test/64_async_deploy_across_disconnect.t>,
F<t/test/63_async_pool_set_access_broker_built.t>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
