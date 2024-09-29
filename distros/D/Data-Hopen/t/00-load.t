#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::UseAllModules;

BEGIN { all_uses_ok(); }

diag( "Testing Data::Hopen $Data::Hopen::VERSION, Perl $], $^X" );

done_testing();
