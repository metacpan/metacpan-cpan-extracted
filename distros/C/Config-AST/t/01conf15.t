# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 2);
	
my $t = new TestConfig(
    lexicon => {
	load => {
	    section => {
		'*' => {
		    section => {
			mode => 1,
		    }
		}
	    }
	}
    },
    config => [
	'load.bar' => 'foo'
    ],
    expect => ['"load.bar" must be a section']
);
ok($t->errors,1);

$t = new TestConfig(
    lexicon => {
	load => 1
    },
    config => [
	'load.bar.foo' => 'foo'
    ],
    expect => ['load: unknown section']
);
ok($t->errors,1);

	
