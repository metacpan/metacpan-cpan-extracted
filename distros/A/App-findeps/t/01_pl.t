use strict;
use warnings;

use Test::More 0.98 tests => 9;
use FastGlob qw(glob);

my @files = &glob('./t/scripts/01/*.pl');
for my $file (@files) {
    my $done = qx"./script/findeps $file";
    chomp $done;
    is $done, 'Dummy', "succeed to detect 'Dummy'";
}

done_testing;
