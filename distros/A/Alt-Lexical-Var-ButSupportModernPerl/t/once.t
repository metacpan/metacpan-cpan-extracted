use warnings;
use strict;

use Test::More tests => 6;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

use Lexical::Var '$scalar' => \1;
is_deeply $scalar, 1;

use Lexical::Var '@array' => [];
is_deeply \@array, [];

use Lexical::Var '%hash' => {};
is_deeply \%hash, {};

use Lexical::Var '&code' => sub { 1 };
is_deeply &code, 1;

use Lexical::Var '*glob' => \*x;
is_deeply *glob, *x;

use Lexical::Sub sub => sub { 1 };
is_deeply &sub, 1;

1;
