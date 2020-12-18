#!perl -wT

use strict;
use warnings;
use CHI;
use Test::Most;

LCM: {
	eval 'use Locale::Country::Multilingual';
	if($@) {
		plan(skip_all => 'Locale::Country::Multilingual required for this test');
	} else {
		plan(tests => 13);

		use_ok('Test::NoWarnings');
		use_ok('Class::Simple::Readonly::Cached');
		my $cache = CHI->new(driver => 'RawMemory', datastore => {});
		$cache->on_set_error('die');
		$cache->on_get_error('die');

		my $lcm = new_ok('Class::Simple::Readonly::Cached' => [ cache => $cache, object => new_ok('Locale::Country::Multilingual') ]);

		is($lcm->code2country('US', 'fr_FR'), 'États-Unis', 'First call to États-Unis');
		is($lcm->code2country('US', 'fr_FR'), 'États-Unis', 'Second call to États-Unis');
		is($lcm->code2country('US'), 'United States', 'First call to United States');
		is($lcm->code2country('US', 'fr_FR'), 'États-Unis', 'Third call to États-Unis');
		is($lcm->code2country('US'), 'United States', 'Second call to United States');
		is($lcm->code2country('US', 'fr_FR'), 'États-Unis', 'Fourth call to États-Unis');

		if($ENV{'TEST_VERBOSE'}) {
			foreach my $key($cache->get_keys()) {
				diag($key);
			}
		}

		# diag(Data::Dumper->new([$cached->state()])->Dump());
		my $hits = $lcm->state()->{'hits'};
		my $count;
		while(my($k, $v) = each %{$hits}) {
			$count += $v;
		}
		is($count, 4, 'cache contains 4 hits');

		my $misses = $lcm->state()->{'misses'};
		$count = 0;
		while(my($k, $v) = each %{$misses}) {
			$count += $v;
		}
		is($count, 2, 'cache contains 2 misses');
	}
}
