########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::More tests => 14;
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
    my $expected_data = get_dir_data();
    $dir->data($expected_data);
    is($dir->data(), $expected_data, 'set disk directory data as a scalar value, and check it by getting data as a scalar value');
}
########################################
{
    my $dir = $class->new();
    my $assigned_data = get_dir_data();
    $dir->data($assigned_data);
    my @expected_data = get_dir_data();
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'set disk directory data as a scalar value, and check it by getting data as an array of bytes');
}
########################################
{
    my $dir = $class->new();
    my @assigned_data = get_dir_data();
    $dir->data(@assigned_data);
    my $expected_data = get_dir_data();
    is($dir->data(), $expected_data, 'set disk directory data as an array of bytes, and check it by getting data as a scalar value');
}
########################################
{
    my $dir = $class->new();
    my @expected_data = get_dir_data();
    $dir->data(@expected_data);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'set disk directory data as an array of bytes, and check it by getting data as an array of bytes');
}
########################################
{
    my $dir = $class->new();
    my @assigned_data = get_dir_data();
    $dir->data(\@assigned_data);
    my $expected_data = get_dir_data();
    is($dir->data(), $expected_data, 'set disk directory data as an arrayref of bytes, and check it by getting data as a scalar value');
}
########################################
{
    my $dir = $class->new();
    my @expected_data = get_dir_data();
    $dir->data(\@expected_data);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'set disk directory data as an arrayref of bytes, and check it by getting data as an array of bytes');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my $replaced_data = get_more_dir_data();
    $dir->data($replaced_data);
    my @expected_data = get_more_dir_data();
    my @test_data = $dir->data();
    cmp_deeply(\@test_data, \@expected_data, 'replace disk directory layout object with stream of bytes and check array of bytes');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_data = get_more_dir_data();
    $dir->data(@replaced_data);
    my $expected_data = get_more_dir_data();
    my $test_data = $dir->data();
    is($test_data, $expected_data, 'replace disk directory layout object with array of bytes and check stream of bytes');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_data = get_more_dir_data();
    $dir->data(\@replaced_data);
    my $expected_data = get_more_dir_data();
    my $test_data = $dir->data();
    is($test_data, $expected_data, 'replace disk directory layout object with arrayref of bytes and check stream of bytes');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_items = get_more_dir_items();
    $dir->items(@replaced_items);
    my $expected_data = get_more_dir_data();
    $expected_data =~ s/^(.)./${1}\x04/;
    my $test_data = $dir->data();
    is($test_data, $expected_data, 'replace disk directory layout object with item data and check stream of bytes');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_items = get_more_dir_items();
    $dir->items(@replaced_items);
    my @expected_data = get_more_dir_data();
    $expected_data[1] = chr 0x04;
    my @test_data = $dir->data();
    cmp_deeply(\@test_data, \@expected_data, 'replace disk directory layout object with item data and check array of bytes');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_sectors = get_more_dir_sectors();
    $dir->sectors(@replaced_sectors);
    my $expected_data = get_more_dir_data();
    my $test_data = $dir->data();
    is($test_data, $expected_data, 'replace disk directory layout object with sector data and check stream of bytes');
}
########################################
{
    my $dir = $class->new(data => [get_dir_data()]);
    my @replaced_sectors = get_more_dir_sectors();
    $dir->sectors(@replaced_sectors);
    my @expected_data = get_more_dir_data();
    my @test_data = $dir->data();
    cmp_deeply(\@test_data, \@expected_data, 'replace disk directory layout object with sector data and check array of bytes');
}
########################################
