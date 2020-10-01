use strict;
use warnings;

use Test::More 0.98 tests => 9;
use FastGlob qw(glob);

my @files = &glob('t/scripts/02/*.pl');
for my $file (@files) {
    my $done = qx"$^X script/findeps -L t/lib $file";
    chomp $done;
    is $done, 'Dummy', "succeed to detect 'Dummy'";
}

done_testing;
