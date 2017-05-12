# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
# use Test::More tests => 1210;
use Test::More qw(no_plan);
BEGIN {
	use_ok('Cv', -nomore, -subdiv);
}

our %cv;

use File::Basename;
use lib dirname($0);
require "hackcv.pm";

my @TBD = (
	qw(cv3dTrackerCalibrateCameras),
	qw(cv3dTrackerLocateObjects),
	qw(cvBackProjectPCA),
	qw(cvCalcCovarMatrixEx),
	qw(cvCalcDecompCoeff),
	qw(cvCalcEMD2),
	qw(cvCalcEigenObjects),
	qw(cvCalcPCA),
	qw(cvCalibrationMatrixValues),
	qw(cvCheckArr),
	qw(cvClearGraph),
	qw(cvClearSet),
	qw(cvClone),
	qw(cvCloneGraph),
	qw(cvConDensInitSampleSet),
	qw(cvConDensUpdateByTime),
	qw(cvConvertPointsHomogenious),
	qw(cvCreate2DHMM),
	qw(cvCreateConDensation),
	qw(cvCreateFeatureTree),
	qw(cvCreateGraph),
	qw(cvCreateGraphScanner),
	qw(cvCreateObsInfo),
	qw(cvCreatePOSITObject),
	qw(cvCreateSet),
	qw(cvCvtScaleAbs),
	qw(cvDeleteMoire),
	qw(cvDynamicCorrespondMulti),
	qw(cvEViterbi),
	qw(cvEigenDecomposite),
	qw(cvEigenProjection),
	qw(cvEllipse2Poly),
	qw(cvEstimateHMMStateParams),
	qw(cvEstimateObsProb),
	qw(cvEstimateTransProb),
	qw(cvFindFeatures),
	qw(cvFindFeaturesBoxed),
	qw(cvFindGraphEdge),
	qw(cvFindGraphEdgeByPtr),
	qw(cvFindRuns),
	# qw(cvGetCol),
	qw(cvGetGraphVtx),
	qw(cvGetSetElem),
	qw(cvGetHistValue_1D),
	qw(cvGetHistValue_2D),
	qw(cvGetHistValue_3D),
	qw(cvGetHistValue_nD),
	qw(cvGetModuleInfo),
	qw(cvGetNextSparseNode),
	# qw(cvGetRow),
	qw(cvGetStarKeypoints),
	qw(cvGraphAddEdge),
	qw(cvGraphAddEdgeByPtr),
	qw(cvGraphAddVtx),
	qw(cvGraphEdgeIdx),
	qw(cvGraphRemoveEdge),
	qw(cvGraphRemoveEdgeByPtr),
	qw(cvGraphRemoveVtx),
	qw(cvGraphRemoveVtxByPtr),
	qw(cvGraphVtxDegree),
	qw(cvGraphVtxDegreeByPtr),
	qw(cvGraphVtxIdx),
	qw(cvGuiBoxReport),
	qw(cvImgToObs),
	qw(cvImgToObs_DCT),
	qw(cvInitLineIterator),
	qw(cvInitMixSegm),
	qw(cvInitSystem),
	qw(cvInitImageHeader),
	qw(cvInitMatHeader),
	qw(cvInitMatNDHeader),
	qw(cvInitSparseMatIterator),
	qw(cvInitTreeNodeIterator),
	qw(cvInsertNodeIntoTree),
	# qw(cvInvert),
	qw(cvMakeAlphaScanlines),
	qw(cvMakeHistHeaderForArray),
	qw(cvMakeScanlines),
	qw(cvMat),
	qw(cvMaxRect),
	qw(cvMixSegmL2),
	qw(cvMorphEpilinesMulti),
	qw(cvNextGraphItem),
	qw(cvNextTreeNode),
	qw(cvPOSIT),
	qw(cvPostWarpImage),
	qw(cvPreWarpImage),
	qw(cvProjectPCA),
	qw(cvQueryHistValue_1D),
	qw(cvQueryHistValue_2D),
	qw(cvQueryHistValue_3D),
	qw(cvQueryHistValue_nD),
	qw(cvRandShuffle),
	qw(cvRange),
	qw(cvReadByName),
	qw(cvRegisterModule),
	qw(cvRelease2DHMM),
	qw(cvReleaseConDensation),
	qw(cvReleaseFeatureTree),
	qw(cvReleaseGraphScanner),
	qw(cvReleaseImageHeader),
	qw(cvReleaseObsInfo),
	qw(cvReleasePOSITObject),
	qw(cvRemoveNodeFromTree),
	qw(cvNextGraphItem),
	qw(cvNextTreeNode),
	qw(cvPrevTreeNode),
	qw(cvRegisterType),
	qw(cvReadByName),			# XXXXX
	qw(cvRelease),
	qw(cvReleaseCapture),
	qw(cvReleaseFileStorage),
	qw(cvReleaseGraphScanner),
	qw(cvReleaseHist),
	qw(cvReleaseImage),
	qw(cvReleaseImageHeader),
	qw(cvReleaseMat),
	qw(cvReleaseMatND),
	qw(cvReleaseMemStorage),
	qw(cvReleaseSparseMat),
	qw(cvReleaseStereoGCState),	# 
	qw(cvReleaseVideoWriter),
	qw(cvSeqElemIdx),
	qw(cvSeqPartition),
	qw(cvSeqSearch),
	qw(cvSeqSort),
	qw(cvSetAdd),
	qw(cvSetNew),
	qw(cvSetOpenGlDrawCallback),
	qw(cvSetRemove),
	qw(cvSetRemoveByPtr),
	qw(cvSetSeqBlockSize),
	qw(cvSetSeqReaderPos),
	qw(cvSetIPLAllocators),
	qw(cvSetMemoryManager),
	qw(cvSetNumThreads), #
	qw(cvSize2D23f), #
	qw(cvSolvePoly), #
	qw(cvTreeToNodeSeq),
	qw(cvUniformImgSegm), #
	qw(cvUnregisterType), #
	# qw(cvWaitKey),
	qw(cvCreateContourTree),	# defined __cplusplus
	qw(cvContourFromContourTree),
	qw(cvMatchContourTrees),
	);

	
