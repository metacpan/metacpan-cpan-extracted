########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::More tests => 8;
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
    my @sectors_assigned = get_dir_sectors();
    $dir->sectors(@sectors_assigned);
    my @sectors = $dir->sectors();
    my @sectors_expected = get_dir_sectors();
    cmp_deeply(\@sectors, \@sectors_expected, 'replace empty disk directory layout object providing an array of 18 sectors');
}
########################################
{
    my $dir = $class->new();
    my @sectors_assigned = get_dir_sectors();
    $dir->sectors(\@sectors_assigned);
    my @sectors = $dir->sectors();
    my @sectors_expected = get_dir_sectors();
    cmp_deeply(\@sectors, \@sectors_expected, 'replace empty disk directory layout object providing an arrayref of 18 sectors');
}
########################################
{
    my @sectors_assigned = get_dir_sectors();
    my $dir = $class->new(sectors => \@sectors_assigned);
    my @sectors_expected = get_empty_sectors();
    $dir->sectors(@sectors_expected);
    my @sectors = $dir->sectors();
    cmp_deeply(\@sectors, \@sectors_expected, 'replace disk directory layout object with explicit item data providing an arrayref of 18 sectors');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my $replaced_data = get_more_dir_data();
    $dir->data($replaced_data);
    my @expected_sectors = get_more_dir_sectors();
    my @test_sectors = $dir->sectors();
    cmp_deeply(\@test_sectors, \@expected_sectors, 'replace disk directory layout object with stream of bytes and check sector data');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_data = get_more_dir_data();
    $dir->data(@replaced_data);
    my @expected_sectors = get_more_dir_sectors();
    my @test_sectors = $dir->sectors();
    cmp_deeply(\@test_sectors, \@expected_sectors, 'replace disk directory layout object with array of bytes and check sector data');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_data = get_more_dir_data();
    $dir->data(\@replaced_data);
    my @expected_sectors = get_more_dir_sectors();
    my @test_sectors = $dir->sectors();
    cmp_deeply(\@test_sectors, \@expected_sectors, 'replace disk directory layout object with arrayref of bytes and check sector data');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_items = get_more_dir_items();
    $dir->items(@replaced_items);
    my @expected_sectors = get_more_dir_sectors();
    my $sector_data = $expected_sectors[0]->data;
    $sector_data =~ s/^(.)./${1}\x04/;
    $expected_sectors[0]->data($sector_data);
    $expected_sectors[1]->sector(0x04);
    $expected_sectors[2]->sector(0x07);
    $expected_sectors[3]->sector(0x0a);
    $expected_sectors[4]->sector(0x0d);
    $expected_sectors[5]->sector(0x10);
    $expected_sectors[6]->sector(0x02);
    my @test_sectors = $dir->sectors();
    cmp_deeply(\@test_sectors, \@expected_sectors, 'replace disk directory layout object with item data and check sector data');
}
########################################
