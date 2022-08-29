use Test::More;
use strict;
use warnings;

use Cache::CodeBlock (
	driver => 'File',
    	root_dir => '/tmp',
	expires_in => 60
);

sub test {
	my $data = cache {
		my $i = 0;
		for (0 .. 10) {
			$i += $_;
		}
		return $i;
	};
	return $data;
}

ok(1);

is(test(), 55);
is(test(), 55);


done_testing();
