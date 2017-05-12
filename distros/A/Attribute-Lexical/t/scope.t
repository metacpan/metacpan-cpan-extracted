use warnings;
use strict;

use Test::More tests => 50;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

sub foo { }
our $foo;

my @attributes;
sub atthandler0 { push @attributes, [0,@_[0..2,4..$#_]] }
sub atthandler1 { push @attributes, [1,@_[0..2,4..$#_]] }

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	use Attribute::Lexical "CODE:A0" => \&atthandler1;
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [1,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		sub foo :A0;
	}
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{ ; }
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	{
		use Attribute::Lexical "CODE:A0" => \&atthandler0;
	}
	sub foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		use Attribute::Lexical "CODE:A0" => \&atthandler1;
		sub foo :A0;
	}
};
is $@, "";
is_deeply \@attributes, [ [1,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		use Attribute::Lexical "CODE:A0" => \&atthandler1;
	}
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		use Attribute::Lexical "CODE:A0" => \&atthandler1;
		sub foo :A0;
	}
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [1,\&foo,"A0",undef], [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	package wibble;
	sub main::foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	package wibble;
	use Attribute::Lexical "CODE:A0" => \&main::atthandler0;
	sub main::foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	package wibble;
	use Attribute::Lexical "CODE:A0" => \&main::atthandler0;
	package main;
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	package wibble;
	use Attribute::Lexical "CODE:A0" => \&main::atthandler1;
	sub main::foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [1,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	package wibble;
	use Attribute::Lexical "CODE:A0" => \&main::atthandler1;
	package main;
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [1,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		no Attribute::Lexical "CODE:A0";
		sub foo :A0;
	}
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		no Attribute::Lexical "CODE:A0";
	}
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		no Attribute::Lexical "CODE:A0" => \&atthandler0;
		sub foo :A0;
	}
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		no Attribute::Lexical "CODE:A0" => \&atthandler0;
	}
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		no Attribute::Lexical "CODE:A0" => \&atthandler1;
		sub foo :A0;
	}
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	{
		no Attribute::Lexical "CODE:A0" => \&atthandler1;
	}
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	use t::scope0;
	sub foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	use t::scope1;
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	use t::scope2;
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [1,\&foo,"A0",undef], [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	use t::scope3;
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	use t::scope4;
	sub foo :A0;
};
isnt $@, "";
is_deeply \@attributes, [];

@attributes = ();
eval q{
	use Attribute::Lexical "CODE:A0" => \&atthandler0;
	BEGIN { my $x = "foo\x{666}"; $x =~ /foo\p{Alnum}/; }
	sub foo :A0;
};
is $@, "";
is_deeply \@attributes, [ [0,\&foo,"A0",undef] ];

SKIP: {
	skip "can't do runtime lexical stuff on this perl", 2
		if "$]" < 5.009004;

@attributes = ();
eval q{
	use Attribute::Lexical "SCALAR:A0" => \&atthandler0;
	{
		use Attribute::Lexical "SCALAR:A0" => \&atthandler1;
		foreach(0..2) {
			my $foo :A0;
		}
	}
};
is $@, "";
is_deeply \@attributes, [
	[1,\$foo,"A0",undef],
	[1,\$foo,"A0",undef],
	[1,\$foo,"A0",undef],
];

}

1;
