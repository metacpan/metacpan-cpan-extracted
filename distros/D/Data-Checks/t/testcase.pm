package testcase;

use v5.22;
use warnings;

use lib "t/blib", "t/blib/arch";

use Data::Checks;

sub import
{
   shift;
   require XSLoader;
   XSLoader::load( $_[0], $Data::Checks::VERSION );
}

sub unimport
{
   die "testcase cannot be unimported";
}

0x55AA;
