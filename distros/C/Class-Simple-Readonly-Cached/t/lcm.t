#!perl -w

use strict;
use warnings;
use CHI;
use Test::Needs 'Locale::Country::Multilingual';

# Load at compile time so Sub::Private's CHECK block runs at the correct phase.
# The use_ok() calls below are still exercised (require is a no-op for already-
# loaded modules) and keep the test count correct.
use Test::NoWarnings;
use Class::Simple::Readonly::Cached;

use Test::Most tests => 16;

my $cache = CHI->new(driver => 'RawMemory', datastore => {});
$cache->on_set_error('die');
$cache->on_get_error('die');

my $lcm = new_ok('Class::Simple::Readonly::Cached' => [{ cache => $cache, object => new_ok('Locale::Country::Multilingual') }]);

is($lcm->code2country('US', 'fr_FR'), 'États-Unis', 'First call to États-Unis');
is($lcm->code2country('US', 'fr_FR'), 'États-Unis', 'Second call to États-Unis');
is($lcm->code2country('US'), 'United States', 'First call to United States');
is($lcm->code2country('US', 'fr_FR'), 'États-Unis', 'Third call to États-Unis');
is($lcm->code2country('US'), 'United States', 'Second call to United States');
is($lcm->code2country('US', 'fr_FR'), 'États-Unis', 'Fourth call to États-Unis');

$lcm->set_lang('fr');
is($lcm->country2code('Angleterre'), undef, 'Angleterre returns undef');
is($lcm->country2code('Angleterre'), undef, 'Second call to Angleterre returns undef');
is($lcm->country2code('England'), undef, 'England returns undef');
is($lcm->country2code('Angleterre'), undef, 'Third call to Angleterre returns undef');
is($lcm->country2code('England'), undef, 'Third call to England returns undef');

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
is($count, 7, 'cache contains 7 hits');

my $misses = $lcm->state()->{'misses'};
$count = 0;
while(my($k, $v) = each %{$misses}) {
	$count += $v;
}
is($count, 5, 'cache contains 5 misses');
