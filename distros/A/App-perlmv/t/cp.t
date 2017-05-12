#!perl -T

use strict;
use warnings;
use Test::More tests => 2;
use FindBin '$Bin';
($Bin) = $Bin =~ /(.+)/;

our $Perl;
our $Dir;

require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv([1, 2, 3], {code=>'$_++', mode=>'c'}, ["1", "2", "2.1", "3", "3.1", "4"], 'normal');

end_testing();
