use strict;
use Acme::PSON qw(obj2pson pson2obj); 
use Test::More qw/no_plan/;

my $org = { x=> 1, y => 2 };

my $pson = obj2pson( $org );

my $b = pson2obj( $pson );

is( $b->{x} , 1 );
is( $b->{y} , 2 );

