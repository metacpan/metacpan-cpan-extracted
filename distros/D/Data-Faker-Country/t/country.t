use strict;
use warnings;

use Test::More;

use Data::Faker;

my $faker = new_ok('Data::Faker');
cmp_ok(length($faker->country), '>', 0, 'have nonzero length for sample country');
ok(eval { length Locale::Country::code2country($faker->country_code) }, 'can reverse lookup a sample country code');
ok(eval { length Locale::Country::country2code($faker->country) }, 'can reverse lookup a sample country');

done_testing;

