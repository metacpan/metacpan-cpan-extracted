#!/usr/bin/perl
# '$Id: 80preprocessor_math.t,v 1.3 2005/08/06 23:28:40 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 140;
#use Test::More qw/no_plan/;

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::Parser::PreProcessor::Math';
    use_ok($CLASS) or die;
}

foreach my $compare (qw( is = < <= > >= == \= )) {
    ok $CLASS->_compare($compare), "$compare matches : compare";
}

my @math_terms = qw/
    X
    Y_
    3
    0.3
    3.0
    .3
    -7
    +.3
    -.19
/;
foreach my $math_term (@math_terms) {
    ok $CLASS->_simple_math_term($math_term), "$math_term matches : simple math term";
}
my @not_math_terms = qw/
    x
    y_
    .
    _
    _y
    _9
/;
foreach my $not_math_term (@not_math_terms) {
    ok ! $CLASS->_simple_math_term($not_math_term), "$not_math_term should not match : simple math term";
}

foreach my $op (qw{- + * / % **}) {
    ok $CLASS->_op($op), "$op matches : op";
}

foreach my $not_op (qw{ . _ ( ) }) {
    ok ! $CLASS->_op($not_op), "$not_op should not match :  op";
}
 
my @rhs = (
    '3',
    'A%2',
    'A % 2',
    '17.2 * A % 2',
    'A+B+C+D+2',
    '7/2 ** 4',
);
foreach my $simple_rhs (@rhs) {
    ok $CLASS->_simple_rhs($simple_rhs), "$simple_rhs matches : simple rhs";
}

my @not_rhs = (
    '(3)',
    'A]2',
    'A _ 2',
    '3 3',
    '% 3',
    '2 + 2 + Y -',
);
foreach my $not_simple_rhs (@not_rhs) {
    ok ! $CLASS->_simple_rhs($not_simple_rhs), "$not_simple_rhs should not match : simple rhs";
}

my @simple_group_term = (
    '(3)',
    '( A%2)',
    '(A % 2 )',
    '(17.2 * A % 2 )',
    '(A+B/C+D+2)',
);
foreach my $simple_group_term (@simple_group_term) {
    ok $CLASS->_simple_group_term($simple_group_term), "$simple_group_term matches : simple group term";
}

my @not_simple_group_term = (
    '((3))',
    '( A%2',
    '(A % 2 ))',
    '(17.2 * (A) % 2 )',
    '(A+B/)C+D+2)',
);
foreach my $not_simple_group_term (@not_simple_group_term) {
    ok ! $CLASS->_simple_group_term($not_simple_group_term), "$not_simple_group_term should not match : simple group term";
}
my @math_term = (
    '3',
    '0.3',
    '3.0',
    '(3)',
    '.3',
    '-.3',
    '( A%2)',
    '(A % 2 )',
    '(17.2 * A % 2 )',
    '(A+B/C+D+2)',
);
foreach my $math_term (@math_term) {
    ok $CLASS->_math_term($math_term), "$math_term matches : math term";
}

my @not_math_term = (
    'x',
    'y_',
    ' % _',
    '3 + ',
    '- 0.3',
);
foreach my $not_math_term (@not_math_term) {
    ok ! $CLASS->_math_term($not_math_term), "$not_math_term should not match : math term";
}

my @complex_rhs = (
    'X',
    'Y_',
    '3',
    '.3',
    '3.0',
    '(3)',
    '( A%2)',
    '(A % 2 )',
    '(17.2 * A % 2 )',
    '(A+B/C+D+2)',
    '2 + (3)',
    '( A%2) / 3 * (2+2)',
);
foreach my $complex_rhs (@complex_rhs) {
    ok $CLASS->_complex_rhs($complex_rhs), "$complex_rhs matches : complex rhs";
}

my @not_complex_rhs = (
    'x',
    '_Y',
    '3)',
);
foreach my $not_complex_rhs (@not_complex_rhs) {
    ok ! $CLASS->_complex_rhs($not_complex_rhs), "$not_complex_rhs should not match : complex rhs";
}

