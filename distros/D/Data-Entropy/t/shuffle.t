use warnings;
use strict;

use Test::More tests => 22;

use IO::File 1.03;

BEGIN {
	use_ok "Data::Entropy::Source";
	use_ok "Data::Entropy", qw(with_entropy_source);
	use_ok "Data::Entropy::Algorithms", qw(shuffle shuffle_r);
}

with_entropy_source +Data::Entropy::Source->new(
		IO::File->new("t/test0.entropy", "r") || die($!), "getc"
), sub {
	my @items = qw(a b c d e f g h i j);
	$_ = <DATA>;
	while(/([a-z]+)/g) {
		is join("", shuffle(@items)), $1;
	}
	$_ = <DATA>;
	while(/([a-z]+)/g) {
		is join("", @{shuffle_r(\@items)}), $1;
	}
	is_deeply [ shuffle(qw(a)) ], [ qw(a) ];
	is_deeply shuffle_r([qw(a)]), [ qw(a) ];
	is_deeply [ shuffle() ], [];
	is_deeply shuffle_r([]), [];
	eval { shuffle_r("a"); };
	like $@, qr/\Aneed an array to shuffle/;
};

1;

__DATA__
djeciabhgf jchfbgidae hcfijbgdae dfghaicebj dcibgfajeh cajgedfbhi fbejdihacg
jdefaghcbi bigdajhfec efhbgacjdi jgiafcdheb cjfeahbgid dbhajegcfi iaefhcdbgj
