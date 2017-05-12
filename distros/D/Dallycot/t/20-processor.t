use lib 't/lib';

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use AnyEvent;
use Promises backend => ['EV'];

use Scalar::Util qw(blessed);

use Dallycot::Parser;

BEGIN { use_ok 'Dallycot::Processor' };

use Dallycot::Library::LOC;
use Dallycot::Library::Core::Streams;

my $processor = Dallycot::Processor -> new;

my $parser = Dallycot::Parser->new;

sub Numeric {
  bless [ Math::BigRat->new($_[0]) ] => 'Dallycot::Value::Numeric'
}

sub Boolean {
  bless [ !!$_[0] ] => 'Dallycot::Value::Boolean'
}

sub Vector {
  bless \@_ => 'Dallycot::Value::Vector'
}

sub String {
  Dallycot::Value::String->new(@_);
}

sub Set {
  bless \@_ => 'Dallycot::Value::Set'
}

sub Uri {
  return Dallycot::Value::URI -> new(@_);
}

sub Stream {
  my(@things) = @_;

  my $stream = Dallycot::Value::Stream -> new(pop @things);
  foreach my $thing (reverse @things) {
    $stream = Dallycot::Value::Stream -> new($thing, $stream);
  }
  return $stream;
}

my $result;

$result = run('Y := ((f) :> f(f, ___))');

$result = run('1 + 2 - 3 + 4 - 5');

isa_ok $result, 'Dallycot::Value::Numeric';

is_deeply $result, Numeric(-1);

$result = run('ones_f(f) :> [ 1, f(f) ]');

isa_ok $result, 'Dallycot::Value::Lambda';

$result = run('ones := ones_f(ones_f)');

isa_ok $result, 'Dallycot::Value::Stream';

$result = run("ones'");

isa_ok $result, 'Dallycot::Value::Numeric';

$result = run("ones...");

isa_ok $result, 'Dallycot::Value::Stream';

$result = run("ones...'");

isa_ok $result, 'Dallycot::Value::Numeric';

$result = run('upfrom_f(self,n) :> [ n, self(self, n+1) ]');

isa_ok $result, 'Dallycot::Value::Lambda';

ok $processor -> has_assignment('upfrom_f'), "We've stored something in the environment (upfrom_f)";
is get_resolution($processor -> get_assignment('upfrom_f')), $result, "The returned closure is stored in the environment (upfrom_f)";

$result = run('upfrom := Y(upfrom_f)');

ok $processor -> has_assignment('upfrom'), "We've stored something in the environment (upfrom)";
is $result, get_resolution($processor -> get_assignment('upfrom')), "The returned closure is stored in the environment (upfrom)";

$result = run("upfrom");

isa_ok $result, 'Dallycot::Value::Lambda';

$result = run("upfrom(1)");

isa_ok $result, 'Dallycot::Value::Stream';

#print STDERR Data::Dumper->Dump([$result]);

$result = run("upfrom(1)'");

is_deeply $result, Numeric(1), "The head of 1.. is 1";

$result = run("upfrom(1)...");

isa_ok $result, 'Dallycot::Value::Stream';

$result = run("upfrom(1)...'");

is_deeply $result, Numeric(2), "The head of the tail of 1.. is 2";

$result = run("upfrom(1)......'");

is_deeply $result, Numeric(3), "The head of the tail of the tail of 1.. is 3";

$result = run("upfrom(1).........'");

is_deeply $result, Numeric(4), "The head of the tail of the tail of the tail of 1.. is 4";

$result = run("repeater_f(f,e) :> [ e, f(f, e) ]");

isa_ok $result, 'Dallycot::Value::Lambda';

$result = run("repeater := Y(repeater_f)");

isa_ok $result, 'Dallycot::Value::Lambda';

$result = run("repeater(1)");

isa_ok $result, 'Dallycot::Value::Stream';

$result = run("repeater(1)...");

isa_ok $result, 'Dallycot::Value::Stream';

$result = run("doubles := Y((f,s) :> ([ 2 * s', f(f, s...) ]))");

is_deeply $result, get_resolution($processor -> get_assignment('doubles')), "Return is the last statement";

$result = run("doubles(upfrom(1))'");

is_deeply $result, Numeric(2), "Double 1 is 2";