#print $CLASS->expression;
my @complex_group_term = (
    '( X )',
    '( Y_ )',
    '( 3 )',
    '( .3 )',
    '( 3.0 )',
    '( (3) )',
    '(( A%2) )',
    '( (A % 2 ) )',
    '( (17.2 * A % 2 ) )',
    '( (A+B/C+D+2))',
    '(2 + (3))',
    '( ( A%2) / 3 * (2+2) )',
);
foreach my $complex_group_term (@complex_group_term) {
    ok $CLASS->_complex_group_term($complex_group_term), "$complex_group_term matches : complex group term";
}

my @not_complex_group_term = (
    '( x )',
    '()',
    '( 3',
    '( .3 ))',
    '(( 3.)0 )',
    '(( A%2 )',
    '( (A+B/(C+D+2))',
    '( ( A%2) (/) 3 * (2+2) )',
);
foreach my $not_complex_group_term (@not_complex_group_term) {
    ok ! $CLASS->_complex_group_term($not_complex_group_term), "$not_complex_group_term should not match : complex group term";
}

can_ok $CLASS, '_lex';
my $rhs = '3';
is_deeply $CLASS->_lex($rhs), [[qw/ ATOM 3 /]], "$rhs : lexes properly";

$rhs = 'A + 3';
is_deeply $CLASS->_lex($rhs), [
    [qw/ ATOM A /],
    [qw/ OP   + /],
    [qw/ ATOM 3 /]
], "$rhs : lexes properly";

$rhs = 'A ** 3';
is_deeply $CLASS->_lex($rhs), [
    [qw/ ATOM A  /],
    [qw/ OP   ** /],
    [qw/ ATOM 3  /]
], "$rhs : lexes properly";

$rhs = '3 * ( 7 +4)';
is_deeply $CLASS->_lex($rhs), [
    [qw/ ATOM   3 /],
    [qw/ OP     * /],
    [qw/ LPAREN ( /],
    [qw/ ATOM   7 /],
    [qw/ OP     + /],
    [qw/ ATOM   4 /],
    [qw/ RPAREN ) /],
], "$rhs : lexes properly";

$rhs = '3 ** ( 7 +4)';
is_deeply $CLASS->_lex($rhs), [
    [qw/ ATOM   3  /],
    [qw/ OP     ** /],
    [qw/ LPAREN (  /],
    [qw/ ATOM   7  /],
    [qw/ OP     +  /],
    [qw/ ATOM   4  /],
    [qw/ RPAREN )  /],
], "$rhs : lexes properly";

$rhs = '3 * ( 7 + -4)';
is_deeply $CLASS->_lex($rhs), [
    [qw/ ATOM    3 /],
    [qw/ OP      * /],
    [qw/ LPAREN  ( /],
    [qw/ ATOM    7 /],
    [qw/ OP      + /],
    [qw/ ATOM   -4 /],
    [qw/ RPAREN  ) /],
], "$rhs : lexes properly";

$rhs = '-3 * ( 7 + -4)';
is_deeply $CLASS->_lex($rhs), [
    [qw/ ATOM   -3 /],
    [qw/ OP      * /],
    [qw/ LPAREN  ( /],
    [qw/ ATOM    7 /],
    [qw/ OP      + /],
    [qw/ ATOM   -4 /],
    [qw/ RPAREN  ) /],
], "$rhs : lexes properly";

$rhs = '-3 * (-7 + 4)';
is_deeply $CLASS->_lex($rhs), [
    [qw/ ATOM  -3 /],
    [qw/ OP     * /],
    [qw/ LPAREN ( /],
    [qw/ ATOM  -7 /],
    [qw/ OP     + /],
    [qw/ ATOM   4 /],
    [qw/ RPAREN ) /],
], "$rhs : lexes properly";

$rhs = 'E ** ( PI * I )';
is_deeply $CLASS->_lex($rhs), [
  [ 'ATOM',   'E' ],
  [ 'OP',    '**' ],
  [ 'LPAREN', '(' ],
  [ 'ATOM',  'PI' ],
  [ 'OP',     '*' ],
  [ 'ATOM',   'I' ],
  [ 'RPAREN', ')' ],
], "$rhs : lexes properly";

