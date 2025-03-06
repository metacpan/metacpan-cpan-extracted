use strict;
use warnings;
use Test::More tests => 18;
BEGIN { use_ok('Array::Intersection') };

is(join(",", intersection([1,2,3,4], [3,4,5,6])), "3,4", 'intersection');
is(join(",", intersection([1,2,3,3,4], [3,4,5,6])), "3,4", 'intersection uniq array 1');
is(join(",", intersection([1,2,3,4], [3,4,4,5,6])), "3,4", 'intersection uniq array 2');
is(join(",", intersection(['1','2','3','4'], ['3','4','5','6'])), "3,4", 'intersection strings');
is(join(",", intersection([1 .. 10_000], [9_000 .. 20_000])), join(",", 9_000 .. 10_000), 'large intersection');

is(join(",", intersection([1,1.0,1.00,1e0], [1])), "1", 'intersection'); #is this ok
is(join(",", intersection(["1\0"], ["1\0"])), "1\0", 'intersection with escape char');

{
  no warnings qw(uninitialized);
  my @intersection = intersection([0,1,2,3,4,5,6,'',undef,7,8,9], ["a", "b", "c", "d", 0, '', undef, "e"]);
  #use Data::Dumper qw{Dumper};
  #diag(Dumper \@intersection);
  is(scalar(@intersection), 3, 'intersection with false values');
  is($intersection[0],   '0', 'intersection with false value 1'); #order of second array ref is perserved due to use of uniq
  is($intersection[1],    '', 'intersection with false value undef');
  is($intersection[2], undef, 'intersection with false value 0');
}

{
  eval{intersection()};
  my $error = $@;
  #diag($error);
  ok($error, 'intersection syntax');
  like($error, qr/Syntax/, 'intersection syntax');
}

{
  eval{intersection([1], 2)};
  my $error = $@;
  #diag($error);
  ok($error, 'intersection array ref error');
  like($error, qr/Can't use string/, 'intersection array ref error');
}

{
  eval{intersection(1, [2])};
  my $error = $@;
  #diag($error);
  ok($error, 'intersection array ref error');
  like($error, qr/Can't use string/, 'intersection array ref error');
}
