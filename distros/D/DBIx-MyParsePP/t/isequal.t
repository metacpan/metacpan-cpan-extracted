use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl isequal.t'

#########################

use Test::More tests => 3;

use DBIx::MyParsePP;

my $parser1 = DBIx::MyParsePP->new();
my $query1 = $parser1->parse('SELECT a, b FROM c JOIN d USING(somekey)');
my $parser2 = DBIx::MyParsePP->new();
my $query2 = $parser2->parse('SELECT a, b FROM c JOIN d USING(somekey)');

ok( $query1->root()->isEqual( $query2->root() ) == 1 );
ok( $query1->shrink()->isEqual( $query2->shrink() ) == 1 );
ok( $query1->shrink()->isEqual( $query2->root() ) == 0 );
