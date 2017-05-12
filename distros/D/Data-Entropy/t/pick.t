use warnings;
use strict;

use Test::More tests => 158;

use IO::File 1.03;

BEGIN {
	use_ok "Data::Entropy::Source";
	use_ok "Data::Entropy", qw(with_entropy_source);
	use_ok "Data::Entropy::Algorithms", qw(pick pick_r);
}

with_entropy_source +Data::Entropy::Source->new(
		IO::File->new("t/test0.entropy", "r") || die($!), "getc"
), sub {
	my @items = qw(a b c d e f g h i j);
	$_ = <DATA>;
	while(/([a-z])/g) {
		is pick(@items), $1;
	}
	$_ = <DATA>;
	while(/([a-z])/g) {
		is pick_r(\@items), $1;
	}
	is pick("a"), "a";
	is pick_r(["a"]), "a";
	eval { pick(); };
	like $@, qr/\Aneed a non-empty array to pick from/;
	eval { pick_r([]); };
	like $@, qr/\Aneed a non-empty array to pick from/;
	eval { pick_r("a"); };
	like $@, qr/\Aneed a non-empty array to pick from/;
};

1;

__DATA__
fhgfjhhejgdhcjegdidehfjcfhacbcbdccbhhaecfcdfbjchfgejdchgbdegaegcjighddbeegf
ggiifdjdddhhdcdccefjhdhdcicecbeagjhjeieggegjgfdagedbeacjegdgghghddaijhibdja
