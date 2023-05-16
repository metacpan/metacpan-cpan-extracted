#########################
use strict;
use warnings;
use Capture::Tiny qw(capture_stdout capture_stderr);
use D64::Disk::BAM;
use D64::Disk::Image qw(:all);
use D64::Disk::Layout::Sector;
use D64::Disk::Layout;
use Data::Dumper;
use File::Slurp;
use File::Temp qw(tmpnam);
use IO::Scalar;
use Test::More tests => 15;
#########################
{
BEGIN { use_ok('D64::Disk::Dir', qw(:all)) };
}
#########################
# Helper subroutine to create image and populate it with files for directory access method test cases:
sub create_test_image {
    my $filename = tmpnam() . '.d64';
    my $d64 = D64::Disk::Image->create_image($filename, D64);
    my $rawname = $d64->rawname_from_name('dj gruby / triad');
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
my $directory_content = capture_stdout { $d64DiskDirObj->print_dir(undef, { verbose => 1 }); };
like($directory_content, qr/"1".*1 10 \$6261.*"2".*1 11 \$6261.*."3".*1 12 \$7978.*661/s, 'print_dir - verbosely printing out the entire directory content to standard output');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
# Create the "splat" (non-closed) file in the raw D64 disk image data:
{
  $d64->free_image();
  # Read disk image layout from the current test file:
  my $d64_layout = D64::Disk::Layout->new($filename);

  # Block Availability Map (BAM) track:
  my $BAM_TRACK = 18;
  # Block Availability Map (BAM) sector:
  my $BAM_SECTOR = 0;
  # Get BAM sector object from a D64 disk layout:
  my $sector_layout = $d64_layout->sector(track => $BAM_TRACK, sector => $BAM_SECTOR);
  # Read BAM sector data:
  my $sector_data = $sector_layout->data();
  # Create new BAM object based on the BAM sector data retrieved from a D64 disk image file:
  my $diskBAM = D64::Disk::BAM->new($sector_data);

  # Get directory entry at the index 0:
  my $entryObj = $d64DiskDirObj->get_entry(0);
  # Get the initial track/sector of the file:
  my $track = $entryObj->get_track();
  my $sector = $entryObj->get_sector();
  # Collect all subsequent track/sector links:
  my @ts_links = ([ $track, $sector ]);
  while (1) {
    # Get disk sector object from a D64 disk layout:
    my $sector_layout = $d64_layout->sector(track => $track, sector => $sector);
    # Check if first two bytes of data indicate index of the last allocated byte:
    last if $sector_layout->is_last_in_chain();
    # Get track and sector link values to the next chunk of data in a chain:
    ($track, $sector) = $sector_layout->ts_link();
    push @ts_links, [ $track, $sector ];
  }
  # Deallocate all track/sector pairs:
  for my $ts_link (@ts_links) {
    # Set specific sector to deallocated:
    my ($track, $sector) = @{$ts_link};
    $diskBAM->sector_free($track, $sector, 1);
  }

  # Get the BAM sector data:
  $sector_data = $diskBAM->get_bam_data();
  # Update BAM sector providing 256 bytes of scalar data:
  $sector_layout->data($sector_data);
  # Put new data into specific disk layout sector:
  $d64_layout->sector(data => $sector_layout);

  # Fetch disk layout data as a scalar of 683 * 256 bytes:
  my $data = $d64_layout->data();
  # Write raw bytes with an updated BAM sector data back into a D64 disk image file:
  write_file($filename, { binmode => ':raw' }, $data);

  # Reload D64 disk directory object from file:
  $d64 = D64::Disk::Image->load_image($filename, D64);
  $d64DiskDirObj = D64::Disk::Dir->new($filename);

  # Get directory entry at the index 0:
  $entryObj = $d64DiskDirObj->get_entry(0);
  # Mark file as non-closed:
  $entryObj->set_closed(0);
}
my $fh = new IO::Scalar;
my $directory_content = capture_stdout { $d64DiskDirObj->print_dir(undef, { verbose => 1 }); };
like($directory_content, qr/\*prg\s{3}1\s10$ .* 662\sblocks\sfree/xms, 'print_dir - do not attempt to read loading address of a non-closed file');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $title = $d64DiskDirObj->get_title(1);
is($title, 'DJ GRUBY / TRIAD', 'get_title - get disk directory title converted to ASCII string');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
my $id = $d64DiskDirObj->get_id(1);
is($id, '10 2a', 'get_id - get disk directory ID converted to ASCII string');
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
is(ref $entryObj, 'D64::Disk::Dir::Entry', 'get_entry - get directory entry at the specified position');
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
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
# Set the initial track link to $00:
{
  # Get directory entry at the index 0:
  my $entryObj = $d64DiskDirObj->get_entry(0);
  # Set the initial track of the file:
  $entryObj->set_track(0x00);
}
my $file_content = capture_stderr { my $data = $d64DiskDirObj->get_file_data(0); };
like($file_content, qr/Unable to get file data from an illegal track/, 'get_file_data - get binary file data from a directory entry with an illegal initial track');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $d64DiskDirObj, $filename) = create_test_image();
# Set the initial sector link to $ff:
{
  # Get directory entry at the index 0:
  my $entryObj = $d64DiskDirObj->get_entry(0);
  # Set the initial sector of the file:
  $entryObj->set_sector(0xff);
}
my $file_content = capture_stderr { my $data = $d64DiskDirObj->get_file_data(0); };
like($file_content, qr/Unable to get file data from an illegal sector/, 'get_file_data - get binary file data from a directory entry with an illegal initial sector');
free_test_image($d64, $filename);
}
#########################
