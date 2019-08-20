# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 1);

my %keywords = (
    core => {
	section => {
	    list => {
		array => 1
	    },
	    pidfile => 1
	}
    }
);

my $cfg = new TestConfig(
    config => [
	'core.list' => 'en',
	'core.list' => 'to',
	'core.list' => '5',

	'core.pidfile' => 'file1',
	'core.pidfile' => 'file2'
    ],
    lexicon => \%keywords);
ok($cfg->canonical(),'core.list=["en","to",5] core.pidfile="file2"');
