use warnings;
use strict;

use Test::More tests => 54;

use IO::File 1.03;

BEGIN {
	use_ok "Data::Entropy::Source";
	use_ok "Data::Entropy", qw(with_entropy_source);
	use_ok "Data::Entropy::Algorithms", qw(choose choose_r);
}

with_entropy_source +Data::Entropy::Source->new(
		IO::File->new("t/test0.entropy", "r") || die($!), "getc"
), sub {
	my @items = qw(a b c d e f g h i j);
	$_ = <DATA>;
	while(/([a-z]+)/g) {
		is join("", choose(3, @items)), $1;
	}
	$_ = <DATA>;
	while(/([a-z]+)/g) {
		is join("", @{choose_r(3, \@items)}), $1;
	}
	is_deeply [ choose(1, qw(a)) ], [ qw(a) ];
	is_deeply choose_r(1, [qw(a)]), [ qw(a) ];
	is_deeply [ choose(3, qw(a b c)) ], [ qw(a b c) ];
	is_deeply choose_r(3, [qw(a b c)]), [ qw(a b c) ];
	is_deeply [ choose(0, qw(a b c)) ], [];
	is_deeply choose_r(0, [qw(a b c)]), [];
	eval { choose(-1, qw(a b c)); };
	like $@, qr/\Aneed a non-negative number of items to choose/;
	eval { choose_r(-1, [qw(a b c)]); };
	like $@, qr/\Aneed a non-negative number of items to choose/;
	eval { choose(4, qw(a b c)); };
	like $@, qr/\Aneed a sufficiently large array to pick from/;
	eval { choose_r(4, [qw(a b c)]); };
	like $@, qr/\Aneed a sufficiently large array to pick from/;
	eval { choose_r(4, "a"); };
	like $@, qr/\Aneed a sufficiently large array to pick from/;
};

1;

__DATA__
bci abg abi fgh fgj chj bce dfh bhj adj dij cde ceh acd adi cij cdg beh acf egi
egj efj abe bcf dgj abd abd acf adi ehj eij bef bei bhi bcf cde bfj ach eij ahi
