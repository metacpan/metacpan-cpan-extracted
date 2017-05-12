########################################
use strict;
use warnings;
use IO::Scalar;
use Test::Deep;
use Test::More tests => 31;
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
    my $track = $object->track();
    is($track, 0x00, 'get track location of sector data from an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $track = $object->track();
    is($track, 0x11, 'get track location of sector data from a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my $track = $object->track();
    is($track, 0x13, 'get track location of sector data from a last sector object');
}
########################################
{
    my $object = $class->new();
    my $sector = $object->sector();
    is($sector, 0x00, 'get sector location of sector data from an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $sector = $object->sector();
    is($sector, 0x03, 'get sector location of sector data from a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my $sector = $object->sector();
    is($sector, 0x01, 'get sector location of sector data from a last sector object');
}
########################################
{
    my $object = $class->new();
    my $is_empty = $object->empty();
    ok($is_empty, 'check if empty flag check for an empty sector object yields true');
}
########################################
{
    my $object = get_chained_sector_object();
    my $is_empty = $object->empty();
    ok(!$is_empty, 'check if empty flag check for a chained sector object yields true');
}
########################################
{
    my $object = get_last_sector_object();
    my $is_empty = $object->empty();
    ok(!$is_empty, 'check if empty flag check for a last sector object yields true');
}
########################################
{
    my $object = $class->new();
    my $is_valid_ts_link = $object->is_valid_ts_link();
    is($is_valid_ts_link, 0, 'check if first two bytes of data for an empty sector object point to the next chunk of data in a chain');
}
########################################
{
    my $object = get_chained_sector_object();
    my $is_valid_ts_link = $object->is_valid_ts_link();
    is($is_valid_ts_link, 1, 'check if first two bytes of data for a chained sector object point to the next chunk of data in a chain');
}
########################################
{
    my $object = get_last_sector_object();
    my $is_valid_ts_link = $object->is_valid_ts_link();
    is($is_valid_ts_link, 0, 'check if first two bytes of data for a last sector object point to the next chunk of data in a chain');
}
########################################
{
    my $object = $class->new();
    my $alloc_size = $object->alloc_size();
    is($alloc_size, 0x00, 'get index of the last allocated byte within the sector data for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $alloc_size = $object->alloc_size();
    is($alloc_size, 0xff, 'get index of the last allocated byte within the sector data for a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my $alloc_size = $object->alloc_size();
    is($alloc_size, 0x04, 'get index of the last allocated byte within the sector data for a last sector object');
}
########################################
{
    my $object = $class->new();
    my $is_last_in_chain = $object->is_last_in_chain();
    ok($is_last_in_chain, 'check if first two bytes of data indicate index of the last allocated byte for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $is_last_in_chain = $object->is_last_in_chain();
    ok(!$is_last_in_chain, 'check if first two bytes of data indicate index of the last allocated byte for a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my $is_last_in_chain = $object->is_last_in_chain();
    ok($is_last_in_chain, 'check if first two bytes of data indicate index of the last allocated byte for a last sector object');
}
########################################
{
    my $object = $class->new();
    my ($track, $sector) = $object->ts_link();
    ok(!defined $track && !defined $sector, 'get track and sector link values to the next chunk of data in a chain for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my ($track, $sector) = $object->ts_link();
    ok(defined $track && $track == 0x11 && defined $sector && $sector == 0x06, 'get track and sector link values to the next chunk of data in a chain for a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my ($track, $sector) = $object->ts_link();
    ok(!defined $track && !defined $sector, 'get track and sector link values to the next chunk of data in a chain for a last sector object');
}
########################################
{
    my $object = $class->new();
    my ($track, $sector) = $object->ts_pointer();
    ok(!defined $track && !defined $sector, 'get track and sector pointer values to the next chunk of data in a chain for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my ($track, $sector) = $object->ts_pointer();
    ok(defined $track && $track == 0x11 && defined $sector && $sector == 0x06, 'get track and sector pointer values to the next chunk of data in a chain for a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my ($track, $sector) = $object->ts_pointer();
    ok(!defined $track && !defined $sector, 'get track and sector pointer values to the next chunk of data in a chain for a last sector object');
}
########################################
{
    my $object = $class->new();
    is($object->file_data(), '', 'get default file data from an empty sector object as an empty scalar');
}
########################################
{
    my $object = get_chained_sector_object();
    my @file_data = get_chained_sector_data();
    splice @file_data, 0, 2;
    my $file_data = join '', @file_data;
    is($object->file_data(), $file_data, 'get default file data as a scalar of 256 bytes from a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my @file_data = get_last_sector_data();
    splice @file_data, 0, 2;
    splice @file_data, 3;
    my $file_data = join '', @file_data;
    is($object->file_data(), $file_data, 'get default file data as a scalar of 256 bytes from a last sector object');
}
########################################
{
    my $object = $class->new();
    my @file_data = $object->file_data();
    my @expected_file_data = ();
    cmp_deeply(\@file_data, \@expected_file_data, 'get default file data from an empty sector object as an empty array');
}
########################################
{
    my $object = get_chained_sector_object();
    my @file_data = $object->file_data();
    my @expected_file_data = get_chained_sector_data();
    splice @expected_file_data, 0, 2;
    cmp_deeply(\@file_data, \@expected_file_data, 'get default file data as an array of 256 bytes from a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my @file_data = $object->file_data();
    my @expected_file_data = get_last_sector_data();
    splice @expected_file_data, 0, 2;
    splice @expected_file_data, 3;
    cmp_deeply(\@file_data, \@expected_file_data, 'get default file data as an array of 256 bytes from a last sector object');
}
########################################
