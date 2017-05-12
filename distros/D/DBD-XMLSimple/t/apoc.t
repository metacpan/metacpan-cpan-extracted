#!perl -w

use strict;

use Test::Most;
eval "use Test::Apocalypse";

if ($@){
	plan skip_all => 'Test::Apocalypse required for testing the distribution';
} else {
	is_apocalypse_here();
}
