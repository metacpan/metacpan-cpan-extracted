#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Data::SSHPubkey') || print "Bail out!\n";
}

diag("Testing Data::SSHPubkey $Data::SSHPubkey::VERSION, Perl $], $^X");
