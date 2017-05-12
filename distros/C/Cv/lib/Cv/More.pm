# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

package Cv::More;

use 5.008008;
use strict;
use warnings;

# use Cv qw( );
use Cv::Seq;
use Cv::Seq::Point;
use Cv::Seq::Point2;
use Cv::Seq::Rect;
use Cv::Seq::SURFPoint;

our $VERSION = '0.29';

package Cv;

our %O;

BEGIN {
	$O{$_} ||= 0 for qw(cs cs-warn);
}

our %M;

$M{butscalar} = "called in list context, but returning scaler";

package Cv::More;

sub import {
	my $self = shift;
	for (@_) {
		next if /^:/;			# ignore
		if (defined $Cv::O{$_}) {
			$O{$_} = 1;
		} else {
			Carp::croak join(' ', "can't import", $_, 'in', (caller 0)[3]);
		}
	}
}

sub unimport {
	my $self = shift;
	for (@_) {
		next if /^:/;			# ignore
		if (defined $Cv::O{$_}) {
			$O{$_} = 0;
		} else {
			Carp::croak join(' ', "can't unimport", $_, 'in', (caller 0)[3]);
		}
	}
}


package Cv;

sub m_dims {
	if (@_) {
		if (ref $_[0]) {
			(scalar(@_), m_dims(@{$_[0]}));
		} else {
			(scalar(@_));
		}
	} else {
		();
	}
}


package Cv::Mat;

{
	no warnings 'redefine';
	*new = sub { goto &m_new };
}

sub m_new {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my ($self, $sizes, $type) = Cv::new_args(@_);
	my $mat;
	if (@$sizes) {
		my ($rows, $cols) = @$sizes; $cols ||= 1;
		if (@_) {
			my ($data, $step) = @_;
			$step = &Cv::CV_AUTOSTEP unless $step;
			$mat = Cv::cvCreateMatHeader($rows, $cols, $type);
			$mat->setData($data, $step) if $data;
		} else {
			$mat = Cv::cvCreateMat($rows, $cols, $type);
		}
	} elsif (@_) {
		my @dims = Cv::m_dims(@_);
		pop(@dims) if $dims[-1] == &Cv::CV_MAT_CN($type);
		return undef unless my ($rows, $cols) = @dims; $cols ||= 1;
		$mat = Cv::cvCreateMat($rows, $cols, $type);
		local $Carp::CarpLevel = $Carp::CarpLevel + 2;
		$mat->m_set([], \@_);
	}
	$mat;
}


package Cv::MatND;

{
	no warnings 'redefine';
	*new = \&m_new;
}

sub m_new {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my ($self, $sizes, $type) = Cv::new_args(@_);
	my $mat;
	if (@$sizes) {
		if (@_) {
			$mat = Cv::cvCreateMatNDHeader($sizes, $type);
			$mat->setData($_[0], &Cv::CV_AUTOSTEP) if $_[0];
		} else {
			$mat = Cv::cvCreateMatND($sizes, $type);
		}
	} elsif (@_) {
		my @dims = Cv::m_dims(@_);
		pop(@dims) if $dims[-1] == &Cv::CV_MAT_CN($type);
		$mat = Cv::cvCreateMatND(\@dims, $type);
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		$mat->m_set([], \@_);
	}
	$mat;
}


package Cv::Seq::Point;

{
	no warnings 'redefine';
	*new = \&s_new;
}

sub s_new {
	my $class = shift;
	my @init = ();
	while (ref $_[-1] && ref $_[-1] eq 'ARRAY') {
		CORE::unshift(@init, CORE::pop);
	}
	my $self = $class->SUPER::new(@_);
	if (@init) {
		my @dims = Cv::m_dims(@init);
		pop(@dims) if $dims[-1] == &Cv::CV_MAT_CN($self->type);
		if (@dims > 1 && $dims[0] == 1) {
			shift(@dims); @init = @{$init[0]};
		}
		if (@dims == 1 && $dims[0] > 1) {
			@init = map { [ $_ ] } @init if &Cv::CV_MAT_CN($self->type) == 1;
		}
		if (@dims == 1) {
			$self->Push(@init);
		} else {
			Carp::croak "can't init in ", (caller 0)[3];
		}
	}
	$self;
}


# ============================================================
#  core. The Core Functionality: Operations on Arrays
# ============================================================

package Cv::Arr;

