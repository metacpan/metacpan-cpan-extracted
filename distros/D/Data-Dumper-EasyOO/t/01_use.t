#!perl
use strict;
use Test::More (tests => 5);
diag "To see output from all tests that test data output,"
    . " you can force failures with \$ENV{TEST_FAIL}=1";

use_ok qw(Data::Dumper);

my $dd = Data::Dumper->new([]);
isa_ok ($dd, 'Data::Dumper', "good DD object. sanity test");

use_ok qw(Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "good DDEz object");
isa_ok ($ddez, 'CODE', "CODE object");

