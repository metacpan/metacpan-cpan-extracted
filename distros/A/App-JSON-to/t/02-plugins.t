use strict;
use warnings;

use Test::More tests => 4;
use Test::Is 'perl v5.8';
use App::JSON::to;

my @TESTS = (
    '{"a":4}' => {
	perl => "{a => 4}\n",
	yaml => <<YAML
---
a: 4
YAML
    },
    '[1,2,3]' => {
	perl => "[1,2,3]\n",
	yaml => <<YAML
---
- 1
- 2
- 3
YAML
    },
);

while (my ($in, $tests) = splice @TESTS, 0, 2) {
    foreach my $t (sort keys %$tests) {
	SKIP: {
	    my $out;
	    {
		local *STDOUT; # STDOUT is used for test output
		local *STDIN;
		open STDIN,  '<', \$in   or skip q{can't reopen STDIN}, 1;
		open STDOUT, '>', \$out  or skip q{can'r reopen STDOUT}, 1;
		App::JSON::to::run($t, $in);
		close STDOUT;
		close STDIN;
	    }
	    is($out, $tests->{$t}, "$in => $t") and note $tests->{$t};
	}
    }
}

