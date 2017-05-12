########################################
use strict;
use warnings;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Text::Convert::PETSCII qw(:convert);
use Test::Deep;
use Test::Exception;
use Test::More tests => 18;
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
    throws_ok(
        sub { $dir->get(index => []) },
        qr/\QUnable to fetch an item from a directory listing: Invalid index parameter (got "[]", but expected an integer between 0 and 143)\E/,
        'get an item from a directory listing at position specified as an array reference',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->get(index => undef) },
        qr/\QUnable to fetch an item from a directory listing: Invalid index parameter (got "undef", but expected an integer between 0 and 143)\E/,
        'get an item from a directory listing at unspecified position',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->get(index => -1) },
        qr/\QUnable to fetch an item from a directory listing: Invalid index parameter (got "-1", but expected an integer between 0 and 143)\E/,
        'get an item from a directory listing at position specified as a negative integer',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->get(index => 5.1) },
        qr/\QUnable to fetch an item from a directory listing: Invalid index parameter (got "5.1", but expected an integer between 0 and 143)\E/,
        'get an item from a directory listing at position specified as a floating point number',
    );
}
########################################
{
    my $dir = $class->new();
    throws_ok(
        sub { $dir->get(index => 144) },
        qr/\QUnable to fetch an item from a directory listing: Invalid index parameter (got "144", but expected an integer between 0 and 143)\E/,
        'get an item from a directory listing at position beyond the maximum possible amount of elements in a disk directory',
    );
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    is($dir->get(index => 143), undef, 'get an item from a directory listing at a maximum possible position');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    is($dir->get(index => 12), undef, 'get an item from a directory listing right after the last non-empty directory item');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    cmp_deeply($dir->get(index => 11), $items[-1], 'get an item from a directory listing at a position of the last non-empty directory item');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    cmp_deeply($dir->get(index => 10), $items[-2], 'get an item from a directory listing at a position of the last but one non-empty directory item');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    cmp_deeply($dir->get(index => 0), $items[0], 'get an item from a directory listing at a position of the first directory item');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    cmp_deeply($dir->get(index => 1), $items[1], 'get an item from a directory listing at a position of the second directory item');
}
########################################
{
    my @assigned_items = get_dir_items();
    my $dir = $class->new(items => \@assigned_items);
    my $pattern = ascii_to_petscii '*';
    my @items = $dir->get(pattern => $pattern);
    my @expected_items = @assigned_items[0,1,2];
    cmp_deeply(\@items, \@expected_items, 'fetch a list of items from a directory listing matching "*" pattern');
}
########################################
{
    my @assigned_items = get_dir_items();
    my $dir = $class->new(items => \@assigned_items);
    my $pattern = ascii_to_petscii 'file*';
    my @items = $dir->get(pattern => $pattern);
    my @expected_items = @assigned_items[0,1,2];
    cmp_deeply(\@items, \@expected_items, 'fetch a list of items from a directory listing matching "file*" pattern');
}
########################################

{
    my @assigned_items = get_dir_items();
    my $dir = $class->new(items => \@assigned_items);
    my $pattern = ascii_to_petscii 'file01';
    my @items = $dir->get(pattern => $pattern);
    my @expected_items = $assigned_items[0];
    cmp_deeply(\@items, \@expected_items, 'fetch a list of items from a directory listing matching "file01" pattern');
}
########################################
{
    my @assigned_items = get_dir_items();
    my $dir = $class->new(items => \@assigned_items);
    my $pattern = ascii_to_petscii 'file0?';
    my @items = $dir->get(pattern => $pattern);
    my @expected_items = @assigned_items[0,1,2];
    cmp_deeply(\@items, \@expected_items, 'fetch a list of items from a directory listing matching "file0?" pattern');
}
########################################
{
    my @assigned_items = get_dir_items();
    my $dir = $class->new(items => \@assigned_items);
    my $pattern = ascii_to_petscii 'foo';
    my @items = $dir->get(pattern => $pattern);
    cmp_deeply(\@items, [], 'fetch a list of items from a directory listing matching "foo" pattern');
}
########################################
{
    my @assigned_items = get_dir_items();
    my $dir = $class->new(items => \@assigned_items);
    my $pattern = ascii_to_petscii 'file?3';
    my @items = $dir->get(pattern => $pattern);
    my @expected_items = $assigned_items[2];
    cmp_deeply(\@items, \@expected_items, 'fetch a list of items from a directory listing matching "file?3" pattern');
}
########################################
