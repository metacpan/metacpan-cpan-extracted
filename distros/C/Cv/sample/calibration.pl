#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

# http://opencv.jp/sample/camera_calibration.html

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use IO::File;
use File::Basename;

my @images;
my $calib_image;

&Calibrate($ARGV[0] || join('/', dirname($0), "calibration.txt"));
&Undistort($calib_image);
# &UndistortMap($calib_image);
exit 0;

sub Calibrate {
	# (1) キャリブレーション画像の読み込み
	my $imageList = shift;
	my $f = new IO::File $imageList, "r";
	die "can not open file $imageList\n" unless ($f);

	while (<$f>) {
		next if (/^#/);
		chomp;
		my $image;
		if (-f $_) {
			$image = Cv->LoadImage($_, CV_LOAD_IMAGE_COLOR);
		} else {
			$image = Cv->LoadImage(join('/', dirname($0), $_),
								   CV_LOAD_IMAGE_COLOR);
		}
		die "cannot load image file : $_\n" unless $image;
		push(@images, $image);
		$calib_image = $image->clone unless $calib_image;
	}
	
	# (2) 3次元空間座標の設定
	my $IMAGE_NUM = @images;		# 画像数
	my $PAT_ROW = 6;				# パターンの行数
	my $PAT_COL = 9;				# パターンの列数
	my $PAT_SIZE   = $PAT_ROW * $PAT_COL;
	my $ALL_POINTS = $IMAGE_NUM * $PAT_SIZE;
	my $CHESS_SIZE = 24.0;			# パターン1マスの1辺サイズ[mm]
	
	my $object_points = Cv::Mat->new([$ALL_POINTS, 1], CV_32FC3);
#	my $object_points = Cv::Mat->new([$ALL_POINTS, 3], CV_32FC1);

	for my $i (0 .. $IMAGE_NUM-1) {
		for my $j (0 .. $PAT_ROW-1) {
			for my $k (0 .. $PAT_COL-1) {
				$object_points->set(
					[$i*$PAT_SIZE + $j*$PAT_COL + $k, 0],
					[$j*$CHESS_SIZE, $k*$CHESS_SIZE, 0],
					);
			}
		}
	}

	# (3) チェスボード（キャリブレーションパターン）のコーナー検出
	my $image_points = Cv::Mat->new([$ALL_POINTS, 1], CV_32FC2); # corners
	my $point_counts = Cv::Mat->new([$IMAGE_NUM,  1], CV_32SC1); # p_count;
	
	my $pattern_size = [$PAT_COL, $PAT_ROW];
	my $found_num = 0;

	for (my $i = 0; $i < $IMAGE_NUM; $i++) {
		my $found = $images[$i]->FindChessboardCorners(
			$pattern_size, \ my @corners,
			&CV_CALIB_CB_ADAPTIVE_THRESH | &CV_CALIB_CB_NORMALIZE_IMAGE,
			);

		printf STDERR "%02d...", $i;
		if ($found) {
			print STDERR "ok\n";
			$found_num++;
		} else {
			print STDERR "fail\n";
		}

		# (4) コーナー位置をサブピクセル精度に修正，描画
		my $gray = $images[$i]->CvtColor(CV_BGR2GRAY);
		$gray->FindCornerSubPix(
			\@corners, [3, 3], [-1, -1], cvTermCriteria(
				CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 20, 0.03),
			);
		$images[$i]->DrawChessboardCorners(
			$pattern_size, \@corners, $found);
		$point_counts->set([$i, 0], [scalar @corners]);
		for (0 .. $#corners) {
			$image_points->set([$i*$PAT_SIZE + $_, 0], $corners[$_]);
		}
		Cv->NamedWindow("Calibration", 0);
		$images[$i]->ShowImage("Calibration");
		Cv->WaitKey(100);
	}
	exit -1 if ($found_num != $IMAGE_NUM);

	# (5) 内部パラメータ，歪み係数の推定
	my $intrinsic   = Cv::Mat->new([3, 3], CV_32FC1);
	my $distortion  = Cv::Mat->new([1, 4], CV_32FC1);

	my $rvects = Cv::Mat->new([$IMAGE_NUM, 3], CV_64FC1);
	my $tvects = Cv::Mat->new([$IMAGE_NUM, 3], CV_64FC1);

	$object_points->CalibrateCamera2(
		$image_points, $point_counts, $calib_image->size,
		$intrinsic, $distortion, $rvects, $tvects,
		);

	# (6) 外部パラメータの推定
	my $sub_image_points = Cv::Mat->new([$PAT_SIZE, 1], CV_32FC2);
#	my $sub_object_points = Cv::Mat->new([$PAT_SIZE, 1], CV_32FC3);
	my $sub_object_points = Cv::Mat->new([$PAT_SIZE, 3], CV_32FC1);
	my $base = 0;
	$image_points->GetRows(
		$sub_image_points, $base * $PAT_SIZE, ($base+1) * $PAT_SIZE,
		);
	$object_points->GetRows(
		$sub_object_points, $base * $PAT_SIZE, ($base+1) * $PAT_SIZE,
		);
	my $rotation    = Cv::Mat->new([1, 3], CV_32FC1);
	my $translation = Cv::Mat->new([1, 3], CV_32FC1);
	$sub_object_points->FindExtrinsicCameraParams2(
		$sub_image_points, $intrinsic, $distortion,
		$rotation, $translation,
		);

	# Cv->Save("intrinsic.xml", $intrinsic);
	# Cv->Save("distortion.xml", $distortion);

	# (7) XMLファイルへの書き出し
	my $fs = Cv::FileStorage->new("camera.xml", CV_STORAGE_WRITE);
	$fs->Write("intrinsic", $intrinsic);
	$fs->Write("rotation", $rotation);
	$fs->Write("translation", $translation);
	$fs->Write("distortion", $distortion);
}


sub Undistort {
	# (1)補正対象となる画像の読み込み
	my $src_img = shift;
	$src_img = $src_img->CvtColor(CV_RGB2GRAY) if ($src_img->channels == 3);

	# (2)パラメータファイルの読み込み
	my $param;
	my $fs = Cv::FileStorage->new("camera.xml", CV_STORAGE_READ);
	$param = $fs->GetFileNodeByName(\0, "intrinsic");
	my $intrinsic = $fs->Read($param);
	$param = $fs->GetFileNodeByName(\0, "distortion");
	my $distortion = $fs->Read($param);

	# (3)歪み補正
	$src_img->Undistort2(my $dst_img = $src_img->new, $intrinsic, $distortion);

	# (4)画像を表示，キーが押されたときに終了
	Cv->NamedWindow("Distortion", 0);
	Cv->NamedWindow("UnDistortion", 0);
	$src_img->ShowImage("Distortion");
	$dst_img->ShowImage("UnDistortion");
	Cv->WaitKey;
}


sub UndistortMap {
	# (1)補正対象となる画像の読み込み
	my $src_img = shift;
	$src_img = $src_img->CvtColor(CV_RGB2GRAY) if ($src_img->channels == 3);
	my $mapx = Cv::Image->new([480, 640], CV_32FC1);
	my $mapy = Cv::Image->new([480, 640], CV_32FC1);

	# (2)パラメータファイルの読み込み
	my $param;
	my $fs = Cv::FileStorage->new("camera.xml", CV_STORAGE_READ);
	$param = $fs->GetFileNodeByName(\0, "intrinsic");
	my $intrinsic = $fs->Read($param);
	$param = $fs->GetFileNodeByName(\0, "distortion");
	my $distortion = $fs->Read($param);

	# (3) 歪み補正のためのマップ初期化
	$intrinsic->InitUndistortMap($distortion, $mapx, $mapy);

	# (4) 歪み補正
	$src_img->Remap(my $dst_img = $src_img->new, $mapx, $mapy);

	Cv->NamedWindow("Distortion", 0);
	Cv->NamedWindow("UnDistortion", 0);
	$src_img->ShowImage("Distortion");
	$dst_img->ShowImage("UnDistortion");
	Cv->WaitKey;
}
