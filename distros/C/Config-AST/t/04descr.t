# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use Config::AST;
use Data::Dumper;

plan tests => 7;

my $ast = new Config::AST(lexicon => {
    a => 1,
    b => { mandatory => 1 },
    c => {
	section => {
	    d => { array => 1 },
	    e => 1,
	    f => {
		section => {
		    g => 1,
		    h => {
			section => {
			    i => 1,
			    j => 1,
			    k => 1
			}
		    }
		}
	    }
	}
    },
    l => {
	section => {
	    x => { mandatory => 1 },
	    '*' => '*'
	}
    }
});

sub dump_lexicon {
    my $arg = shift;
    Data::Dumper->new([$arg])->Terse(1)->Sortkeys(1)->Useqq(1)->Indent(0)->Dump
}

ok($ast->describe_keyword('a'),1);
ok(dump_lexicon($ast->describe_keyword('b')),q({"mandatory" => 1}));    
ok($ast->describe_keyword(qw(c f g)),1);
ok(!$ast->describe_keyword(qw(c f g i)));
ok($ast->describe_keyword(qw(c f h i)));
ok(!$ast->describe_keyword(qw(c f h i x)));
ok($ast->describe_keyword(qw(l y z)),'*');