{
	no warnings 'redefine';
	*Set = *set = \&m_set;
}

sub m_set {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my $mat = shift;
	my $value = pop;
	my $idx = ref $_[0] eq 'ARRAY'? shift : [ splice(@_, 0) ];
	my @dims = $mat->getDims;
	if (@dims <= @$idx) {
		$value = [ $value ] unless ref $value;
		unshift(@_, $mat, $idx, $value);
		goto &cvSetND;
	} elsif (ref $value && ref $value->[0] ||
			 ref $value && @$value > 1 && $dims[-1] > 1 &&
			 	Cv::CV_MAT_CN($mat->type) == 1) {
		$mat->m_set([@$idx, $_], $value->[$_]) for 0 .. $#{$value};
	} else {
		$mat->m_set([@$idx, 0], $value);
	}
	$mat;
}


sub m_get {
	my $arr = shift;
	my $idx = shift;
	cvGetDims($arr, my @dims);
	if (@dims <= @$idx) {
		my $type = cvGetElemType($arr);
		[ @{ cvGetND($arr, $idx) }[0 .. Cv::CV_MAT_CN($type) - 1] ];
	} else {
		[ map { $arr->m_get([@$idx, $_]) } (0 .. $dims[scalar @$idx] - 1) ];
	}
}


use overload
	'@{}' => sub { $_[0]->ToArray },
	bool => sub { $_[0] },
	'<=>' => \&overload_cmp,
	cmp => \&overload_cmp,
	fallback => undef;

sub overload_cmp {
	my ($l, $r) = @_;
	my ($lc, $rc) = (ref $l, ref $r);
	bless $l, 'overload::dummy';
	bless $r, 'overload::dummy';
	my $cmp = $l cmp $r;
	bless $l, $lc;
	bless $r, $rc;
	$cmp;
}


# ============================================================
#  core. The Core Functionality: Dynamic Structures
# ============================================================

{ *Cv::Seq::Point::ToArray = \&ToArray }
{ *Cv::Seq::Point::CvtSeqToArray = \&ToArray }
{ *Cv::Arr::CvtMatToArray = \&ToArray }

sub ToArray {
	# @array = cvtSeqToArray($seq)
	# @array = cvtSeqToArray($seq, $slice)
	# cvtSeqToArray($seq, \@array)
	# cvtSeqToArray($seq, \@array, $slice)
	my $self = CORE::shift;
	my $slice = ref $_[-1] eq 'ARRAY' && @{$_[-1]} == 2?
		CORE::pop : &Cv::CV_WHOLE_SEQ;
	if (@_ >= 1 && ref $_[0] eq 'ARRAY') {
		@{$_[0]} = ();
	} else {
		$_[0] = [];
	}
	if ($self->isa('Cv::Seq::Point')) {
		cvCvtSeqToArray($self, my $string, $slice);
		$self->UnpackMulti($_[0], $string);
	} else {
		my ($start, $end) = @$slice;
		if ($self->isa('Cv::MatND') && $self->dims == 1) {
			$end = $self->rows - 1 if $end == Cv::CV_WHOLE_SEQ_END_INDEX;
			@{$_[0]} = map { $self->get([$_]) } $start .. $end;
		} elsif ($self->cols == 1) {
			$end = $self->rows - 1 if $end == Cv::CV_WHOLE_SEQ_END_INDEX;
			@{$_[0]} = map { $self->get([$_, 0]) } $start .. $end;
		} elsif ($self->rows == 1) {
			$end = $self->cols - 1 if $end == Cv::CV_WHOLE_SEQ_END_INDEX;
			@{$_[0]} = map { $self->get([0, $_]) } $start .. $end;
		} else {
			Carp::croak join(' ', "can't convert", join('x', $self->getDims),
							 'in', (caller 0)[3]);
		}
	}
	wantarray? @{$_[0]} : $_[0];
}


# ============================================================
#  imgproc. Image Processing: Geometric Image Transformations
# ============================================================

package Cv::Arr;

sub Affine {
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	my $map = shift;
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	GetQuadrangleSubPix($src, $dst, Cv::Mat->new([], &Cv::CV_32FC1, @$map));
}


