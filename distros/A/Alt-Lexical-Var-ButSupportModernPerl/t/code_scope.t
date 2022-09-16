use warnings;
use strict;

use Test::More tests => 62;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

sub main::foo { "main" }
sub wibble::foo { "wibble" }

our @values;

@values = ();
eval q{
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use Lexical::Var '&foo' => sub { 2 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{ ; }
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	{
		use Lexical::Var '&foo' => sub { 1 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		use Lexical::Var '&foo' => sub { 2 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	package wibble;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	package wibble;
	use Lexical::Var '&foo' => sub { 1 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	package wibble;
	use Lexical::Var '&foo' => sub { 1 };
	package main;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	package wibble;
	use Lexical::Var '&foo' => sub { 2 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	package wibble;
	use Lexical::Var '&foo' => sub { 2 };
	package main;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo';
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo';
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo' => \&foo;
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo' => \&foo;
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo' => sub { 1 };
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo' => sub { 1 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	BEGIN { my $x = "foo\x{666}"; $x =~ /foo\p{Alnum}/; }
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_0;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main", 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_1;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_2;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_3;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_4;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main", 1 ];

SKIP: { skip "no lexical propagation into string eval", 10 if "$]" < 5.009003;

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	eval q{
		push @values, &foo;
	};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	eval q{
		use Lexical::Var '&foo' => sub { 1 };
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	eval q{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
	};
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	eval q{
		use Lexical::Var '&foo' => sub { 2 };
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	eval q{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

}

1;
