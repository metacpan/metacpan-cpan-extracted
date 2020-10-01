use strict;
use warnings;

use Test::More 0.98 tests => 3;
use FastGlob qw(glob);

my @files = &glob('t/scripts/03/*.pl');
for my $file (@files) {
    my $done = qx"$^X script/findeps $file 2>/dev/null";
    chomp $done;
    is $done, 'Dummy', "succeed to ignore quoted by 'eval'";
}

done_testing;
