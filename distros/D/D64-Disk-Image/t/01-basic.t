#########################
use Test::More tests => 14;
#########################
{
BEGIN { use_ok('D64::Disk::Image', qw(:all)) };
}
#########################
{
$rawname = D64::Disk::Image->rawname_from_name('abcdefghijklmnopqrstuvwxyz');
is($rawname, 'abcdefghijklmnop', 'rawname_from_name - converting name consisting of 26 bytes');
}
#########################
{
$rawname = D64::Disk::Image->rawname_from_name('ABCDEF');
$rawname = join '', map { ord $_ == 0xA0 ? chr 0x20 : $_ } split '', $rawname;
is($rawname, 'ABCDEF          ', 'rawname_from_name - converting name consisting of 6 bytes');
}
#########################
{
$name = D64::Disk::Image->name_from_rawname('abcdefghijklmnop');
is($name, 'abcdefghijklmnop', 'name_from_rawname - converting rawname consisting of 16 bytes');
}
#########################
{
$rawname = 'ABCDEF' . chr (0xA0) x 10;
$name = D64::Disk::Image->name_from_rawname($rawname);
is($name, 'ABCDEF', 'name_from_rawname - converting rawname consisting of 6 bytes');
}
#########################
{
$tracks = D64::Disk::Image->tracks(D64);
cmp_ok($tracks, '==', 35, 'tracks - retrieving number of tracks for D64 disk image file');
}
#########################
{
$tracks = D64::Disk::Image->tracks(D71);
cmp_ok($tracks, '==', 70, 'tracks - retrieving number of tracks for D71 disk image file');
}
#########################
{
$tracks = D64::Disk::Image->tracks(D81);
cmp_ok($tracks, '==', 80, 'tracks - retrieving number of tracks for D81 disk image file');
}
#########################
{
$sectors = D64::Disk::Image->sectors_per_track(D64, 1);
cmp_ok($sectors, '==', 21, 'sectors_per_track - retrieving number of sectors per D64 track 1');
}
#########################
{
$sectors = D64::Disk::Image->sectors_per_track(D64, 35);
cmp_ok($sectors, '==', 17, 'sectors_per_track - retrieving number of sectors per D64 track 35');
}
#########################
{
$sectors = D64::Disk::Image->sectors_per_track(D71, 1);
cmp_ok($sectors, '==', 21, 'sectors_per_track - retrieving number of sectors per D71 track 1');
}
#########################
{
$sectors = D64::Disk::Image->sectors_per_track(D71, 70);
cmp_ok($sectors, '==', 17, 'sectors_per_track - retrieving number of sectors per D71 track 70');
}
#########################
{
$sectors = D64::Disk::Image->sectors_per_track(D81, 1);
cmp_ok($sectors, '==', 40, 'sectors_per_track - retrieving number of sectors per D81 track 1');
}
#########################
{
$sectors = D64::Disk::Image->sectors_per_track(D81, 80);
cmp_ok($sectors, '==', 40, 'sectors_per_track - retrieving number of sectors per D81 track 80');
}
#########################
