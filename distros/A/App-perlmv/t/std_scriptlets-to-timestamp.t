#!perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use FindBin '$Bin';
require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv(["1.txt"], {extra_opt=>"to-timestamp"},
            sub { my $files = shift; @$files == 1 && $files->[0] =~ /^\d{4}-\d\d-\d\d-\d\d_\d\d_\d\d$/ },
            'to-timestamp');

end_testing();
