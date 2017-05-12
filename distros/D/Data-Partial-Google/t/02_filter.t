#!perl
use strict;
use warnings;
use Test::Most;
use Data::Partial::Google;

my $mask = Data::Partial::Google->new('a,b(d/*/z,b(g)),c');

cmp_deeply(
	$mask->filter,
	noclass({
		properties => {
			a => undef,
			b => {
				properties => {
					d => {
						properties => {
							'*' => {
								properties => {
									z => undef,
								}
							}
						}
					},
					b => {
						properties => {
							g => undef,
						}
					}
				}
			},
			c => undef,
		}
	}),
	'filter compiles'
);

my $object = {
	a => 11,
	n => 00,
	b => [{
		d => { g => { z => 22 }, b => 34, c => { a => 32 } },
		b => [{ z => 33 }],
		k => 99,
	}],
	c => 44,
	g => 99,
};

my $expected = {
	a => 11,
	b => [{
		d => {
			g => {
				z => 22,
			}
		}
	}],
	c => 44
};

cmp_deeply($mask->mask($object), $expected, 'filters properly');

done_testing;
