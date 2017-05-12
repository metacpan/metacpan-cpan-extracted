# vim:ft=perl

use Test::More tests => 10;

use_ok("Bit::Vector::Minimal");

{
	my $vec = Bit::Vector::Minimal->new;
	isa_ok $vec => "Bit::Vector::Minimal";

	$vec->set(2);
	is $vec->display(), "00000100", "pattern set correctly for default LE";
	is $vec->get(2), 1, "Bit two set";
	is $vec->get(3), 0, "Bit three not set";
}

{
	my $vec = Bit::Vector::Minimal->new(
		size       => 32,
		width      => 2,
		endianness => "big"
	);
	isa_ok $vec => "Bit::Vector::Minimal";
	$vec->set(2, 0b10);
	is $vec->display(), "00001000000000000000000000000000",
		"pattern set correctly for BE";
}

{
	for (19 .. 21) {
		my $vec = Bit::Vector::Minimal->new(size => $_);
		is $vec->display(), "000000000000000000000000",
			"pattern initialized correctly when size not divisible by 8";
	}
}

