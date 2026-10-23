use strict;
use warnings;
use Test::More;

use Data::LnArray::XS;

my @big = (1 .. 5000);
my $array = Data::LnArray::XS->new(@big);

is_deeply([$array->retrieve], \@big, 'retrieve on a long array');
is_deeply([$array->values], \@big, 'values on a long array');
is_deeply([$array->keys], [0 .. 4999], 'keys on a long array');

my @pairs = $array->entries;
is(scalar @pairs, 10000, 'entries returns every pair');
is_deeply([@pairs[0 .. 3]], [0, 1, 1, 2], 'entries pairs index and value');

my @each = $array->forEach(sub { ($_, $_ * 2) });
is(scalar @each, 10000, 'forEach returns every result on a long array');
is_deeply([@each[0 .. 3]], [1, 2, 2, 4], 'forEach keeps result order');

is($array->map(sub { $_[0] + 1 })->[4999], 5001, 'map on a long array');

is($array->find(sub { $_[0] == -1 }), undef, 'find with no match is undef');
is($array->findIndex(sub { $_[0] == -1 }), undef, 'findIndex with no match is undef');
is($array->find(sub { $_[0] == 4000 }), 4000, 'find');
is($array->findIndex(sub { $_[0] == 4000 }), 3999, 'findIndex');

my $small = Data::LnArray::XS->new(1, 2, 3, 4);
is($small->reduce(sub { $_[0] + $_[1] }, 100), 110, 'reduce with an initial value');
is($small->reduceRight(sub { $_[0] . $_[1] }, 'x'), 'x4321', 'reduceRight with an initial value');

my @source = qw/a b c/;
my $from = Data::LnArray::XS->new->from(\@source, sub { uc $_ });
is_deeply([$from->retrieve], [qw/A B C/], 'from with a callback');
is_deeply(\@source, [qw/a b c/], 'from leaves the source array alone');

{
	local $_ = 'outer';
	$small->forEach(sub { 1 });
	Data::LnArray::XS->new->from([1, 2], sub { $_ });
	is($_, 'outer', 'forEach and from restore $_');
}

{
	package Other::Pkg;
	my $sorted = Data::LnArray::XS->new(qw/c a b/)->sort(sub { $a cmp $b });
	Test::More::is_deeply([@$sorted], [qw/a b c/], 'sort outside main');
}

is_deeply(
	[@{ Data::LnArray::XS->new(5, 3, 9, 1)->sort(sub { $a <=> $b }) }],
	[1, 3, 5, 9],
	'numeric sort'
);

done_testing;
