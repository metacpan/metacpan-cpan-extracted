# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 25;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

my $yml = "objects.yml";
my $fs = Cv->OpenFileStorage($yml, CV_STORAGE_WRITE);

my %TYPENAME = (
	'Cv::Mat'       => CV_TYPE_NAME_MAT,
	'Cv::Image'     => CV_TYPE_NAME_IMAGE,
	'Cv::MatND'     => CV_TYPE_NAME_MATND,
	'Cv::SparseMat' => CV_TYPE_NAME_SPARSE_MAT,
	);

for my $class (keys %TYPENAME) {
	my $type_name = $TYPENAME{$class};
	my $obj = $class->new([3, 3], CV_32FC2);
	my $info = Cv->TypeOf($obj);
	isa_ok($info, 'Cv::TypeInfo');
	is($info->type_name, $type_name);
	isa_ok(Cv->findType($type_name), 'Cv::TypeInfo');
	is(Cv->findType($type_name)->type_name, $type_name);
	foreach my $x (0 .. $obj->width - 1) {
		foreach my $y (0 .. $obj->height - 1) {
			$obj->set([$y, $x], [$y, $x]);
		}
	}
	$fs->write(Cv->TypeOf($obj)->type_name, $obj);
}

if (1) {
	my $type_name = CV_TYPE_NAME_SEQ_TREE;
	my $obj = Cv::Seq->new(CV_32SC2);
	my $info = Cv->TypeOf($obj);
	isa_ok($info, 'Cv::TypeInfo');
	is($info->type_name, $type_name);
	isa_ok(Cv->findType($type_name), 'Cv::TypeInfo');
	is(Cv->findType($type_name)->type_name, $type_name);
	$obj->Push(pack("i2", $_ * 10 + 1, $_ * 10 + 2)) for 1 .. 10;
	$fs->write($type_name, $obj);
}

if (7) {
	use File::Basename;
	my $lena = dirname($0) . "/lena.jpg";
	my $image = Cv->loadImage($lena);
	$fs->write("lena", $image);
}

undef $fs;
$fs = Cv::FileStorage->new($yml, CV_STORAGE_READ);

if (8) {
	my $image = $fs->ReadByName(\0, "lena");
	isa_ok($image, 'Cv::Image');
	if ($verbose) {
		$image->show;
		Cv->waitKey(1000);
	}
}

if (10) {
	local $Cv::CLASS{&CV_TYPE_NAME_IMAGE} = undef;
	throws_ok { $fs->Read($fs->getFileNodeByName(\0, "lena")) } qr/type_name unknown in Cv::FileStorage::Read at $0/;
}

if (11) {
	local $Cv::CLASS{&CV_TYPE_NAME_IMAGE} = undef;
	throws_ok { $fs->ReadByName(\0, "lena") } qr/type_name unknown in Cv::FileStorage::Read at $0/;
}

unlink($yml);

SKIP: {
	skip "opencv-2.x", 1 unless cvVersion() >= 2.004;
	throws_ok { Cv->OpenFileStorage('', 0) } qr/OpenCV Error:/;
}
