########################################
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr);
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::Exception;
use Test::MockModule;
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
our $max_entries = eval "\$${class}::MAX_ENTRIES";
our $total_sector_count = eval "\$${class}::TOTAL_SECTOR_COUNT";
########################################
our $sector_data_size = eval "\$D64::Disk::Layout::Sector::SECTOR_DATA_SIZE";
########################################
{
    my $dir = $class->new();
    my $module = new Test::MockModule($class);
    $module->mock('num_items', sub { return $max_entries; });
    my $stderr = capture_stderr { $dir->unshift(item => get_empty_item()); };
    like($stderr, qr/Unable to prepend an item to the front of directory listing, maximum number of 144 entries has been reached/, 'unshift new item to a directory listing already filled with maximum possible number of elements');
    $module->unmock_all();
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->unshift(); },
        qr/\QFailed to validate prepended directory item: Undefined item parameter (expected valid item object)\E/,
        'unshift an undefined item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->unshift(item => ''); },
        qr/\QFailed to validate prepended directory item: Invalid item parameter (got "", but expected a valid item object)\E/,
        'unshift a scalar value instead of a new item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->unshift(item => []); },
        qr/\QCan't call method "isa" on unblessed reference\E/,
        'unshift an array reference instead of a new item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    $dir->unshift(item => get_empty_item());
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size * $total_sector_count);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'unshift an empty item to an empty directory listing');
}
########################################
{
    my $dir = $class->new();
    $dir->unshift(item => get_empty_item());
    is($dir->num_items(), 0, 'count number of items after unshifting an empty item to an empty directory listing');
}
########################################
{
    my $dir = $class->new();
    my $num_items = $dir->unshift(item => get_empty_item());
    is($num_items, 0, 'check the new number of items after unshifting an empty item to an empty directory listing');
}
########################################
{
    my $dir = $class->new();
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    $dir->unshift(item => $item);
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size * $total_sector_count);
    $expected_data[0x01] = chr 0xff;
    add_items_to_data([$item], \@expected_data);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'unshift a new item to an empty directory listing');
}
########################################
{
    my $dir = $class->new();
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    $dir->unshift(item => $item);
    is($dir->num_items(), 1, 'count number of items after unshifting a new item to an empty directory listing');
}
########################################
{
    my $dir = $class->new();
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    my $num_items = $dir->unshift(item => $item);
    is($num_items, 1, 'check the new number of items after unshifting a new item to an empty directory listing');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    $dir->unshift(item => $item);
    my @expected_data = get_empty_data();
    $expected_data[0x01] = chr 0xff;
    add_items_to_data([$item], \@expected_data);
    add_items_to_data(\@items, \@expected_data, 1);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'unshift a new item to a valid directory listing');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    $dir->unshift(item => $item);
    is($dir->num_items(), 4, 'count number of items after unshifting a new item to a valid directory listing');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    my $num_items = $dir->unshift(item => $item);
    is($num_items, 4, 'check the new number of items after unshifting a new item to a valid directory listing');
}
########################################
