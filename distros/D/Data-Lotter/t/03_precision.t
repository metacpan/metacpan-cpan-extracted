use strict;
use Data::Dumper;
use Data::Lotter;
use Test::More tests => 5;

my %candidates = (
    red   => 1,
    green => 10,
    blue  => 25,
    yellow => 30,
    white => 34,
);

my $num = 100000;
my $count;
for ( 1 .. $num ) {
    my $lotter = Data::Lotter->new(%candidates);
    my @ret = $lotter->pickup( 1, "REMOVE" );
    $count->{ $ret[0] }++;
}
while ( my ( $item, $weight ) = each %candidates ) {
    my $result = $count->{$item} / $num * 100;
    my $error  = abs( $result - $weight );
    ok( $error < 1,
        "$item has $error% error (weight:$weight, result:$result)" );
}
