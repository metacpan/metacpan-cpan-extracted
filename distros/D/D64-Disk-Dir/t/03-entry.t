#########################
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr capture_stdout);
use IO::Scalar;
use Test::More tests => 13;
use D64::Disk::Dir;
use D64::Disk::Image qw(:all);
#########################
{
BEGIN { use_ok('D64::Disk::Dir::Entry', qw(:all)) };
}
#########################
# Helper subroutine to create image and populate it with files for directory entry access method test cases:
sub create_test_image {
    my $filename = '__temp__.d64';
    my $d64 = D64::Disk::Image->create_image($filename, D64);
    my $rawname = $d64->rawname_from_name(' djgruby/oxyron ');
    my $rawid = $d64->rawname_from_name('10');
    my $numstatus = $d64->format($rawname, $rawid);
    # Write file named "1" with contents "abcde":
    my $rawname1 = $d64->rawname_from_name('1');
    my $prg1 = $d64->open($rawname1, T_PRG, F_WRITE);
    my $buffer1 = join '', map { chr ord $_ } split '', 'abcde';
    my $counter1 = $prg1->write($buffer1);
    $prg1->close();
    # Write file named "2" with contents "abcdefghij":
    my $rawname2 = $d64->rawname_from_name('2');
    my $prg2 = $d64->open($rawname2, T_PRG, F_WRITE);
    my $buffer2 = join '', map { chr ord $_ } split '', 'abcdefghij';
    my $counter2 = $prg2->write($buffer2);
    $prg2->close();
    # Write file named "3" with contents "xyz":
    my $rawname3 = $d64->rawname_from_name('3');
    my $prg3 = $d64->open($rawname3, T_PRG, F_WRITE);
    my $buffer3 = join '', map { chr ord $_ } split '', 'xyz';
    my $counter3 = $prg3->write($buffer3);
    $prg3->close();
    $d64->free_image();
    $d64 = D64::Disk::Image->load_image($filename, D64);
    my $d64DiskDirObj = D64::Disk::Dir->new($filename);
    my $entryObj = $d64DiskDirObj->get_entry(0);
    return ($d64, $entryObj, $filename);
}
#########################
# Helper subroutine to free image for directory entry access method test cases:
sub free_test_image {
    my ($d64, $filename) = @_;
    $d64->free_image();
    unlink($filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $bytes = join '', map { chr ord $_; } split //, $entryObj->get_bytes();
my $newEntryObj = D64::Disk::Dir::Entry->new($bytes);
is(ref $newEntryObj, 'D64::Disk::Dir::Entry', 'new - creating new directory entry object and initializing it');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $bytes = join '', map { sprintf "%02x", ord $_; } split //, $entryObj->get_bytes();
is($bytes, '82010a31a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000000100', 'get_bytes - getting 30 bytes of data describing directory entry on disk');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $type = $entryObj->get_type();
is($type, 'prg', 'get_type - getting the actual filetype');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $closed = $entryObj->get_closed();
cmp_ok($closed, '==', 1, 'get_closed - getting "Closed" flag');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $locked = $entryObj->get_locked();
cmp_ok($locked, '==', 0, 'get_locked - getting "Locked" flag');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $track = $entryObj->get_track();
like($track, qr/^\d+$/, 'get_track - getting track location of first sector of file');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $sector = $entryObj->get_sector();
like($sector, qr/^\d+$/, 'get_sector - getting sector location of first sector of file');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $convert2ascii = 1;
my $name = $entryObj->get_name($convert2ascii);
is($name, '1', 'get_name - getting filename converted to ASCII string');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $warning_message = capture_stderr { $entryObj->get_side_track(); };
like($warning_message, qr/not a REL file/, 'get_side_track - getting first side-sector block for non-relative file');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $size = $entryObj->get_size();
cmp_ok($size, '==', 1, 'get_size - getting file size in sectors');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $fh = new IO::Scalar;
$entryObj->print_entry($fh);
my $entry_content = ${$fh->sref};
like($entry_content, qr/^1.*"1".*prg.*$/, 'print_entry - printing out directory entry details to opened handle');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $entryObj, $filename) = create_test_image();
my $entry_content = capture_stdout { $entryObj->print_entry(); };
like($entry_content, qr/^1.*"1".*prg.*$/, 'print_entry - printing out directory entry details to standard output');
free_test_image($d64, $filename);
}
#########################
