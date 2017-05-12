#!perl -w

use strict;


$Data::Util::TESTING_PERL_ONLY = $Data::Util::TESTING_PERL_ONLY = 1;
my $file = $0;
$file =~ s/pp//;
do "./$file";
die $@ if $@;
