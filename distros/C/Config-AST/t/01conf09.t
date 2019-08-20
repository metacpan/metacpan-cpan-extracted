# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 2);

my %keywords = (
    core => {
	section => {
	    backend => { mandatory => 1, default => "file" },
	    acl => 1
	}
    },
    file => {
	section => {
	    name => 1
	}
    }
);

my $cfg = new TestConfig(lexicon => \%keywords);
ok($cfg);
ok($cfg->canonical, q{core.backend="file"});


