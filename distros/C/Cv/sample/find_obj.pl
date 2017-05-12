#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;
use Getopt::Long;

sub help {
	print << "----";
This program demonstrated the use of the SURF Detector and Descriptor using
either FLANN or brute force matching on planar objects.
----
	;
}

# define whether to use approximate nearest-neighbor search
my $USE_FLANN = 1;
GetOptions('flann!' => \$USE_FLANN)
	or die << "----";
Usage: $0 [--(no)?flann] <object_filename> <scene_filename>
	default filename is box.png and box_in_scene.png
----
	;

use Cv::Config;
use Inline C => Config => %Cv::Config::C;
use Inline C => << '----';

#ifndef __cplusplus
#  error "use C++"
#endif

#include <opencv/cv.h>

AV*
flannFindPairs(
	const CvSeq* objectKeypoints, const CvSeq* objectDescriptors,
	const CvSeq* imageKeypoints, const CvSeq* imageDescriptors)
{
	int length = (int)(objectDescriptors->elem_size/sizeof(float));
	cv::Mat m_object(objectDescriptors->total, length, CV_32F);
	cv::Mat m_image(imageDescriptors->total, length, CV_32F);

	// copy descriptors;
	cvCvtSeqToArray(objectDescriptors, m_object.ptr<float>(0));
	cvCvtSeqToArray(imageDescriptors, m_image.ptr<float>(0));

	// find nearest neighbors using FLANN
	cv::Mat m_indices(objectDescriptors->total, 2, CV_32S);
	cv::Mat m_dists(objectDescriptors->total, 2, CV_32F);
	cv::flann::Index flann_index(m_image, cv::flann::KDTreeIndexParams(4));  //using 4 randomized kdtrees
	flann_index.knnSearch(m_object, m_indices, m_dists, 2, cv::flann::SearchParams(64)); // maximum number of leafs checked

	AV* ptpairs = newAV();
	int* indices_ptr = m_indices.ptr<int>(0);
	float* dists_ptr = m_dists.ptr<float>(0);
	for (int i = 0; i < m_indices.rows; ++i) {
		if (dists_ptr[2*i] < 0.6 * dists_ptr[2*i+1]) {
			av_push(ptpairs, newSViv(i));
			av_push(ptpairs, newSViv(indices_ptr[2*i]));
		}
	}
	return ptpairs;
}

static double
compareSURFDescriptors( const float* d1, const float* d2, double best, int length )
{
    double total_cost = 0;
    assert( length % 4 == 0 );
    for( int i = 0; i < length; i += 4 )
    {
        double t0 = d1[i  ] - d2[i  ];
        double t1 = d1[i+1] - d2[i+1];
        double t2 = d1[i+2] - d2[i+2];
        double t3 = d1[i+3] - d2[i+3];
        total_cost += t0*t0 + t1*t1 + t2*t2 + t3*t3;
        if( total_cost > best )
            break;
    }
    return total_cost;
}

static int
naiveNearestNeighbor( const float* vec, int laplacian,
                      const CvSeq* model_keypoints,
                      const CvSeq* model_descriptors )
{
    int length = (int)(model_descriptors->elem_size/sizeof(float));
    int i, neighbor = -1;
    double d, dist1 = 1e6, dist2 = 1e6;
    CvSeqReader reader, kreader;
    cvStartReadSeq( model_keypoints, &kreader, 0 );
    cvStartReadSeq( model_descriptors, &reader, 0 );

    for( i = 0; i < model_descriptors->total; i++ )
    {
        const CvSURFPoint* kp = (const CvSURFPoint*)kreader.ptr;
        const float* mvec = (const float*)reader.ptr;
        CV_NEXT_SEQ_ELEM( kreader.seq->elem_size, kreader );
        CV_NEXT_SEQ_ELEM( reader.seq->elem_size, reader );
        if( laplacian != kp->laplacian )
            continue;
        d = compareSURFDescriptors( vec, mvec, dist2, length );
        if( d < dist1 )
        {
            dist2 = dist1;
            dist1 = d;
            neighbor = i;
        }
        else if ( d < dist2 )
            dist2 = d;
    }
    if ( dist1 < 0.6*dist2 )
        return neighbor;
    return -1;
}

AV*
findPairs(const CvSeq* objectKeypoints, const CvSeq* objectDescriptors,
           const CvSeq* imageKeypoints, const CvSeq* imageDescriptors)
{
    int i;
    CvSeqReader reader, kreader;
    cvStartReadSeq( objectKeypoints, &kreader );
    cvStartReadSeq( objectDescriptors, &reader );

	AV* ptpairs = newAV();
    for( i = 0; i < objectDescriptors->total; i++ )
    {
        const CvSURFPoint* kp = (const CvSURFPoint*)kreader.ptr;
        const float* descriptor = (const float*)reader.ptr;
        CV_NEXT_SEQ_ELEM( kreader.seq->elem_size, kreader );
        CV_NEXT_SEQ_ELEM( reader.seq->elem_size, reader );
        int nearest_neighbor = naiveNearestNeighbor( descriptor, kp->laplacian, imageKeypoints, imageDescriptors );
        if( nearest_neighbor >= 0 )
        {
			av_push(ptpairs, newSViv(i));
			av_push(ptpairs, newSViv(nearest_neighbor));
        }
    }
	return ptpairs;
}
----
	;

