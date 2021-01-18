########################################
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr);
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More tests => 11;
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
our $max_entries = eval "\$${class}::MAX_ENTRIES";
our $total_sector_count = eval "\$${class}::TOTAL_SECTOR_COUNT";
########################################
our $sector_data_size = eval "\$D64::Disk::Layout::Sector::SECTOR_DATA_SIZE";
########################################
{
    my $dir = $class->new();
    my $module = new Test::MockModule($class);
    $module->mock('num_items', sub { return $max_entries; });
    my $stderr = capture_stderr { $dir->push(item => get_empty_item()); };
    like($stderr, qr/Unable to push another item to a directory listing, maximum number of 144 entries has been reached/, 'push new item to a directory listing already filled with maximum possible number of elements');
    $module->unmock_all();
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->push(); },
        qr/\QFailed to validate pushed directory item: Undefined item parameter (expected valid item object)\E/,
        'push an undefined item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->push(item => ''); },
        qr/\QFailed to validate pushed directory item: Invalid item parameter (got "", but expected a valid item object)\E/,
        'push a scalar value instead of a new item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->push(item => []); },
        qr/\QCan't call method "isa" on unblessed reference\E/,
        'push an array reference instead of a new item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    $dir->push(item => get_empty_item());
    my @expected_data = get_empty_data();
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'push an empty item to an empty directory listing');
}
########################################
{
    my $dir = $class->new();
    $dir->push(item => get_empty_item());
    is($dir->num_items(), 0, 'count number of items after pushing an empty item to an empty directory listing');
}
########################################
{
    my $dir = $class->new();
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    $dir->push(item => $item);
    my @expected_data = get_empty_data();
    add_items_to_data([$item], \@expected_data);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'push a new item to an empty directory listing');
}
########################################
{
    my $dir = $class->new();
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    $dir->push(item => $item);
    is($dir->num_items(), 1, 'count number of items after pushing a new item to an empty directory listing');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    $dir->push(item => $item);
    my @expected_data = get_dir_data();
    add_items_to_data([$item], \@expected_data, 3);
    my @data = $dir->data();
    cmp_deeply(\@data, \@expected_data, 'push a new item to a valid directory listing');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my ($item) = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(1);
    $dir->push(item => $item);
    is($dir->num_items(), 4, 'count number of items after pushing a new item to a valid directory listing');
}
########################################
