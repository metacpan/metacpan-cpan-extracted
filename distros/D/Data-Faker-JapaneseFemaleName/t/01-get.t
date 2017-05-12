#!perl

use Test::More tests => 6;

BEGIN {
	use_ok( 'Data::Faker', qw/JapaneseFemaleName/ );
}

ok( my $faker = Data::Faker->new() );

ok( my $data  = $faker->japanese_female_name );
ok( utf8::is_utf8( $data ) );

ok( $data  = $faker->japanese_female_name );
ok( utf8::is_utf8( $data ) );
