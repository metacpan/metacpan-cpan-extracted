########################################
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr);
use D64::Disk::Dir::Item qw(:types);
use D64::Disk::Layout::Sector;
use Test::Exception;
use Test::MockModule;
use Test::More tests => 25;
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
########################################
our $sector_data_size = eval "\$D64::Disk::Layout::Sector::SECTOR_DATA_SIZE";
########################################
sub get_new_item {
    my @bytes = map { chr } map { hex } qw(82 10 00 4e 45 57 20 46 49 4c 45 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 10 00);
    my $item = D64::Disk::Dir::Item->new(@bytes);
    return $item;
}
########################################
sub get_deleted_item {
    my @bytes = map { chr } map { hex } qw(82 10 00 4e 45 57 20 46 49 4c 45 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 10 00);
    my $item = D64::Disk::Dir::Item->new(@bytes);
    $item->closed(0);
    $item->type($T_DEL);
    return $item;
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->add(); },
        qr/\QUnable to add an item to a directory listing: Missing item parameter (what element did you want to add?)\E/,
        'add an item to a directory listing without any parameter specification',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->add(item => $item, index => []); },
        qr/\QUnable to add an item to a directory listing: Invalid index parameter (got "[]", but expected an integer between 0 and 143)\E/,
        'add an item to a directory listing designated by a non-numeric offset',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->add(item => $item, index => -1); },
        qr/\QUnable to add an item to a directory listing: Invalid index parameter (got "-1", but expected an integer between 0 and 143)\E/,
        'add an item to a directory listing designated by a negative numeric offset',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->add(item => $item, index => 2.1); },
        qr/\QUnable to add an item to a directory listing: Invalid index parameter (got "2.1", but expected an integer between 0 and 143)\E/,
        'add an item to a directory listing designated by a floating point number offset',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->add(item => $item, index => 144); },
        qr/\QUnable to add an item to a directory listing: Invalid index parameter (got "144", but expected an integer between 0 and 143)\E/,
        'add an item to a directory listing designated by an offset beyond the maximum possible amount of elements in a disk directory',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->add(index => 0); },
        qr/\QUnable to add an item to a directory listing: Missing item parameter (what element did you want to add?)\E/,
        'add an item to a directory listing without any item specification',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->add(item => ''); },
        qr/\QUnable to add an item to a directory listing: Invalid item parameter (got "", but expected a valid item object)\E/,
        'add a scalar value instead of a new item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->add(item => []); },
        qr/\QCan't call method "isa" on unblessed reference\E/, #' <- fix for gedit syntax-highlighting issues
        'add an array reference instead of a new item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    my $module = new Test::MockModule($class);
    $module->mock('num_items', sub { return $max_entries; });
    my $stderr = capture_stderr { $dir->add(item => get_empty_item(), index => 0); };
    like($stderr, qr/Unable to add another item to a directory listing, maximum number of 144 entries has been reached/, 'add new item to a directory listing already filled with maximum possible number of non-empty elements');
    $module->unmock_all();
}
########################################
{
    my $dir = $class->new();
    my $is_success = $dir->add(item => get_new_item(), index => 1);
    # Not a successful add of a new entry:
    my $test1 = $is_success == 0;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 0;
    # There is no item data inserted into directory listing:
    my $data = get_empty_data();
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing designated by an offset beyond the last non-empty directory item');
}
########################################
{
    my $dir = $class->new();
    my $is_success = $dir->add(item => get_empty_item(), index => 0);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 0;
    # There is no item data inserted into directory listing:
    my $data = get_empty_data();
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an empty item to a directory listing');
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item, index => 0);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 1;
    # New item data added into directory listing:
    my @data = get_empty_data();
    my @new_item_data = $item->data();
    splice @data, 0x02, 0x00, @new_item_data;
    splice @data, 0x20, 0x00, chr 0x00, chr 0x00;
    splice @data, -0x20, 0x20;
    $data[0x01] = chr 0xff;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add a valid item to a directory listing');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item, index => 0);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 4;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x02, 0x00, @new_item_data;
    splice @data, 0x20, 0x00, chr 0x00, chr 0x00;
    splice @data, -0x20, 0x20;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing designated by an offset of the first non-empty directory item');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item, index => 1);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 4;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x22, 0x00, @new_item_data;
    splice @data, 0x40, 0x00, chr 0x00, chr 0x00;
    splice @data, -0x20, 0x20;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing designated by an offset of the second non-empty directory item');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item, index => 2);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 4;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x42, 0x00, @new_item_data;
    splice @data, 0x60, 0x00, chr 0x00, chr 0x00;
    splice @data, -0x20, 0x20;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing designated by an offset of the last non-empty directory item');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item, index => 3);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 4;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x62, 0x00, @new_item_data;
    splice @data, 0x80, 0x00, chr 0x00, chr 0x00;
    splice @data, -0x20, 0x20;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing designated by an offset right after the last non-empty directory item');
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 1;
    # New item data added into directory listing:
    my @data = get_empty_data();
    my @new_item_data = $item->data();
    splice @data, 0x02, 0x1e, @new_item_data;
    $data[0x01] = chr 0xff;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to an empty directory listing without any empty slots and without offset specification');
}
########################################
{
    my $dir = $class->new();
    $dir->put(item => get_deleted_item(), index => 0);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 1;
    # There is no item data inserted into directory listing:
    # New item data added into directory listing:
    my @data = get_empty_data();
    my @new_item_data = $item->data();
    splice @data, 0x02, 0x1e, @new_item_data;
    $data[0x01] = chr 0xff;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to an empty directory listing with an empty slot at index 0 and without offset specification');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->put(item => get_deleted_item(), index => 0);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 3;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x02, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing with an empty slot at index 0 and without offset specification');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->put(item => get_deleted_item(), index => 1);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 3;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x22, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing with an empty slot at index 1 and without offset specification');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->put(item => get_deleted_item(), index => 2);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 3;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x42, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing with an empty slot at index 2 and without offset specification');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->put(item => get_deleted_item(), index => 3);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 4;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x62, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing with an empty slot at index 3 and without offset specification');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 4;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x62, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a directory listing without an empty slot and without offset specification');
}
########################################
{
    my $module = new Test::MockModule($class);
    $module->mock('num_items', sub { return $max_entries; });
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    $dir->put(item => get_deleted_item(), index => 1);
    my $item = get_new_item();
    my $is_success = $dir->add(item => $item);
    # A successful add of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 144;
    # New item data added into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x22, 0x1e, @new_item_data;
    $data[0x00] = chr 0x12;
    $data[0x01] = chr 0x04;
    my $data = join '', @data[0x00 .. $sector_data_size - 1];
    my $test3 = ($dir->sectors())[0]->data() eq $data;
    ok($test1 && $test2 && $test3, 'add an item to a full directory listing with an empty slot at index 1 and without offset specification');
    $module->unmock_all();
}
########################################
