#!perl

use Test::More (tests => 3);

use_ok (Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "good object");
isa_ok ($ddez, 'CODE', "good object");

