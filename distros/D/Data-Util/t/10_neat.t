#!perl -w

use warnings 'FATAL';

use strict;
use Test::More tests => 18;

use Tie::Scalar;
use Tie::Array;
use Tie::Hash;

sub foo{}

{
	package Foo;
	use overload '""' => sub{ 'Foo!' }, fallback => 1;

	sub new{ bless {}, shift }
}
use Data::Util qw(neat);

is neat(42), 42, 'neat()';
is neat(3.14), 3.14;
is neat("foo"), q{"foo"};
is neat(undef), 'undef';
is neat(*ok), '*main::ok';
ok neat({'!foo' => '!bar'});
unlike neat({foo => 'bar', baz => 'bax'}), qr/undef/;
like neat(\&foo), qr/^\\&main::foo\(.*\)$/;
like neat(Foo->new(42)), qr/^Foo=HASH\(.+\)$/, 'for an overloaded object';

like neat(qr/foo/), qr/foo/, 'neat(qr/foo/) includes "foo"';

ok neat(+9**9**9), '+Inf';
ok neat(-9**9**9), '-Inf';
ok neat(9**9**9 - 9**9**9), 'NaN';

tie my $s, 'Tie::StdScalar', "foo";
is neat($s), q{"foo"}, 'for magical scalar';

my $x;

$x = tie my @a, 'Tie::StdArray';
$x->[0] = 42;

is neat($a[0]), 42, 'for magical scalar (aelem)';

$x = tie my %h, 'Tie::StdHash';
$x->{foo} = 'bar';

is neat($h{foo}), '"bar"', 'for magical scalar (helem)';

# recursive
my @rec;
push @rec, \@rec;
ok neat(\@rec), 'neat(recursive array) is safe';

my %rec;
$rec{self} = \%rec;
ok neat(\%rec), 'neat(recursive hash) is safe';

