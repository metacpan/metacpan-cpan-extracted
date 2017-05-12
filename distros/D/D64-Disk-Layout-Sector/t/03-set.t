########################################
use strict;
use warnings;
use IO::Scalar;
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
    my $track = 0x10;
    $object->track($track);
    is($object->track(), $track, 'set new track location of sector data for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $track = 0x14;
    $object->track($track);
    is($object->track(), $track, 'set new track location of sector data for a chained sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->track(0x0100); },
        qr/\QInvalid value (256) of track location of sector data (single byte expected)\E/,
        'set non-byte track location of sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->track('0x14'); },
        qr/\QInvalid value ('0x14') of track location of sector data (single byte expected)\E/,
        'set non-numeric track location of sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->track([0x14]); },
        qr/\QInvalid type ([20]) of track location of sector data (single byte expected)\E/,
        'set non-scalar track location of sector data for a chained sector object',
    );
}
########################################
{
    my $object = $class->new();
    my $sector = 0x07;
    $object->sector($sector);
    is($object->sector(), $sector, 'set new sector location of sector data for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $sector = 0x01;
    $object->sector($sector);
    is($object->sector(), $sector, 'set new sector location of sector data for a chained sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->sector(0x0100); },
        qr/\QInvalid value (256) of sector location of sector data (single byte expected)\E/,
        'set non-byte sector location of sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->sector('0x14'); },
        qr/\QInvalid value ('0x14') of sector location of sector data (single byte expected)\E/,
        'set non-numeric sector location of sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->sector([0x14]); },
        qr/\QInvalid type ([20]) of sector location of sector data (single byte expected)\E/,
        'set non-scalar sector location of sector data for a chained sector object',
    );
}
########################################
{
    my $object = $class->new();
    $object->empty(1);
    is($object->empty(), 1, 'set empty flag for an empty sector object');
}
########################################
{
    my $object = $class->new();
    $object->empty(666);
    is($object->empty(), 1, 'set empty flag integer value for an empty sector object');
}
########################################
{
    my $object = $class->new();
    $object->empty(0);
    is($object->empty(), 0, 'clear empty flag for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    $object->empty(1);
    is($object->empty(), 1, 'set empty flag for a chained sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    $object->empty(666);
    is($object->empty(), 1, 'set empty flag integer value for a chained sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    $object->empty(0);
    is($object->empty(), 0, 'clear empty flag for a chained sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->empty([0]); },
        qr/Invalid "empty" flag/,
        'set invalid empty flag for a chained sector object',
    );
}
########################################
{
    my $object = $class->new();
    my $alloc_size = 0x10;
    $object->alloc_size($alloc_size);
    my $test1 = $object->alloc_size() == $alloc_size;
    my $test2 = $object->is_last_in_chain();
    ok($test1 && $test2, 'set new index value of the last allocated byte within the sector data for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $alloc_size = 0x20;
    $object->alloc_size($alloc_size);
    my $test1 = $object->alloc_size() == $alloc_size;
    my $test2 = $object->is_last_in_chain();
    ok($test1 && $test2, 'set new index value of the last allocated byte within the sector data for a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my $alloc_size = 0x30;
    $object->alloc_size($alloc_size);
    my $test1 = $object->alloc_size() == $alloc_size;
    my $test2 = $object->is_last_in_chain();
    ok($test1 && $test2, 'set new index value of the last allocated byte within the sector data for a last sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->alloc_size(0x0100); },
        qr/\QInvalid index value (256) of the last allocated byte within the sector data (single byte expected)\E/,
        'set non-byte index value of the last allocated byte within the sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->alloc_size('0x40'); },
        qr/\QInvalid index value ('0x40') of the last allocated byte within the sector data (single byte expected)\E/,
        'set non-numeric index value of the last allocated byte within the sector data for a chained sector object',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->alloc_size([0x50]); },
        qr/\QInvalid index type ([80]) of the last allocated byte within the sector data (single byte expected)\E/,
        'set non-scalar index value of the last allocated byte within the sector data for a chained sector object',
    );
}
########################################
{
    my $object = $class->new();
    my $track = 0x11;
    my $sector = 0x07;
    $object->ts_link($track, $sector);
    my $test1 = ($object->ts_link)[0] == $track;
    my $test2 = ($object->ts_link)[1] == $sector;
    my $test3 = $object->is_valid_ts_link();
    ok($test1 && $test2 && $test3, 'set new track and sector link values to the next chunk of data in a chain for an empty sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    my $track = 0x10;
    my $sector = 0x09;
    $object->ts_link($track, $sector);
    my $test1 = ($object->ts_link)[0] == $track;
    my $test2 = ($object->ts_link)[1] == $sector;
    my $test3 = $object->is_valid_ts_link();
    ok($test1 && $test2 && $test3, 'set new track and sector link values to the next chunk of data in a chain for a chained sector object');
}
########################################
{
    my $object = get_last_sector_object();
    my $track = 0x15;
    my $sector = 0x01;
    $object->ts_link($track, $sector);
    my $test1 = ($object->ts_link)[0] == $track;
    my $test2 = ($object->ts_link)[1] == $sector;
    my $test3 = $object->is_valid_ts_link();
    ok($test1 && $test2 && $test3, 'set new track and sector link values to the next chunk of data in a chain for a last sector object');
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link(undef, 0x02); },
        qr/\QUndefined value of track location for the next chunk of data in a chain (single byte expected)\E/,
        'set undefined track value for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link(0x13, undef); },
        qr/\QUndefined value of sector location for the next chunk of data in a chain (single byte expected)\E/,
        'set undefined sector value for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link(0x00, 0x09); },
        qr/\QIllegal value (0) of track location for the next chunk of data in a chain (track 0 does not exist)\E/,
        'set track 0 for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link(0x0100, 0x09); },
        qr/\QInvalid value (256) of track location for the next chunk of data in a chain (single byte expected)\E/,
        'set non-byte track value for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link(0x10, 0x0100); },
        qr/\QInvalid value (256) of sector location for the next chunk of data in a chain (single byte expected)\E/,
        'set non-byte sector value for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link('0x10', 0x09); },
        qr/\QInvalid value ('0x10') of track location for the next chunk of data in a chain (single byte expected)\E/,
        'set non-numeric track value for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link(0x10, '0x09'); },
        qr/\QInvalid value ('0x09') of sector location for the next chunk of data in a chain (single byte expected)\E/,
        'set non-numeric scalar value for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link([0x10], 0x09); },
        qr/\QInvalid type ([16]) of track location for the next chunk of data in a chain (single byte expected)\E/,
        'set non-scalar track value for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    throws_ok(
        sub { $object->ts_link(0x10, [0x09]); },
        qr/\QInvalid type ([9]) of sector location for the next chunk of data in a chain (single byte expected)\E/,
        'set non-scalar sector value for the next chunk of data in a chain',
    );
}
########################################
{
    my $object = get_chained_sector_object();
    $object->clean();
    my $data = chr (0x00) x $sector_data_size;
    my $test1 = $object->data() eq $data;
    my $test2 = $object->track() == 0x00;
    my $test3 = $object->sector() == 0x00;
    my $test4 = $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'wipe out an entire sector data, and mark it as empty');
}
########################################
