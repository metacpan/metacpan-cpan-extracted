#!perl -w
use strict;

use Acme::Perl::VM;

sub f{
    my($x, $y) = @_;
    print $x, ' - ', $y, "\r";
    return $x * $y;
}

run_block {
    local $| = 1;

    my $sum = 0;
    foreach my $i(1 .. 10){
        foreach my $j(1 .. 100){
            $sum += f($i, $j);
        }
    }

    print "\n", $sum, "\n";
};

print B::timing_info(), "\n";
