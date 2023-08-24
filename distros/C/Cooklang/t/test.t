use 5.022;
use strict;
use warnings;
use lib './lib';
use Test::More;
use CookLang;

is( Recipe->new('Cook @onion nicely')->ast->{'ingredients'}[0]{'quantity'}, 1, 'Integer 1');
is( Recipe->new('Cook @onion{1} nicely')->ast->{'ingredients'}[0]{'quantity'}, 1, 'Integer 1');
is( Recipe->new('Cook @onion{1/2} nicely')->ast->{'ingredients'}[0]{'quantity'}, 0.5, 'Fraction 1/2');
is( Recipe->new('Cook @onion{1/3} nicely')->ast->{'ingredients'}[0]{'quantity'}, '1/3', 'Fraction 1/3');
done_testing;
