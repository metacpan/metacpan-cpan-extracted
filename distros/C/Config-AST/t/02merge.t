# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use Config::AST qw(:sort);

plan(tests => 1);

my $t = new Config::AST(
    lexicon => {
	x => {
	    section => {
		number => { array => 1 },
		name => 1
	    }
    	}
    });

my $node = new Config::AST::Node::Section;
$node->subtree(number => new Config::AST::Node::Value(
		   value => [1],
		   locus => new Text::Locus('input',1)));
$node->subtree(name => new Config::AST::Node::Value(
		   value => 'foo',
		   locus => new Text::Locus('input',2)));
$t->add_node(x => $node);

$node = new Config::AST::Node::Section;
$node->subtree(number => new Config::AST::Node::Value(
		   value => 2,
		   locus => new Text::Locus('input',3)));
$node->subtree(name => new Config::AST::Node::Value(
		   value => 'bar',
		   locus => new Text::Locus('input',4)));
$t->add_node(x => $node);

ok($t->canonical(delim => ' ', locus => 1),
    q{[input:2]: x.name="bar" [input:1,3]: x.number=[1,2]});
