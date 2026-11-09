use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';
use DBIO::Extension;
use DBIO::Extension::Protocol;

# ADR 0066 section 2.2 / 2.3: the context, the phases and their merges.

sub mk {
  my ($name, %methods) = @_;
  our $n; my $class = "T::Proto::\u$name" . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Extension');
  *{"${class}::extension_interface"} = sub { 1 };
  *{"${class}::name"} = sub { $name };
  *{"${class}::$_"} = $methods{$_} for keys %methods;
  return { name => $name, class => $class, options => {}, installed => 1, version => '1', schema => 'public' };
}

sub proto {
  my (@entries) = @_;
  return DBIO::Extension::Protocol->new(entries => \@entries, driver => { h => 1 });
}

# --- phase 0: inspect ---------------------------------------------------------------
{
  my @seen;
  my $a = mk(a => inspect => sub { push @seen, ['a', $_[1]]; { graphs => [1] } });
  my $b = mk(b => inspect => sub { push @seen, ['b', $_[1]]; undef });
  my $p = proto($b, $a);
  my $states = $p->inspect('FAKE-DBH');
  is_deeply $states, { a => { graphs => [1] } }, 'state is kept per extension under its name; none is none';
  is $seen[0][1]{dbh}, 'FAKE-DBH', 'inspect gets the dbh';
  is_deeply [ sort keys %{ $seen[0][1]{peers} } ], [ $seen[0][0] eq 'a' ? 'b' : 'a' ], 'peers are the other entries';
  is $seen[0][1]{self}{name}, $seen[0][0], 'self is the extension own entry';
  is_deeply $seen[0][1]{driver}, { h => 1 }, 'driver helpers are in the context';
  ok exists $seen[0][1]{connection_schema} || 1, 'connection_schema key present';
}

# --- the context in later phases -----------------------------------------------------
{
  my %ctx;
  my $a = mk(a => inspect => sub { { n => 1 } }, claims => sub { $ctx{a} = $_[2]; [] });
  my $b = mk(b => inspect => sub { { n => 2 } }, claims => sub { $ctx{b} = $_[2]; [] });
  $b->{version} = '3.4'; $b->{schema} = 'gis';
  my $p = DBIO::Extension::Protocol->new(entries => [$a, $b], driver => {},
    connection_schema => 'app', restricted => 1);
  $p->inspect('DBH');
  $p->claims({});
  is_deeply $ctx{a}{peers}, { b => { class => $b->{class}, installed => 1, version => '3.4', schema => 'gis', state => { n => 2 } } },
    'peers carry class, installed, version, schema and the inspect state';
  is_deeply $ctx{a}{self}{state}, { n => 1 }, 'self carries its own state';
  is $ctx{a}{connection_schema}, 'app', 'connection_schema';
  is $ctx{a}{restricted}, 1, 'restricted';
  ok !exists $ctx{a}{dbh}, 'no database access outside inspect';
}

# --- phase 1: claims ------------------------------------------------------------------
{
  my $a = mk(a => claims => sub { [ [ schema => 'g2' ], [ schema => 'g1' ] ] });
  my $b = mk(b => claims => sub { [ [ schema => 'g1' ], [ table => 'x.y' ] ] });
  my $c = mk(c => );
  is_deeply proto($c, $b, $a)->claims({}),
    [ [ schema => 'g1' ], [ schema => 'g2' ], [ table => 'x.y' ] ],
    'claims: union, de-duplicated, sorted';
  is_deeply proto($a, $b, $c)->claims({}), proto($c, $b, $a)->claims({}), 'independent of entry order';
  throws_ok { proto(mk(bad => claims => sub { 'schema' }))->claims({}) } 'DBIO::Exception',
    'claims that are not a list of addresses refuse';
  like "$@", qr/bad/, 'naming the extension';
}

