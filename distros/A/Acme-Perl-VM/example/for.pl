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
    for(my $i = 1; $i <= 10; $i++){
        for(my $j = 1; $j <= 100; $j++){
            $sum += f($i, $j);
        }
    }

    print "\n", $sum, "\n";
};

print B::timing_info(), "\n";
