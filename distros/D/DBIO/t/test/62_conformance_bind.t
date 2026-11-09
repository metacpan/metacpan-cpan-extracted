use strict;
use warnings;

use Test::More;
use lib 't/lib';

# The Bind list of DBIO::Test::Conformance (ADR 0060, karr k330): the case
# table, the runner's value checks, and the proof that every operation of the
# list goes through the data seams -- which is what lets an async transport
# run it. Against a mock server, never a database; a scenario bends one thing
# and asserts that the case turns red.

use DBIO::Test::Conformance;
use DBIO::Test::Conformance::Cases::Bind;
use DBIO::Schema::Type ();
use DBIO::Test::Storage;
use MockConformanceServer;

my $MOCK = 'MockConformanceServer';

# ------------------------------------------------------------ the case table

my $cases = DBIO::Test::Conformance::Cases::Bind->cases;
is scalar(@$cases), 10, 'the Bind list holds 10 cases: B1..B10';
is(DBIO::Test::Conformance->table_version('Bind'), 1, 'table version 1 for Bind');

is_deeply [ map { $_->{name} } @$cases ], [qw(
  bind-empty-string bind-digit-string-leading-zero
  bind-integer-string-in-expression bind-long-string bind-non-ascii
  bind-binary bind-lob-empty-and-large bind-lob-row-operations
  bind-question-mark-in-literal bind-numeric-exact
)], 'B1..B10 in the order of the ADR appendix';

my %OPS = map { $_ => 1 } qw(create find search update populate int_first);

