use strict;
use warnings;
use Test::More;
use Data::Undump qw(undump);
use Data::Dumper;
our @tests;
{
    local $/= "";
    while (<DATA>) {
        chomp;
        push @tests, [split /\s*\|\s*/, $_, 2];
    }
}
plan tests => 1 + @tests;
pass();
foreach my $test (@tests) {
    my ($dump, $want_error)= @$test;
    my $res= undump($dump);
    my $got_error= $@ || "";
    s/^\s+//, s/\s+\z// for $got_error;
    is( $got_error, $want_error, "code: >>$dump<<")
        or diag("result was " . Dumper($res));
}

__DATA__
{ | unterminated HASH constructor

{ foo => | unterminated HASH constructor

{ foo => [ | unterminated ARRAY constructor

{ foo foo => | expected fat comma after bareword

"foo | unterminated double quoted string

'foo | unterminated single quoted string

001234 | Zero may not be followed by another digit at the start of a number

-foo | bare '-' only allowed to signify negative number

1. | Unexpected end of floating point number after decimal point

12-34 | Unhandled tail garbage

{ {} => undef } | unexpected open bracket '{' when expecting a key

{ undef => {} } | got an undef when we wanted a key

{ a,,,b } | expected fat comma after bareword

{ a,1 } | expected fat comma after bareword

{ a => => b } | unexpected fat comma when expecting a value

{ a => x => => b } | unexpected fat comma when expecting a key

$VAR1 | Encountered variable in input. This is not eval - can not undump code

[ 1, # ] | unterminated ARRAY constructor

{ 1,#2 } | unterminated HASH constructor

bless( [ ], "Foo", ) | expecting a close paren for bless but got a ','
