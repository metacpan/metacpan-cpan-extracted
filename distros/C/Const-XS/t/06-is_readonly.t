use Const::XS qw/all/;
use Test::More;
const my $foo => 'a scalar value';
const my @bar => qw/a list value/, { hash => 1, deep => { one => 'nope' } }, [ 'nested', { hash => 2 } ];
const my %buz => (a => 'hash', of => 'something', array => [ 'nested', { hash => 1 } ], hash => { hash => 2, deep => { one => 'nope' } } );
const my $sub => sub { return 1 };
const my $ref => { a => 1, b => 2 };

is(is_readonly($foo), 1);

my $test = 'abc';
is(is_readonly($test), 0);

if ($] >= 5.016) {
	eval "is(is_readonly(\@bar[3]), 1)";
} else {
	diag explain "Skip: Type of arg 1 to Const::XS::PP::is_readonly must be one of [$@%] (not array slice)";
}

is(is_readonly($buz{array}), 1);

is(is_readonly(%buz), 1);

is(is_readonly($sub), 1);

my $other_sub = sub { return 2 };

is(is_readonly($other_sub), 0);

is(is_readonly($ref), 1);

my $array = [ $foo ];

is(is_readonly($array), 0);

my $string = "abc";
is(is_readonly($string), 0); # 0;
make_readonly($string);

eval { $string = 'def' };
like($@, qr/Modification of a read-only value attempted/);
is(is_readonly($string), 1); # should be 1 currently is 0 no idea how to fix this;

unmake_readonly($string);
is(is_readonly($string), 0);

my $hash = { a => 1, b => 2, c => 3 };
is(is_readonly($hash), 0); # 0;
make_readonly($hash);
is(is_readonly($hash), 1);
unmake_readonly($hash);
is(is_readonly($hash), 0);

my $array = [ qw/1 2 3/, { deep => { deeper => { one => 1 } } } ];
is(is_readonly($array), 0); # 0;
make_readonly($array);
is(is_readonly($array), 1);
unmake_readonly($array);
is(is_readonly($array), 0);


const my $ref => { a => 1, b => 2, c => 3 };

is(is_readonly($ref), 1);

my $copy = $ref;

is(&Internals::SvREADONLY($copy), 1);
is(Internals::SvREADONLY($copy), '');

is(&is_readonly($copy), 1);

my $wow = { a => 'one' };

is(&is_readonly($wow), 0);

is(&Internals::SvREADONLY($wow), '');

done_testing();
