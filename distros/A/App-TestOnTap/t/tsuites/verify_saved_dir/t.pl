use strict;
use warnings;

use Test::More tests => 10;

for (1 .. 10)
{
	pass("$_ ($0)");
}

open(my $fh, '>', "$ENV{TESTONTAP_SAVE_DIR}/persist") or die;
print $fh "persist this\n";
close($fh);

done_testing();
