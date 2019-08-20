# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 1);

my %keywords = (
    core => {
	section => {
	    'tempdir' => 1,
	    'verbose' => 1,
	}
    },
    backend => {
	section => {
	    file => 1
	}
    }
);
my $cfg = new TestConfig(
    config => [
	'core.tempdir' => '/tmp',
	'core.output' => 'file'
    ],
    lexicon => \%keywords,
    expect => [ 'keyword "output" is unknown' ]);
ok($cfg->errors() == 1);
