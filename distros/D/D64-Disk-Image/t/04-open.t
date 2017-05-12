#########################
use Test::More tests => 14;
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
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
is(ref $prg, 'D64::Disk::Image::File', 'open - creating new image file object via disk image object');
$prg->close();
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$rawid = $d64->rawname_from_name('10');
$numstatus = $d64->format($rawname, $rawid);
$rawname = $d64->rawname_from_name('testfile');
$prg = D64::Disk::Image::File->new($d64, $rawname, T_PRG, F_WRITE);
is(ref $prg, 'D64::Disk::Image::File', 'open - creating new image file object directly via new method');
$prg->close();
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$rawid = $d64->rawname_from_name('10');
$numstatus = $d64->format($rawname, $rawid);
$rawname = $d64->rawname_from_name('testfile');
eval { $prg = $d64->open($rawname, T_PRG, F_READ); };
like($@, qr/^Failed to open image file 'testfile' in 'rb' mode/, 'open - catching error when opening inexisting file in READ mode');
$d64->free_image();
unlink('__temp__.d64');
}
#########################
{
$d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
$rawname = $d64->rawname_from_name(' djgruby/oxyron ');
$rawid = $d64->rawname_from_name('10');
$numstatus = $d64->format($rawname, $rawid);
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$prg->close();
$prg = $d64->open($rawname, T_PRG, F_READ);
is(ref $prg, 'D64::Disk::Image::File', 'open - opening existing (created) file in READ mode');
$prg->close();
$d64->free_image();
unlink('__temp__.d64');
}
#########################
# Helper subroutine to create image for read/write method test cases:
sub create_test_image {
    my $d64 = D64::Disk::Image->create_image('__temp__.d64', D64);
    my $rawname = $d64->rawname_from_name(' djgruby/oxyron ');
    my $rawid = $d64->rawname_from_name('10');
    my $numstatus = $d64->format($rawname, $rawid);
    return $d64;
}
#########################
# Helper subroutine to free image for read/write method test cases:
sub free_test_image {
    my $d64 = shift;
    $d64->free_image();
    unlink('__temp__.d64');
}
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr ord $_ } split '', '0123456789';
$counter = $prg->write($buffer, 20);
$prg->close();
cmp_ok($counter, '==', 20, 'write - too many bytes actually written to image file');
free_test_image($d64);
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr ord $_ } split '', '0123456789';
$counter = $prg->write($buffer, 5);
$prg->close();
cmp_ok($counter, '==', 5, 'write - too few bytes actually written to image file');
free_test_image($d64);
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr ord $_ } split '', '0123456789';
$counter = $prg->write($buffer);
$prg->close();
cmp_ok($counter, '==', 10, 'write - exact length of data written to image file');
free_test_image($d64);
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr $_ } split '', '1234567890';
$counter = $prg->write($buffer);
$prg->close();
$prg = $d64->open($rawname, T_PRG, F_READ);
($counter, $buffer) = $prg->read();
$prg->close();
cmp_ok($counter, '==', 254, 'write - reading length of image file written to disk image');
free_test_image($d64);
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr ord $_ } split '', '1234567890';
$counter = $prg->write($buffer);
$prg->close();
$prg = $d64->open($rawname, T_PRG, F_READ);
($counter, $buffer) = $prg->read();
$prg->close();
@buffer = map { chr ord $_ } split '', $buffer;
$buffer = join '', @buffer[0..9];
is($buffer, '1234567890', 'write - reading and verifying data written to image file');
free_test_image($d64);
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr ord $_ } split '', '1234567890';
$counter = $prg->write($buffer);
$prg->close();
$prg = $d64->open($rawname, T_PRG, F_READ);
($counter, $buffer) = $prg->read(5);
$prg->close();
@buffer = map { chr ord $_ } split '', $buffer;
$buffer = join '', @buffer;
is($buffer, '12345', 'read - reading too little data than actually written to image file');
free_test_image($d64);
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr ord $_ } split '', '1234567890';
$counter = $prg->write($buffer);
$prg->close();
$numstatus = $d64->delete($rawname, T_PRG);
eval { $prg = $d64->open($rawname, T_PRG, F_READ); };
like($@, qr/^Failed to open image file/, 'delete - removing existing file from disk image');
free_test_image($d64);
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr ord $_ } split '', '1234567890';
$counter = $prg->write($buffer);
$prg->close();
$newrawname = $d64->rawname_from_name('newtestfile');
$numstatus = $d64->rename($rawname, $newrawname, T_PRG);
eval { $prg = $d64->open($rawname, T_PRG, F_READ); };
like($@, qr/^Failed to open image file/, 'rename - renaming file and trying to open file with old name');
free_test_image($d64);
#########################
$d64 = create_test_image();
$rawname = $d64->rawname_from_name('testfile');
$prg = $d64->open($rawname, T_PRG, F_WRITE);
$buffer = join '', map { chr ord $_ } split '', '1234567890';
$counter = $prg->write($buffer);
$prg->close();
$newrawname = $d64->rawname_from_name('newtestfile');
$numstatus = $d64->rename($rawname, $newrawname, T_PRG);
eval { $prg = $d64->open($newrawname, T_PRG, F_READ); };
is($@, '', 'rename - renaming file and opening it with new name after that');
free_test_image($d64);
#########################
