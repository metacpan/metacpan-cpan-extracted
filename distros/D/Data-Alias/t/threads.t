use warnings;
use strict;

BEGIN {
	eval { require threads; };
	if($@ =~ /\AThis Perl not built to support threads/) {
		require Test::More;
		Test::More::plan(skip_all => "non-threading perl build");
	}
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