my @Qt = (
	qw(cvAddText),
	qw(cvCreateButton),
	qw(cvCreateOpenGLCallback),
	qw(cvDisplayOverlay),
	qw(cvDisplayStatusBar),
	qw(cvFontQt),
	qw(cvGetWindowProperty),
	qw(cvLoadWindowParameters),
	qw(cvSetWindowProperty),
	qw(cvSaveWindowParameters),
	);

my @C_ARGS = (
	[ 3, qw(cvCalcBackProject) ],
	[ 4, qw(cvCalcBackProjectPatch) ],
	[ 2, qw(cvCalcHist) ],
	[ 2, qw(cvEncodeImage) ],
	[ 2, qw(cvGetTextSize) ],
	[ 2, qw(cvSliceLength) ],
	[ 2, qw(cvSaveImage) ],
	[ 2, qw(cvPointSeqFromMat) ],
	[ 2, qw(cvShowImage) ],
	[ 4, qw(cvFindStereoCorrespondenceBM) ],
	[ 5, qw(cvFindStereoCorrespondenceGC) ],
	);

my @OVERRIDE = (
	[ [ 'CvFont*', 'cvInitFont' ],
	  [ 'int', 'fontFace' ],
	  [ 'double', 'hscale' ],
	  [ 'double', 'vscale' ],
	  [ 'double', 'shear', '=0' ],
	  [ 'int', 'thickness', '=1' ],
	  [ 'int', 'lineType', '=8' ],
	],
	);

my %ignore = (
	map { $_ => 1 } @TBD, @Qt,
);

SKIP: {
	my $refpm;
	if ($0 =~ /(ref-\d+\.\d+\.\d+)\.t/) {
		$refpm = dirname($0) . "/$1.pm";
		skip("no $refpm") unless eval { require $refpm };
	} else {
		my ($a, $b, $c) = CV_VERSION();
		while ($c >= 0) {
			my $pm = dirname($0) . "/ref-$a.$b.$c.pm";
			$refpm ||= $pm;
			if (eval { require $pm }) {
				diag $pm; last;
			}
			if (--$c < 0) {
				last unless --$b >= 0;
				$c = 9;
			}
		}
		diag("no $refpm (make ref)")
			unless $c >= 0;
	}
	for (@C_ARGS) {
		my ($i, $name) = @$_;
		my $p = $cv{$name};
		use Data::Dumper;
		my $retval = shift(@$p);
		my @others = splice(@$p, 0, $i - 1);
		my $first = shift(@$p);
		unshift(@$p, $retval, $first, @others);
	}
	$cv{$_->[0]->[1]} = $_ for @OVERRIDE;

	for (sort { $a->[0]->[1] cmp $b->[0]->[1] } values %cv) {
		my $args = @{$_}?
			join(', ', map { join(' ', @$_) } @{$_}[1..$#{$_}]) : 'void';
		next unless @{$_} >= 1;
		my $name = ${${$_}[0]}[1];
		next unless $name =~ /^cv/;
		next if $ignore{$name};
		my $class = hack_class($_);
		(my $upper = $name) =~ s/^cv//;
		(my $lower = $upper) =~ s/^[A-Z]+/\L$&/;
		ok(($class->can($upper) or $class->can($name)),
		   "$class->can($upper) or $class->can($name) for $name($args)");
	}
}
