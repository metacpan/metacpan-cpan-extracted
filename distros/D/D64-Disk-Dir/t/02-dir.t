#########################
use strict;
use warnings;
use Capture::Tiny qw(capture_stdout);
use IO::Scalar;
use Test::More tests => 11;
use D64::Disk::Image qw(:all);
#########################
{
BEGIN { use_ok('D64::Disk::Dir', qw(:all)) };
}
#########################
# Helper subroutine to create image and populate it with files for directory access method test cases:
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
    return ($d64, $d64DiskDirObj, $filename);
}
#########################
# Helper subroutine to free image for directory access method test cases:
sub free_test_image {
    my ($d64, $filename) = @_;
    $d64->free_image();
    unlink($filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
is(ref $d64DiskDirObj, 'D64::Disk::Dir', 'new - creating new object and loading disk directory from file on disk');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $readOK = $d64DiskDirObj->read_dir($filename);
cmp_ok($readOK, '==', 1, 'read_dir - replacing currently loaded disk directory with new image file');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $fh = new IO::Scalar;
$d64DiskDirObj->print_dir($fh);
my $directory_content = ${$fh->sref};
like($directory_content, qr/"1".*"2".*."3".*661/s, 'print_dir - printing out the entire directory content to opened handle');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $directory_content = capture_stdout { $d64DiskDirObj->print_dir(); };
like($directory_content, qr/"1".*"2".*."3".*661/s, 'print_dir - printing out the entire directory content to standard output');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $title = $d64DiskDirObj->get_title(1);
is($title, ' DJGRUBY/OXYRON ', 'get_title - get disk directory title converted to ASCII string');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $id = $d64DiskDirObj->get_id(1);
is($id, '10', 'get_id - get disk directory ID converted to ASCII string');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $blocksFree = $d64DiskDirObj->get_blocks_free();
cmp_ok($blocksFree, '==', 661, 'get_blocks_free - get number of blocks free in a disk directory');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $num_entries = $d64DiskDirObj->num_entries();
cmp_ok($num_entries, '==', 3, 'num_entries - get number of directory entries in a disk directory');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $entryObj = $d64DiskDirObj->get_entry(0);
is(ref $entryObj, 'D64::Disk::Dir::Entry', 'num_entries - get directory entry at the specified position');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $data = $d64DiskDirObj->get_file_data(2);
my @data = map { chr ord $_ } split '', $data;
$data = join '', @data[0..2];
is($data, 'xyz', 'get_file_data - get binary file data from a directory entry');
free_test_image($d64, $filename);
}
#########################