can_ok $CLASS, '_parse';
is $CLASS->_parse([
    [qw/ ATOM 5 /],
    [qw/ OP   * /],
    [qw/ ATOM 4 /],
]), 'mult(5, 4)', '... and simple expressions should parse properly';

is $CLASS->_parse([
    [qw/ ATOM 5 /],
    [qw{ OP   / }],
    [qw/ ATOM 4 /],
]), 'div(5, 4)', '... and simple expressions should parse properly';

is $CLASS->_parse([
    [qw/ ATOM 5 /],
    [qw{ OP   + }],
    [qw/ ATOM 4 /],
]), 'plus(5, 4)', '... and simple expressions should parse properly';

is $CLASS->_parse([
    [qw/ ATOM 5 /],
    [qw{ OP   - }],
    [qw/ ATOM 4 /],
]), 'minus(5, 4)', '... and simple expressions should parse properly';

is $CLASS->_parse([
    [qw/ ATOM 5 /],
    [qw{ OP   % }],
    [qw/ ATOM 4 /],
]), 'mod(5, 4)', '... and simple expressions should parse properly';

is $CLASS->_parse([
    [qw/ ATOM 5 /],
    [qw{ OP   + }],
    [qw/ ATOM 4 /],
    [qw{ OP   * }],
    [qw/ ATOM 7.2/],
]), 'plus(5, mult(4, 7.2))', '... and compound expressions should parse properly';

is $CLASS->_parse([
    [qw/ ATOM 5 /],
    [qw{ OP   * }],
    [qw/ ATOM 4 /],
    [qw{ OP   + }],
    [qw/ ATOM 7.2/],
]), 'plus(mult(5, 4), 7.2)', '... and compound expressions should parse properly';

is $CLASS->_parse([
    [qw/ ATOM   5 /],
    [qw/ OP     * /],
    [qw/ LPAREN ( /],
    [qw/ ATOM   4 /],
    [qw/ OP     + /],
    [qw/ ATOM 7.2 /],
    [qw/ RPAREN ) /],
]), 'mult(5, plus(4, 7.2))', '... and parentheses should group properly';

is $CLASS->process('X is 3 + 2.'), 'is(X, plus(3, 2)).',
    '... and it should be able to transform full math expressions.';

my @expressions = (
    'X is 3.',
    'is(X, 3).',

    'Answer = A + B.',
    'eq(Answer, plus(A, B)).',

    'Answer = A + B + C.',
    'eq(Answer, plus(plus(A, B), C)).',

    'Answer = A + B + C + D + E.',
    'eq(Answer, plus(plus(plus(plus(A, B), C), D), E)).',

    '7 >= 3 * 7 + 4.',
    'ge(7, plus(mult(3, 7), 4)).',
    
    '7 < 3 * (7 + 4),',
    'lt(7, mult(3, plus(7, 4))),',

    'X = 3 % 2.',
    'eq(X, mod(3, 2)).',

    'X = (3 % 2).',
    'eq(X, mod(3, 2)).',

    'Result is (3 + 4) % ModValue.',
    'is(Result, mod(plus(3, 4), ModValue)).',

    'Result is ((3 + 4) % ModValue).',
    'is(Result, mod(plus(3, 4), ModValue)).',

    'Answer is 9 / (3 + (4+7) % ModValue).',
    'is(Answer, div(9, mod(plus(3, plus(4, 7)), ModValue))).',

    'Answer is 9 / (3 + (4+7) % ModValue) + 2 / (3+7).',
    'is(Answer, plus(div(9, mod(plus(3, plus(4, 7)), ModValue)), div(2, plus(3, 7)))).',
    
    'X \= 9 / (3 + (4+7) % ModValue) + 2 / (3+7).',
    'ne(X, plus(div(9, mod(plus(3, plus(4, 7)), ModValue)), div(2, plus(3, 7)))).',

    '-1 is E ** (PI * I).',
    'is(-1, pow(E, mult(PI, I))).',
);

while (my ($before, $after) = splice @expressions, 0, 2) {
    is $CLASS->process($before), $after,
        "$before : should transform correctly";
}

