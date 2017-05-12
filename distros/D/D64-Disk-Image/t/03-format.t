#########################
use Test::More tests => 10;
#########################
{
BEGIN { use_ok('D64::Disk::Image', qw(:all)) };
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$rawid = $d64->rawname_from_name('10');
$numstatus = $d64->format($rawname, $rawid);
($numstatus, $status) = $d64->status();
is($status, '00,ok,00,00', 'format - status of formatting disk with full data erasure');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$numstatus = $d64->format($rawname);
($numstatus, $status) = $d64->status();
is($status, '00,ok,00,00', 'format - status of formatting disk without full data erasure');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$rawid = $d64->rawname_from_name('10');
$numstatus = $d64->format($rawname, $rawid);
($title, $id) = $d64->title();
$title = $d64->name_from_rawname($title);
$id =~ s/\xa0/\x20/;
is("${title}${id}", ' djgruby/oxyron 10 2A', 'title - title and id of fully formatted disk');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$numstatus = $d64->format($rawname);
$track_blocks_free = $d64->track_blocks_free(1);
cmp_ok($track_blocks_free, '==', 21, 'track_blocks_free - track blocks free amount after disk format');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$numstatus = $d64->format($rawname);
$d64->alloc_ts(1, 1);
$track_blocks_free = $d64->track_blocks_free(1);
cmp_ok($track_blocks_free, '==', 20, 'track_blocks_free - track blocks free amount after sector allocation');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$numstatus = $d64->format($rawname);
$d64->alloc_ts(1, 1);
$d64->free_ts(1, 1);
$track_blocks_free = $d64->track_blocks_free(1);
cmp_ok($track_blocks_free, '==', 21, 'track_blocks_free - track blocks free amount after sector deallocation');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$numstatus = $d64->format($rawname);
$is_ts_free = $d64->is_ts_free(1, 1);
cmp_ok($is_ts_free, '==', 1, 'is_ts_free - is track/sector free after disk format');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$numstatus = $d64->format($rawname);
$d64->alloc_ts(1, 1);
$is_ts_free = $d64->is_ts_free(1, 1);
cmp_ok($is_ts_free, '==', 0, 'is_ts_free - is track/sector free after sector allocation');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$numstatus = $d64->format($rawname);
$d64->alloc_ts(1, 1);
$d64->free_ts(1, 1);
$is_ts_free = $d64->is_ts_free(1, 1);
cmp_ok($is_ts_free, '==', 1, 'is_ts_free - is track/sector free after sector deallocation');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