{ *Cv::Transform = \&Transform }
sub Transform {
	# cvTransform(CvArr* src, CvArr* dst, CvMat* transmat, CvMat* shiftvec)
	my $self = shift;
	my $cs = 0;
	unless (ref $self) {
		my $points = shift;
		my @dims = Cv::m_dims(@$points);
		$self = Cv::Mat->new([], &Cv::CV_32FC($dims[-1]), @$points);
		$cs++;
	}
	if (ref $_[0] && $_[0]->isa('Cv::Mat') &&
		$_[0]->rows == 2 && $_[0]->cols == 3) { # $_[0] is transmat
		unshift(@_, $self->new);
	} else {
		$_[0] ||= $self->new;
	}
	unshift(@_, $self);
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my $retval = &cvTransform;
	if ($cs) {
		@{ $_[1] = [] } = @$retval;
		if (wantarray) {
			return @{$_[1]} if $Cv::O{cs};
			local $Carp::CarpLevel = $Carp::CarpLevel + 1;
			Carp::carp $Cv::M{butscalar} if $Cv::O{'cs-warn'}
		}
		return $_[1];
	}
	$retval;
}


# ============================================================
#  imgproc. Image Processing: Structural Analysis and Shape Descriptors
# ============================================================

package Cv::Arr;

{ *Cv::BoundingRect = \&BoundingRect }
sub BoundingRect {
	# CvRect cvBoundingRect(CvArr* points, int update=0)
	my $self = shift;
	unless (ref $self) {
		$self = Cv::Mat->new([], &Cv::CV_32SC2, @_);
	}
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my $retval = cvBoundingRect($self);
	if (wantarray) {
		return @$retval if $Cv::O{cs};
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		Carp::carp $Cv::M{butscalar} if $Cv::O{'cs-warn'}
	}
	return $retval;
}

{ *Cv::ContourArea = \&ContourArea }
sub ContourArea {
	# double cvContourArea(const CvArr* contour, CvSlice slice=CV_WHOLE_SEQ)
	my $self = shift;
	unless (ref $self) {
		my $points = shift;
		$self = Cv::Mat->new([], &Cv::CV_32SC2, @$points);
	}
	my $slice = shift || &Cv::CV_WHOLE_SEQ;
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	cvContourArea($self, $slice);
}

{ *FitEllipse = \&FitEllipse2 }
{ *Cv::FitEllipse = *Cv::FitEllipse2 = \&FitEllipse2 }
sub FitEllipse2 {
	# Cv->FitEllipse2(\@points);                                                
	# Cv->FitEllipse2(pt1, pt2, pt3, ...);                                      
	# $mat->FitEllipse2;                                                        
	my $self = shift;
	unless (ref $self) {
		Carp::croak "Usage: ${[ caller 0 ]}[3](points)"
			unless @_;
		$self = Cv::Mat->new([], &Cv::CV_32SC2, @_);
	}
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my $retval = cvFitEllipse2($self);
	if (wantarray) {
		return @$retval if $Cv::O{cs};
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		Carp::carp $Cv::M{butscalar} if $Cv::O{'cs-warn'};
	}
	return $retval;
}

{ *Cv::FitLine = \&FitLine }
sub FitLine {
    my $self = shift;
    unless (ref $self) {
		my $points = shift;
		Carp::croak "Usage: ${[ caller 0 ]}[3](points, distType=CV_DIST_L2, param=0, reps=0.01, aeps=0.01)"
			unless defined $points;
		Carp::croak "points is not [ pt1, pt2, ... ] in ", (caller 0)[3]
			unless my @dims = Cv::m_dims(@$points);
		$self = Cv::Mat->new([], &Cv::CV_32FC($dims[-1]), @$points);
    }
	my $rr = \ [ ];			# dummy
	if (@_ && (!defined $_[-1] || ref $_[-1] eq 'ARRAY')) {
		$rr = \ $_[-1]; pop;
	}
	my ($distType, $param, $reps, $aeps) = @_;
	$distType ||= &Cv::CV_DIST_L2;
	$param    ||= 0;
	$reps     ||= 0.01;
	$aeps     ||= 0.01;
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	cvFitLine($self, $distType, $param, $reps, $aeps, $$rr);
	my $retval = $$rr;
	if (wantarray) {
		return @$retval if $Cv::O{cs};
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		Carp::carp $Cv::M{butscalar} if $Cv::O{'cs-warn'};
	}
	return $retval;
}