$result = run("doubles(upfrom(1))......'");

is_deeply $result, Numeric(6), "Double 3 is 6";

$result = run("doubles(doubles(upfrom(3)))'");

is_deeply $result, Numeric(12), "Double of Double of 3 is 12";

$result = run("doubles(doubles(upfrom(3)))......'");

is_deeply $result, Numeric(20), "Double of Double of 5 is 20";

$result = run("
  even?(n) :> n mod 2 = 0;
  evens := Y((f, s) :> (
    (even?(s')) : [ s', f(f, s...) ]
    (         ) :       f(f, s...)
  ));
");

isa_ok $result, 'Dallycot::Value::Lambda';
my $expected = get_resolution($processor->get_assignment('evens'));
is_deeply $result, $expected, "Returns the last statement (evens)";
#is_deeply $result, get_resolution($processor->get_assignment('evens')); #, "Returns the last statement (evens)";

$result = run("evens(upfrom(1))'");

is_deeply $result, Numeric(2), "First even is 2";

$result = run("evens(upfrom(1))......'");

is_deeply $result, Numeric(6), "Third even is 6";

$result = run("
  odd?(n) :> n mod 2 = 1;
  odds := Y((f, s) :> (
    (odd?(s')) : [ s', f(f, s...) ]
    (        ) :       f(f, s...)
  ))
");

is_deeply $result, get_resolution($processor->context->get_assignment('odds')), "Returns the last statement (odds)";

ok !$processor->context->has_assignment('odds_f'), "Doesn't have the 'odds_f' from the inner scope";

$result = run("odds(upfrom(1))...'");

is_deeply $result, Numeric(3), "The second odd is 3";

$result = run("10 div 2");

is_deeply $result, Numeric(5), "10 div 2 => 5";

$result = run(<<EOF);
filter := Y((ff, f, s) :> (
    (f(s')) : [ s', ff(ff, f, s...) ]
    (     ) : ff(ff, f, s...)
  ))
EOF

is_deeply $result, get_resolution($processor->context->get_assignment('filter')), "Returns the last statement (filter)";

$result = run("filter(odd?, upfrom(1))......'");

is_deeply $result, Numeric(5), "The third odd number from 1 is 5";

$result = run(<<EOF);
map := Y((ff, f, s) :> ([ f(s'), ff(ff, f, s...) ]))
EOF

# # use Data::Dumper;
# # print STDERR Data::Dumper->Dump([$processor -> context -> get_assignment("filter")]);

is_deeply $result, get_resolution($processor -> get_assignment('map')), "Returns the last statement (map)";

$result = run("quintuple(x) :> 5 * x; map(quintuple, upfrom(1))'");

is_deeply $result, Numeric(5), "The first number multiplied by 5 is 5";

$result = run("map( { # * 5 }, upfrom(1))'");

is_deeply $result, Numeric(5), "The mapping should accept an anonymous function";

$result = run("times25 := quintuple . quintuple");

is_deeply $result, get_resolution($processor -> context -> get_assignment('times25')), "Returns the stored definition (times25)";

$result = run("times25(4)");

is_deeply $result, Numeric(100), "4 * 25 = 100";

$result = run("times125 := quintuple . quintuple . quintuple; times125(4)");

is_deeply $result, Numeric(500), "125 * 4 = 500";

$result = run("add4(x) :> x + 4; (quintuple . add4)(0)");

is_deeply $result, Numeric(20), "5 * (0 + 4) == 20";

for my $i (1..7) {
  $result = run("(quintuple . add4)($i)");
  my $expected = 5 * ($i + 4);
  is_deeply $result, Numeric($expected), "5 * ($i + 4) == $expected";
}

$result = run("add4(5)");

is_deeply $result, Numeric(9), "5 + 4 == 9";

for my $i (0..7) {
  $result = run("(add4 . quintuple)($i)");
  my $expected = (5 * $i) + 4;
  is_deeply $result, Numeric($expected), "(5 * $i) + 4 == $expected";
}

$result = run("fives := quintuple @ upfrom(1); fives'");

is_deeply $result, Numeric(5), "The first in fives is 5";

$result = run("fives......'");

is_deeply $result, Numeric(15), "The third five is 15";

$result = run("twentyfives := quintuple @ quintuple @ upfrom(1); twentyfives'");

is_deeply $result, Numeric(25), "The first twentyfive is 25";

$result = run("twentyfives......'");

is_deeply $result, Numeric(75), "The third twentyfive is 75";

$result = run("evensFiltered := even? % upfrom(1); evensFiltered'");

is_deeply $result, Numeric(2), "The first filtered even is 2";

$result = run("fifties := quintuple @ quintuple @ even? % upfrom(1); fifties'");

is_deeply $result, Numeric(50), "The first fifty is fifty";

$result = run("fifties......'");

is_deeply $result, Numeric(150), "The third fifty is 150";

$result = run("fifties' = 50 and fifties...' = 100");

is_deeply $result, Boolean(1), "The result of the 'all' should be 'true'";

$result = run("fifties' > 50 and fifties...' = 100");

is_deeply $result, Boolean(0), "The result of the 'all' should be 'false'";

$result = run("fifties[3]");

is_deeply $result, Numeric(150), "The third fifty should be 150";

$result = run("1.23 * 4");

is_deeply $result, Numeric(1.23*4), "1.23*4 should be 4.92ish";

$result = run("<1,2,3>");

is_deeply $result, Vector(Numeric(1),Numeric(2),Numeric(3)), "<1,2,3> is a vector with three items";

$result = run("<1,2,3>[2]");

is_deeply $result, Numeric(2), "second in <1,2,3> is 2";

$result = run("quintuple @ <1,2,3>");

is_deeply $result, Vector(Numeric(5), Numeric(10), Numeric(15)), "5 * <1,2,3> = <5,10,15>";

$result = run("opt-foo(x,y,multiplier -> 2) :> x + y * multiplier; opt-foo(1,1)");

is_deeply $result, Numeric(3), "1 + 1 * 2 => 3";

$result = run("opt-foo(1,1,multiplier->3)");

is_deeply $result, Numeric(4), "1 + 1 * 3 => 4";

$result = run("def-foo(x, y=3) :> x * y; def-foo(2)");

is_deeply $result, Numeric(6);

$result = run("def-foo(2,4)");

is_deeply $result, Numeric(8);

$result = run(<<'EOD');
sine-wave(strings, terminal-width -> 80) :> (
  number-of-strings := 4;
  max-string-length := 3;
  offset := max-string-length div 2;
  multiplier := terminal-width - offset;
  blank-line :=
"                                                                              "
;
  (y) :> (
    string := strings[((y - 1) mod number-of-strings) + 1];
    "  " ::> string;
  );
)
EOD

isa_ok $result, 'Dallycot::Value::Lambda';

$result = run('sine-wave(5)');

isa_ok $result, 'Dallycot::Value::Lambda';

$result = run("(sine-wave(<<the big red fox>>) @ 1..)...'");

is_deeply $result, String("  big");

$result = run(<<'EOD');
(<http://www.dallycot.net/ns/streams/1.0#last>)(
  (<http://www.dallycot.net/ns/loc/1.0#foldl>)(
    0,
    { #1 + #2 }/2,
    [1,2,3,4,5]
  )
)
EOD

is_deeply $result, Numeric(1+2+3+4+5), "sum of 1..5 is 15";

$result = run(<<'EOD');
(<http://www.dallycot.net/ns/streams/1.0#last>)(
  (<http://www.dallycot.net/ns/loc/1.0#foldl1>)(
    ((a,b) :> (a + b)),
    1..5
  )
)
EOD

is_deeply $result, Numeric(1+2+3+4+5), "sum of 1..5 is 15";

$result = run("1 ::> 2 ::> []");

is_deeply $result, Stream(Numeric(1), Numeric(2));

$result = run(q{"abc" ::> "123" ::> ""});

is_deeply $result, String("abc123");

$result = run(q{even? % <| 1 | 2 | 3 | 5 | 8 | 13 | 21 | 34 |>});

is_deeply [
  sort { $a <=> $b } map { $_ -> value } @$result
], [
  sort { $a <=> $b } map { $_ -> value} @{
    Set(Numeric(2), Numeric(8), Numeric(34))
  }
];

$result = run(q{1 ::> <| 2 |>});

is_deeply [
  sort { $a <=> $b } map { $_ -> value } @$result
], [
  sort { $a <=> $b } map { $_ -> value} @{
    Set(Numeric(1), Numeric(2))
  }
];

$result = run(q{1 ::> <| 1 |>});

is_deeply $result, Set(Numeric(1));

$result = run('1 -> @type');

is_deeply $result, Set(Uri('http://www.dallycot.net/ns/types/1.0/Numeric'));

$result = run('1 -> @type -> @type');

is_deeply $result, Set(Uri('http://www.dallycot.net/ns/types/1.0/Set'));

$processor -> context -> add_namespace(rdfs => 'http://www.w3.org/2000/01/rdf-schema#');

if($ENV{'NETWORK_TESTS'}) {
  $result = run("<http://dbpedia.org/resource/Semantic_Web> -> :rdfs:label");

  ok $result, "We have a result";

  # # print STDERR Data::Dumper->Dump([$result]);

  ok ref($result), "It's a ref";

  ok 0 < @$result, "We have at least one value returned";

  ($result) = map { $_->value } grep { $_->isa('Dallycot::Value::String') && $_->lang eq 'en' } @$result;

  is $result, "Semantic Web", "We should get the resource and parse it into a node";
}

$result = run('P1Y + PT1S');

ok !DateTime::Duration->compare($result->value, DateTime::Duration->new(years => 1, seconds => 1)),
   "P1Y + PT1S = 1 year and 1 second";

$result = run('P1YT1H - PT1M');

ok !DateTime::Duration->compare($result->value, DateTime::Duration->new(years => 1, minutes => 59)),
   "P1YT1H - PT1M = 1 year and 59 minutes";

$result = run('P1Y + P15M');

ok !DateTime::Duration->compare($result->value, DateTime::Duration->new(years => 2, months => 3)),
   "P1Y + P15M = 2 years and 3 months";

$result = run('P1Y + PT15M');

ok !DateTime::Duration->compare($result->value, DateTime::Duration->new(years => 1, minutes => 15)),
   "P1Y + PT15M = 1 year and 15 minutes";

$result = run('P1Y + P366D');

ok !DateTime::Duration->compare($result->value, DateTime::Duration->new(years => 1, days => 366)),
   "P1Y + P366D = 1 year and 366 days";

$result = run('P1Y ::> PT15M');

ok !DateTime::Duration->compare($result->value, DateTime::Duration->new(years => 1, minutes => 15)),
   "P1Y ::> PT15M = 1 year and 15 minutes";

$result = run('10 ::> PT55S');

ok !DateTime::Duration->compare($result->value, DateTime::Duration->new(seconds => 65)),
   "10 ::> PT55S = 65 seconds";

$result = run (<<'EOD');
{ "a": 123 }
EOD

isa_ok $result, 'Dallycot::Value::JSON';

$result = run('{ "a": 123 } -> "a"');

is_deeply $result, Numeric(123);

done_testing();

#==============================================================================

use Data::Dumper;

sub run {
  my($stmt) = @_;
  #print STDERR "Running ($stmt)\n";
  my $cv = AnyEvent -> condvar;

  eval {
    my $parse = $parser -> parse($stmt);
    if(!$parse) {
      print STDERR "unable to parse: $stmt\n";
    }
    # if(!blessed($parse->[0])) {
    #   print STDERR Data::Dumper->Dump([$parse]);
    # }
    # print STDERR "parse stmts: ", join(", ", @$parse), "\n";
    $processor->add_cost(-$processor -> cost);
    $processor -> execute(@{$parse}) -> done(
      sub { $cv -> send( @_ ) },
      sub { $cv -> croak( @_ ) }
    );
  };

  if($@) {
    $cv -> croak($@);
  }

  my $ret = eval {
    $cv -> recv;
  };
  if($@) {
    warn "$stmt: $@";
    #print STDERR "($stmt): ", Data::Dumper->Dump([$parser->program($stmt)]);
  }
  $ret;
}

sub get_resolution {
  my($promise) = @_;
  return unless blessed $promise;
  my $cv = AnyEvent -> condvar;
  $promise -> done( sub {
    $cv -> send(@_);
  }, sub {
    $cv -> croak( @_ );
  });

  $cv -> recv;
}
