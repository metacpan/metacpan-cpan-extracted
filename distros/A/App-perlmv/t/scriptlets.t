#!perl -T

use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use FindBin '$Bin';
($Bin) = $Bin =~ /(.+)/;

our $Perl;
our $Dir;

require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv(["a.txt", "b"], {extra_opt=>"to-number-ext", verbose=>1}, ["1.txt", "2"], 'use std: to-number-ext');

run_perlmv({code=>'s/\.\w+$//', write=>'foo'}, []);

test_perlmv(["a.txt", "b"], {extra_opt=>'foo'}, ["a", "b"], "use saved: foo");

dies_ok { run_perlmv({code=>1, write=>"foo"}, []) } 'overwrite';
run_perlmv({code=>1, write=>'foo', overwrite=>1}, []);

run_perlmv({delete=>'foo'}, []);
dies_ok { run_perlmv({extra_opt=>"foo"}, ["1.txt"]) } 'remove: foo';

DONE_TESTING:
end_testing();

