package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

my $path = $ENV{PATH};

require_ok 'Date::Manip';

my $ver = Date::Manip->VERSION();
$ver =~ s/_//smx;

if ( $ver >= 6.32 ) {
    is $ENV{PATH}, $path, 'Date::Manip RT 80435 is fixed'
	and diag 'RT 80435 is fixed. You can remove code that refers to it';
} else {
    ok "Date::Manip @{[ Date::Manip->VERSION()
	]} is not subject to RT 80435.";
}

done_testing;

1;

# ex: set textwidth=72 :
