# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 1);

my %keywords = (
    core => {
	section => {
	    'retain-interval' => { mandatory => 1 },
	    'tempdir' => 1,
	    'verbose' => 1,
	}
    },
    backend => {
	section => {
	    file => {
		section => {
		    name => { mandatory => 1 },
		    local => 1
		}
	    }
	}
    }
);

my $cfg = new TestConfig(
    config => [
	'core.tempdir' => '/tmp',
	'backend.file.local' => 1
    ],
    lexicon => \%keywords,
    expect => [ 'mandatory variable "core.retain-interval" not set',
		'mandatory variable "backend.file.name" not set' ]);
ok($cfg->errors()==2);
