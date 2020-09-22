use strict;
use warnings;

use Test::More 0.98 tests => 2;
use FastGlob qw(glob);

use lib qw(lib t/lib);    # temporary

my @files = &glob('./t/scripts/02/*.pl');

for my $file (@files) {
    my $done = qx"./script/findeps --myLib t/lib $file";

    chomp $done;
    is $done, 'Dummy', "succeed to exculde --myLib";
}

done_testing;