# --- phase 2: annotate -----------------------------------------------------------------
{
  my $a = mk(a => annotate => sub { [ [ [ column => 't', 'c' ], srid => 4326 ] ] });
  my $b = mk(b => annotate => sub { [ [ [ column => 't', 'c' ], srid => 4326 ], [ [ column => 't', 'c' ], kind => 'x' ] ] });
  is_deeply proto($b, $a)->annotate({}),
    [ [ [ column => 't', 'c' ], kind => 'x' ], [ [ column => 't', 'c' ], srid => 4326 ] ],
    'annotate: union of triples; the same value twice is one triple';

  my $c = mk(c => annotate => sub { [ [ [ column => 't', 'c' ], srid => 3857 ] ] });
  throws_ok { proto($a, $c)->annotate({}) } 'DBIO::Exception', 'same address and attribute, two values refuse';
  like "$@", qr/\ba\b.*\bc\b|\bc\b.*\ba\b/s, 'naming both extensions';
  like "$@", qr/srid/, 'and the attribute';
  my $first = do { eval { proto($a, $c)->annotate({}) }; "$@" };
  my $second = do { eval { proto($c, $a)->annotate({}) }; "$@" };
  s{ at \S+ line \d+.*}{}s for $first, $second;
  is $first, $second, 'the refusal does not depend on entry order';
  throws_ok { proto(mk(bad => annotate => sub { [ ['x'] ] }))->annotate({}) } 'DBIO::Exception',
    'a malformed triple refuses';
}

# --- phase 3: verdict -----------------------------------------------------------------------
{
  my $none = mk(none => );
  my $u1 = mk(u1 => verdict => sub { { using => 'f(x)' } });
  my $u2 = mk(u2 => verdict => sub { { using => 'f(x)' } });
  my $u3 = mk(u3 => verdict => sub { { using => 'g(x)' } });
  my $r1 = mk(r1 => verdict => sub { { refuse => 'no way' } });
  my $r2 = mk(r2 => verdict => sub { { refuse => 'not either' } });

  is proto($none)->verdict({ kind => 'column_type' }), undef, 'nobody answers: undef';
  is_deeply proto($none, $u1)->verdict({}), { using => 'f(x)' }, 'one answer';
  is_deeply proto($u1, $u2)->verdict({}), { using => 'f(x)' }, 'the same answer twice is one answer';

  my $p = proto($u1, $u3);
  my $answer = $p->verdict({});
  ok $answer->{refuse}, 'two different answers are a refusal';
  like join(' ', @{ $answer->{refuse} }), qr/u1.*u3/s, 'naming both extensions';
  is_deeply proto($u3, $u1)->verdict({}), $answer, 'independent of entry order';
  is scalar(() = $p->conflicts), 1, 'a conflict is kept apart from plain refusals';
  my $plain = proto($u1, mk(r => verdict => sub { { refuse => 'x' } }));
  $plain->verdict({});
  is scalar(() = $plain->conflicts), 0, 'a plain refusal is no conflict';
  is scalar(() = $plain->refusals), 1, 'but it is a refusal';

  my $q = proto($u1, $r1, $r2);
  my $got = $q->verdict({ column_name => 'c' });
  is_deeply $got, { refuse => [ 'r1: no way', 'r2: not either' ] }, 'any refuse refuses; every refusal listed, by name';
  $q->verdict({});
  is scalar @{ [ $q->refusals ] }, 4, 'refusals accumulate across changes';
  throws_ok { $q->assert_no_refusals } 'DBIO::Exception', 'the diff is refused';
  like "$@", qr/no way/, 'listing the first refusal';
  like "$@", qr/not either/, 'and the second';
  lives_ok { proto($u1)->assert_no_refusals } 'no refusals, no exception';

  throws_ok { proto(mk(bad => verdict => sub { { using => 'a', refuse => 'b' } }))->verdict({}) }
    'DBIO::Exception', 'an answer that is both using and refuse is malformed';
  throws_ok { proto(mk(bad => verdict => sub { 'maybe' }))->verdict({}) }
    'DBIO::Exception', 'an answer that is no hash is malformed';
}

