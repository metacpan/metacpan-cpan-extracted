#########################
use strict;
use warnings;
use Test::More tests => 3;
use D64::Disk::Dir;
use D64::Disk::Image qw(:all);
#########################
{
BEGIN { use_ok('D64::Disk::Dir::Iterator', qw(:all)) };
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
    my $iter = D64::Disk::Dir::Iterator->new($d64DiskDirObj);
    return ($d64, $iter, $filename);
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
my ($d64, $i, $filename) = create_test_image();
my $filetypes;
while (my $entry = $i->getNext()) {
    $filetypes .= $entry->get_type();
}
is($filetypes, 'prgprgprg', 'getNext - Perlish style iterator');
free_test_image($d64, $filename);
}
#########################
{
my ($d64, $i, $filename) = create_test_image();
my $filesizes;
for (my $iter = $i; $iter->hasNext(); $iter->next()) {
    my $entry = $iter->current();
    $filesizes .= $entry->get_size();
}
is($filesizes, '111', 'hasNext/next/current - C++-ish style iterator');
free_test_image($d64, $filename);
}
#########################
