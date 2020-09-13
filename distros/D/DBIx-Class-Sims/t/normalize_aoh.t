# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing is subtest );

use DBIx::Class::Sims::Util qw( normalize_aoh );

subtest successes => sub {
  is(normalize_aoh([]), [], "Arrayref in, arrayref out");
  is(normalize_aoh([{}]), [{}], "Arrayref in, arrayref out");
  is(normalize_aoh([{},{}]), [{}, {}], "Arrayref in, arrayref out");

  is(normalize_aoh({}), [{}], "Hashref in, arrayref out");

  is(normalize_aoh(1), [{}], "Number in, arrayref out");
  is(normalize_aoh(2), [{}, {}], "Number in, arrayref out");
  is(normalize_aoh(4), [{}, {}, {}, {}], "Number in, arrayref out");

  is(normalize_aoh(2, []), [{}, {}], "Ignore addl params");
};

subtest failures => sub {
  is(normalize_aoh(), undef, "Garbage in, undef out");
  is(normalize_aoh(undef), undef, "Garbage in, undef out");
  is(normalize_aoh(''), undef, "Garbage in, undef out");
  is(normalize_aoh([{}, 1]), undef, "Garbage in, undef out");
  is(normalize_aoh(1.43), undef, "Garbage in, undef out");
};

done_testing;
