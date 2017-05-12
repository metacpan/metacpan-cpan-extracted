########################################
use strict;
use warnings;
use IO::Scalar;
use Test::Deep;
use Test::Exception;
use Test::More tests => 41;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Layout::Sector';
    use_ok($class);
}
########################################
our $sector_data_size = eval "\$${class}::SECTOR_DATA_SIZE";
########################################
sub get_sector_data {
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    my @file = map { chr } map { hex } qw(11 03 00 10);
    splice @data, 0, scalar (@file), @file;
    return @data;
}
########################################
sub get_file_from_sector_data {
    my @data = get_sector_data();
    splice @data, 0, 2;
    my $data = join '', @data;
    return $data;
}
########################################
sub get_sector_object {
    my @data = get_sector_data();
    my $track = 0x11;
    my $sector = 0x00;
    my $object = $class->new(data => \@data, track => $track, sector => $sector);
    return $object;
}
########################################
sub get_file_data {
    my @file_data = map { chr } map { hex } qw(01 08 0b 08 0a 00 9e 34 30 39 36 00 00 00);
    return @file_data;
}
########################################
sub get_sector_from_file_data {
    my ($type) = @_; # chained/empty/last
    my @data = get_sector_data();
    my @file = get_file_data();
    splice @data, 2, scalar (@file), @file;
    if ($type eq 'last') {
        $data[0] = chr 0x00;
        $data[1] = chr 0x0f;
    }
    elsif ($type eq 'empty') {
        $data[0] = chr 0x00;
        $data[1] = chr 0x00;
    }
    return @data;
}
########################################
{
    my $object = get_sector_object();
    throws_ok(
        sub { $object->file_data({}); },
        qr/\QUnable to set file data: Invalid arguments given\E/,
        'set non-scalar file data for a valid sector object',
    );
}
########################################
{
    my $object = get_sector_object();
    $object->file_data('');
    my $expected_data = join '', get_sector_data();
    is($object->data(), $expected_data, 'set an empty file data for a valid sector object and get sector data');
}
########################################
{
    my $object = get_sector_object();
    $object->file_data('');
    my $expected_data = get_file_from_sector_data();
    is($object->file_data(), $expected_data, 'set an empty file data for a valid sector object and get file data');
}
########################################
{
    my $object = get_sector_object();
    $object->file_data('', set_alloc_size => 1);
    my @expected_data = get_sector_data();
    $expected_data[0] = chr 0x00;
    $expected_data[1] = chr 0x00;
    my $expected_data = join '', @expected_data;
    is($object->data(), $expected_data, 'set an empty file data with flag set_alloc_size set for a valid sector object and get sector data');
}
########################################
{
    my $object = get_sector_object();
    $object->file_data('', set_alloc_size => 1);
    is($object->file_data(), '', 'set an empty file data with flag set_alloc_size set for a valid sector object and get file data');
}
########################################
{
    my $object = get_sector_object();
    $object->file_data('', set_alloc_size => 0);
    my $expected_data = join '', get_sector_data();
    is($object->data(), $expected_data, 'set an empty file data with flag set_alloc_size clear for a valid sector object and get sector data');
}
########################################
{
    my $object = get_sector_object();
    $object->file_data('', set_alloc_size => 0);
    my $expected_data = get_file_from_sector_data();
    is($object->file_data(), $expected_data, 'set an empty file data with flag set_alloc_size clear for a valid sector object and get file data');
}
########################################
{
    my $object = get_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size - 1);
    my $data = join '', @data;
    throws_ok(
        sub { $object->file_data($data); },
        qr/\QUnable to set file data: Invalid length of data\E/,
        'update file providing 255 bytes of scalar data for a valid sector object',
    );
}
########################################
{
    my $object = get_sector_object();
    my @data = get_file_data();
    $data[0x03] = chr 0x0100;
    my $data = join '', @data;
    throws_ok(
        sub { $object->file_data($data); },
        qr/\QUnable to set file data: Invalid byte value at offset 3 ("\x{100}")\E/,
        'update file providing illegal wide character amongst 14 bytes of scalar data for a valid sector object',
    );
}
########################################
{
    my $object = get_sector_object();
    my @data = get_file_data();
    $data[0x04] = [];
    throws_ok(
        sub { $object->file_data(\@data); },
        qr/\QUnable to set file data: Invalid data type at offset 4 (ARRAY)\E/,
        'update file given arrayref of 14 byte values with a non-scalar variable amongst them for a valid sector object',
    );
}
########################################
{
    my $object = get_sector_object();
    my @data = get_file_data();
    $data[0x05] = chr 0x0100;
    throws_ok(
        sub { $object->file_data(\@data); },
        qr/\QUnable to set file data: Invalid byte value at offset 5 ("\x{100}")\E/,
        'update file given arrayref of 14 byte values with an illegal wide character amongst them for a valid sector object',
    );
}
########################################
{
    my $object = get_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size - 1);
    throws_ok(
        sub { $object->file_data(\@data); },
        qr/\QUnable to set file data: Invalid amount of data\E/,
        'update file given arrayref with 255 bytes of data for a valid sector object',
    );
}
########################################
{
    my $object = get_sector_object();
    my @data = (chr (0x00), chr (0x00), chr (0x00));
    $object->file_data(@data);
    my $expected_data = join '', get_sector_data();
    is($object->data(), $expected_data, 'update file given array with more than 1 byte of data for a valid sector object and get sector data');
}
########################################
{
    my $object = get_sector_object();
    my @data = (chr (0x00), chr (0x00), chr (0x00));
    $object->file_data(@data);
    my $expected_data = get_file_from_sector_data();
    is($object->file_data(), $expected_data, 'update file given array with more than 1 byte of data for a valid sector object and get file data');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    $object->file_data(\@data);
    ok($object->empty(), 'when valid file data is set for an empty sector object, it remains empty by default');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    $object->file_data(\@data, set_alloc_size => 1);
    ok(!$object->empty(), 'when valid file data is set for an empty sector object with flag set_alloc_size set, it is no longer empty');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    $object->file_data(\@data, set_alloc_size => 0);
    ok($object->empty(), 'when valid file data is set for an empty sector object with flag set_alloc_size clear, it remains empty');
}
########################################
{
    my $object = get_sector_object();
    $object->file_data([]);
    ok(!$object->empty(), 'when empty file data is set for a valid sector object, it remains non-empty by default');
}
########################################
{
    my $object = get_sector_object();
    $object->file_data([], set_alloc_size => 1);
    ok($object->empty(), 'when empty file data is set for a valid sector object with flag set_alloc_size set, it becomes empty');
}
########################################
{
    my $object = get_sector_object();
    $object->file_data([], set_alloc_size => 0);
    ok(!$object->empty(), 'when empty file data is set for a valid sector object with flag set_alloc_size set, it remains non-empty');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    my $data = join '', @data;
    $object->file_data($data, set_alloc_size => 1);
    is($object->file_data(), $data, 'update empty sector file data providing 14 bytes of scalar data with marking sector as the last one in chain and get file data');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    my $data = join '', @data;
    $object->file_data($data, set_alloc_size => 1);
    my $expected_data = join '', get_sector_from_file_data('last');
    is($object->data(), $expected_data, 'update empty sector file data providing 14 bytes of scalar data with marking sector as the last one in chain and get sector data');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    my $data = join '', @data;
    $object->file_data($data);
    is($object->file_data(), '', 'update empty sector file data providing 14 bytes of scalar data and get file data');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    my $data = join '', @data;
    $object->file_data($data);
    my $expected_data = join '', get_sector_from_file_data('empty');
    is($object->data(), $expected_data, 'update empty sector file data providing 14 bytes of scalar data and get sector data');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    my $data = join '', @data;
    $object->file_data($data, set_alloc_size => 0);
    my $test1 = not $object->is_valid_ts_link();
    my $test2 = $object->is_last_in_chain();
    my $test3 = $object->alloc_size() == 0x00;
    my $test4 = $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'update empty sector file data providing 14 bytes of scalar data without marking sector as the last one in chain');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    my $data = join '', @data;
    $object->file_data($data, set_alloc_size => 1);
    my $test1 = not $object->is_valid_ts_link();
    my $test2 = $object->is_last_in_chain();
    my $test3 = $object->alloc_size() == 0x0f;
    my $test4 = not $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'update empty sector file data providing 14 bytes of scalar data with marking sector as the last one in chain');
}
########################################
{
    my $object = $class->new();
    my @expected_data = get_file_data();
    $object->file_data(\@expected_data, set_alloc_size => 1);
    my @data = $object->file_data();
    cmp_deeply(\@data, \@expected_data, 'update empty sector file data given arrayref with 14 bytes of data and get file data');
}
########################################
{
    my $object = $class->new();
    my @assigned_data = get_file_data();
    $object->file_data(\@assigned_data, set_alloc_size => 1);
    my @data = $object->data();
    my @expected_data = get_sector_from_file_data('last');
    cmp_deeply(\@data, \@expected_data, 'update empty sector file data given arrayref with 14 bytes of data and get sector data');
}
########################################
{
    my $object = $class->new();
    $object->file_data([get_file_data()]);
    my @data = $object->file_data();
    cmp_deeply(\@data, [], 'update empty sector file data given arrayref with 14 bytes of data with marking sector as the last one in chain and get file data');
}
########################################
{
    my $object = $class->new();
    $object->file_data([get_file_data()]);
    my @data = $object->data();
    my @expected_data = get_sector_from_file_data('empty');
    cmp_deeply(\@data, \@expected_data, 'update empty sector file data given arrayref with 14 bytes of data with marking sector as the last one in chain and get sector data');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    $object->file_data(\@data, set_alloc_size => 0);
    my $test1 = not $object->is_valid_ts_link();
    my $test2 = $object->is_last_in_chain();
    my $test3 = $object->alloc_size() == 0x00;
    my $test4 = $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'update empty sector file data given arrayref with 14 bytes without marking sector as the last one in chain');
}
########################################
{
    my $object = $class->new();
    my @data = get_file_data();
    $object->file_data(\@data, set_alloc_size => 1);
    my $test1 = not $object->is_valid_ts_link();
    my $test2 = $object->is_last_in_chain();
    my $test3 = $object->alloc_size() == 0x0f;
    my $test4 = not $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'update empty sector file data given arrayref with 14 bytes with marking sector as the last one in chain');
}
########################################
{
    my $object = get_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    my $data = join '', @data;
    $object->file_data($data);
    is($object->file_data(), $data, 'update valid sector file data providing 254 bytes of scalar data and get file data');
}
########################################
{
    my $object = get_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    my $data = join '', @data;
    $object->file_data($data);
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    unshift @expected_data, chr 0x11, chr 0x03;
    my $expected_data = join '', @expected_data;
    is($object->data(), $expected_data, 'update valid sector file data providing 254 bytes of scalar data and get sector data');
}
########################################
{
    my $object = get_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    my $data = join '', @data;
    $object->file_data($data, set_alloc_size => 0);
    my $test1 = $object->is_valid_ts_link();
    my $test2 = not $object->is_last_in_chain();
    my $test3 = $object->alloc_size() == 0xff;
    my $test4 = not $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'update valid sector file data providing 254 bytes of scalar data without marking sector as the last one in chain');
}
########################################
{
    my $object = get_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    my $data = join '', @data;
    $object->file_data($data, set_alloc_size => 1);
    my $test1 = not $object->is_valid_ts_link();
    my $test2 = $object->is_last_in_chain();
    my $test3 = $object->alloc_size() == 0xff;
    my $test4 = not $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'update valid sector file data providing 254 bytes of scalar data with marking sector as the last one in chain');
}
########################################
{
    my $object = get_sector_object();
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    $object->file_data(\@expected_data);
    my @data = $object->file_data();
    cmp_deeply(\@data, \@expected_data, 'update valid sector file data given arrayref with 256 bytes of data and get file data');
}
########################################
{
    my $object = get_sector_object();
    my @assigned_data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    $object->file_data(\@assigned_data);
    my @data = $object->data();
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    unshift @expected_data, chr 0x11, chr 0x03;
    cmp_deeply(\@data, \@expected_data, 'update valid sector file data given arrayref with 256 bytes of data and get sector data');
}
########################################
{
    my $object = get_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    $object->file_data(\@data, set_alloc_size => 0);
    my $test1 = $object->is_valid_ts_link();
    my $test2 = not $object->is_last_in_chain();
    my $test3 = $object->alloc_size() == 0xff;
    my $test4 = not $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'update valid sector file data given arrayref with 254 bytes without marking sector as the last one in chain');
}
########################################
{
    my $object = get_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size - 2);
    $object->file_data(\@data, set_alloc_size => 1);
    my $test1 = not $object->is_valid_ts_link();
    my $test2 = $object->is_last_in_chain();
    my $test3 = $object->alloc_size() == 0xff;
    my $test4 = not $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'update valid sector file data given arrayref with 254 bytes with marking sector as the last one in chain');
}
########################################
