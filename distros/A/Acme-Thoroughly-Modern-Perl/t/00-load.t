#!perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 00-load.t'
# Test::More is use()ed here so read its man page ( perldoc Test::More )
# for help writing your own test scripts.

use strict;
use warnings FATAL => 'all';

use Test::More;

# tells A::T::M::P to exit with 0 instead of 255
$ENV{ATMP_TEST} = 1;
use_ok( 'Acme::Thoroughly::Modern::Perl' );

diag("Testing Acme::Thoroughly::Modern::Perl $Acme::Thoroughly::Modern::Perl::VERSION, Perl $], $^X");

done_testing();

__END__

