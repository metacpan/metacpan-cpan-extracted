use strict;
use Data::Lotter;
use Data::Dumper;
use Test::More tests => 3;

my @items = qw( red blue yellow green white);

my %candidates;
for(@items){
    $candidates{$_} = 10;
}

my $lotter = Data::Lotter->new(%candidates);

# check the number of ret values
my @ret = $lotter->pickup(2,"REMOVE");
is( int @ret, 2, "check the number of pickup items");

# check the remove data
my $flag;
for my $item ($lotter->left_items){
    for my $ret (@ret){
        $flag = 1 if $ret eq $item;
    }
}
isnt($flag, 1, "check the item was removed");

# pickup again 
my @ret2 = $lotter->pickup(2, "REMOVE");
my ($item) = $lotter->left_items;
is( $lotter->left_item_waits($item), 10, "check the number of left item wait");


1;
