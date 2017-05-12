use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl options.t'

#########################

use Test::More tests => 4;

use DBIx::MyParsePP;
use DBIx::MyParsePP::Lexer;

my $parser1 = DBIx::MyParsePP->new();
my $query1 = $parser1->parse('SELECT "a" || "b"');
my $shrink1 = $query1->shrink();
my $expr1 = $shrink1->extract('simple_expr');
my @children1 = $expr1->children();
ok ($children1[1]->type() eq 'OR_OR_SYM','options1');


my $parser2 = DBIx::MyParsePP->new( sql_mode => MODE_PIPES_AS_CONCAT );
my $query2 = $parser2->parse('SELECT "a" || "b"');
my $shrink2 = $query2->shrink();
my $expr2 = $shrink2->extract('bool_or_expr');
ok(defined $expr2, 'options2');

my $parser3 = DBIx::MyParsePP->new( version => 10000 );
my $query3 = $parser3->parse('SELECT /*!20000 1 */');
ok(!defined $query3->root(), 'options3');

my $parser4 = DBIx::MyParsePP->new( version => 20000 );
my $query4 = $parser4->parse('SELECT /*!10000 1 */');
ok(defined $query4->root(), 'options4');


