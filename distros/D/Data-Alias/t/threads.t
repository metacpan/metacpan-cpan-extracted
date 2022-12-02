use warnings;
use strict;
use Config;

BEGIN {
	unless($Config{usethreads}) {
		require Test::More;
		Test::More::plan(skip_all => "non-threading perl build");
	}
	if($] < 5.010001) {
		require Test::More;
		Test::More::plan(skip_all => "threads are broken in this perl version");
	}
	eval { require threads; };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "threads unavailable");
	}
}

use threads;

use Test::More tests => 1;

use Data::Alias;
sub worker { eval "1 + 1"; return 1; }

my $thr = threads->create(\&worker);
$thr->join();
ok 1;

1;
