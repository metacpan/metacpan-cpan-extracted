########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::More tests => 16;
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
{
    my $dir = $class->new();
    my $expected_data = join '', map { chr (0x00), chr (0xff), map { chr 0x00 } (0x03 .. 256) } (0x01 .. 18);
    is($dir->data(), $expected_data, 'when the directory is done and the track value is $00, the sector link shall contain a value of $FF');
}
########################################
{
    my $empty_sector_data = chr (0x00) . chr (0xff) . chr (0x00) x 254;
    my $data = $empty_sector_data x 18;
    my $dir = D64::Disk::Layout::Dir->new(data => $data);
    is($dir->data(), $data, 'initialise disk directory layout with a formatted empty disk data');
}
########################################
