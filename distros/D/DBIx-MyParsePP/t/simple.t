use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl simple.t'

#########################

use Test::More tests => 13;

BEGIN { use_ok('DBIx::MyParsePP') };
BEGIN { use_ok('DBIx::MyParsePP::Query') };
BEGIN { use_ok('DBIx::MyParsePP::Rule') };
BEGIN { use_ok('DBIx::MyParsePP::Token') };

my $query_class = 'DBIx::MyParsePP::Query';
my $rule_class = 'DBIx::MyParsePP::Rule';
my $token_class = 'DBIx::MyParsePP::Token';

my $parser = DBIx::MyParsePP->new();

my $query = $parser->parse("SELECT 1");
ok(defined $query, 'simple1');

ok(ref($query) eq $query_class,'simple2');

my $root = $query->getRoot();
ok(ref($root) eq $rule_class,'simple3');
ok($root->name() eq 'query','simple4');

my @children = $root->children();
ok(ref($children[0]) eq $rule_class,'simple5');
ok($children[0]->name() eq 'verb_clause', 'simple6');

ok(ref($children[1]) eq $token_class,'simple7');
ok($children[1]->type() eq 'END_OF_INPUT', 'simple8');

ok([[[$root->children()]->[0]->children()]->[0]->children()]->[0]->name() eq 'select', 'simple8');
