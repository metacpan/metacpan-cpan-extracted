#!perl

use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 25;

BEGIN {
	use_ok( 'App::Midgen' );
}

######
# let's check our subs/methods.
######

my @subs = qw(
	find_runtime_modules find_test_modules find_develop_modules
	first_package_name remove_noisy_children run
	remove_twins found_twins min_version mod_in_dist
	numify get_module_version
);

foreach my $subs (@subs) {
	can_ok( 'App::Midgen', $subs );
}

my @attributes = qw(
	core debug dual_life experimental zero
);
my $midgen1 = App::Midgen->new();

foreach my $attribute (@attributes) {
	is( $midgen1->{$attribute}, 0, "default found $attribute" );
}
is( $midgen1->{format}, 'dsl', "default found format" );

my $midgen2 = App::Midgen->new(
	core         => 1,
	dual_life    => 1,
	verbose      => 1,
	format       => 'mi',
	experimental => 1,
	zero         => 1,
	debug        => 1,
);
App::Midgen->new();

foreach my $attribute (@attributes) {
	is( $midgen2->{$attribute}, 1, "defined found $attribute" );
}
is( $midgen2->{format}, 'mi', "defined found output format" );


done_testing();

__END__