{
  my %kind = map { $_ => 1 } DBIO::Test::Conformance->expectation_kinds;
  my %seen;
  my @bad;
  for my $c (@$cases) {
    my $n = $c->{name};
    push @bad, "$n: not bind-kebab-case" unless $n =~ /^bind-[a-z0-9]+(?:-[a-z0-9]+)*$/;
    push @bad, "$n: duplicate" if $seen{$n}++;
    push @bad, "$n: since is not 1" unless ($c->{since} // '') eq '1';
    push @bad, "$n: no cards" unless ref $c->{cards} eq 'ARRAY' && @{ $c->{cards} };
    push @bad, "$n: no expect" unless ref $c->{expect} eq 'ARRAY' && @{ $c->{expect} };

    my $schema_class = eval { DBIO::Test::Conformance->_build_schema_class($c) };
    if (!$schema_class or !$schema_class->isa('DBIO::Schema')) {
      push @bad, "$n: the sources do not build a schema class: " . ($@ || 'no class');
      next;
    }
    my %src = map { $_->{name} => $_ } @{ $c->{input}{sources} };
    push @bad, "$n: subject names no source" unless $c->{subject} && $src{ $c->{subject}{source} };

    # only the base types, and varchar with a size: the bounded string every
    # driver writes, as the DDL list uses it (text is a LOB on Oracle, karr k366)
    for my $def (values %src) {
      my %col = @{ $def->{columns} };
      for my $col (sort keys %col) {
        my $t = $col{$col}{data_type};
        push @bad, "$n: column $col of $def->{name} has the type $t, not a base type"
          unless DBIO::Schema::Type::is_base_type($t)
              || ($t eq 'varchar' && defined $col{$col}{size});
      }
    }

    for my $e (@{ $c->{expect} }) {
      push @bad, "$n: an expect entry is not a one-key hash" if ref $e ne 'HASH' or keys(%$e) != 1;
      my ($k, $a) = %$e;
      push @bad, "$n: unknown expectation kind $k" unless $kind{$k};
      my $def = $src{ $a->{source} // '' };
      push @bad, "$n: $k names the unknown source" unless $def;
      next unless $def;
      my %col = @{ $def->{columns} };
      if ($k eq 'bind_roundtrip') {
        push @bad, "$n: unknown column $a->{column}" unless $col{ $a->{column} };
        push @bad, "$n: the value column must be nullable ($a->{column})"
          if $col{ $a->{column} } && !$col{ $a->{column} }{is_nullable};
        push @bad, "$n: unknown operation $_" for grep { !$OPS{$_} } @{ $a->{ops} };
        push @bad, "$n: no values" unless @{ $a->{values} || [] };
        my %v;
        $v{$_}++ for @{ $a->{values} };
        push @bad, "$n: the values of one roundtrip must differ" if grep { $_ > 1 } values %v;
        # a search counts the rows holding the value: it needs one to exist
        my $has_row = 0;
        for my $op (@{ $a->{ops} }) {
          push @bad, "$n: $op comes before any operation that makes a row" if ($op eq 'find' or $op eq 'search') and !$has_row;
          $has_row = 1 if $op =~ /\A(?:create|update|populate)\z/;
        }
      }
      if ($k eq 'bind_lob_ops') {
        push @bad, "$n: unknown column" unless $col{ $a->{column} } && $col{ $a->{label_column} };
        push @bad, "$n: bind_lob_ops needs an auto-increment key"
          unless $col{id}{is_auto_increment};
      }
    }
  }
  is_deeply \@bad, [], 'every Bind case is well formed' or diag join "\n", @bad;
}

# the large and binary values are built, and are what the ADR says
{
  my %by = map { $_->{name} => $_ } @$cases;
  my $values = sub { $by{ $_[0] }{expect}[$_[1] // 0]{bind_roundtrip}{values} };

  is_deeply [ map { length } @{ $values->('bind-long-string') } ], [ 4001, 8001, 32769, 70000 ],
    'bind-long-string: 4 001, 8 001, 32 769 and 70 000 characters';
  my $bin = $values->('bind-binary');
  is_deeply [ map { ord } split //, $bin->[0] ], [ 0 .. 255 ], 'bind-binary: every byte value once, in order';
  is length($bin->[1]), 9000, '... and 9 000 bytes';
  my $na = $values->('bind-non-ascii');
  ok scalar(grep { /[^\x00-\x7f]/ } @$na) == @$na, 'bind-non-ascii: every value holds non-ASCII';
  ok scalar(grep { length($_) == 1 } @$na), '... at one character';
  ok scalar(grep { length($_) >= 5000 } @$na) >= 2, '... and at 5 000 and more';
  is $by{'bind-lob-empty-and-large'}{expect}[0]{bind_roundtrip}{values}[0], '', 'bind-lob-empty-and-large: the empty value';
  is length($by{'bind-lob-empty-and-large'}{expect}[1]{bind_roundtrip}{values}[1]), 100000, '... and 100 000 bytes';
  is_deeply $values->('bind-digit-string-leading-zero'), [ '01234', '007' ], 'bind-digit-string-leading-zero: the strings';
  is $values->('bind-numeric-exact')->[0], '1234567890123456.7890', 'bind-numeric-exact: the exact numeric';
}

{
  my $a = DBIO::Test::Conformance::Cases::Bind->cases;
  $a->[0]{name} = 'tampered';
  is(DBIO::Test::Conformance::Cases::Bind->cases->[0]{name}, 'bind-empty-string', 'cases() hands out a copy');
}

# ------------------------------------------------------------ the right server

sub statuses {
  my (%o) = @_;
  my @r = $MOCK->results('Bind', %o);
  return { map { $_->{case} => $_ } @r };
}

{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  my @r = $MOCK->results('Bind');
  is scalar(@r), 10, 'one result per case';
  is_deeply [ grep { $_->{status} ne 'pass' } @r ], [],
    'the correct mock answers every Bind case correctly'
    or diag join "\n", map { "$_->{case}: $_->{status}: $_->{message}" } grep { $_->{status} ne 'pass' } @r;
  is $MockConformanceServer::CALLS{upgrade}, undef, 'no upgrade, no diff: a Bind case installs and binds';
  is $MockConformanceServer::CALLS{fact}, undef, '... and asks no fact';
}

# a value is not a declaration: the diff postcondition is not asked of a Bind case
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{diff_nonempty} = 1;
  is statuses(only => ['bind-empty-string'])->{'bind-empty-string'}{status}, 'pass',
    'a non-empty diff does not fail a Bind case';
}

# ------------------------------------------- a server that gets it wrong: red

my @WRONG = (
  # quirk               case                                  message
  [ empty_to_null    => 'bind-empty-string',                  qr/Val\.s create: expected '', read back NULL/ ],
  [ digit_to_int     => 'bind-digit-string-leading-zero',     qr/Val\.v create: expected '01234', read back '1234'/ ],
  [ loose_search     => 'bind-integer-string-in-expression',  qr/search: '5\.0' found \d+ rows, expected 1/ ],
  [ truncate_long    => 'bind-long-string',                   qr/Val\.v create: expected 4001 characters.*read back 4000 characters.*first difference at position 4000/ ],
  [ truncate_long    => 'bind-non-ascii',                     qr/Val\.v create: expected 5\d{3} characters/ ],
  [ truncate_long    => 'bind-lob-empty-and-large',           qr/Lob\.t create: expected 100000 characters/ ],
  [ numeric_float    => 'bind-numeric-exact',                 qr/Num\.v create: expected '1234567890123456\.7890'/ ],
  [ update_mutates_hash   => 'bind-lob-row-operations',       qr/update: the caller's hash/ ],
  [ populate_mutates_rows => 'bind-lob-row-operations',       qr/populate: the caller's row 0/ ],
  [ literal_miscount => 'bind-question-mark-in-literal',      qr/literal SQL: the bind 'x' found 0 rows, expected 1/ ],
);
for my $w (@WRONG) {
  my ($quirk, $case, $message) = @$w;
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{$quirk} = 1;
  my $s = statuses(only => [$case])->{$case};
  is $s->{status}, 'fail', "$case: the quirk $quirk is a failure";
  like $s->{message}, $message, '... and the message names the value and the operation';

  MockConformanceServer::reset_state();
  is statuses(only => [$case])->{$case}{status}, 'pass', '... and the same case passes without it';
}

# B1's second half: an integer column that takes '' is a failure
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  no warnings 'redefine';
  my $orig = \&MockConformanceServer::_insert;
  local *MockConformanceServer::_insert = sub {
    my ($schema, $moniker, $vals) = @_;
    return +{ %$vals } if exists $vals->{n} and ($vals->{n} // 'x') eq '';
    return $orig->(@_);
  };
  my $s = statuses(only => ['bind-empty-string'])->{'bind-empty-string'};
  is $s->{status}, 'fail', 'an integer column that accepts an empty string is a failure';
  like $s->{message}, qr/accepted a row it must reject/, '... as a row the server accepted';
}

# ------------------------------------------------------- refusals and answers

{
  local $ENV{AUTHOR_TESTING} = 1;
  my $name = 'bind-non-ascii';
  MockConformanceServer::reset_state();
  $MockConformanceServer::REFUSALS{$name} = { kind => 'server', reason => qr/character set cannot hold it/ };
  $MockConformanceServer::QUIRK{throw}{$name} = sub {
    $_[0]->throw_exception("bind refused for table 'val', column 'v': the character set cannot hold it");
  };
  is statuses(only => [$name])->{$name}{status}, 'refused', 'a declared refusal of a Bind case is refused';

  MockConformanceServer::reset_state();
  $MockConformanceServer::REFUSALS{'bind-binary'} = { kind => 'server', reason => qr/./ };
  my $s = statuses(only => ['bind-binary'])->{'bind-binary'};
  is $s->{status}, 'fail', 'a refusal that runs through is a failure';
  like $s->{message}, qr/stale refusal/, '... as a stale refusal';

  # a deviation: the engine stores what it stores, on the record
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{numeric_float} = 1;
  $MockConformanceServer::REFUSALS{'bind-numeric-exact'} = {
    kind => 'deviation', fact => qr/Num\.v create: expected '1234567890123456\.7890'/,
    reason => 'the engine keeps numeric as a double',
  };
  $s = statuses(only => ['bind-numeric-exact'])->{'bind-numeric-exact'};
  is $s->{status}, 'deviation', 'a declared deviation answers a Bind case';
}

# refused area Bind
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  $MockConformanceServer::AREAS{Bind} = { kind => 'pending', card => 'k99', reason => qr/bind is not built yet/ };
  $MockConformanceServer::QUIRK{throw} = {
    map {
      my $c = $_;
      my ($def) = grep { $_->{name} eq $c->{subject}{source} } @{ $c->{input}{sources} };
      my $col = $c->{subject}{column};
      ($c->{name} => sub { $_[0]->throw_exception("bind refused for table '$def->{table}', column '$col': bind is not built yet") })
    } @$cases
  };
  my @r = $MOCK->results('Bind');
  is_deeply [ map { $_->{status} } @r ], [ ('pending') x 10 ], 'a driver that refuses the Bind area is green: every case pending';
  is(MockConformanceServer->summary_line(\@r), 'Bind area pending (karr k99): 10 cases', '... with one summary entry for the area');

  delete $MockConformanceServer::QUIRK{throw}{'bind-binary'};
  my $s = statuses();
  is $s->{'bind-binary'}{status}, 'fail', 'a Bind case that runs through despite the refused area fails';
  like $s->{'bind-binary'}{message}, qr/stale refusal/, '... as a stale refusal';
}

# answered through, scalar and hash
{
  my $name = 'bind-empty-string';
  my %quiet = (AUTHOR_TESTING => '', RELEASE_TESTING => '');
  MockConformanceServer::reset_state();
  $MockConformanceServer::QUIRK{empty_to_null} = 1;

  $MockConformanceServer::THROUGH = 1;
  { local @ENV{keys %quiet} = values %quiet;
    is statuses(only => [$name])->{$name}{status}, 'todo', 'a scalar 1 does not cover Bind: todo, not fail'; }
  { local @ENV{keys %quiet} = values %quiet; local $ENV{AUTHOR_TESTING} = 1;
    is statuses(only => [$name])->{$name}{status}, 'fail', '... and fails under AUTHOR_TESTING'; }

  $MockConformanceServer::THROUGH = { DDL => 1, Diff => 1, Bind => 1 };
  { local @ENV{keys %quiet} = values %quiet;
    is statuses(only => [$name])->{$name}{status}, 'fail', 'a hash with Bind => 1 answers Bind: red'; }
  $MockConformanceServer::THROUGH = { Bind => 0 };
  { local @ENV{keys %quiet} = values %quiet;
    is statuses(only => [$name])->{$name}{status}, 'todo', 'Bind => 0 is todo'; }
}

# run() over the mock, and without a server
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  subtest 'run(Bind) over the mock' => sub {
    MockConformanceServer->run('Bind');
    done_testing;
  };

  package MockNoServer;
  our @ISA = ('MockConformanceServer');
  sub conformance_live_available { 0 }
  package main;

  my @diag;
  no warnings 'redefine';
  local *Test::More::diag = sub { push @diag, @_; 0 };
  subtest 'run(Bind) without a server' => sub {
    MockNoServer->run('Bind');
    like $diag[0], qr/\A10 cases not run: no server/, 'the cases not run are counted';
    done_testing;
  };
}

# ---------------------------------------------- the async way: data seams only
#
# An async transport overrides conformance_connect and the data seams and
# waits for the Futures there. This server does exactly that much: it counts
# every call of a data seam, and the ResultSet API is made to die, so a Bind
# operation that bypassed a seam would fail its case.

{
  package CountingConf;
  our @ISA = ('MockConformanceServer');
  our %SEAM;
  for my $seam (qw(create find count update populate)) {
    no strict 'refs';
    my $name = "conformance_$seam";
    *{$name} = sub {
      $SEAM{$seam}++;
      my $class = shift;
      return MockConformanceServer->can($name)->($class, @_);
    };
  }
}

{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConformanceServer::reset_state();
  %CountingConf::SEAM = ();

  no warnings 'redefine';
  my $bypassed = sub { die "the ResultSet API was used by the runner\n" };
  local (*DBIO::ResultSet::search, *DBIO::ResultSet::create, *DBIO::ResultSet::update,
         *DBIO::ResultSet::populate, *DBIO::ResultSet::count, *DBIO::ResultSet::first,
         *DBIO::ResultSet::find, *DBIO::ResultSet::delete, *DBIO::ResultSet::all) =
    ($bypassed) x 9;

  my @r = CountingConf->results('Bind');
  is_deeply [ grep { $_->{status} ne 'pass' } @r ], [],
    'the whole Bind list runs on a server that implements only connect and the data seams'
    or diag join "\n", map { "$_->{case}: $_->{status}: $_->{message}" } grep { $_->{status} ne 'pass' } @r;
  ok $CountingConf::SEAM{$_} > 0, "... and $_ went through its seam" for qw(create find count update populate);

  # one case, counted exactly. bind-digit-string-leading-zero: two roundtrips
  # of two values. Per value: create 1 + update's create 1; find 1 + update's
  # read-back 1; search 1 (count); update 1. The second roundtrip adds int_first
  # (a count) per value.
  %CountingConf::SEAM = ();
  my @one = CountingConf->results('Bind', only => ['bind-digit-string-leading-zero']);
  is $one[0]{status}, 'pass', 'bind-digit-string-leading-zero passes through the seams';
  is_deeply { %CountingConf::SEAM },
    { create => 8, find => 8, count => 6, update => 4 },
    'every operation of the case is one seam call: 4 values x (2 create, 2 find, 1 update) + 6 counts';
}

# the data seams' defaults send what a ResultSet would: INSERT, SELECT, UPDATE
{
  package MockDefaultOps;
  our @ISA = ('DBIO::Test::Conformance');
  sub conformance_connect {
    my ($class, $schema_class) = @_;
    $schema_class->storage_type('DBIO::Test::Storage');
    return $schema_class->connect(sub { });
  }
}
{
  my $case = (grep { $_->{name} eq 'bind-lob-row-operations' } @$cases)[0];
  my $schema = MockDefaultOps->conformance_connect(DBIO::Test::Conformance->_build_schema_class($case));
  my $st = $schema->storage;
  $st->mock_persistent(qr/^SELECT/i, [[ 7, 'l', 'b' ]]);

  my $row = MockDefaultOps->conformance_find($schema, 'Doc', { label => 'l' });
  is_deeply $row, { id => 7, label => 'l', body => 'b' }, 'the default conformance_find returns the first row as a hash';
  $st->mock_persistent(qr/^SELECT/i, []);
  is(MockDefaultOps->conformance_find($schema, 'Doc', { label => 'nope' }), undef, '... and undef when none matches');

  $st->reset_captured;
  my %set = (body => 'x');
  MockDefaultOps->conformance_update($schema, 'Doc', { id => 7 }, \%set);
  MockDefaultOps->conformance_populate($schema, 'Doc', [ { label => 'a', body => undef }, { label => 'b', body => 'y' } ]);
  my @q = $st->captured_queries;
  ok scalar(grep { $_->{op} eq 'update' } @q), 'the default conformance_update sends an UPDATE';
  ok scalar(grep { $_->{op} eq 'insert' } @q), 'the default conformance_populate sends INSERTs';
  is_deeply \%set, { body => 'x' }, '... and leaves the caller\'s hash as it was';
}

done_testing;
