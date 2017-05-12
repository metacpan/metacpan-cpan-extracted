#!perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Acme::Perl::VM::Run;

sub hello{
    my($s) = @_;

    print "Hello, $s world!\n";
}

hello("APVM");
