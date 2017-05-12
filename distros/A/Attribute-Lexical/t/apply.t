use warnings;
use strict;

use Test::More tests => 34;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

our($foo, @foo, %foo);
sub foo { }

my @attributes;
sub atthandler { push @attributes, [@_[0..2,4..$#_]] }

@attributes = ();
eval q{
	sub foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler;
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [\&foo,"A0",undef] ];

@attributes = ();
eval q{
	sub foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler;
	sub foo :A0(wibble);
};
is $@, "";
is_deeply \@attributes, [ [\&foo,"A0","wibble"] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler;
	sub foo :A1;
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler;
	sub foo :A0(wibble) :A0 A0(wobble);
};
is $@, "";
is_deeply \@attributes, [
	[\&foo,"A0","wibble"],
	[\&foo,"A0",undef],
	[\&foo,"A0","wobble"],
];

@attributes = ();
eval q{
	use Attribute::Lexical
		"CODE:A0" => \&atthandler,
		"CODE:A1" => \&atthandler;
	sub foo :A0 A1;
};
is $@, "";
is_deeply \@attributes, [ [\&foo,"A0",undef], [\&foo,"A1",undef] ];

SKIP: {
	skip "attributes on \"our\" variables don't work on this perl", 10
		if "$]" < 5.008;

@attributes = ();
eval q{
	use Attribute::Lexical "SCALAR:A0" => \&atthandler;
	our $foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [\$foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "ARRAY:A0" => \&atthandler;
	our @foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [\@foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "HASH:A0" => \&atthandler;
	our %foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [\%foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "SCALAR:A0" => \&atthandler;
	sub foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler;
	our $foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

}

SKIP: {
	skip "can't do runtime lexical stuff on this perl", 10
		if "$]" < 5.009004;

@attributes = ();
eval q{
	use Attribute::Lexical "SCALAR:A0" => \&atthandler;
	foreach(0..2) {
		my $foo :A0;
	}
};
is $@, "";
is_deeply \@attributes, [
	[\$foo,"A0",undef],
	[\$foo,"A0",undef],
	[\$foo,"A0",undef],
];

@attributes = ();
eval q{
	use Attribute::Lexical "ARRAY:A0" => \&atthandler;
	my @foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [\@foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "HASH:A0" => \&atthandler;
	my %foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [\%foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "SCALAR:A0" => \&atthandler;
	sub foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler;
	my $foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

}

1;
