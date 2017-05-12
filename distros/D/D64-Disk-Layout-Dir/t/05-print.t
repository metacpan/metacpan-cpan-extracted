########################################
use strict;
use warnings;
use IO::Scalar;
use D64::Disk::Dir::Item;
use D64::Disk::Layout::Sector;
use Test::More tests => 6;
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
    my $sh = new IO::Scalar;
    $dir->print(fh => $sh);
    my $print_out = ${$sh->sref};
    my $expected_print_out = '';
    is($print_out, $expected_print_out, 'print out disk directory from an empty disk directory layout object');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $sh = new IO::Scalar;
    $dir->print(fh => $sh, as_petscii => 0);
    my $print_out = ${$sh->sref};
    my $expected_print_out = <<'    LISTING';
1    "file01"           prg 
2    "file02"           prg 
3    "file03"           prg 
    LISTING
    is($print_out, $expected_print_out, 'print out disk directory from a disk directory layout object with explicit item data using ASCII character set');
}
########################################
{
    my @items = get_dir_items();
    my $dir = $class->new(items => \@items);
    my $sh = new IO::Scalar;
    $dir->print(fh => $sh, as_petscii => 1);
    my $print_out = ${$sh->sref};
    $sh = new IO::Scalar;
    $_->print(fh => $sh, as_petscii => 1) for @items;
    my $expected_print_out = ${$sh->sref};
    is($print_out, $expected_print_out, 'print out disk directory from a disk directory layout object with explicit item data using PETSCII character set');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    my $sh = new IO::Scalar;
    $dir->print(fh => $sh, as_petscii => 0);
    my $print_out = ${$sh->sref};
    my $expected_print_out = <<'    LISTING';
1    "file01"           prg 
2    "file02"           prg 
3    "file03"           prg 
1    "file04"           prg 
2    "file05"           prg 
3    "file06"           prg 
1    "file07"           prg 
2    "file08"           prg 
1    "file11"           prg 
2    "file12"           prg 
3    "file13"           prg 
1    "file14"           prg 
    LISTING
    is($print_out, $expected_print_out, 'print out disk directory from a disk directory layout object with extended item data using ASCII character set');
}
########################################
{
    my @items = get_more_dir_items();
    my $dir = $class->new(items => \@items);
    my $sh = new IO::Scalar;
    $dir->print(fh => $sh, as_petscii => 1);
    my $print_out = ${$sh->sref};
    $sh = new IO::Scalar;
    $_->print(fh => $sh, as_petscii => 1) for @items;
    my $expected_print_out = ${$sh->sref};
    is($print_out, $expected_print_out, 'print out disk directory from a disk directory layout object with extended item data using PETSCII character set');
}
########################################
