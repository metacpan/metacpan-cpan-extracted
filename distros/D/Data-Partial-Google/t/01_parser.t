#!perl
use strict;
use warnings;
use Test::Most;
use Data::Partial::Google::Parser;

my $cases = {
	'a' => {
		properties => {
			a => undef,
		}
	},
	'a,b,c' => {
		properties => {
			a => undef,
			b => undef,
			c => undef,
		}
	},
	'a,b(d/*/g,b),c' => {
		properties => {
			a => undef,
			b => {
				properties => {
					d => {
						properties => {
							'*' => {
								properties => {
									g => undef,
								}
							}
						}
					},
					b => undef,
				}
			},
			c => undef,
		}
	},
};

while (my ($rule, $filter) = each %$cases) {
	cmp_deeply(
		Data::Partial::Google::Parser->parse($rule),
		noclass($filter),
		$rule,
	);
}

done_testing;
