#!perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Acme::Perl::VM;

sub f{
    print 42 + undef, "\n";
}
sub g{
    f(42);
}

run_block {
    &g;
};
