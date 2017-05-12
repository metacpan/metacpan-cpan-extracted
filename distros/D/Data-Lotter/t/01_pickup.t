use strict;
use Data::Lotter;
use Data::Dumper;
use Test::More tests => 2;

my @items = qw( red blue yellow green white);

my %candidates;
for(@items){
    $candidates{$_} = 10;
}

my $lotter = Data::Lotter->new(%candidates);
#$lotter->debug(1);

# check the number of ret values
my @ret = $lotter->pickup(1);
is( int @ret, 1, "check the number of pickup items");

#check the number of left item wait
is( $lotter->left_item_waits($ret[0]), 9, "check the number of left item wait");


1;
