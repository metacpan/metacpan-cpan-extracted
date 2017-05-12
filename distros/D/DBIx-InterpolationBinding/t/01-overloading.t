# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01-overloading.t'

#########################

use Test;
BEGIN { plan tests => 5 };
use DBIx::InterpolationBinding;
ok(1); # If we made it this far, we're ok.

#########################

sub array_eq {
	my $list1 = shift;
	my $list2 = shift;

	return 0 unless @$list1 == @$list2; # Same length?
	my $i;
	for($i = 0; $i < @$list1; ++$i) {
		if ($list1->[$i] ne $list2->[$i]) { return 0; }
	}
	return 1;
}

my $a = 1;
my $b = 'hello';

ok(array_eq(
	[ 'SELECT * FROM table WHERE a=? AND b=?', $a, $b ],
	[ DBIx::InterpolationBinding::_create_sql_and_params(
		"SELECT * FROM table WHERE a=$a AND b=$b"
	) ]
), 1, "2: Sanity check");

ok(array_eq(
	[ 'SELECT * FROM table WHERE a=$a AND b=$b' ],
	[ DBIx::InterpolationBinding::_create_sql_and_params(
		'SELECT * FROM table WHERE a=$a AND b=$b'
	) ]
), 1, "3: Double quotes only");

{

	no DBIx::InterpolationBinding;

	ok(array_eq(
		[ 'SELECT * FROM table WHERE a=1 AND b=hello' ],
		[ DBIx::InterpolationBinding::_create_sql_and_params(
			"SELECT * FROM table WHERE a=$a AND b=$b"
		) ]
	), 1, "4: Lexical scope only");

}

ok('hello 1', "hello $a", "5: Can stringify");
