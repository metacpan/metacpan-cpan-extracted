use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl error.t'

#########################

use Test::More tests => 16;

BEGIN { use_ok('DBIx::MyParsePP') };
BEGIN { use_ok('DBIx::MyParsePP::Query') };
BEGIN { use_ok('DBIx::MyParsePP::Rule') };
BEGIN { use_ok('DBIx::MyParsePP::Token') };

my $query_class = 'DBIx::MyParsePP::Query';
my $rule_class = 'DBIx::MyParsePP::Rule';
my $token_class = 'DBIx::MyParsePP::Token';

my $parser = DBIx::MyParsePP->new();

my $query = $parser->parse("SELECT\n(1");
ok(defined $query, 'error1');

ok(ref($query) eq $query_class,'error2');
ok(!defined($query->root()), 'error3');

ok(ref($query->expected()) eq 'ARRAY', 'error4');
my @expected = @{$query->expected()};

ok($expected[0] eq ')', 'error5');
ok($expected[1] eq ',', 'error6');

ok(ref($query->actual()) eq $token_class, 'error7');
my $actual = $query->actual();
ok($actual->type() eq 'END_OF_INPUT', 'error8');

ok($query->line() == 2, 'error9');
ok($query->pos() == 10, 'error10');

my $tokens = $query->tokens();

ok($tokens->[0]->type() eq 'SELECT_SYM','error11');
ok($tokens->[1]->value() eq '(','error12');
