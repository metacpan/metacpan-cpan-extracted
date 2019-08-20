# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;
use Data::Dumper;

plan(tests => 2);

my %syntax = (
    load => {
	section => {
	    file => 1
	}
    },
    load => {
	section => {
	    '*' => {
		section => {
		    param => {
			section => {
			    mode => 1
			},
			mandatory => 1
		    }
		}
	    }
	}
    }
);
	

my $t = new TestConfig(lexicon => \%syntax,
		       expect => ['mandatory section [load * param] not present']);
ok($t->errors,1);
$t = new TestConfig(lexicon => \%syntax,
		    config => [
			'load.foo.param.mode' => 'rw'
		    ]);
ok($t->canonical, q{load.foo.param.mode="rw"});

	
