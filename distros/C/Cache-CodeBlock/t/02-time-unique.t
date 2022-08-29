use Test::More;
use strict;
use warnings;

use Cache::CodeBlock (
	driver => 'File',
    	root_dir => '/tmp',
	expires_in => 60
);

sub test {
	my $n = shift;
	my $data = cache {
		my $i = 0;
		for ($n .. 10) {
			$i += $_;
		}
		return $i;
	} 60, $n;
	return $data;
}

ok(1);

is(test(1), 55);
is(test(1), 55);


done_testing();
