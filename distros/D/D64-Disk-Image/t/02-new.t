#########################
use Test::More tests => 7;
#########################
{
BEGIN { use_ok('D64::Disk::Image', qw(:all)) };
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
is(ref $d64, 'D64::Disk::Image', 'create_image - verifying type of new D64::Disk::Image object');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$name = join '', reverse split '', 'abcdefghijklmnopqrstuvwxyz';
$rawname = $d64->rawname_from_name($name);
is($rawname, 'zyxwvutsrqponmlk', 'create_image - creating new empty D64 disk image file');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
my ($numstatus, $status) = $d64->status();
is($status, '73,cbm dos v2.6 1541,00,00', 'status - verifying status of created disk image');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$d64->sync();
is(-e '__temp__.d64', 1, 'sync - verifying that D64 file is created after syncing image');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$d64->free_image();
is(-e '__temp__.d64', 1, 'free_image - verifying that D64 file is created after freeing image');
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name('-djgruby/oxyron-');
$rawid = $d64->rawname_from_name('10');
$d64->format($rawname, $rawid);
$d64->free_image();
$newd64 = D64::Disk::Image->load_image('__temp__.d64');
($title, $id) = $newd64->title();
$title = $newd64->name_from_rawname($title);
$id = $newd64->name_from_rawname($id);
is("${title}${id}", '-djgruby/oxyron-10', 'load_image - opening existing D64 disk image file');
$newd64->free_image();
unlink('__temp__.d64');
}
#########################
