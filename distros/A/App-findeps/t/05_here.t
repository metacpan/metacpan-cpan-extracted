use strict;
use warnings;

use Test::More 0.98 tests => 3;
use FastGlob qw(glob);

my @files = &glob('t/scripts/05/*.pl');
for my $file (@files) {
    my $done = qx"$^X script/findeps $file";
    chomp $done;
    is $done, 'Dummy', "succeed to ignore 'HERE' in here document";
}

done_testing;
