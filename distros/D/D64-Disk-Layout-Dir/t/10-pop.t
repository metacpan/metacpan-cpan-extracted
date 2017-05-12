########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::More tests => 11;
########################################
require 't/Util.pm';
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
    is($dir->pop(), undef, 'pop the last directory item from an empty disk directory layout object');
}
########################################
{
    my $dir = $class->new();
    $dir->pop();
    is($dir->num_items(), 0, 'count number of items after popping the last directory item from an empty disk directory layout object');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    cmp_deeply($dir->pop(), $items[-1], 'pop the last directory item from a disk directory layout object with explicit item data');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->pop();
    is($dir->num_items(), 2, 'count number of items after popping the last directory item from a disk directory layout object with explicit item data');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    cmp_deeply($dir->pop(), $items[-1], 'pop the last directory item from a disk directory layout object with extended item data');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->pop();
    is($dir->num_items(), 11, 'count number of items after popping the last directory item from a disk directory layout object with extended item data');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->pop();
    cmp_deeply($dir->pop(), $items[-2], 'pop the last directory item from a disk directory layout object with explicit item data after popping one item before already');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->pop();
    $dir->pop();
    is($dir->num_items(), 1, 'count number of items after popping the last directory item from a disk directory layout object with explicit item data after popping one item before already');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->pop();
    $dir->pop();
    $dir->pop();
    is($dir->pop(), undef, 'pop the last directory item from a disk directory layout object with explicit item data after popping all items before already');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->pop();
    $dir->pop();
    $dir->pop();
    $dir->pop();
    is($dir->num_items(), 0, 'count number of items after popping the last directory item from a disk directory layout object with explicit item data after popping all items before already');
}
########################################
