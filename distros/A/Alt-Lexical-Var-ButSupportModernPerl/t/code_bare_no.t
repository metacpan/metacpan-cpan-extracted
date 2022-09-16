use warnings;
use strict;

use Test::More;
BEGIN {
	plan skip_all => "bare subs possible on this perl" if "$]" >= 5.011002;
}
plan tests => 12;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

sub main::foo { "main" }
sub main::bar () { "main" }

our @values;

{ local $TODO = "bareword ref without parens works funny";
@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 1 };
	push @values, foo;
};
like $@, qr/\Acan't reference lexical subroutine without \& sigil/;
is_deeply \@values, [];
}

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 1 };
	push @values, foo();
};
like $@, qr/\Acan't reference lexical subroutine without \& sigil/;
is_deeply \@values, [];

{ local $TODO = "bareword ref without parens works funny";
@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { 1+$_[0] };
	push @values, foo 10;
};
like $@, qr/\Acan't reference lexical subroutine without \& sigil/;
is_deeply \@values, [];
}

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { 1+$_[0] };
	push @values, foo(10);
};
like $@, qr/\Acan't reference lexical subroutine without \& sigil/;
is_deeply \@values, [];

{ local $TODO = "constant subs work funny";
@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 1 };
	push @values, bar;
};
like $@, qr/\Acan't reference lexical subroutine without \& sigil/;
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 1 };
	push @values, bar();
};
like $@, qr/\Acan't reference lexical subroutine without \& sigil/;
is_deeply \@values, [];
}

1;
