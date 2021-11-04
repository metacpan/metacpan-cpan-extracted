use strict;
use warnings;

use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval "use Test::Kwalitee tests => [ qw( -has_meta_yml ) ]";

	if($@) {
		plan(skip_all => 'Test::Kwalitee not installed; skipping') if $@;
	} else {
		unlink('Debian_CPANTS.txt') if -e 'Debian_CPANTS.txt';
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}
