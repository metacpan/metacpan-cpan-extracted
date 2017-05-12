#!perl
use strict;
use warnings;
use Acme::rafl::Everywhere;
use Test::More;

my $A = Acme::rafl::Everywhere->new;  # rafl is so everywhere
my $B = Acme::rafl::Everywhere->new;  # and he's also here

for ( 1 .. 5 ) {
    like( $A->fact, qr{^rafl is so everywhere} );
    like( $B->fact, qr{^rafl is so everywhere} );
}

done_testing();
