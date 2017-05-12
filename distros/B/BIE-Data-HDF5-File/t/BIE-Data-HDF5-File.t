# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BIE-Data-HDF5-File.t'

#########################

use strict;
use warnings;
use Test::More;
use v5.10;

BEGIN { use_ok('BIE::Data::HDF5::File') };
BEGIN { use_ok('BIE::Data::HDF5::Path') };

#get a nonexist file
my $digit = 1;
my $dataFile = 'tmp' . $digit . '.h5';
while (-e $dataFile) {
  $dataFile = 'tmp' . ($digit++) . '.h5';
}

my $h5 = BIE::Data::HDF5::File->new(h5File => $dataFile);
ok($h5->fileID >= 0, "H5 File created and opened");
ok($h5->locID >= 0, "Got location ID");
ok($h5->loc eq '/', "At root");

my $p = $h5->pwd;
ok($p->id >= 0, "Got root");
my $pathName1 = 'p1/subp1/subsubp1';
my $pathName2 = 'p2/subp2/subsubp2';
$p->mkPath($pathName1);
$p->mkPath($pathName2);

my $p1 = $h5->cd('p1');
ok($p1->name eq '/p1', "Got p1");
my $subp1 = $p1->cd('subp1');
ok($subp1->name eq '/p1/subp1', "Got subp1");

unlink($dataFile);
done_testing;