# --- activation ----------------------------------------------------------------------------------
{
  my $a = mk(a => activation => sub { { load => 'age', search_path => ['ag_catalog'] } });
  my $b = mk(b => activation => sub { { load => ['postgis', 'age'], search_path => ['gis', 'ag_catalog'] } });
  my $c = mk(c => );
  is_deeply proto($c, $b, $a)->activation,
    { load => [qw(age postgis)], search_path => [qw(ag_catalog gis)] },
    'activation: merged in name order, de-duplicated, data not statements';
  is_deeply proto($a, $b, $c)->activation, proto($c, $b, $a)->activation, 'independent of entry order';
  is_deeply proto($c)->activation, { load => [], search_path => [] }, 'nothing active, nothing to compose';

  my $d = mk(d => activation => sub { { load => { age => 'age' } } });
  my $e = mk(e => activation => sub { { load => { age => '$libdir/age-1.5' } } });
  throws_ok { proto($d, $e)->activation } 'DBIO::Exception', 'two libraries for one name refuse';
  like "$@", qr/age/, 'naming the name';
  like "$@", qr/\bd\b.*\be\b/s, 'and both extensions';

  throws_ok { proto(mk(bad => activation => sub { { statements => ['LOAD'] } }))->activation }
    'DBIO::Exception', 'activation is data: an unknown key refuses';
}

# --- every extension gets the same input, as a copy ----------------------------------------------------
{
  my @in;
  my $a = mk(a => claims => sub { push @in, $_[1]; $_[1]{tables}{mutated} = 1; [] });
  my $b = mk(b => claims => sub { push @in, $_[1]; [] });
  my $model = { tables => { t => 1 } };
  proto($a, $b)->claims($model);
  is_deeply $model, { tables => { t => 1 } }, 'the caller model is not touched';
  is_deeply $in[1], { tables => { t => 1 } }, 'the second extension sees what the first saw, not its changes';

  my $p = DBIO::Extension::Protocol->new(entries => [$a, $b], driver => {}, verify_input => 1);
  throws_ok { $p->claims($model) } 'DBIO::Exception', 'with verify_input a changed input refuses';
  like "$@", qr/\ba\b.*(changed|modif)/is, 'naming the extension';
}

# --- run order only changes the sequence ----------------------------------------------------------------
{
  my @calls;
  my $a = mk(a => claims => sub { push @calls, 'a'; [ [ schema => 'x' ] ] });
  my $b = mk(b => claims => sub { push @calls, 'b'; [ [ schema => 'y' ] ] });
  my $p = DBIO::Extension::Protocol->new(entries => [$a, $b], driver => {}, run_order => [qw(b a)]);
  my $r = $p->claims({});
  is_deeply \@calls, [qw(b a)], 'run_order overrides the call sequence';
  is_deeply $r, [ [ schema => 'x' ], [ schema => 'y' ] ], 'the merged result is the same';
  my $q = proto($a, $b);
  @calls = ();
  $q->claims({});
  is_deeply \@calls, [qw(a b)], 'default sequence is name order';
}

# --- extend_models: phases 1 and 2 on both sides -----------------------------------------------------------
{
  require TestDBIO::Extension::Deploy;
  my $deploy = TestDBIO::Extension::Deploy->new;
  my $a = mk(a => inspect => sub { { graphs => ['g1'] } },
                  claims => sub { [ [ schema => 'g1' ] ] });
  my $b = mk(b => annotate => sub {
    [ map { [ [ column => $_, 'c' ], tag => 'seen' ] } grep { $_[1]{tables}{$_}{columns}{c} } sort keys %{ $_[1]{tables} } ] });
  my $mk = sub { { schemas => { public => 1, g1 => 1 }, tables => { 'public.t' => { columns => { c => {} } }, 'g1.l' => { columns => { c => {} } } } } };
  my ($s, $t) = (proto($a, $b))->extend_models($deploy, $mk->(), $mk->());
  for my $m ($s, $t) {
    ok !$m->{schemas}{g1} && !$m->{tables}{'g1.l'}, 'claims are applied by the driver to both sides';
    is $m->{tables}{'public.t'}{columns}{c}{tag}, 'seen', 'annotations are applied after claims on both sides';
    ok !exists $m->{tables}{'g1.l'}, 'phase 2 saw the model after phase 1 (no annotation on claimed objects)';
  }
}

done_testing;
