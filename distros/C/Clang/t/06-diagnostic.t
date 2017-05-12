#!perl -T

use Test::More;

use Clang;

my $index = Clang::Index -> new(0);
my $tunit = $index -> parse('t/fragments/test.c');
my $cursr = $tunit -> cursor;

my $diags = $tunit -> diagnostics;

my @formats  = map { $_ -> format(1) } @$diags;
my @expected = (
	"t/fragments/test.c:2:10: error: use of undeclared identifier 'argp'",
	"t/fragments/test.c:4:2: error: void function 'foo' should not return a value",
	"t/fragments/test.c:8:6: error: initializing 'int' with an expression of incompatible type 'void'"
);

is_deeply(\@formats, \@expected);

done_testing;

