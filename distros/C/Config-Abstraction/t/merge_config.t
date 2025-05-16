#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Config::Abstraction') }

subtest 'basic hash merge' => sub {
	my $conf = Config::Abstraction->new(data => {
		foo => 'baz',
		nums => [3],
		nested => { b => 2 }
	});
	my $defaults = {
		foo => 'bar',
		nums => [1, 2],
		nested => { a => 1 }
	};

	my $merged = $conf->merge_defaults($defaults);

	is $merged->{foo}, 'baz', 'second hash overrides scalar value';
	is_deeply $merged->{nums}, [3], 'second hash overrides arrayref';
	# is_deeply $merged->{nested}, { a => 1, b => 2 }, 'nested hash merged correctly';
};

subtest 'merge with undefined override' => sub {
	my $conf = Config::Abstraction->new(data => {'foo' => 1});
	my $merged = $conf->merge_defaults({});

	is($merged->{'foo'}, 1, 'undefined override treated as empty hash');
};

subtest 'deep nested merge' => sub {
	my $a = {
		outer => {
			inner => {
				setting1 => 'yes',
				setting2 => 'no'
			}
		}
	};
	my $b = {
		outer => {
			inner => {
				setting2 => 'maybe',
				setting3 => 'sure'
			}
		}
	};
	my $conf = Config::Abstraction->new(data => $b);

	my $merged = $conf->merge_defaults(defaults => $a, merge => 1, deep => 1);

	is($merged->{outer}{inner}{setting1}, 'yes', 'retains original setting1');
	is($merged->{outer}{inner}{setting2}, 'maybe', 'overrides setting2');
	is($merged->{outer}{inner}{setting3}, 'sure', 'adds setting3');

	$merged = $conf->merge_defaults(defaults => $a, deep => 1);

	isnt($merged->{outer}{inner}{setting1}, 'yes', 'loses original setting1');
	is($merged->{outer}{inner}{setting2}, 'maybe', 'overrides setting2');
	is($merged->{outer}{inner}{setting3}, 'sure', 'adds setting3');

};

done_testing();
