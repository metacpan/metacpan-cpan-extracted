########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::More tests => 12;
########################################
require './t/Util.pm';
D64::Disk::Layout::Dir::Test::Util->import(qw(:all));
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Layout::Dir';
    use_ok($class);
}
########################################
{
    my $dir = $class->new();
    is($dir->shift(), undef, 'shift the first directory item from an empty disk directory layout object');
}
########################################
{
    my $dir = $class->new();
    $dir->shift();
    is($dir->num_items(), 0, 'count number of items after shifting the first directory item from an empty disk directory layout object');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    cmp_deeply($dir->shift(), $items[0], 'shift the first directory item from a disk directory layout object with explicit item data');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->shift();
    is($dir->num_items(), 2, 'count number of items after shifting the first directory item from a disk directory layout object with explicit item data');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    cmp_deeply($dir->shift(), $items[0], 'shift the first directory item from a disk directory layout object with extended item data');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->shift();
    is($dir->num_items(), 11, 'count number of items after shifting the first directory item from a disk directory layout object with extended item data');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->shift();
    cmp_deeply($dir->shift(), $items[1], 'shift the first directory item from a disk directory layout object with explicit item data after shifting one item before already');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->shift();
    $dir->shift();
    is($dir->num_items(), 1, 'count number of items after shifting the first directory item from a disk directory layout object with explicit item data after shifting one item before already');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->shift();
    $dir->shift();
    cmp_deeply($dir->shift(), $items[2], 'shift the first directory item from a disk directory layout object with explicit item data after shifting two items before already');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->shift();
    $dir->shift();
    $dir->shift();
    is($dir->shift(), undef, 'shift the first directory item from a disk directory layout object with explicit item data after shifting all items before already');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->shift();
    $dir->shift();
    $dir->shift();
    $dir->shift();
    is($dir->num_items(), 0, 'count number of items after shifting the first directory item from a disk directory layout object with explicit item data after shifting all items before already');
}
########################################
