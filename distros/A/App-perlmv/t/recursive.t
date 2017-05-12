#!perl -T

use strict;
use warnings;
#use Test::More tests => 2;
use Test::More skip_all => 'TODO';
use FindBin '$Bin';
($Bin) = $Bin =~ /(.+)/;

our $Perl;
our $Dir;

require "$Bin/testlib.pl";
prepare_for_testing();

# TODO: still some problem with tainting in mode=method
#test_perlmv([3, 4], {recursive=>1, extra_arg=>'a', codes=>['s/(\d+)/"file".($1+2).".ext"/e', 's/\.ext$//']}, [3, 4], '',
#        sub { mkdir "a"; open F, ">3"; open F, ">4"; open F, ">a/1"; open F, ">a/2" },
#        sub { ok((-f "file5") && (-f "file6") && (-d "a") && (-f "a/file3") && (-f "a/file4"), "recursive + multi") });

end_testing();
