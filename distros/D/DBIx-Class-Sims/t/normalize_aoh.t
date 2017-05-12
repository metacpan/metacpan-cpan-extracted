# vi:sw=2
use strictures 2;

use Test::More;
use Test::Deep;

use DBIx::Class::Sims::Util;
my $p = 'DBIx::Class::Sims::Util';

subtest successes => sub {
  cmp_deeply($p->normalize_aoh([]), [], "Arrayref in, arrayref out");
  cmp_deeply($p->normalize_aoh([{}]), [{}], "Arrayref in, arrayref out");
  cmp_deeply($p->normalize_aoh([{},{}]), [{}, {}], "Arrayref in, arrayref out");

  cmp_deeply($p->normalize_aoh({}), [{}], "Hashref in, arrayref out");

  cmp_deeply($p->normalize_aoh(1), [{}], "Number in, arrayref out");
  cmp_deeply($p->normalize_aoh(2), [{}, {}], "Number in, arrayref out");
  cmp_deeply($p->normalize_aoh(4), [{}, {}, {}, {}], "Number in, arrayref out");

  cmp_deeply($p->normalize_aoh(2, []), [{}, {}], "Ignore addl params");
};

subtest failures => sub {
  is($p->normalize_aoh(), undef, "Garbage in, undef out");
  is($p->normalize_aoh(undef), undef, "Garbage in, undef out");
  is($p->normalize_aoh(''), undef, "Garbage in, undef out");
  is($p->normalize_aoh([{}, 1]), undef, "Garbage in, undef out");
  is($p->normalize_aoh(1.43), undef, "Garbage in, undef out");
};

done_testing;
