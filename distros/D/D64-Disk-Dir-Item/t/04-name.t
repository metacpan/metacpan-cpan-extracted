########################################
use strict;
use utf8;
use warnings;
use Test::Exception;
use Test::More tests => 25;
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
    my $name = chr (0x00) x 16;
    is($item->name(), $name, 'get 16 character filename from an empty directory item');
}
########################################
{
    my $item = $class->new();
    my $name = chr (0x00) x 16;
    is($item->name(padding_with_a0 => 0), $name, 'get 16 character filename without $A0 padding from an empty directory item');
}
########################################
{
    my $item = get_item();
    my $name = chr(0x54) . chr(0x45) . chr(0x53) . chr(0x54) . chr(0xa0) x 12;
    is($item->name(), $name, 'get 16 character filename from a valid directory item');
}
########################################
{
    my $item = get_item();
    my $name = chr(0x54) . chr(0x45) . chr(0x53) . chr(0x54);
    is($item->name(padding_with_a0 => 0), $name, 'get 16 character filename without $A0 padding from a valid directory item');
}
########################################
sub test_filename {
    my ($item, $name, $length) = @_;
    return $item->name() eq $name && $item->name(padding_with_a0 => 0) eq substr $name, 0, $length;
}
########################################
{
    my $item = $class->new();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x20) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45) . chr(0xa0) x 8;
    $item->name($new_name);
    ok(test_filename($item, $new_name, 8), 'set new filename for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x20) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45) . chr(0xa0) x 8;
    $item->name($new_name);
    ok(test_filename($item, $new_name, 8), 'set new filename for a valid directory item');
}
########################################
{
    my $item = $class->new();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57);
    $item->name($new_name);
    my $set_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0xa0) x 13;
    ok(test_filename($item, $set_name, 3), 'set new filename without $A0 padding of input data for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57);
    $item->name($new_name);
    my $set_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0xa0) x 13;
    ok(test_filename($item, $set_name, 3), 'set new filename without $A0 padding of input data for a valid directory item');
}
########################################
{
    my $item = $class->new();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x20) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45) . chr(0xa0) x 8;
    $item->name($new_name, padding_with_a0 => 0);
    ok(test_filename($item, $new_name, 8), 'set new filename without $A0 padding of stored data for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x20) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45) . chr(0xa0) x 8;
    $item->name($new_name, padding_with_a0 => 0);
    ok(test_filename($item, $new_name, 8), 'set new filename without $A0 padding of stored data for a valid directory item');
}
########################################
{
    my $item = $class->new();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57);
    $item->name($new_name, padding_with_a0 => 0);
    my $set_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x00) x 13;
    ok(test_filename($item, $set_name, 16), 'set new filename without $A0 padding of input and stored data for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57);
    $item->name($new_name, padding_with_a0 => 0);
    my $set_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x54) . chr(0xa0) x 12;
    ok(test_filename($item, $set_name, 4), 'set new filename without $A0 padding of input and stored data for a valid directory item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->name([chr(0x4e) . chr(0x45) . chr(0x57)]); },
        qr/\QInvalid type (['NEW']) of filename (string value expected)\E/,
        'set non-scalar filename for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->name(chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x0100)); },
        qr/\QInvalid string ("NEW\E\\\Qx{100}") of filename (PETSCII string expected)\E/,
        'set filename with illegal characters for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x20) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45) . chr(0x20) . chr(0x4e) . chr(0x45) . chr(0x57) . chr(0x20) . chr(0x46) . chr(0x49) . chr(0x4c) . chr(0x45);
    throws_ok(
        sub { $item->name($new_name); },
        qr/\QToo long ('NEW FILE NEW FILE') filename (maximum 16 PETSCII characters allowed)\E/,
        'set too long filename for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->name(0x41); },
        qr/\QInvalid type (65) of filename (string value expected)\E/,
        'set numeric filename for a valid directory item',
    );
}
########################################
{
    my $item = $class->new();
    my $new_name = chr(0xa0) x 16;
    $item->name($new_name);
    ok(test_filename($item, $new_name, 0), 'set empty filename for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0xa0) x 16;
    $item->name($new_name);
    ok(test_filename($item, $new_name, 0), 'set empty filename for a valid directory item');
}
########################################
{
    my $item = $class->new();
    $item->name('');
    my $set_name = chr(0xa0) x 16;
    ok(test_filename($item, $set_name, 0), 'set empty filename without $A0 padding of input data for an empty directory item');
}
########################################
{
    my $item = get_item();
    $item->name('');
    my $set_name = chr(0xa0) x 16;
    ok(test_filename($item, $set_name, 0), 'set empty filename without $A0 padding of input data for a valid directory item');
}
########################################
{
    my $item = $class->new();
    my $new_name = chr(0xa0) x 16;
    $item->name($new_name, padding_with_a0 => 0);
    ok(test_filename($item, $new_name, 0), 'set empty filename without $A0 padding of stored data for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $new_name = chr(0xa0) x 16;
    $item->name($new_name, padding_with_a0 => 0);
    ok(test_filename($item, $new_name, 0), 'set empty filename without $A0 padding of stored data for a valid directory item');
}
########################################
{
    my $item = $class->new();
    $item->name('', padding_with_a0 => 0);
    my $set_name = chr(0x00) x 16;
    ok(test_filename($item, $set_name, 16), 'set empty filename without $A0 padding of input and stored data for an empty directory item');
}
########################################
{
    my $item = get_item();
    $item->name('', padding_with_a0 => 0);
    my $set_name = chr(0x54) . chr(0x45) . chr(0x53) . chr(0x54) . chr(0xa0) x 12;
    ok(test_filename($item, $set_name, 4), 'set empty filename without $A0 padding of input and stored data for a valid directory item');
}
########################################
