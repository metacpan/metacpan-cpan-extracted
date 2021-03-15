use strict;
use warnings;

use Test::Most;

BEGIN {
	if($ENV{AUTHOR_TESTING}) {
		eval {
			require Test::EOL;
		};
		if($@) {
			plan(skip_all => 'Test::EOL not installed');
		} else {
			import Test::EOL;
			all_perl_files_ok({ trailing_whitespace => 1 });
		}
	} else {
		plan(skip_all => 'Author tests not required for installation');
	}
}
