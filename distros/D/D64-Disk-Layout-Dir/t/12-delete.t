########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Text::Convert::PETSCII qw(:convert);
use Test::Exception;
use Test::More tests => 31;
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
sub get_dir_layout_object {
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    return $dir;
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(); },
        qr/\QUnable to mark directory item as deleted: Missing index\/pattern parameter (which element did you want to delete?)\E/,
        'delete disk directory item without any offset designation',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(index => undef); },
        qr/\QUnable to mark disk directory item as deleted: Invalid index parameter (got "undef", but expected an integer between 0 and 143)\E/,
        'delete disk directory item designated by an undefined offset',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(pattern => undef); },
        qr/\QUnable to mark disk directory item as deleted: Invalid pattern parameter (got "undef", but expected a valid PETSCII text string)\E/,
        'delete disk directory item matching an undefined pattern',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(index => undef, pattern => undef); },
        qr/\QUnable to mark directory item as deleted: ambiguous deletion index\/pattern specified (you cannot specify both parameters at the same time)\E/,
        'delete disk directory item designated by an offset and a pattern both at the same time',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(index => []); },
        qr/\QUnable to mark disk directory item as deleted: Invalid index parameter (got "[]", but expected an integer between 0 and 143)\E/,
        'delete disk directory item designated by a non-numeric offset',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(pattern => []); },
        qr/\QUnable to mark disk directory item as deleted: Invalid pattern parameter (got "[]", but expected a valid PETSCII text string)\E/,
        'delete disk directory item matching an arrayref pattern',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(index => -1); },
        qr/\QUnable to mark disk directory item as deleted: Invalid index parameter (got "-1", but expected an integer between 0 and 143)\E/,
        'delete disk directory item designated by a negative numeric offset',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(index => 2.1); },
        qr/\QUnable to mark disk directory item as deleted: Invalid index parameter (got "2.1", but expected an integer between 0 and 143)\E/,
        'delete disk directory item designated by a floating point number offset',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(index => 144); },
        qr/\QUnable to mark disk directory item as deleted: Invalid index parameter (got "144", but expected an integer between 0 and 143)\E/,
        'delete disk directory item designated by an offset beyond the maximum possible amount of elements in a disk directory',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(pattern => chr 0x03A9); },
        qr/\QUnable to mark disk directory item as deleted: Invalid pattern parameter (got "\x{3a9}", but expected a valid PETSCII text string)\E/,
        'delete disk directory item matching an invalid PETSCII text string',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(pattern => ascii_to_petscii 'abcdefghijklmnopqrstuvwxyz'); },
        qr/\QUnable to mark disk directory item as deleted: Invalid pattern parameter (got "abcdefghijklmnopqrstuvwxyz", but expected a valid PETSCII text string)\E/,
        'delete disk directory item matching too long PETSCII text string',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->delete(pattern => ''); },
        qr/\QUnable to mark disk directory item as deleted: Invalid pattern parameter (got "", but expected a valid PETSCII text string)\E/,
        'delete disk directory item matching an empty PETSCII text string',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    my $num_deleted = $dir->delete(index => 3);
    # number of successfully deleted items is 0
    my $test1 = $num_deleted == 0;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # directory item data remains unchanged
    my $expected_data = get_dir_data();
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete disk directory item designated by an offset beyond the last non-empty directory item');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $num_deleted = $dir->delete(index => 2);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # last directory item gets mark as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x42] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete disk directory item designated by an offset of the last non-empty directory item');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $num_deleted = $dir->delete(index => 0);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first directory item gets mark as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete disk directory item designated by an offset of the first directory item');
}
########################################
{
    my $dir = get_dir_layout_object();
    $dir->delete(index => 0);
    my $num_deleted = $dir->delete(index => 0);
    # number of successfully deleted items is 0
    my $test1 = $num_deleted == 0;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first directory item gets mark as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete disk directory item designated by an offset of an already deleted directory item');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii '*';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first directory item gets marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "*" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii '*';
    $dir->delete(pattern => $pattern, global => 0);
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first and second directory items get marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    $expected_data[0x22] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "*" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii '*';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 1);
    # number of successfully deleted items is 3
    my $test1 = $num_deleted == 3;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # all directory items get marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    $expected_data[0x22] = chr 0x00;
    $expected_data[0x42] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete all disk directory items matching "*" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file*';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first directory item gets marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "file*" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file*';
    $dir->delete(pattern => $pattern, global => 0);
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first and second directory items get marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    $expected_data[0x22] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "file*" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file*';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 1);
    # number of successfully deleted items is 3
    my $test1 = $num_deleted == 3;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # all directory items get marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    $expected_data[0x22] = chr 0x00;
    $expected_data[0x42] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete all disk directory items matching "file*" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file01';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first directory item gets marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "file01" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file01';
    $dir->delete(pattern => $pattern, global => 0);
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 0
    my $test1 = $num_deleted == 0;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first directory item gets marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "file01" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file01';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 1);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first directory item gets marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete all disk directory items matching "file01" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file0?';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first directory item gets marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "file0?" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file0?';
    $dir->delete(pattern => $pattern, global => 0);
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 1
    my $test1 = $num_deleted == 1;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # first and second directory items get marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    $expected_data[0x22] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "file0?" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file0?';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 1);
    # number of successfully deleted items is 3
    my $test1 = $num_deleted == 3;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # all directory items get marked as deleted
    my @expected_data = get_dir_data();
    $expected_data[0x02] = chr 0x00;
    $expected_data[0x22] = chr 0x00;
    $expected_data[0x42] = chr 0x00;
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete all disk directory items matching "file0?" pattern');
}
#########################################    'delete first disk directory item matching "foo" pattern'
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'foo';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 0);
    # number of successfully deleted items is 0
    my $test1 = $num_deleted == 0;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # no directory items get marked as deleted
    my @expected_data = get_dir_data();
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete first disk directory item matching "foo" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'foo';
    my $num_deleted = $dir->delete(pattern => $pattern, global => 1);
    # number of successfully deleted items is 0
    my $test1 = $num_deleted == 0;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # no directory items get marked as deleted
    my @expected_data = get_dir_data();
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'delete all disk directory items matching "foo" pattern');
}
########################################
