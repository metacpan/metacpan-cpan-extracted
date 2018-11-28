########################################
use strict;
use warnings;
use Capture::Tiny;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::More tests => 20;
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
    is($dir->num_items(), 0, 'get number of items from an empty disk directory layout object');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    is($dir->num_items(), 3, 'get number of items from a disk directory layout with explicit item data');
}
########################################
{
    my $dir = $class->new();
    my @items = $dir->items();
    cmp_deeply(\@items, [], 'get directory object data as an array of items from an empty disk directory layout object');
}
########################################
{
    my @items_expected = get_dir_items();
    my $dir = $class->new(items => \@items_expected);
    my @items = $dir->items();
    cmp_deeply(\@items, \@items_expected, 'get directory object data as an array of items from a disk directory layout object with explicit item data');
}
########################################
{
    my @items_assigned = get_all_dir_items();
    my $dir = $class->new(items => \@items_assigned);
    my @items = $dir->items();
    my @items_expected = get_dir_items();
    cmp_deeply(\@items, \@items_expected, 'get directory object data as an array of items from a disk directory layout object with complete item data');
}
########################################
{
    my $dir = $class->new();
    my @sectors = $dir->sectors();
    my @expected_sectors = get_empty_sectors();
    cmp_deeply(\@sectors, \@expected_sectors, 'get directory object data as an array of sectors from an empty disk directory layout object');
}
########################################
{
    my @sectors_expected = get_dir_sectors();
    my $dir = $class->new(sectors => \@sectors_expected);
    my @sectors = $dir->sectors();
    cmp_deeply(\@sectors, \@sectors_expected, 'get directory object data as an array of sectors from a disk directory layout object with explicit sectors data');
}
########################################
{
    my @sectors_expected = get_more_dir_sectors();
    my $dir = $class->new(sectors => \@sectors_expected);
    my @sectors = $dir->sectors();
    cmp_deeply(\@sectors, \@sectors_expected, 'get directory object data as an array of sectors from a disk directory layout object with extended sectors data');
}
########################################
{
    my $dir = $class->new();
    my @data = $dir->data();
    my @expected_data = get_empty_data();
    cmp_deeply(\@data, \@expected_data, 'get directory object data as an array of bytes from an empty disk directory layout object');
}
########################################
{
    my $dir = $class->new();
    my $data = $dir->data();
    my $expected_data = get_empty_data();
    is($data, $expected_data, 'get directory object data as a stream of bytes from an empty disk directory layout object');
}
########################################
{
    my @expected_data = get_dir_data();
    my $dir = $class->new(data => \@expected_data);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'get directory object data as an array of bytes from a disk directory layout object with explicit directory data');
}
########################################
{
    my $expected_data = get_dir_data();
    my $dir = $class->new(data => $expected_data);
    my $data = $dir->data();
    is($data, $expected_data, 'get directory object data as a stream of bytes from a disk directory layout object with explicit directory data');
}
########################################
{
    my @expected_data = get_more_dir_data();
    my $dir = $class->new(data => \@expected_data);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'get directory object data as an array of bytes from a disk directory layout object with extended directory data');
}
########################################
{
    my $expected_data = get_more_dir_data();
    my $dir = $class->new(data => $expected_data);
    my $data = $dir->data();
    is($data, $expected_data, 'get directory object data as a stream of bytes from a disk directory layout object with extended directory data');
}
########################################
{
    my $dir = $class->new();
    my $num_sectors = $dir->num_sectors(count => 'all');
    is($num_sectors, 18, 'get total number of allocated sectors that can be used to store disk directory data for an empty disk directory layout object');
}
########################################
{
    my @data = get_dir_data();
    my $dir = $class->new(data => \@data);
    my $num_sectors = $dir->num_sectors(count => 'all');
    is($num_sectors, 18, 'get total number of allocated sectors that can be used to store disk directory data for a disk directory layout object with explicit directory data');
}
########################################
{
    my $dir = $class->new();
    my $num_sectors = $dir->num_sectors(count => 'used');
    is($num_sectors, 0, 'get number of currently used sectors that are used to store actual disk directory data for an empty disk directory layout object');
}
########################################
{
    my @data = get_dir_data();
    my $dir = $class->new(data => \@data);
    my $num_sectors = $dir->num_sectors(count => 'used');
    is($num_sectors, 1, 'get number of currently used sectors that are used to store actual disk directory data for a disk directory layout object with explicit directory data');
}
########################################
{
    my @data = get_more_dir_data();
    my $dir = $class->new(data => \@data);
    my $num_sectors = $dir->num_sectors(count => 'used');
    is($num_sectors, 2, 'get number of currently used sectors that are used to store actual disk directory data for a disk directory layout object with extended directory data');
}
########################################