{ *MinAreaRect = \&MinAreaRect2 }
{ *Cv::MinAreaRect = *Cv::MinAreaRect2 = \&MinAreaRect2 }
sub MinAreaRect2 {
    my $self = shift;
	&Cv::stor(@_);				# remove memstorage;
    unless (ref $self) {
		$self = Cv::Mat->new([], &Cv::CV_32SC2, @_);
	}
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my $retval = cvMinAreaRect2($self);
	if (wantarray) {
		return @$retval if $Cv::O{cs};
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		Carp::carp $Cv::M{butscalar} if $Cv::O{'cs-warn'};
	}
	return $retval;
}

{ *Cv::MinEnclosingCircle = \&MinEnclosingCircle }
sub MinEnclosingCircle {
	my $self = shift;
	my ($xcenter, $xradius);	# dummy
	my ($rcenter, $rradius) = (\$xcenter, \$xradius);
	if (@_ >= 2 &&
		# undef or scalar
		(!defined $_[-2] || !ref $_[-2]) &&
		(!defined $_[-1] || !ref $_[-1])) {
		($rcenter, $rradius) = (\$_[-2], \$_[-1]);
		pop; pop;
	}
    unless (ref $self) {
		$self = Cv::Mat->new([], &Cv::CV_32SC2, @_);
		Carp::croak $@ if $@;
	}
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my $retval = cvMinEnclosingCircle($self, $$rcenter, $$rradius)?
		[$$rcenter, $$rradius] : undef;
	if (wantarray) {
		return @$retval if $Cv::O{cs};
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		Carp::carp $Cv::M{butscalar} if $Cv::O{'cs-warn'};
	}
	return $retval;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=encoding utf8

=head1 NAME

Cv::More - A little more easy to using L<Cv> in Perl.

=head1 SYNOPSIS

 use Cv::More qw(cs);

=head1 DESCRIPTION

C<Cv::More> is a package to organize some of the experimental features
from L<Cv>. I believe it will be easier to extend the
C<Cv>. C<Cv::More> is what separated the part of the C<Cv>. So, it is
enabled by default. Please make a explicit if you do not use.

 use Cv;              # enabled Cv::More
 use Cv -nomore;	  # disabled Cv::More

=head2 Added or Extended Method

=head3 Cv::Arr - Using Perl Array

=over

=item FitEllipse2()

 my $box2d = Cv->FitEllipse2($points);

The return value is CvBox2D. If you specify C<cs>, and called in
listcontext, the following elements will be expanded.

 use Cv::More qw(cs);
 my ($center, $size, $angle) = Cv->FitEllipse2($points);

The following example shows how to draw a list of points
FitEllipse2().

 my $img = Cv::Image->new([250, 250], CV_8UC3)->fill(cvScalarAll(255));
 $img->origin(1);
 my @pts = (map { [ map { $_ / 4 + rand $_ / 2 } @{$img->size} ] } 1 .. 20);
 $img->circle($_, 3, &color, 1, CV_AA) for @pts;
 my $box = Cv->fitEllipse(\@pts);
 $img->polyLine([[Cv->boxPoints($box)]], -1, &color, 1, CV_AA);
 $img->ellipseBox($box, &color, 1, CV_AA);
 $img->show("FitEllipse2");
 Cv->waitKey;
 sub color { [ map { rand 255 } 1 .. 3 ] }


=item FitLine()

FitLine() has the following two methods call.

 my $line = Cv->FitLine($points, $dist_type, $param, $reps, $aeps);     # (1)
 Cv->FitLine($points, $dist_type, $param, $reps, $aeps, my $line);      # (2)

Can omit the parameters other than $points. $points is a list of
points in two-or three-dimensional. The return value is determined by
the number of dimensions of $points.

 my $points2d = [ [$x1, $y1], [$x2, $y2], ... ];
 my ($vx, $vy, $x0, $y0) = Cv->FitLine($points2d, ...);
 my $points3d = [ [$x1, $y1, $z1], [$x2, $y2, $z2], ... ];
 my ($vx, $vy, $vz, $x0, $y0, $z0) = Cv->FitLine($points3d, ...);

The following examples, draw a straight line fit to a collection of
some points.

 my @pts = ([ 50, 50 ], [ 100, 120 ], [ 150, 150 ], [ 200, 150 ]);
 my ($vx, $vy, $x0, $y0) = Cv->fitLine(\@pts); 
 $img->line((map { [ $_, $vy / $vx * ($_ - $x0) + $y0 ] } 20, 230),
			cvScalarAll(200), 3, CV_AA);


=item MinAreaRect2()

 my $box2d = Cv->MinAreaRect2($points);
 my ($center, $size, $angle) = Cv->MinAreaRect2($points);

The return value is CvBox2D, means the smallest rectangle enclosing a
list of points.

 for ([ [ Cv->fitEllipse(\@pts)  ], [ 200, 200, 200 ] ],
      [ [ Cv->minAreaRect(\@pts) ], [ 100, 100, 255 ] ]) {
   $img->polyLine([[Cv->boxPoints($_->[0])]], -1, $_->[1], 1, CV_AA);
   $img->ellipseBox($_->[0], $_->[1], 1, CV_AA);
 }

To Cv-0.15, used the memory storage same as the interface of C
language. But, Cv-0.16 and later versions do not use memory storage.

=item MinEnclosingCircle()

 my $circle = Cv->MinEnclosingCircle($points);                          # (1)
 my ($center, $radius) = Cv->MinEnclosingCircle($points);               # (1')
 Cv->MinEnclosingCircle($points, my $center, my $radius);               # (2)

The return value is the coordinates of the center $center and the
radius of the circle $radius.

The following example drawn C<fitEllipse2()>, C<minEnclosingCircle()>
and C<minAreaRect2()> using a same list of points.

 my $rectangle = Cv->minAreaRect2(\@pts);
 my $ellipse = Cv->fitEllipse2(\@pts);
 my ($center, $radius) = Cv->minEnclosingCircle(\@pts);
 my $circle = [ $center, [ ($radius * 2) x 2 ], 0 ];
 for ([ $rectangle, [ 200, 200, 200 ] ],
      # [ $ellipse,   [ 200, 200, 200 ] ],
      [ $circle,    [ 100, 100, 255 ] ]) {
   $img->polyLine([[Cv->boxPoints($_->[0])]], -1, $_->[1], 1, CV_AA);
   $img->ellipseBox($_->[0], $_->[1], 1, CV_AA);
 }

=item BoundingRect()

 my $rect = Cv->BoundingRect($points)
 my ($x, $y, $width, $height) = Cv->BoundingRect($points)

Returns the minimal up-right bounding rectangle for the specified
point set.The return value is C<CvRect>. By converting to C<CvBox2D> from
C<CvRect> as follows, and usability of C<BoxPoints> EllipseBox better.

 my $box2d = [ [ $x + $width / 2, $y + $height / 2 ], [ $width, $height ], 0 ];


=item ContourArea()

 my $s = Cv->ContourArea($points)
 my $s = Cv->ContourArea($points, $slice)

The function computes the contour area. In the following example, area
C<$s> is the (100x100) horizontal x vertical.

 my @pts = ([100, 100], [100, 200], [200, 200], [200, 100]);
 my $s = Cv->contourArea(\@pts);


=item Transform()

 my $dst = Cv->Transform([ $pt1, $pt2, ... ], $transmat);               # (1)
 my @dst = Cv->Transform([ $pt1, $pt2, ... ], $transmat);               # (1')
 Cv->Transform([ $pt1, $pt2, ... ], my $dst, $transmat);                # (2)

 my @points = ( [$x1, $y1], [$x2, $y2], ... );
 my $arr = Cv::Mat->new([], CV_32FC2, @points);
 my $dst = $arr->Transform($transmat);                                  # (3)
 $arr->Transform(my $dst, $transmat);                                   # (4)

 my $dst = $arr->WarpAffine($transmat);                                 # (5)
 $arr->warpTransform(my $dst, $transmat);                               # (6)


=item Affine()

This method performs a rotation and contraction for images and matrix.
Implementation is a wrapper for C<GetQuadrangleSubPix()>.

  my $mapMatrix = [ [ $A11, $A12, $b1 ],
                    [ $A21, $A22, $b2 ] ];
  my $dst = $src->Affine($mapMatrix);

This function makes it easy effort to make the transformation matrix.
In addition, can also write the same in the following.

  $src->GetQuadrangleSubPix(
          Cv::Mat->new([], &Cv::CV_32FC1,
                       [ $A11, $A12, $b1 ],
                       [ $A21, $A22, $b2 ],
                       ));

=item new()

=item m_new()

Object of the matrix and the image in OpenCV is made by specifying the
type and element size. C<m_new()> is a method to redefine the C<new()>
so as to provide the value of each element. If specify an empty
arrayref [] to the size of the matrix, the size of the matrix is the
number of elements.

 my $mat = Cv::Mat->new([], $type, $elements);

The following is an example of a matrix camera. The size of matrix is
3x3, the element type is CV_32FC1.

 my $mat = Cv::Mat->new([ ], CV_32FC1,
    [ $fx,   0, $cx ],
    [   0, $fy, $cy ],
    [   0,   0,   1 ],
    );


=item Set()

=item m_set()

 $mat->Set($index, $value);

C<m_set()> extends the <Set()> to make it possible to collectively set
the element. As follows, C<$index> is an array reference.

 $mat = Cv::Mat->new([ 2, 2 ], CV_32FC2);
 $value = [ 100, 100 ];
 
If any part of the index is omitted, 0 is supplemented.

 $mat->m_set([@$index, 0], $value);

In the case where C<$value> is given as a list, the value of the
element is set as follows in order from C<$index>.

 $mat->m_set([@$index, $_], $value->[$_]) for 0 .. $#{$value};

For example,

 $mat->Set([ 0, 1 ], $value);
 # (1) set element [ 0, 1 ]
 # [
 #   [ [ 0, 0 ], [ 100, 100 ] ],
 #   [ [ 0, 0 ], [   0,   0 ] ],
 # ]
 
 $mat->Set([ 1 ], $value);
 # (2) set element [ 0, 1 ]
 # [
 #   [ [   0,   0 ], [   0,   0 ] ],
 #   [ [ 100, 100 ], [   0,   0 ] ],
 # ]
 
 $mat->Set([ 1 ], [ ($value) x 2 ]);
 # (2)' set element [ 0, 1 ], [ 1, 1 ]
 # [
 #   [ [   0,   0 ], [   0,   0 ] ],
 #   [ [ 100, 100 ], [ 100, 100 ] ],
 # ]
 
 $mat->Set([], $value);
 # (3) set element [ 0, 0 ]
 # [
 #   [ [ 100, 100 ], [   0,   0 ] ],
 #   [ [   0,   0 ], [   0,   0 ] ],
 # ]
 
 $mat->Set([], [ [ $value ], [ ($value) x 2 ] ]);
 # (3)' set element [ 0, 0 ], [ 0, 1 ], [ 1, 1 ]
 # [
 #   [ [ 100, 100 ], [ 100, 100 ] ],
 #   [ [   0,   0 ], [ 100, 100 ] ],
 # ]


=item ToArray()

 my @array = $arr->ToArray();                                           # (1)
 my @array = $arr->ToArray($slice);                                     # (2)

Converted into array of points from sequence or matrix (1xN, Nx1). 
To be able to convert the matrix, this method has been extended
cvCvtSeqToArray() to convert the sequence. So can specify a range
$slice give.  This range can be represented by array reference [$
start, $ end] or cvSlice().  When you omit the range will convert all
of the elements.

 $arr->ToArray(\my @array);
 $arr->ToArray(\my @attay, $slice);

It is useful if can use negative index like an array of Perl, which
can not be.

 my @array = $arr->ToArray([ -1, 1 ]); # cannot use
 my @array = $arr->ToArray([ 1, -1 ]); # cannot use

=back


=head3 Other Method

=over

=item GetBuildInformation()

  my $info = Cv->GetBuildInformation()
  my %info = Cv->GetBuildInformation()

Build-time information can be retrieved from OpenCV 2.4.0.  If the
scalar context, returns the return value of
C<cv::getBuildInformation()>. If the list context, it returns the
following results.

  'OpenCV modules' => {
	'Disabled by dependency' => '-',
	'Unavailable' => 'androidcamera java ocl',
	'Disabled' => 'world',
	'To be built' => 'core imgproc flann highgui features2d calib3d ml video objdetect contrib nonfree photo legacy gpu python stitching ts videostab'
  },
  'Version control' => 'commit:6484732',
  'Linker flags (Debug)' => {
	'Precompiled headers' => 'YES'
  },
  ...

t is used in the C <HasModule()>. In order to check the module
available in OpenCV.


=item HasModule()

 my $hasCore = Cv->HasModule('core');

This method returns what has been built to enable any module in OpenCV.

=back

=head1 SEE ALSO

L<Cv>

=head1 LICENCE

MASUDA Yuta E<lt>yuta.cpan@gmail.comE<gt>

Copyright (c) 2012, 2013 by MASUDA Yuta.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
