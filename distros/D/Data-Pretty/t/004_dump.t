#!perl -w

use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
# use Test::More qw(plan ok);
use Test::More;
plan tests => 39;

use Data::Pretty qw(dump);
local $Data::Pretty::DEBUG = $DEBUG;

is(dump(), "()", "()");
is(dump("abc"), qq("abc"), qq("abc"));
is(dump("1\n"), qq("1\\n"), qq("1\\n"));
is(dump(undef), "undef", "undef");
is(dump(0), "0", "0");
is(dump(1234), "1234", "integer");
is(dump(12345), "12345", "longer integer");
is(dump(12345678), "12345678", "another longer integer");
is(dump(123456789012345), "123456789012345", "much longer integer");
is(dump(0.333), "0.333", "float");
like(dump(1/3), qr/^0\.3+\z/, '/^0\.3+\z/');
is(dump(-33), "-33", "-33");
is(dump(-1.5), "-1.5", "-1.5");
is(dump("Inf"), qq("Inf"), qq("Inf"));
is(dump("-Inf"), qq("-Inf"), qq("-Inf"));
is(dump("nan"), qq("nan"), qq("nan"));
is(dump("NaN"), qq("NaN"), qq("NaN"));
is(dump("0123"), qq("0123"), qq("0123"));
is(dump(1..2), "(1, 2)", "(1, 2)");
is(dump(1..3), "(1, 2, 3)", "(1, 2, 3)");
is(dump(1..4), "(1 .. 4)", "(1 .. 4)");
is(dump(1..5,6,8,9), "(1 .. 6, 8, 9)", "(1 .. 6, 8, 9)");
is(dump(1..5,4..8), "(1 .. 5, 4 .. 8)", "(1 .. 5, 4 .. 8)");
is(dump([-2..2]), "[-2 .. 2]", "[-2 .. 2]");
is(dump(["a0" .. "z9"]), qq(["a0" .. "z9"]), qq(["a0" .. "z9"]));
is(dump(["x", 0, 1, 2, 3, "a", "b", "c", "d"]), qq(["x", 0 .. 3, "a" .. "d"]), qq(["x", 0 .. 3, "a" .. "d"]));
is(dump({ a => 1, b => 2 }), "{ a => 1, b => 2 }", "{ a => 1, b => 2 }");
is(dump({ 1 => 1, 2 => 1, 10 => 1 }), "{ 1 => 1, 2 => 1, 10 => 1 }", "{ 1 => 1, 2 => 1, 10 => 1 }");
is(dump({ 0.14 => 1, 1.8 => 1, -0.5 => 1 }), qq({ -0.5 => 1, 0.14 => 1, 1.8 => 1 }), qq({ -0.5 => 1, 0.14 => 1, 1.8 => 1 }));
is(dump({ "1,1" => 1, "1,2" => 1 }), qq({ "1,1" => 1, "1,2" => 1 }), qq({ "1,1" => 1, "1,2" => 1 }));
is(dump({ a => 1, aa => 2, aaa => join("", "a" .. "z", "a" .. "z")}) . "\n", <<EOT, 'multi line hash');
{
    a => 1,
    aa => 2,
    aaa => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
}
EOT

is(dump({ a => 1, aa => 2, aaaaaaaaaaaaaa => join("", "a" .. "z", "a" .. "z")}) . "\n", <<EOT, 'multi line hash');
{
    a => 1,
    aa => 2,
    aaaaaaaaaaaaaa => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
}
EOT

is(dump(bless {}, "foo"), "bless({}, \"foo\")", "bless({}, \"foo\")");
is(dump(bless [], "foo"), "bless([], \"foo\")", "bless([], \"foo\")");
my $sv = [];
is(dump(bless \$sv, "foo"), "bless(do{\\(my \$o = [])}, \"foo\")", "bless(do{\\(my \$o = [])}, \"foo\")");
is(dump(bless { a => 1, aa => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz", aaa => \$sv}, "foo") . "\n", <<'EOT', 'multi line blessed hash');
bless({
    a => 1,
    aa => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
    aaa => bless(do{\(my $o = [])}, "foo"),
}, "foo")
EOT


# stranger stuff
is(dump({ a => sub
{
    my $v = shift( @_ );
    print( "Hello world $v\n" );
    return(1);
}, aa => do {require Symbol; Symbol::gensym()}}), q{do {
    require Symbol;
    {
        a => sub {
            my $v = shift @_;
            print "Hello world $v\n";
            return 1;
        },
        aa => Symbol::gensym(),
    };
}}, 'bless({}, "foo=bar")' );

is(dump(bless{}, "foo=bar"), 'bless({}, "foo=bar")');

{
    local $Data::Pretty::CODE_DEPARSE = 0;
    is(dump({ a => sub
    {
        my $v = shift( @_ );
        print( "Hello world $v\n" );
        return(1);
    }, aa => do {require Symbol; Symbol::gensym()}}),
       "do {\n    require Symbol;\n    { a => sub { ... }, aa => Symbol::gensym() };\n}");
}
