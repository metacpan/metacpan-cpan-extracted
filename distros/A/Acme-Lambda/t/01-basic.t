use Test::More qw(no_plan);

use Acme::Lambda;

use utf8;

my $sub = lambda {my $x = shift; $x*$x};

is(ref($sub), "CODE", "lambda returns a subref");
is($sub->(4), 16, "subref returns correct value");

my $sub2 = λ{my $x = shift; $x*$x};

is(ref($sub2), "CODE", "λ returns a subref");
is($sub2->(4), 16, "subref returns correct value");
