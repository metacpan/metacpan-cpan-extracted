########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::Exception;
use Test::More tests => 37;
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
    can_ok($class, qw(new data items num_items sectors num_sectors get push pop shift unshift delete remove add put print));
}
########################################
{
    my $dir = $class->new();
    is(ref $dir, $class, 'create an empty disk directory layout object with default parameters and check object type');
}
########################################
{
    my $dir = $class->new();
    is($dir->data(), get_empty_data(), 'create an empty disk directory layout object with default parameters and check directory data');
}
########################################
{
    throws_ok(
        sub { $class->new(data => undef); },
        qr/\QUnable to initialize disk directory: Undefined value of data (expected 4608 bytes)\E/,
        'create an empty disk directory layout object with undefined source data',
    );
}
########################################
{
    throws_ok(
        sub { $class->new(data => {}); },
        qr/\QUnable to initialize disk directory: Invalid arguments given (expected 4608 bytes)\E/,
        'create an empty disk directory layout object with invalid data type',
    );
}
########################################
{
    throws_ok(
        sub { $class->new(data => ''); },
        qr/\QUnable to initialize disk directory: Invalid amount of data (got 0 bytes, but required 4608)\E/,
        'create an empty disk directory layout object with empty scalar data',
    );
}
########################################
{
    throws_ok(
        sub { $class->new(data => []); },
        qr/\QUnable to initialize disk directory: Invalid amount of data (got 0 bytes, but required 4608)\E/,
        'create an empty disk directory layout object with empty array data',
    );
}
########################################
{
    my $data = substr get_empty_data(), 0, -1;
    throws_ok(
        sub { $class->new(data => $data); },
        qr/\QUnable to initialize disk directory: Invalid amount of data (got 4607 bytes, but required 4608)\E/,
        'create an empty disk directory layout object with insuffucient amount of scalar data',
    );
}
########################################
{
    my @data = get_empty_data();
    pop @data;
    throws_ok(
        sub { $class->new(data => \@data); },
        qr/\QUnable to initialize disk directory: Invalid amount of data (got 4607 bytes, but required 4608)\E/,
        'create an empty disk directory layout object with insuffucient amount of array data',
    );
}
########################################
{
    my $data = get_empty_data() . chr 0x00;
    throws_ok(
        sub { $class->new(data => $data); },
        qr/\QUnable to initialize disk directory: Invalid amount of data (got 4609 bytes, but required 4608)\E/,
        'create an empty disk directory layout object with excessive amount of scalar data',
    );
}
########################################
{
    my @data = get_empty_data();
    push @data, chr 0x00;
    throws_ok(
        sub { $class->new(data => \@data); },
        qr/\QUnable to initialize disk directory: Invalid amount of data (got 4609 bytes, but required 4608)\E/,
        'create an empty disk directory layout object with excessive amount of array data',
    );
}
########################################
{
    my $data = get_empty_data();
    my $dir = $class->new(data => $data);
    is(ref $dir, $class, 'create an empty disk directory layout object with explicit empty scalar data and check object type');
}
########################################
{
    my @data = get_empty_data();
    my $dir = $class->new(data => \@data);
    is(ref $dir, $class, 'create an empty disk directory layout object with explicit empty array data and check object type');
}
########################################
{
    my $data = get_empty_data();
    my $dir = $class->new(data => $data);
    is($dir->data(), $data, 'create an empty disk directory layout object with explicit empty scalar data and check directory data');
}
########################################
{
    my @expected_data = get_empty_data();
    my $dir = $class->new(data => \@expected_data);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'create an empty disk directory layout object with explicit empty array data and check directory data');
}
########################################
{
    my @sectors = get_empty_sectors();
    my $dir = $class->new(sectors => \@sectors);
    is(ref $dir, $class, 'create an empty disk directory layout object with explicit empty sector data and check object type');
}
########################################
{
    my @sectors = get_empty_sectors();
    my $dir = $class->new(sectors => \@sectors);
    my @data = $dir->data();
    my @expected_data = get_empty_data();
    cmp_deeply(\@data, \@expected_data, 'create an empty disk directory layout object with explicit empty sector data and check directory data');
}
########################################
{
    my $dir = $class->new(items => []);
    is(ref $dir, $class, 'create an empty disk directory layout object with empty item list and check object type');
}
########################################
{
    my $dir = $class->new(items => []);
    my @data = $dir->data();
    my @expected_data = get_empty_data();
    cmp_deeply(\@data, \@expected_data, 'create an empty disk directory layout object with empty item list and check directory data');
}
########################################
{
    my @items = get_empty_items();
    my $dir = $class->new(items => \@items);
    is(ref $dir, $class, 'create an empty disk directory layout object with explicit empty item data and check object type');
}
########################################
{
    my @items = get_empty_items();
    my $dir = $class->new(items => \@items);
    my @data = $dir->data();
    my @expected_data = get_empty_data();
    cmp_deeply(\@data, \@expected_data, 'create an empty disk directory layout object with explicit empty item data and check directory data');
}
########################################
{
    my @sectors = get_empty_sectors();
    pop @sectors;
    throws_ok(
        sub { $class->new(sectors => \@sectors); },
        qr/\QUnable to initialize disk directory: Invalid number of sectors (got 17 sectors, but required 18)\E/,
        'create an empty disk directory layout object with insuffucient amount of sector data',
    );
}
########################################
{
    my @sectors = get_empty_sectors();
    push @sectors, get_empty_sector(18, 19);
    throws_ok(
        sub { $class->new(sectors => \@sectors); },
        qr/\QUnable to initialize disk directory: Invalid number of sectors (got 19 sectors, but required 18)\E/,
        'create an empty disk directory layout object with excessive amount of sector data',
    );
}
########################################
{
    my @items = get_empty_items();
    pop @items;
    my $dir = $class->new(items => \@items);
    my @data = $dir->data();
    my @expected_data = get_empty_data();
    cmp_deeply(\@data, \@expected_data, 'create an empty disk directory layout object with 143 empty items and check directory data');
}
########################################
{
    my @items = get_empty_item();
    my $dir = $class->new(items => \@items);
    my @data = $dir->data();
    my @expected_data = get_empty_data();
    cmp_deeply(\@data, \@expected_data, 'create an empty disk directory layout object with 1 empty item and check directory data');
}
########################################
{
    my @items = get_empty_items();
    push @items, get_empty_item();
    throws_ok(
        sub { $class->new(items => \@items); },
        qr/\QUnable to initialize disk directory: Invalid number of items (got 145 items, but required up to 144)\E/,
        'create an empty disk directory layout object with excessive amount of item data',
    );
}
########################################
{
    my @sectors = get_empty_sectors();
    $sectors[-1]->sector(17); # now we have got sector 17 defined twice and no sector 18 defined at all
    throws_ok(
        sub { $class->new(sectors => \@sectors); },
        qr/\QUnable to initialize disk directory: Invalid number of sectors (got 17 sectors, but required 18)\E/,
        'create an empty disk directory layout object with insufficient duplicated sector data',
    );
}
########################################
{
    my @sectors = get_empty_sectors();
    push @sectors, get_empty_sector(18, 16); # now we have got sector 16 defined twice
    throws_ok(
        sub { $class->new(sectors => \@sectors); },
        qr/\QUnable to initialize disk directory: Invalid number of sectors (got 19 sectors, but required 18)\E/,
        'create an empty disk directory layout object with excessive duplicated sector data',
    );
}
########################################
{
    my $expected_data = get_dir_data();
    my $dir = $class->new(data => $expected_data);
    my $data = $dir->data();
    cmp_deeply($data, $expected_data, 'create a disk directory layout object with explicit scalar data and check directory data');
}
########################################
{
    my @expected_data = get_dir_data();
    my $dir = $class->new(data => \@expected_data);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'create a disk directory layout object with explicit array data and check directory data');
}
########################################
{
    my @sectors = get_dir_sectors();
    my $dir = $class->new(sectors => \@sectors);
    my @data = $dir->data();
    my @expected_data = get_dir_data();
    cmp_deeply(\@data, \@expected_data, 'create a disk directory layout object with explicit sector data and check directory data');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my @data = $dir->data();
    my @expected_data = get_dir_data();
    cmp_deeply(\@data, \@expected_data, 'create a disk directory layout object with explicit item data and check directory data');
}
########################################
{
    my @items = get_all_dir_items();
    my $dir = $class->new(items => \@items);
    my @data = $dir->data();
    my @expected_data = get_dir_data();
    cmp_deeply(\@data, \@expected_data, 'create a disk directory layout object with complete item data and check directory data');
}
########################################
{
    my @data = get_empty_data();
    $data[0x04] = [];
    throws_ok(
        sub { $class->new(data => \@data); },
        qr/\QUnable to initialize disk directory: Invalid data type at offset 4 (ARRAY)\E/,
        'create an empty disk directory layout object with invalid data type amongst source array data',
    );
}
########################################
{
    my @data = get_empty_data();
    $data[0x08] = 0x0100;
    throws_ok(
        sub { $class->new(data => \@data); },
        qr/\QUnable to initialize disk directory: Invalid byte value at offset 8 (256)\E/,
        'create an empty disk directory layout object with invalid byte value amongst source array data',
    );
}
########################################
{
    my @data = get_empty_data();
    $data[0x0c] = '0x00';
    throws_ok(
        sub { $class->new(data => \@data); },
        qr/\QUnable to initialize disk directory: Invalid byte value at offset 12 ('0x00')\E/,
        'create an empty disk directory layout object with invalid string value amongst source array data',
    );
}
########################################