sub findPairs2 {
	my ($objectKeypoints, $objectDescriptors,
		$imageKeypoints, $imageDescriptors) = @_;
	my $ptpairs = findPairs(@_);
	[ map {
		[ $objectKeypoints->get($ptpairs->[$_ * 2])->[0],
		  $imageKeypoints->get($ptpairs->[$_ * 2 + 1])->[0] ]
	  } 0 .. int($#$ptpairs / 2)
	];
}
	

# a rough implementation for object location
sub locatePlanarObject {
	my $objectKeypoints = shift;
	my $objectDescriptors = shift;
	my $imageKeypoints = shift;
	my $imageDescriptors = shift;
	my $src_corners = shift;
	my $dst_corners = shift;

	if ($USE_FLANN) {
		no warnings 'redefine';
		*findPairs = \&flannFindPairs;
	}

	my $ptpairs = findPairs2(
		$objectKeypoints, $objectDescriptors,
		$imageKeypoints, $imageDescriptors,
		);
    my $n = $#$ptpairs;
	return 0 if $n < 4;

	my $pt1 = Cv::Mat->new([], CV_32FC2, map { $_->[0] } @$ptpairs);
	my $pt2 = Cv::Mat->new([], CV_32FC2, map { $_->[1] } @$ptpairs);

	my $h = Cv::Mat->new([ 3, 3 ], CV_64F);
    Cv->findHomography($pt1, $pt2, $h, CV_RANSAC, 5);

	my %H = ();
	for my $j (0 .. 2) {
		for my $i (0 .. 2) {
			$H{$j, $i} = $h->getReal([int $j, int $i]);
		}
	}

    for (my $i = 0; $i < 4; $i++) {
        my ($x, $y) = @{$src_corners->[$i]}[0..1];
        my $Z = 1.0 / ($H{2, 0}*$x + $H{2, 1}*$y + $H{2, 2});
        my $X = ($H{0, 0}*$x + $H{0, 1}*$y + $H{0, 2})*$Z;
		my $Y = ($H{1, 0}*$x + $H{1, 1}*$y + $H{1, 2})*$Z;
        $dst_corners->[$i] = cvPoint(cvRound($X), cvRound($Y));
    }
    return 1;
}


my $object_filename = shift || join('/', dirname($0), "box.png");
my $scene_filename = shift || join('/', dirname($0), "box_in_scene.png");

&help;
my $object = Cv->loadImage($object_filename, CV_LOAD_IMAGE_GRAYSCALE);
my $image = Cv->loadImage($scene_filename, CV_LOAD_IMAGE_GRAYSCALE);
unless ($object && $image) {
	die "Can not load $object_filename and/or $scene_filename\n";
}

my $storage = Cv::MemStorage->new;
Cv->namedWindow("Object", 1);
Cv->namedWindow("Object Correspond", 1);

my @colors = (
	[   0,   0, 255 ],
	[   0, 128, 255 ],
	[   0, 255, 255 ],
	[   0, 255,   0 ],
	[ 255, 128,   0 ],
	[ 255, 255,   0 ],
	[ 255,   0,   0 ],
	[ 255,   0, 255 ],
	[ 255, 255, 255 ],
	);

my $params = cvSURFParams(500, 1);
my $tt = Cv->getTickCount();
$object->extractSURF(
	\0, my $objectKeypoints, my $objectDescriptors,
	$storage, $params,
	);
printf("Object Descriptors: %d\n", $objectDescriptors->total);
$image->extractSURF(
	\0, my $imageKeypoints, my $imageDescriptors,
	$storage, $params,
	);
printf("Image Descriptors: %d\n", $imageDescriptors->total);
$tt = Cv->getTickCount() - $tt;
printf("Extraction time = %gms\n", $tt / (Cv->getTickFrequency() * 1000.0));

my $correspond = Cv::Image->new(
	[$object->height + $image->height, $image->width], CV_8UC3,
	);
my $object_color = $object->cvtColor(CV_GRAY2BGR);
$object_color->copy(
	$correspond->getSubRect([0, 0, @{$object->size}])
	);
my $image_color = $image->cvtColor(CV_GRAY2BGR);
$image_color->copy(
	my $correspond_image = $correspond->getSubRect(
		[0, $object->height, @{$image->size}])
	);

if ($USE_FLANN) {
    print "Using approximate nearest neighbor search\n";
}

my @src_corners = (
	[ 0, 0 ],
	[ $object->width, 0 ],
	[ $object->width, $object->height ],
	[ 0, $object->height ]
	);
my @dst_corners;
if (locatePlanarObject($objectKeypoints, $objectDescriptors, $imageKeypoints, $imageDescriptors, \@src_corners, \@dst_corners)) {
	$correspond_image->PolyLine([\@dst_corners], -1, $colors[0], 2, CV_AA);
}

my $ptpairs = findPairs2(
	$objectKeypoints, $objectDescriptors,
	$imageKeypoints, $imageDescriptors,
	);
for (@$ptpairs) {
	my $pt_object = $_->[0];
	my $pt_image = [ $_->[1]->[0], $_->[1]->[1] + $object->height ];
	$correspond->line($pt_object, $pt_image, $colors[3], 1, CV_AA);
}
$correspond->show("Object Correspond");

for (@$objectKeypoints) {
	my ($center, $radius) = ($_->[0], $_->[2] * 1.2 / 9 * 2);
	$object_color->circle($center, $radius, $colors[0]);
}
$object_color->show("Object");

Cv->waitKey;
