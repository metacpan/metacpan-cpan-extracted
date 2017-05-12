#!perl 

use strict;
use warnings;

use Acme::Roman;

use Term::ReadLine qw( readline );
my $term = Term::ReadLine->new( 'A guessing game' );
print <<GAME;
A guessing game:

Enter roman or arabic numerals to answer.
Just ENTER to quit.

GAME

while (1) {
    my $n1 = int(rand(20))+I; # I .. XX
    my $n2 = int(rand(20))+I; # I .. XX
    my $input = $term->readline("$n1 + $n2 = ");
    last unless $input;

    my $sum = $n1+$n2;
    my $ans = $input;
    if ( $sum-$ans==0 ) {
        print "Right!\n";
    } else {
        print "Wrong!\n";
    }
}

print "Bye\n";
