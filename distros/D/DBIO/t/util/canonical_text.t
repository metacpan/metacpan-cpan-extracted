use strict;
use warnings;
use Test::More;

use DBIO::Util qw(canonical_text);

# canonical_text is the one value form for "are these two the same value":
# equal text is equal value, whatever Perl keeps beside the value.

sub same   { my ($x, $y, $name) = @_; is canonical_text($x), canonical_text($y), $name }
sub differ { my ($x, $y, $name) = @_; isnt canonical_text($x), canonical_text($y), $name }

same({ a => 1, b => [1, 2] }, { b => [1, 2], a => 1 }, 'hash key order does not matter');
differ([1, 2], [2, 1], 'array order does');
differ({ a => 1 }, { a => 1, b => 1 }, 'an added key differs');

{ my $s = '4326'; my $n = $s + 0;
  same($s, $n, 'a string read as a number is the same value'); }
same(4326, '4326', '4326 and the string 4326');
differ(4326, 4327, '4326 and 4327');
differ(undef, '', 'undef is not the empty string');
differ('a"b', 'a\\"b', 'quotes are escaped');

same(\'x', \'x', 'scalar references by content');
differ(\'x', \'y', '... and differ by content');
same(\\'x', \\'x', 'reference to reference');

my $one = bless { a => 1 }, 'Foo';
same($one, bless({ a => 1 }, 'Foo'), 'blessed by class and content');
differ($one, bless({ a => 1 }, 'Bar'), '... other class differs');
differ($one, { a => 1 }, '... blessed is not plain');

same(qr/a/i, qr/a/i, 'regexp by pattern and flags');
differ(qr/a/i, qr/a/, '... other flags differ');
differ(qr/a/, qr/b/, '... other pattern differs');

my $sub = sub { 1 };
same($sub, $sub, 'the same code reference');
differ($sub, sub { 1 }, 'two subs are two values');
same([$sub], [$sub], 'a code reference inside a structure');
differ([$sub], [sub { 1 }], '... two subs inside a structure');

my $c1 = { n => 1 }; $c1->{self} = $c1;
my $c2 = { n => 1 }; $c2->{self} = $c2;
same($c1, $c2, 'cycles end and compare equal');
my $c3 = { n => 2 }; $c3->{self} = $c3;
differ($c1, $c3, '... and differ by content');

done_testing;
