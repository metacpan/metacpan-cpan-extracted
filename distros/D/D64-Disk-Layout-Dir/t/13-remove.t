########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Text::Convert::PETSCII qw(:convert);
use Test::Exception;
use Test::More tests => 34;
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
sub get_dir_layout_object {
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    return $dir;
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(); },
        qr/\QUnable to entirely remove directory item: Missing index\/pattern parameter (which element did you want to remove?)\E/,
        'remove disk directory item without any offset designation',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(index => undef); },
        qr/\QUnable to entirely remove directory item: Invalid index parameter (got "undef", but expected an integer between 0 and 143)\E/,
        'remove disk directory item designated by an undefined offset',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(pattern => undef); },
        qr/\QUnable to entirely remove directory item: Invalid pattern parameter (got "undef", but expected a valid PETSCII text string)\E/,
        'remove disk directory item matching an undefined pattern',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(index => undef, pattern => undef); },
        qr/\QUnable to entirely remove directory item: ambiguous removal index\/pattern specified (you cannot specify both parameters at the same time)\E/,
        'remove disk directory item designated by an offset and a pattern both at the same time',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(index => []); },
        qr/\QUnable to entirely remove directory item: Invalid index parameter (got "[]", but expected an integer between 0 and 143)\E/,
        'remove disk directory item designated by a non-numeric offset',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(pattern => []); },
        qr/\QUnable to entirely remove directory item: Invalid pattern parameter (got "[]", but expected a valid PETSCII text string)\E/,
        'remove disk directory item matching an arrayref pattern',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(index => -1); },
        qr/\QUnable to entirely remove directory item: Invalid index parameter (got "-1", but expected an integer between 0 and 143)\E/,
        'remove disk directory item designated by a negative numeric offset',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(index => 2.1); },
        qr/\QUnable to entirely remove directory item: Invalid index parameter (got "2.1", but expected an integer between 0 and 143)\E/,
        'remove disk directory item designated by a floating point number offset',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(index => 144); },
        qr/\QUnable to entirely remove directory item: Invalid index parameter (got "144", but expected an integer between 0 and 143)\E/,
        'remove disk directory item designated by an offset beyond the maximum possible amount of elements in a disk directory',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(pattern => chr 0x03A9); },
        qr/\QUnable to entirely remove directory item: Invalid pattern parameter (got "\x{3a9}", but expected a valid PETSCII text string)\E/,
        'remove disk directory item matching an invalid PETSCII text string',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(pattern => ascii_to_petscii 'abcdefghijklmnopqrstuvwxyz'); },
        qr/\QUnable to entirely remove directory item: Invalid pattern parameter (got "abcdefghijklmnopqrstuvwxyz", but expected a valid PETSCII text string)\E/,
        'remove disk directory item matching too long PETSCII text string',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    throws_ok(
        sub { $dir->remove(pattern => ''); },
        qr/\QUnable to entirely remove directory item: Invalid pattern parameter (got "", but expected a valid PETSCII text string)\E/,
        'remove disk directory item matching an empty PETSCII text string',
    );
}
########################################
{
    my $dir = get_dir_layout_object();
    my $num_removed = $dir->remove(index => 3);
    # number of successfully removed items is 0
    my $test1 = $num_removed == 0;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # directory item data remains unchanged
    my $expected_data = get_dir_data();
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove disk directory item designated by an offset beyond the last non-empty directory item');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $num_removed = $dir->remove(index => 2);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # last directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x40, 0x20;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove disk directory item designated by an offset of the last non-empty directory item');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $num_removed = $dir->remove(index => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # first directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x20;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove disk directory item designated by an offset of the first directory item');
}
########################################
{
    my $dir = get_dir_layout_object();
    $dir->remove(index => 0);
    my $num_removed = $dir->remove(index => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 1
    my $test2 = $dir->num_items() == 1;
    # first and second directory items get completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x40;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x20, 0x00, map { chr 0x00 } (0x00 .. 0x3f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove disk directory item designated by an offset of an already removed directory item');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii '*';
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # first directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x20;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "*" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii '*';
    $dir->remove(pattern => $pattern, global => 0);
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 1
    my $test2 = $dir->num_items() == 1;
    # first and second directory items get completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x40;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x20, 0x00, map { chr 0x00 } (0x00 .. 0x3f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "*" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii '*';
    my $num_removed = $dir->remove(pattern => $pattern, global => 1);
    # number of successfully removed items is 3
    my $test1 = $num_removed == 3;
    # number of directory items is now 0
    my $test2 = $dir->num_items() == 0;
    # all directory items get completely removed
    my $expected_data = get_empty_data();
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove all disk directory items matching "*" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file*';
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # first directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x20;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "file*" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file*';
    $dir->remove(pattern => $pattern, global => 0);
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 1
    my $test2 = $dir->num_items() == 1;
    # first and second directory items get completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x40;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x20, 0x00, map { chr 0x00 } (0x00 .. 0x3f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "file*" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file*';
    my $num_removed = $dir->remove(pattern => $pattern, global => 1);
    # number of successfully removed items is 3
    my $test1 = $num_removed == 3;
    # number of directory items is now 0
    my $test2 = $dir->num_items() == 0;
    # all directory items get completely removed
    my $expected_data = get_empty_data();
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove all disk directory items matching "file*" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file01';
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # first directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x20;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "file01" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file01';
    $dir->remove(pattern => $pattern, global => 0);
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 0
    my $test1 = $num_removed == 0;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # first directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x20;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "file01" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file01';
    my $num_removed = $dir->remove(pattern => $pattern, global => 1);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # first directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x20;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove all disk directory items matching "file01" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file02';
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # second directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x20, 0x20;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "file02" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file02';
    $dir->remove(pattern => $pattern, global => 0);
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 0
    my $test1 = $num_removed == 0;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # second directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x20, 0x20;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "file02" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file02';
    my $num_removed = $dir->remove(pattern => $pattern, global => 1);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # second directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x20, 0x20;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove all disk directory items matching "file02" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file0?';
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 2
    my $test2 = $dir->num_items() == 2;
    # first directory item gets completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x20;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x40, 0x00, map { chr 0x00 } (0x00 .. 0x1f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "file0?" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file0?';
    $dir->remove(pattern => $pattern, global => 0);
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 1
    my $test1 = $num_removed == 1;
    # number of directory items is now 1
    my $test2 = $dir->num_items() == 1;
    # first and second directory items get completely removed
    my @expected_data = get_dir_data();
    splice @expected_data, 0x00, 0x40;
    $expected_data[0x01] = chr 0xff;
    splice @expected_data, 0x20, 0x00, map { chr 0x00 } (0x00 .. 0x3f);
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "file0?" pattern twice');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'file0?';
    my $num_removed = $dir->remove(pattern => $pattern, global => 1);
    # number of successfully removed items is 3
    my $test1 = $num_removed == 3;
    # number of directory items is now XXX
    my $test2 = $dir->num_items() == 0;
    # all directory items get completely removed
    my $expected_data = get_empty_data();
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove all disk directory items matching "file0?" pattern');
}
#########################################    'remove first disk directory item matching "foo" pattern'
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'foo';
    my $num_removed = $dir->remove(pattern => $pattern, global => 0);
    # number of successfully removed items is 0
    my $test1 = $num_removed == 0;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # no directory items get completely removed
    my @expected_data = get_dir_data();
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove first disk directory item matching "foo" pattern');
}
########################################
{
    my $dir = get_dir_layout_object();
    my $pattern = ascii_to_petscii 'foo';
    my $num_removed = $dir->remove(pattern => $pattern, global => 1);
    # number of successfully removed items is 0
    my $test1 = $num_removed == 0;
    # number of directory items remains unchanged
    my $test2 = $dir->num_items() == 3;
    # no directory items get completely removed
    my @expected_data = get_dir_data();
    my $expected_data = join '', @expected_data;
    my $data = $dir->data();
    my $test3 = $data eq $expected_data;
    ok($test1 && $test2 && $test3, 'remove all disk directory items matching "foo" pattern');
}
########################################
