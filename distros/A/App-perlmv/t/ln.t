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

test_perlmv([1, 2, 3], {code=>'$_++', mode=>'l'}, ["1", "2", "2.1", "3", "3.1", "4"], 'normal');
# XXX actually test that an extra link is created, via stat()

end_testing();
