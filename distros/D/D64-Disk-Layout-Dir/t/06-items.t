########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::More tests => 13;
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
    my @items_expected = get_dir_items();
    $dir->items(@items_expected);
    my @items = $dir->items();
    cmp_deeply(\@items, \@items_expected, 'replace empty disk directory layout object providing an array of 3 non-empty items');
}
########################################
{
    my $dir = $class->new();
    my @items_expected = get_dir_items();
    $dir->items(\@items_expected);
    my @items = $dir->items();
    cmp_deeply(\@items, \@items_expected, 'replace empty disk directory layout object providing an arrayref of 3 non-empty items');
}
########################################
{
    my $dir = $class->new();
    my @items_assigned = get_all_dir_items();
    $dir->items(@items_assigned);
    my @items = $dir->items();
    my @items_expected = get_dir_items();
    cmp_deeply(\@items, \@items_expected, 'replace empty disk directory layout object providing an array of 144 items');
}
########################################
{
    my $dir = $class->new();
    my @items_assigned = get_all_dir_items();
    $dir->items(\@items_assigned);
    my @items = $dir->items();
    my @items_expected = get_dir_items();
    cmp_deeply(\@items, \@items_expected, 'replace empty disk directory layout object providing an arrayref of 144 items');
}
########################################
{
    my @items_assigned = get_dir_items();
    my $dir = $class->new(items => \@items_assigned);
    $dir->items([]);
    my @items = $dir->items();
    cmp_deeply(\@items, [], 'replace disk directory layout object with explicit item data providing an empty arrayref of items');
}
########################################
{
    my @items_assigned = get_dir_items();
    my $dir = $class->new(items => \@items_assigned);
    my @items_expected = get_dir_items();
    pop @items_expected;
    $dir->items(\@items_expected);
    my @items = $dir->items();
    cmp_deeply(\@items, \@items_expected, 'replace disk directory layout object with explicit item data providing an arrayref of 2 non-empty items');
}
########################################
{
    my @items_assigned = get_dir_items();
    my $dir = $class->new(items => \@items_assigned);
    my @items_expected = get_dir_items();
    splice @items_expected, 0, 2;
    $dir->items(\@items_expected);
    my @items = $dir->items();
    cmp_deeply(\@items, \@items_expected, 'replace disk directory layout object with explicit item data providing an arrayref of 1 non-empty item');
}
########################################
{
    my @items_expected = get_dir_items();
    my $dir = $class->new(items => \@items_expected);
    my @items_assigned = get_all_dir_items();
    $dir->items(@items_assigned);
    my @items = $dir->items();
    cmp_deeply(\@items, \@items_expected, 'replace disk directory layout object with explicit item data providing an arrayref of 144 items');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my $replaced_data = get_more_dir_data();
    $dir->data($replaced_data);
    my @expected_items = get_more_dir_items();
    my @test_items = $dir->items();
    cmp_deeply(\@test_items, \@expected_items, 'replace disk directory layout object with stream of bytes and check item data');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_data = get_more_dir_data();
    $dir->data(@replaced_data);
    my @expected_items = get_more_dir_items();
    my @test_items = $dir->items();
    cmp_deeply(\@test_items, \@expected_items, 'replace disk directory layout object with array of bytes and check item data');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_data = get_more_dir_data();
    $dir->data(\@replaced_data);
    my @expected_items = get_more_dir_items();
    my @test_items = $dir->items();
    cmp_deeply(\@test_items, \@expected_items, 'replace disk directory layout object with arrayref of bytes and check item data');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_sectors = get_more_dir_sectors();
    $dir->sectors(@replaced_sectors);
    my @expected_items = get_more_dir_items();
    my @test_items = $dir->items();
    cmp_deeply(\@test_items, \@expected_items, 'replace disk directory layout object with sector data and check item data');
}
########################################
