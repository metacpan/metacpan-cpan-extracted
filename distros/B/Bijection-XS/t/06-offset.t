use Test::More;
use Bijection::XS qw/:all/;

# offset_set moves the start of the sequence: every id is encoded as id plus
# the offset, and inverse takes it off again.

is(offset_set(100), undef, 'offset_set returns nothing');
is(inverse(biject(5)), 5, 'a round trip survives an offset of a hundred');
isnt(biject(5), do { offset_set(0); biject(5) }, 'and the encoding changed with it');
offset_set(0);
is(biject(0), '', 'with no offset, zero encodes to the empty string');
is(inverse(''), 0, 'and the empty string decodes to zero');
is(inverse(biject(1234567)), 1234567, 'a round trip with no offset');
is(bijection_set(qw/a b c/), 3, 'bijection_set with no leading offset makes it the count');
is(biject(0), 'ba', 'so zero encodes as the count');
is(bijection_set(7, qw/a b c/), 7, 'and a leading positive integer is the offset');
is(bijection_set(0, qw/a b/), 3, 'a leading zero is a letter, not an offset');
is(bijection_set(-2, qw/a b/), 3, 'as is a negative integer');
is(inverse(biject(2)), 2, 'which round trips');

done_testing;
