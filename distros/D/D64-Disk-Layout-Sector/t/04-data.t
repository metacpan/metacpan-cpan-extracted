########################################
use strict;
use warnings;
use IO::Scalar;
use Test::Deep;
use Test::Exception;
use Test::More tests => 37;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Layout::Sector';
    use_ok($class);
}
########################################
our $sector_data_size = eval "\$${class}::SECTOR_DATA_SIZE";
########################################
sub get_chained_sector_data {
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    my @file = map { chr } map { hex } qw(11 06 00 10);
    splice @data, 0, scalar (@file), @file;
    return @data;
}
########################################
sub get_last_sector_data {
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    my @file = map { chr } map { hex } qw(00 04 00 10 60);
    splice @data, 0, scalar (@file), @file;
    return @data;
}
########################################
sub get_chained_sector_object {
    my @data = get_chained_sector_data();
    my $track = 0x11;
    my $sector = 0x03;
    my $object = $class->new(data => \@data, track => $track, sector => $sector);
    return $object;
}
########################################
sub get_last_sector_object {
    my @data = get_last_sector_data();
    my $track = 0x13;
    my $sector = 0x01;
    my $object = $class->new(data => \@data, track => $track, sector => $sector);
    return $object;
}
########################################
{
    my $object = $class->new();
    my $data = join '', map { chr 0x00 } (0x01 .. $sector_data_size);
    is($object->data(), $data, 'get default sector data as a scalar of 256 bytes from an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $data = join '', get_chained_sector_data();
    is($object->data(), $data, 'get default sector data as a scalar of 256 bytes from a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my $data = join '', get_last_sector_data();
    is($object->data(), $data, 'get default sector data as a scalar of 256 bytes from a last sector object');
}
########################################
{
    my $object = $class->new();
    my @data = $object->data();
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size);
    cmp_deeply(\@data, \@expected_data, 'get default sector data as an array of 256 bytes from an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = $object->data();
    my @expected_data = get_chained_sector_data();
    cmp_deeply(\@data, \@expected_data, 'get default sector data as an array of 256 bytes from a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my @data = $object->data();
    my @expected_data = get_last_sector_data();
    cmp_deeply(\@data, \@expected_data, 'get default sector data as an array of 256 bytes from a last sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->data({}); },
        qr/\QUnable to set sector data: Invalid arguments given\E/,
        'set non-scalar sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->data(''); },
        qr/\QUnable to set sector data: Invalid length of data\E/,
        'set an empty sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->data(chr 0x00); },
        qr/\QUnable to set sector data: Invalid length of data\E/,
        'update sector providing 1 byte of scalar data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my $data = chr (0x00) . chr (0x00);
    throws_ok(
        sub { $object->data($data); },
        qr/\QUnable to set sector data: Invalid length of data\E/,
        'update sector providing 2 bytes of scalar data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    pop @data;
    my $data = join '', @data;
    throws_ok(
        sub { $object->data($data); },
        qr/\QUnable to set sector data: Invalid length of data\E/,
        'update sector providing 255 bytes of scalar data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    push @data, chr 0x00;
    my $data = join '', @data;
    throws_ok(
        sub { $object->data($data); },
        qr/\QUnable to set sector data: Invalid length of data\E/,
        'update sector providing 257 bytes of scalar data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    $data[0x03] = chr 0x0100;
    my $data = join '', @data;
    throws_ok(
        sub { $object->data($data); },
        qr/\QUnable to set sector data: Invalid byte value at offset 3 ("\x{100}")\E/,
        'update sector providing illegal wide character amongst 256 bytes of scalar data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->data([]); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'set empty array reference sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = (chr 0x00);
    throws_ok(
        sub { $object->data(\@data); },
        qr/\QUnable to set sector data: Invalid length of data\E/,
        'update sector given arrayref with 1 byte of data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = (chr (0x00), chr (0x00));
    throws_ok(
        sub { $object->data(\@data); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'update sector given arrayref with 2 bytes of data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = (chr (0x00), chr (0x00));
    throws_ok(
        sub { $object->data(@data); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'update sector given array with 2 bytes of data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    $data[0x04] = [];
    throws_ok(
        sub { $object->data(\@data); },
        qr/\QUnable to set sector data: Invalid data type at offset 4 (ARRAY)\E/,
        'update sector given arrayref of 256 byte values with a non-scalar variable amongst them for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    $data[0x04] = [];
    throws_ok(
        sub { $object->data(@data); },
        qr/\QUnable to set sector data: Invalid data type at offset 4 (ARRAY)\E/,
        'update sector given array of 256 byte values with a non-scalar variable amongst them for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    $data[0x05] = chr 0x0100;
    throws_ok(
        sub { $object->data(\@data); },
        qr/\QUnable to set sector data: Invalid byte value at offset 5 ("\x{100}")\E/,
        'update sector given arrayref of 256 byte values with an illegal wide character amongst them for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    $data[0x05] = chr 0x0100;
    throws_ok(
        sub { $object->data(@data); },
        qr/\QUnable to set sector data: Invalid byte value at offset 5 ("\x{100}")\E/,
        'update sector given array of 256 byte values with an illegal wide character amongst them for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    pop @data;
    throws_ok(
        sub { $object->data(\@data); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'update sector given arrayref with 255 bytes of data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    pop @data;
    throws_ok(
        sub { $object->data(@data); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'update sector given array with 255 bytes of data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    push @data, chr 0x00;
    throws_ok(
        sub { $object->data(\@data); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'update sector given arrayref with 257 bytes of data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_chained_sector_data();
    push @data, chr 0x00;
    throws_ok(
        sub { $object->data(@data); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'update sector given array with 257 bytes of data for a chained sector object',
    );
}
########################################
{
    my $object = $class->new();
    my @data = get_chained_sector_data();
    $object->data(@data);
    ok(!$object->empty(), 'when chained sector data is set for an empty sector object, it is no longer empty');
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    $object->data(@data);
    ok($object->empty(), 'when empty sector data is set for a chained sector object, it becomes empty then');
}
########################################
{
    my $object = $class->new();
    my @data = get_chained_sector_data();
    my $data = join '', @data;
    $object->data($data);
    is($object->data(), $data, 'update empty sector object providing 256 bytes of scalar data');
}
########################################
{
    my $object = $class->new();
    my @expected_data = get_chained_sector_data();
    $object->data(\@expected_data);
    my @data = $object->data();
    cmp_deeply(\@data, \@expected_data, 'update empty sector object given arrayref with 256 bytes of data');
}
########################################
{
    my $object = $class->new();
    my @expected_data = get_chained_sector_data();
    $object->data(@expected_data);
    my @data = $object->data();
    cmp_deeply(\@data, \@expected_data, 'update empty sector object given array with 256 bytes of data');
}
########################################
{
    my $object = get_chained_sector_object();
    my @data = get_last_sector_data();
    my $data = join '', @data;
    $object->data($data);
    is($object->data(), $data, 'update chained sector object providing 256 bytes of scalar data');
}
########################################
{
    my $object = get_chained_sector_object();
    my @expected_data = get_last_sector_data();
    $object->data(\@expected_data);
    my @data = $object->data();
    cmp_deeply(\@data, \@expected_data, 'update chained sector object given arrayref with 256 bytes of data');
}
########################################
{
    my $object = get_chained_sector_object();
    my @expected_data = get_last_sector_data();
    $object->data(@expected_data);
    my @data = $object->data();
    cmp_deeply(\@data, \@expected_data, 'update chained sector object given array with 256 bytes of data');
}
########################################
{
    my $object = get_last_sector_object();
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    my $data = join '', @data;
    $object->data($data);
    is($object->data(), $data, 'update last sector object providing 256 bytes of scalar data');
}
########################################
{
    my $object = get_last_sector_object();
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size);
    $object->data(\@expected_data);
    my @data = $object->data();
    cmp_deeply(\@data, \@expected_data, 'update last sector object given arrayref with 256 bytes of data');
}
########################################
{
    my $object = get_last_sector_object();
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size);
    $object->data(@expected_data);
    my @data = $object->data();
    cmp_deeply(\@data, \@expected_data, 'update last sector object given array with 256 bytes of data');
}
########################################
