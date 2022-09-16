use warnings;
use strict;

use Test::More tests => 26;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

eval q{use Lexical::Var '$foo' => \undef;};
is $@, "";
eval q{use Lexical::Var '$foo' => \1;};
is $@, "";
eval q{use Lexical::Var '$foo' => \1.5;};
is $@, "";
eval q{use Lexical::Var '$foo' => \[];};
is $@, "";
eval q{use Lexical::Var '$foo' => \"abc";};
is $@, "";
eval q{use Lexical::Var '$foo' => bless(\(my$x="abc"));};
is $@, "";
eval q{use Lexical::Var '$foo' => \*main::wibble;};
is $@, "";
eval q{use Lexical::Var '$foo' => bless(\*main::wibble);};
is $@, "";
eval q{use Lexical::Var '$foo' => qr/xyz/;};
is $@, "";
eval q{use Lexical::Var '$foo' => bless(qr/xyz/);};
is $@, "";
eval q{use Lexical::Var '$foo' => [];};
isnt $@, "";
eval q{use Lexical::Var '$foo' => bless([]);};
isnt $@, "";
eval q{use Lexical::Var '$foo' => {};};
isnt $@, "";
eval q{use Lexical::Var '$foo' => bless({});};
isnt $@, "";
eval q{use Lexical::Var '$foo' => sub{};};
isnt $@, "";
eval q{use Lexical::Var '$foo' => bless(sub{});};
isnt $@, "";

eval q{use Lexical::Var '$foo' => \undef; $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => \1; $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => \1.5; $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => \[]; $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => \"abc"; $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => bless(\(my$x="abc")); $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => \*main::wibble; $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => bless(\*main::wibble); $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => qr/xyz/; $foo if 0;};
is $@, "";
eval q{use Lexical::Var '$foo' => bless(qr/xyz/); $foo if 0;};
is $@, "";

1;
