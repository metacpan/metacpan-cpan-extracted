########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::Exception;
use Test::More tests => 17;
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
sub get_new_item {
    my @bytes = map { chr } map { hex } qw(82 10 00 4e 45 57 20 46 49 4c 45 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 10 00);
    my $item = D64::Disk::Dir::Item->new(@bytes);
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->put(item => $item); },
        qr/\QUnable to put an item to a directory listing: Missing index parameter (where did you want to put it?)\E/,
        'put an item to a directory listing without any offset designation',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->put(item => $item, index => undef); },
        qr/\QUnable to put an item to a directory listing: Invalid index parameter (got "undef", but expected an integer between 0 and 143)\E/,
        'put an item to a directory listing designated by an undefined offset',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->put(item => $item, index => []); },
        qr/\QUnable to put an item to a directory listing: Invalid index parameter (got "[]", but expected an integer between 0 and 143)\E/,
        'put an item to a directory listing designated by a non-numeric offset',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->put(item => $item, index => -1); },
        qr/\QUnable to put an item to a directory listing: Invalid index parameter (got "-1", but expected an integer between 0 and 143)\E/,
        'put an item to a directory listing designated by a negative numeric offset',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->put(item => $item, index => 2.1); },
        qr/\QUnable to put an item to a directory listing: Invalid index parameter (got "2.1", but expected an integer between 0 and 143)\E/,
        'put an item to a directory listing designated by a floating point number offset',
    );
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    throws_ok(
        sub { $dir->put(item => $item, index => 144); },
        qr/\QUnable to put an item to a directory listing: Invalid index parameter (got "144", but expected an integer between 0 and 143)\E/,
        'put an item to a directory listing designated by an offset beyond the maximum possible amount of elements in a disk directory',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->put(index => 0); },
        qr/\QUnable to put an item to a directory listing: Missing item parameter (what did you want to put there?)\E/,
        'put an item to a directory listing without any item specification',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->put(index => 0, item => ''); },
        qr/\QUnable to put an item to a directory listing: Invalid item parameter (got "", but expected a valid item object)\E/,
        'put a scalar value instead of a new item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->put(index => 0, item => []); },
        qr/\QCan't call method "isa" on unblessed reference\E/, #' <- fix for gedit syntax-highlighting issues
        'put an array reference instead of a new item to a directory listing',
    );
}
########################################
{
    my $dir = $class->new();
    my $is_success = $dir->put(item => get_new_item(), index => 1);
    # Not a successful put of a new entry:
    my $test1 = $is_success == 0;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 0;
    # There is no item data inserted into directory listing:
    my $expected_data = get_empty_data();
    my $test3 = $dir->data() eq $expected_data;
    ok($test1 && $test2 && $test3, 'put an item to a directory listing designated by an offset beyond the last non-empty directory item');
}
########################################
{
    my $dir = $class->new();
    my $is_success = $dir->put(item => get_empty_item(), index => 0);
    # A successful put of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 0;
    # There is no item data inserted into directory listing:
    my $data = get_empty_data();
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'put an empty item to a directory listing');
}
########################################
{
    my $dir = $class->new();
    my $item = get_new_item();
    my $is_success = $dir->put(item => $item, index => 0);
    # A successful put of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 1;
    # New item data inserted into directory listing:
    my @data = get_empty_data();
    my @new_item_data = $item->data();
    splice @data, 0x02, 0x1e, @new_item_data;
    $data[0x01] = chr 0xff;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'put a valid item to a directory listing');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->put(item => $item, index => 0);
    # A successful put of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 3;
    # New item data inserted into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x02, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'put an item to a directory listing designated by an offset of the first non-empty directory item');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->put(item => $item, index => 1);
    # A successful put of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 3;
    # New item data inserted into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x22, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'put an item to a directory listing designated by an offset of the second non-empty directory item');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->put(item => $item, index => 2);
    # A successful put of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items remains unchanged:
    my $test2 = $dir->num_items() == 3;
    # New item data inserted into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x42, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'put an item to a directory listing designated by an offset of the last non-empty directory item');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $item = get_new_item();
    my $is_success = $dir->put(item => $item, index => 3);
    # A successful put of a new entry:
    my $test1 = $is_success == 1;
    # Number of directory items increased by +1:
    my $test2 = $dir->num_items() == 4;
    # New item data inserted into directory listing:
    my @data = get_dir_data();
    my @new_item_data = $item->data();
    splice @data, 0x62, 0x1e, @new_item_data;
    my $data = join '', @data;
    my $test3 = $dir->data() eq $data;
    ok($test1 && $test2 && $test3, 'put an item to a directory listing designated by an offset right after the last non-empty directory item');
}
########################################
