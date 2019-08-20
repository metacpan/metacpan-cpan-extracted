# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;
use Data::Dumper;

plan(tests => 2);

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
	'item.foo.backend' => 'tar',
        'item.foo.directory' => 'baz',
	'item.bar.backend' => 'mysql',
        'item.bar.database' => 'quux'
    ],
    lexicon => \%keywords
);

ok($cfg->canonical, 'core.retain-interval=10 item.bar.backend="mysql" item.bar.database="quux" item.foo.backend="tar" item.foo.directory="baz"');
       
my %subkw = (
    item => {
	section => {
	    '*' => {
		select => sub {
		    my ($vref) = @_;
		    return 0 unless ref($vref) eq 'HASH';
		    return $vref->{backend}->{-value} eq 'tar';
		},
		section => {
		    backend => 1,
		    directory => {
			mandatory => 1,
		    }
		}
	    }
	}
    }
);

ok($cfg->lint(\%subkw));

        
