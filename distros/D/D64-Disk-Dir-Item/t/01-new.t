########################################
use strict;
use warnings;
use Readonly;
use Test::Deep;
use Test::Exception;
use Test::More tests => 41;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Dir::Item';
    use_ok($class, qw(:all));
}
########################################
{
    can_ok($class, qw(new data type closed locked track sector name side_track side_sector record_length size print validate));
}
########################################
{
    my $test_del = $T_DEL == 0b000;
    my $test_seq = $T_SEQ == 0b001;
    my $test_prg = $T_PRG == 0b010;
    my $test_usr = $T_USR == 0b011;
    my $test_rel = $T_REL == 0b100;
    my $test_cbm = $T_CBM == 0b101;
    my $test_dir = $T_DIR == 0b110;
    my $test = $test_del && $test_seq && $test_prg && $test_usr && $test_rel && $test_cbm && $test_dir;
    ok($test, 'export file type constants');
}
########################################
{
    my $item = $class->new();
    my $data = $item->data();
    my $expected_data = chr (0x00) x 0x1e;
    is($data, $expected_data, 'empty item initialized with thirty $00 bytes (get scalar data)');
}
########################################
{
    my $item = $class->new();
    my @data = $item->data();
    my @expected_data = map { chr 0x00 } (0x01 .. 0x1e);
    cmp_deeply(\@data, \@expected_data, 'empty item initialized with thirty $00 bytes (get array data)');
}
########################################
sub get_data {
    my @bytes = qw(82 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my @data = map { chr } map { hex } @bytes;
    return @data;
}
########################################
{
    my $initial_data = join '', get_data();
    my $item = $class->new($initial_data);
    my $data = $item->data();
    is($data, $initial_data, 'initialize directory item using data provided via scalar parameter');
}
########################################
{
    my @initial_data = get_data();
    my $item = $class->new(@initial_data);
    my @data = $item->data();
    cmp_deeply(\@data, \@initial_data, 'initialize directory item using data provided via array parameter');
}
########################################
{
    my @initial_data = get_data();
    my $item = $class->new(\@initial_data);
    my @data = $item->data();
    cmp_deeply(\@data, \@initial_data, 'initialize directory item using data provided via arrayref parameter');
}
########################################
{
    my $item = $class->new();
    my $updated_data = join '', get_data();
    my $data = $item->data($updated_data);
    is($data, $updated_data, 'update directory item with data provided via scalar parameter');
}
########################################
{
    my $item = $class->new();
    my @updated_data = get_data();
    my @data = $item->data(@updated_data);
    cmp_deeply(\@data, \@updated_data, 'update directory item with data provided via array parameter');
}
########################################
{
    my $item = $class->new();
    my @updated_data = get_data();
    my @data = $item->data(\@updated_data);
    cmp_deeply(\@data, \@updated_data, 'update directory item with data provided via arrayref parameter');
}
########################################
{
    my @data = get_data();
    my $invalid_data = join ('', @data[0..28]) . join ('', @data[0..1]);
    throws_ok(
        sub { $class->new($invalid_data); },
        qr/Invalid length of data/,
        'initialize directory item using invalid data (wrong number of bytes) provided via scalar parameter',
    );
}
########################################
{
    my @data = get_data();
    my @invalid_data = @data[0..28];
    throws_ok(
        sub { $class->new(@invalid_data); },
        qr/Invalid amount of data/,
        'initialize directory item using invalid data (wrong number of bytes) provided via array parameter',
    );
}
########################################
{
    my @data = get_data();
    my @invalid_data = @data[0..1];
    throws_ok(
        sub { $class->new(\@invalid_data); },
        qr/Invalid amount of data/,
        'initialize directory item using invalid data (wrong number of bytes) provided via arrayref parameter',
    );
}
########################################
{
    my $item = $class->new();
    my @data = get_data();
    my $invalid_data = join ('', @data[0..28]) . join ('', @data[0..1]);
    throws_ok(
        sub { $item->data($invalid_data); },
        qr/Invalid length of data/,
        'update directory item with invalid data (wrong number of bytes) provided via scalar parameter',
    );
}
########################################
{
    my $item = $class->new();
    my @data = get_data();
    my @invalid_data = @data[0..28];
    throws_ok(
        sub { $item->data(@invalid_data); },
        qr/Invalid amount of data/,
        'update directory item with invalid data (wrong number of bytes) provided via array parameter',
    );
}
########################################
{
    my $item = $class->new();
    my @data = get_data();
    my @invalid_data = @data[0..1];
    throws_ok(
        sub { $item->data(\@invalid_data); },
        qr/Invalid amount of data/,
        'update directory item with invalid data (wrong number of bytes) provided via arrayref parameter',
    );
}
########################################
{
    my @data = get_data();
    my $invalid_data = 0x1e;
    throws_ok(
        sub { $class->new($invalid_data); },
        qr/Invalid length of data/,
        'initialize directory item using invalid data (wrong type) provided via scalar parameter',
    );
}
########################################
{
    my @data = get_data();
    my @invalid_data = (0x0101 .. 0x011e);
    throws_ok(
        sub { $class->new(@invalid_data); },
        qr/Invalid byte value at offset 0 \(\$101\)/,
        'initialize directory item using invalid data (wrong type) provided via array parameter',
    );
}
########################################
{
    my @data = get_data();
    my @invalid_data = map { 0x00 } (0x01 .. 0x1e);
    $invalid_data[0x13] = [];
    throws_ok(
        sub { $class->new(\@invalid_data); },
        qr/Invalid data type at offset 19 \(ARRAY\)/,
        'initialize directory item using invalid data (wrong type) provided via arrayref parameter',
    );
}
########################################
{
    my $item = $class->new();
    my @data = get_data();
    my $invalid_data = 0x1e;
    throws_ok(
        sub { $item->data($invalid_data); },
        qr/Invalid length of data/,
        'update directory item with invalid data (wrong type) provided via scalar parameter',
    );
}
########################################
{
    my $item = $class->new();
    my @data = get_data();
    my @invalid_data = (0x0101 .. 0x011e);
    throws_ok(
        sub { $item->data(@invalid_data); },
        qr/Invalid byte value at offset 0 \(\$101\)/,
        'update directory item with invalid data (wrong type) provided via array parameter',
    );
}
########################################
{
    my $item = $class->new();
    my @data = get_data();
    my @invalid_data = map { 0x00 } (0x01 .. 0x1e);
    $invalid_data[0x13] = [];
    throws_ok(
        sub { $item->data(\@invalid_data); },
        qr/Invalid data type at offset 19 \(ARRAY\)/,
        'update directory item with invalid data (wrong type) provided via arrayref parameter',
    );
}
########################################
{
    my $var;
    ok(!$class->is_int($var), "is undef treated as an integer value by Perl internally");
}
########################################
{
    my $var = 0;
    ok($class->is_int($var), "is 0 treated as an integer value by Perl internally");
}
########################################
{
    my $var = 666;
    ok($class->is_int($var), "is 666 treated as an integer value by Perl internally");
}
########################################
{
    my $var = '0';
    ok(!$class->is_int($var), "is '0' treated as an integer value by Perl internally");
}
########################################
{
    my $var = '666';
    ok(!$class->is_int($var), "is '666' treated as an integer value by Perl internally");
}
########################################
{
    my $var = [];
    ok(!$class->is_int($var), "is [] treated as an integer value by Perl internally");
}
########################################
{
    my $var = [666];
    ok(!$class->is_int($var), "is [666] treated as an integer value by Perl internally");
}
########################################
{
    my $var;
    ok(!$class->is_str($var), "is undef treated as a string value by Perl internally");
}
########################################
{
    my $var = 0;
    ok(!$class->is_str($var), "is 0 treated as a string value by Perl internally");
}
########################################
{
    my $var = 666;
    ok(!$class->is_str($var), "is 666 treated as a string value by Perl internally");
}
########################################
{
    my $var = '0';
    ok($class->is_str($var), "is '0' treated as a string value by Perl internally");
}
########################################
{
    my $var = '666';
    ok($class->is_str($var), "is '666' treated as a string value by Perl internally");
}
########################################
{
    my $var = 'test';
    ok($class->is_str($var), "is 'test' treated as a string value by Perl internally");
}
########################################
{
    my $var = [];
    ok(!$class->is_str($var), "is [] treated as a string value by Perl internally");
}
########################################
{
    my $var = [666];
    ok(!$class->is_str($var), "is [666] treated as a string value by Perl internally");
}
########################################
{
    my $var = ['test'];
    ok(!$class->is_str($var), "is ['test'] treated as a string value by Perl internally");
}
########################################
{
    my $magic;
    if ($] < 5.008) {
        eval q{ Readonly \\$magic => 0b0100; };
    }
    else {
        eval q{ Readonly $magic => 0b0100; };
    }
    is($class->magic_to_int($magic), 4, "convert readonly's magic scalar value to internally recognized integer number")
}
########################################
{
    my $magic;
    if ($] < 5.008) {
        eval q{
            Readonly \\$magic => 'test';
        };
    }
    else {
        eval q{
            Readonly $magic => 'test';
        };
    }
    is($class->magic_to_int($magic), undef, "convert readonly's magic string value to undef (conversion to integer not possible)")
}
########################################
