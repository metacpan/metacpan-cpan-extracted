#########################
use D64::Disk::Layout;
use Test::Deep;
use Test::More tests => 4;
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $sectorObj = $d64DiskLayoutObj->sector(track => 1, sector => 0);
is(ref $sectorObj, 'D64::Disk::Layout::Sector', 'sector - retrieve disk sector object from a D64 disk layout');
my @data = $sectorObj->data();
my @expected_data = map { chr 0x00 } (0x01 .. $D64::Disk::Layout::bytes_per_sector);
cmp_deeply(\@data, \@expected_data, 'sector - fetch sector data as an array of 256 bytes');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $sectorObj = $d64DiskLayoutObj->sector(track => 1, sector => 0);
$sectorObj->ts_link(0x11, 0x08);
$d64DiskLayoutObj->sector(data => $sectorObj);
my @sector_data = $d64DiskLayoutObj->sector_data(1, 0);
my $sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$11$08' . '$00' x 254, 'sector - insert new data into specific disk layout sector');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $sectorObj = $d64DiskLayoutObj->sector(track => 1, sector => 0);
$sectorObj->ts_link(0x11, 0x08);
$d64DiskLayoutObj->sector(data => $sectorObj, track => 35, sector => 16);
my @sector_data = ($d64DiskLayoutObj->sector_data(1, 0), $d64DiskLayoutObj->sector_data(35, 16));
my $sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$00' x 256 . '$11$08' . '$00' x 254, 'sector - insert new data into specific track/sector location');
}
#########################
