use warnings;
use strict;

use Test::More tests => 157;

use IO::File 1.03;

BEGIN {
	use_ok "Data::Entropy::Source";
	use_ok "Data::Entropy", qw(with_entropy_source);
	use_ok "Data::Entropy::Algorithms", qw(rand_prob);
}

with_entropy_source +Data::Entropy::Source->new(
		IO::File->new("t/test0.entropy", "r") || die($!), "getc"
), sub {
	$_ = <DATA>;
	while(/([0-9])/g) {
		is rand_prob(1, 2, 0, 3, 4), $1;
	}
	$_ = <DATA>;
	while(/([0-9])/g) {
		is rand_prob([ 1, 2, 0, 3, 4 ]), $1;
	}
	is rand_prob(1), 0;
	is rand_prob([1]), 0;
	eval { rand_prob(-1); };
	like $@, qr/\Aprobabilities must be non-negative/;
	eval { rand_prob(0); };
	like $@, qr/\Acan't have nothing possible/;
};

1;

__DATA__
334004330330101331104144441041440443440340311333014430141343331033433134434
034443443110114433133310340433331041443030303433344343333441344341334414034
