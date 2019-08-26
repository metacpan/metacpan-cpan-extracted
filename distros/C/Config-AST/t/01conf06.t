# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 3);

my %keywords = (
    core => {
	section => {
	    'retain-interval' => { mandatory => 1 },
	    'tempdir' => 1,
	    'verbose' => 1,
	}
    },
    '*' => '*'
);

my $cfg = new TestConfig(
    config => [
	'core.retain-interval' => 10,
	'core.tempdir' => '/tmp',
	'backend.file.local' => 1,
        'backend.file.level' => 3
    ],
    lexicon => \%keywords);
	
ok($cfg->canonical, 'backend.file.level=3 backend.file.local=1 core.retain-interval=10 core.tempdir="/tmp"');

ok($cfg->lint(\%keywords));

my %subkw = (
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

ok(!$cfg->lint(\%subkw,
	   expect => [ 'keyword "level" is unknown',
		       'mandatory variable "backend.file.name" not set' ]));
