########################################
use bytes;
use strict;
use warnings;
use Test::Exception;
use Test::More tests => 15;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Dir::Item';
    use_ok($class, qw(:all));
}
########################################
sub get_item {
    my @bytes = qw(82 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my @data = map { chr } map { hex } @bytes;
    my $item = $class->new(@data);
    return $item;
}
########################################
{
    my $item = $class->new();
    ok($item->validate(), 'validate empty directory item');
}
########################################
{
    my $item = get_item();
    ok($item->validate(), 'validate valid directory item');
}
########################################
{
    my $item = get_item();
    my $I_TYPE = eval "\$${class}::I_TYPE";
    $item->[$I_TYPE] = chr (ord ($item->[$I_TYPE]) | 0b00001000);
    ok(!$item->validate(), 'validate directory item with invalid file type');
}
########################################
{
    my $item = get_item();
    $item->type($T_SEQ);
    my @bytes = qw(81 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new type for a valid directory item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    $item->closed(0);
    my @bytes = qw(02 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'clear closed flag for a valid directory item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    $item->locked(1);
    my @bytes = qw(c2 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set locked flag for a valid directory item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    $item->track(0x13);
    my @bytes = qw(82 13 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new track location of first sector of file for a valid directory item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    $item->sector(0x03);
    my @bytes = qw(82 11 03 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new sector location of first sector of file for a valid directory item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    $item->side_track(0x13);
    my @bytes = qw(84 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 13 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new track location of first side-sector block for a valid relative file item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    $item->side_sector(0x03);
    my @bytes = qw(84 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 03 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new sector location of first side-sector block for a valid relative file item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    $item->record_length(0x01);
    my @bytes = qw(84 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 01 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new record length for a valid relative file item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    $item->size(0xa0);
    my @bytes = qw(82 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 a0 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new file size in sectors for a valid directory item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45) . chr(0x20) . chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45) . chr(0xa0);
    $item->name($new_name);
    my @bytes = qw(82 11 00 4e 45 57 46 49 4c 45 20 4e 45 57 46 49 4c 45 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new filename for a valid directory item and fetch data bytes');
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45) . chr(0x20) . chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45);
    $item->name($new_name, padding_with_a0 => 0);
    my @bytes = qw(82 11 00 4e 45 57 46 49 4c 45 20 4e 45 57 46 49 4c 45 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    is($item->data(), $data, 'set new filename without $A0 padding of stored data for a valid directory item and fetch data bytes');
}
########################################
