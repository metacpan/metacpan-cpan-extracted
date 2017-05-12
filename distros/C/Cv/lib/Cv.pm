# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

=head1 NAME

Cv - helps you to make something around computer vision.

=head1 SYNOPSIS

 use Cv;
 
 my $image = Cv->LoadImage("/path/to/image", CV_LOAD_IMAGE_COLOR);
 $image->ShowImage("image");
 Cv->WaitKey;
 
 my $capture = Cv->CaptureFromCAM(0);
 while (my $frame = $capture->QueryFrame) {
   $frame->Flip(\0, 1)->ShowImage;
   my $c = Cv->WaitKey(100);
   last if $c >= 0;
 }

=head1 DESCRIPTION

C<Cv> is the Perl interface to the OpenCV computer vision library that
originally developed by Intel.  I'm making this module to use the
computer vision more easily like a slogan of perl I<"Easy things
should be easy, hard things should be possible.">

The features are as follows.

=cut

package Cv;

use 5.008008;
use strict;
use warnings;
use Carp;
use Scalar::Util;
use warnings::register;

our $VERSION = '0.29';

use Cv::Constant qw(:all);

require XSLoader;
XSLoader::load('Cv', $VERSION);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = grep /^(IPL|CV|cv)/, (keys %Cv::);

our %EXPORT_TAGS = (
	'all' => \@EXPORT_OK,
	'std' => \@EXPORT_OK,
	);

our @EXPORT = ( );

our %IMPORT;
our %O;
our %M;

BEGIN {
	$IMPORT{$_} = 1 for qw(Histogram More Seq);
	$IMPORT{$_} = 0 for qw(Qt BGCodeBookModel Subdiv2D);
	$O{$_} = 1 for qw(boxhappy);
}

use Getopt::Long;

sub import {
	my $self = shift;
	local @ARGV = @_;
	my %opt = (
		(map { lc($_).'!' => \$IMPORT{$_} } keys %IMPORT),
		(map { lc($_).'!' => \$O{$_} } keys %O),
		);
	unless (GetOptions(%opt)) {
		die << "----";
Usage: use Cv @{[ map { "-".($IMPORT{$_}?"no":"").lc($_) } sort keys %IMPORT ]}
----
;
	}
	if (@ARGV) {
		my @argv = ();
		for (@ARGV) {
			if (/^:no(\w+)$/) {
				$IMPORT{lc $1} = 0;
			} else {
				push(@argv, $_);
			}
		}
		@ARGV = @argv;
	}
	for (grep { $IMPORT{$_} } keys %IMPORT) {
		eval "use Cv::$_";
		die "can't use Cv::$_; $@" if $@;
	}
	push(@ARGV, ":std") unless @ARGV;
	$self->export_to_level(1, $self, @ARGV);
}


sub DESTROY { }

sub CV_MAJOR_VERSION () { ${[ &CV_VERSION ]}[0] }
sub CV_MINOR_VERSION () { ${[ &CV_VERSION ]}[1] }
sub CV_SUBMINOR_VERSION () { ${[ &CV_VERSION ]}[2] }

{ *Version = *version = sub { shift; goto &cvVersion } }

=over 4

=item *

C<Cv> was made along the online reference manual of C in the OpenCV
documentation.  For details, please refer to the
http://opencv.willowgarage.com/.

=item *

You can use C<CreateSomething()> as a constructors. 

 my $img = Cv->CreateImage([ 320, 240 ], IPL_DEPTH_8U, 3);
 my $mat = Cv->CreateMat([ 240, 320 ], CV_8UC3);

=item *

You can also use C<new> as a constructor.  C<Cv::Image-E<gt>new> is
C<Cv-E<gt>CreateImage()>, C<Cv::Mat-E<gt>new> is
C<Cv-E<gt>CreateMat()>.  In the calling parameters, there are some
difference in CreateImage() and CreateMat().  But there are no
difference in C<Cv::Something-E<gt>new>.  This is because we create
same object without knowing about original object in the C<Cv::Arr>.

 my $img = Cv::Image->new([ 240, 320 ], CV_8UC3);
 my $mat = Cv::Mat->new([ 240, 320 ], CV_8UC4);

You can omit parameters and that will be inherited.

 my $sameone = $img->new;
 my $gray = $color->new(CV_8UC1);

=cut

sub new_args (\@) {
	my $x = shift;
	my $self = shift(@$x);
	my $sizes = @$x && ref $x->[0] eq 'ARRAY' ? shift(@$x) :
		ref $self ? $self->sizes : undef;
	Carp::croak 'size not specified in ', (caller 1)[3] unless defined $sizes;
	my $type  = @$x ? shift(@$x) : ref $self ? $self->type : undef;
	Carp::croak 'type not specified in ', (caller 1)[3] unless defined $type;
	($self, $sizes, $type);
}


sub Cv::Image::new {
	my ($self, $sizes, $type) = new_args(@_);
	my ($channels, $depth) = (&Cv::CV_MAT_CN($type), &Cv::CV2IPL_DEPTH($type));
	my ($rows, $cols) = @$sizes;
	my $image = Cv::cvCreateImage([$cols, $rows], $depth, $channels);
	$image->origin($self->origin) if ref $self && $self->can('origin');
	$image;
}


sub Cv::Mat::new {
	my ($self, $sizes, $type) = new_args(@_);
	if (@_) {
		eval "use Cv::More";
		die $@ if $@;
		$self->new($sizes, $type, @_);
	} else {
		my ($rows, $cols) = @$sizes; $cols ||= 1;
		unshift(@_, $rows, $cols, $type);
		goto &Cv::cvCreateMat;
	}
}


sub Cv::MatND::new {
	my ($self, $sizes, $type) = new_args(@_);
	if (@_) {
		eval "use Cv::More";
		die $@ if $@;
		$self->new($sizes, $type, @_);
	} else {
		unshift(@_, $sizes, $type);
		goto &Cv::cvCreateMatND;
	}
}


sub Cv::SparseMat::new {
	my ($self, $sizes, $type) = new_args(@_);
	unshift(@_, $sizes, $type);
	goto &Cv::cvCreateSparseMat;
}


=item *

You have to call cvReleaseImage() when you'll destroy the image object
in the OpenCV application programs.  But in the C<Cv>, you don't have
to call cvReleaseImage() because Perl calls C<DESTROY> for cleanup.
So the subroutine C<DESTROY> has often been defined as an alias of
cvReleaseImage(), cvReleaseMat(), ... and cvReleaseSomething().

Some functions, eg. cvQueryFrame() return a reference but that cannot
be destroyed. In this case, the reference is blessed with
C<Cv::Somthing::Ghost>, and identified. And disable destroying.

=cut

package Cv::Arr;                                            sub DESTROY {}
package Cv::Mat;              our @ISA = qw(Cv::Arr);
package Cv::Mat::Ghost;       our @ISA = qw(Cv::Mat);       sub DESTROY {}
package Cv::MatND;            our @ISA = qw(Cv::Mat);
package Cv::MatND::Ghost;     our @ISA = qw(Cv::MatND);     sub DESTROY {}
package Cv::SparseMat;        our @ISA = qw(Cv::MatND);
package Cv::SparseMat::Ghost; our @ISA = qw(Cv::SparseMat); sub DESTROY {}
package Cv::Image;            our @ISA = qw(Cv::Mat);
package Cv::Image::Ghost;     our @ISA = qw(Cv::Image);     sub DESTROY {}
package Cv::Seq;              our @ISA = qw(Cv::Arr);
package Cv::Seq::Seq;         our @ISA = qw(Cv::Seq);
package Cv::ContourScanner;   our @ISA = qw(Cv::Seq);

=item *

You can use name of method, omitting "cv" from the OpenCV function
name, and also use lowercase name beginning. For example, you can call
C<cvCreateMat()> as:

 my $mat = Cv->CreateMat(240, 320, CV_8UC3);
 my $mat = Cv->createMat(240, 320, CV_8UC3);

=cut

package Cv;

for (
	"Cv",
	"Cv::Arr",
	# "Cv::BGCodeBookModel",
	"Cv::Capture",
	"Cv::Chain",
	"Cv::ChainPtReader",
	"Cv::ConDensation",
	"Cv::ContourScanner",
	"Cv::ContourTree",
	"Cv::ConvKernel",
	"Cv::FileNode",
	"Cv::FileStorage",
	"Cv::Font",
	"Cv::HaarClassifierCascade",
	# "Cv::Histogram",
	"Cv::HuMoments",
	"Cv::Image",
	"Cv::Kalman",
	"Cv::Mat",
	"Cv::MatND",
	"Cv::MemStorage",
	"Cv::Moments",
	# "Cv::POSITObject",
	"Cv::RNG",
	"Cv::SparseMat",
	"Cv::StereoBMState",
	"Cv::StereoGCState",
	"Cv::StereoSGBM",
	"Cv::String",
	"Cv::StringHashNode",
	# "Cv::Subdiv2D",
	"Cv::TypeInfo",
	"Cv::VideoWriter",
	) {
	{ no strict 'refs'; *{$_ . '::AUTOLOAD'} = \&Cv::autoload }
}


sub autoload {
	our $AUTOLOAD;
	(my $short = $AUTOLOAD) =~ s/(.*):://;
	my $family = $1;
	if (my $code = assoc($family, $short)) {
		{ no strict 'refs'; *$AUTOLOAD = $code }
		if (wantarray) {
			my @cc = &$code;
			return @cc;
		} else {
			goto &$code;
		}
	}
	Carp::croak "can't call $AUTOLOAD";
}


sub assoc {
	my $family = shift;
	my $short = shift;
	my @names;
	if ($short =~ /^cv[A-Zm]/) {
		# return $family->can($short);
		return undef;
	}
	# if ($short =~ /^[a-z]/ && $short !~ /^cv[A-Zm]/) {
	if ($short =~ /^[a-z]/) {
		(my $caps = $short) =~ s/^[a-z]/\U$&/;
		push(@names, $caps);
		(my $upper = $short) =~ s/^[a-z]+/\U$&/;
		push(@names, $upper) if $caps ne $upper;
		push(@names, map { "cv$_" } @names);
	} else {
		push(@names, "cv$short");
	}
	push(@names, $short);
	foreach (@names) {
		if (my $subr = $family->can($_)) {
			if ($family eq 'Cv' && $_ =~ /^cv[A-Zm]/) {
				return sub {
					ref (my $class = shift) and Carp::croak 'class name needed';
					goto &$subr;
				};
			}
			return $subr;
		}
	}
	return undef;
}


sub usage {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	Carp::croak "Usage: ${[ caller 1 ]}[3](", join('', @_), ")";
}


sub named_parameter {
	my $template = shift; 
	my @template = @$template;
	my %param = (); my %seen = ();
	if (@_) {
		if ($_[0] =~ /^-[a-z]/i) {
			my %hash = @_;
			while (my ($k, $v) = each %hash) {
				$k =~ s/^-//;
				$param{$k} = $v;
				$seen{$k}++;
			}
		} else {
			while (my ($k, $v) = splice(@template, 0, 2)) {
				last unless @_;
				$param{$k} = shift;
				$seen{$k}++;
			}
		}
	}
	my %template = @template;
	while (my ($k, $v) = each %template) {
		next if $seen{$k};
		$param{$k} = $v;
	}
	my $p = \%param;
	# [ @{$p}{@template[ grep { ($_ & 1) == 0 } 0 .. $#template ]} ];
}


=item *

When you omit the destination image or matrix (often named "dst"),
C<Cv> creates new destination if possible.

 my $dst = $src->Add($src2);
 my $dst = $src->Add($src2, $mask);  # can't omit dst

in this case, you can create $dst as follows:

 my $dst = $src->Add($src2, $src->new, $mask); 

=item *

Some functions in the OpenCV can handle inplace that use source image
as destination one. To tell requesting inplace, you can use C<\0> as
C<NULL> for the destination.

 my $dst = $src->Flip(\0);

=cut

package Cv;

sub is_null { ref $_[0] eq 'SCALAR' && ${$_[0]} == 0 }
sub is_cvarr { Scalar::Util::blessed $_[0] && $_[0]->isa('Cv::Arr') }


# ============================================================
#  core. The Core Functionality: Basic Structures
# ============================================================

package Cv;

sub cvPoint        { [ unpack("i2", pack("i2", @_)) ]; }
sub cvPoint2D32f   { [ unpack("f2", pack("f2", @_)) ]; }
sub cvPoint2D64f   { [ unpack("d2", pack("d2", @_)) ]; }
sub cvPoint3D32f   { [ unpack("f3", pack("f3", @_)) ]; }
sub cvPoint3D64f   { [ unpack("d3", pack("d3", @_)) ]; }
sub cvPointFrom32f { cvPoint(@{$_[0]}); }
sub cvPointTo32f   { cvPoint2D32f(@{$_[0]}); }
sub cvPointTo2D32f { cvPoint2D32f(@{$_[0]}); }
sub cvPointTo3D32f { cvPoint3D32f(@{$_[0]}); }
sub cvPointTo3D64f { cvPoint3D64f(@{$_[0]}); }
sub cvSize         { [ unpack("i2", pack("i2", @_)) ]; }
sub cvSize2D32f    { [ unpack("f2", pack("f2", @_)) ]; }
sub cvRect         { [ unpack("i4", pack("i4", @_)) ]; }
sub cvScalar       { [ unpack("d4", pack("d4", @_)) ]; }
sub cvScalarAll    { cvScalar(($_[0]) x 4); }
sub cvRealScalar   { cvScalar($_[0], 0, 0, 0); }
sub cvTermCriteria { [ unpack("i2d1", pack("i2d1", @_)) ]; }
sub cvSlice        { [ unpack("i2", pack("i2", @_)) ]; }


# ============================================================
#  core. The Core Functionality: Operations on Arrays
# ============================================================

package Cv::Arr;

# The GetDims needs alias before calling.  The function called via
# AUTOLOAD will not know the context of the caller.

sub dst (\@) {
	my $dst = undef;
	for (my $i = 0; $i < @{$_[0]}; $i++) {
		($dst) = splice(@{$_[0]}, $i, 1), last
			if Cv::is_cvarr(${$_[0]}[$i])
			|| $i == 0 && Cv::is_null(${$_[0]}[$i]);
	}
	$dst;
}

=item *

The members of structure are same as function.

 my ($c, $d) = ($img->channels, $img->depth);
 my ($h, $w) = ($img->height, $img->width);
 my ($r, $c) = ($img->rows, $img->cols);
 my @sz = $img->sizes;

But we can't use as lvalue.

 my $roi = $img->roi;              # GetImageROI($img)
 $img->roi($roi);                  # SetImageROI($img, $roi)
 my $coi = $img->coi;              # GetImageCOI($img)
 $img->coi($coi);                  # SetImageCOI($img, $coi)

=cut

sub ROI {
	my $self = shift;
	my $roi = cvGetImageROI($self);
	cvSetImageROI($self, @_) if @_;
	$roi;
}

sub COI {
	my $self = shift;
	my $coi = cvGetImageCOI($self);
	cvSetImageCOI($self, @_) if @_;
	$coi;
}


=item *

There are functions Get() and Set(). They access an elements.  You can
call Get() as cvGetND(), and Set() as cvSetND().  So, you have to to
call Fill() instead of calling the cvSetND().

 my $x = $mat->Get($i, $j);        # cvGetND($mat, [$i, $j])
 my $x = $mat->Get(\@idx);         # cvGetND($mat, \@idx);

When the number of indexes is less than the number of the dimensions,
0 is complemented as indexes.  

 $mat->Set([$i, $j, ...], $x);     # cvSetND($mat, [$i, $j, ...], $x)
 $mat->Set(\@idx, $x);             # cvSetND($mat, \@idx, $x)
 $mat->Fill($x);                   # cvSet($mat, $x)

=cut

{ *Get = \&GetND }
sub GetND {
	# Get($src, $idx0);
	# Get($src, $idx0, $idx1);
	# Get($src, $idx0, $idx1, $idx2);
	# Get($src, $idx0, $idx1, $idx2, $idx3);
	# Get($src, \@idx);
	my $src = shift;
	my $idx = ref $_[0] eq 'ARRAY'? shift : [ splice(@_, 0) ];
	push(@$idx, (0) x ($src->dims - @$idx));
	unshift(@_, $src, $idx);
	goto &cvGetND;
}

*Get1D = *Get2D = *Get3D = \&GetND;
# sub Get1D { GetND($_[0], [$_[1]]) }
# sub Get2D { GetND($_[0], [@_[1..2]]) }
# sub Get3D { GetND($_[0], [@_[1..3]]) }


{ *Set = *set = \&SetND }
sub SetND {
	# Set($src, $idx0, $value);
	# Set($src, $idx0, $idx1, $value);
	# Set($src, $idx0, $idx1, $idx2, $value);
	# Set($src, $idx0, $idx1, $idx2, $idx3, $value);
	# Set($src, \@idx, $value);
	my $src = shift;
	my $value = pop;
	my $idx = ref $_[0] eq 'ARRAY'? shift : [ splice(@_, 0) ];
	push(@$idx, (0) x ($src->dims - @$idx));
	unshift(@_, $src, $idx, $value);
	goto &cvSetND;
}

*Set1D = *Set2D = *Set3D = \&SetND;
# sub Set1D { SetND($_[0], [$_[1]], $_[2]) }
# sub Set2D { SetND($_[0], [@_[1..2]], $_[3]) }
# sub Set3D { SetND($_[0], [@_[1..3]], $_[4]) }


sub GetRawData {
	# GetRawData($arr, my $data, my $step, my $roiSize)
	$_[2] = my $step    unless defined $_[2];
	$_[3] = my $roiSize unless defined $_[3];
	goto &cvGetRawData;
}


sub GetReal {
	# GetReal($src, $idx0);
	# GetReal($src, $idx0, $idx1);
	# GetReal($src, $idx0, $idx1, $idx2);
	# GetReal($src, $idx0, $idx1, $idx2, $idx3);
	# GetReal($src, [$idx0, $idx1, $idx2, $idx3]);
	my $src = shift;
	my $idx = ref $_[0] eq 'ARRAY'? shift : [ splice(@_, 0) ];
	push(@$idx, (0) x ($src->dims - @$idx));
	unshift(@_, $src, $idx);
	goto &cvGetRealND;
}

*GetReal1D = *GetReal2D = *GetReal3D = \&GetReal;
# sub GetReal1D { GetReal($_[0], [$_[1]]) }
# sub GetReal2D { GetReal($_[0], [@_[1..2]]) }
# sub GetReal3D { GetReal($_[0], [@_[1..3]]) }


sub SetReal {
	# SetReal($src, $idx0, $value);
	# SetReal($src, $idx0, $idx1, $value);
	# SetReal($src, $idx0, $idx1, $idx2, $value);
	# SetReal($src, $idx0, $idx1, $idx2, $idx3, $value);
	# SetReal($src, \@idx, $value);
	my $src = shift;
	my $value = pop;
	my $idx = ref $_[0] eq 'ARRAY'? shift : [ splice(@_, 0) ];
	push(@$idx, (0) x ($src->dims - @$idx));
	unshift(@_, $src, $idx);
	push(@_, $value);
	goto &cvSetRealND;
}

*SetReal1D = *SetReal2D = *SetReal3D = \&SetReal;
# sub SetReal1D { SetReal($_[0], [$_[1]], $_[2]) }
# sub SetReal2D { SetReal($_[0], [@_[1..2]], $_[3]) }
# sub SetReal3D { SetReal($_[0], [@_[1..3]], $_[4]) }


=item *

Ptr() returns a string that from specified element up to the end of
the line.  Parameters are same as Get().

 my $str = $mat->Ptr($row, $col);  # cvPtrND($mat, [$row, $col]);
 my $str = $mat->Ptr($row);        # cvPtrND($mat, [$row]);

=cut

sub Ptr {
	# Ptr($src, $idx0);
	# Ptr($src, $idx0, $idx1);
	# Ptr($src, $idx0, $idx1, $idx2);
	# Ptr($src, $idx0, $idx1, $idx2, $idx3);
	# Ptr($src, \@idx);
	my $src = shift;
	my $idx = ref $_[0] eq 'ARRAY'? shift : [ splice(@_, 0) ];
	push(@$idx, (0) x ($src->dims - @$idx));
	unshift(@_, $src, $idx);
	goto &cvPtrND;
}

*Ptr1D = *Ptr2D = *Ptr3D = \&Ptr;
# sub Ptr1D { Ptr($_[0], [$_[1]], $_[2]) }
# sub Ptr2D { Ptr($_[0], [@_[1..2]], $_[3]) }
# sub Ptr3D { Ptr($_[0], [@_[1..3]], $_[4]) }


=item *

There are functions to split per channel and merge them.

 $rgb->Split($r, $g, $b);          # cvSplit($rgb, $r, $g, $b)
 my ($r, $g, $b) = $rgb->Split;    # cvSplit($rgb, $r, $g, $b)
 my $rgb = Cv->Merge($r, $g, $b);  # cvMerge([$r, $g, $b], $rgb);

=cut

{ *CvtPixToPlane = \&Split }
sub Split {
	# Split(src, $dst0, $dst1, ...);
	my $src = shift;
	unless (@_) {
		for (1 .. $src->channels) {
			my $dst = $src->new(&Cv::CV_MAKETYPE($src->type, 1));
			push(@_, $dst);
		}
	}
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	cvSplit($src, @_);
	wantarray ? @_ : \@_;
}

{*Cv::Merge = \&Merge }
sub Merge {
	my $src = shift;
	$src = shift unless ref $src; # ignore class
	my @src;
	if (ref $src eq 'ARRAY') {
		@src = @$src;
	} elsif (Cv::is_cvarr($src)) {
		@src = ($src);
		while (@src < 4) {
			last unless @_ &&
				(Cv::is_cvarr($_[0]) && $_[0]->channels == 1 ||
				 Cv::is_null($_[0]));
			push(@src, shift);
		}
	}
	Cv::usage("[src0, src1, ...], dst") unless @src;
	my $dst = shift;
	$dst ||= $src[0]->new(&Cv::CV_MAKETYPE($src[0]->type, scalar @src));
	push(@src, (\0) x (4 - @src));
	unshift(@_, @src, $dst);
	goto &cvMerge;
}


# The following functions call the CreatelSomethingHeader() if $submat
# is not given.
#
#  my $submat = $src->GetCols($startCol, $endCol);
#  my $submat = $src->GetRows($startRow, $endRow, $deltaRow);
#  my $submat = $src->GetSubRect($rect);

{ *GetCol = \&GetCols }
sub GetCols {
	# GetCols($src, [$submat], $col);
	# GetCols($src, [$submat], $startCol, $endCol);
	my $src = shift;
	my $submat = dst(@_);
	push(@_, 0, $src->cols) if @_ == 0;
	push(@_, $_[-1] + 1) if @_ == 1;
	my $startCol = shift;
	my $endCol  = shift;
	my $cols = $endCol - $startCol;
	$submat ||= Cv::Mat->new([$src->rows, $cols], $src->type, undef);
	unshift(@_, $src, $submat, $startCol, $endCol);
	goto &cvGetCols;
}


{ *GetRow = \&GetRows }
sub GetRows {
	# GetRows($src, [$submat], $row);
	# GetRows($src, [$submat], $startRow, $endRow, [$deltaRow]);
	my $src = shift;
	my $submat = dst(@_);
	push(@_, 0, $src->rows) if @_ == 0;
	push(@_, $_[-1] + 1) if @_ == 1;
	my $startRow = shift;
	my $endRow = shift;
	my $deltaRow = shift || 1;
	my $rows = int(($endRow - $startRow) / $deltaRow);
	$submat ||= Cv::Mat->new([$rows, $src->cols], $src->type, undef);
	unshift(@_, $src, $submat, $startRow, $endRow, $deltaRow);
	goto &cvGetRows;
}


sub GetSubRect {
	# GetSubRect($src, [$submat], $rect);
	my $src = shift;
	my $submat = dst(@_);
	my $rect = shift || [ 0, 0, $src->width, $src->height ];
	my $sizes = [ $rect->[3], $rect->[2] ];
	$submat ||= Cv::Mat->new($sizes, $src->type, undef);
	unshift(@_, $src, $submat, $rect);
	goto &cvGetSubRect;
}


sub MinMaxLoc {
	# MinMaxLoc($arr, my $minVal, my $maxVal, my $minLoc, my $maxLoc, my $mask)
	if (@_ >= 3) {
		$_[3] = my $minLoc unless defined $_[3];
		$_[4] = my $maxLoc unless defined $_[4];
	}
	goto &cvMinMaxLoc;
}

=item *

cvAddS() and cvAdd() are integrated into Add().  The function which
can be identified by the argument.

 my $ar2 = Cv->CreateImage();      # ref Cv::Image
 my $sc2 = cvScalar();             # ref ARRAY
 my $d = $ar->Add($ar2);           # cvAdd($ar, $ar2)
 my $d = $ar->Add($sc2);           # cvAddS($ar, $sc2)

The integrated function as follows.

 AbsDiff(), Add(), And(), Cmp(), InRange(), Max(), Min(), Or(), Sub(),
 Xor()

=cut

{ *AbsDiffS = \&AbsDiff }
sub AbsDiff {
	# AbsDiff(src1, src2, [dst])
	# AbsDiffS(src, value, [dst])
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2_value, $dst);
	if (ref $src2_value eq 'ARRAY') {
		goto &cvAbsDiffS;
		# goto &{*cvAbsDiffS{CODE}};
	} else {
		goto &cvAbsDiff;
		# goto &{*cvAbsDiff{CODE}};
	}
}


{ *AddS = \&Add }
sub Add {
	# Add(src1, src2, [dst], [mask])
	# AddS(src, value, [dst], [mask])
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2_value, $dst);
	if (ref $src2_value eq 'ARRAY') {
		goto &cvAddS;
	} else {
		goto &cvAdd;
	}
}

{ *AndS = \&And }
sub And {
	# And(src1, src2, [dst], [mask])
	# AndS(src, value, [dst], [mask])
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2_value, $dst);
	if (ref $src2_value eq 'ARRAY') {
		goto &cvAndS;
	} else {
		goto &cvAnd;
	}
}


{ *CmpS = \&Cmp }
sub Cmp {
	# Cmp(src, src2, [dst], cmpOp)
	# CmpS(src, value, [dst], cmpOp)
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new(&Cv::CV_8UC1);
	unshift(@_, $src, $src2_value, $dst);
	if (!ref $src2_value) {
		goto &cvCmpS;
	} else {
		goto &cvCmp;
	}
}


{ *InRangeS = \&InRange }
sub InRange {
	# InRange($src, $upper, $lower, [$dst]);
	# InRangeS($src, $upper, $lower, [$dst]);
	my $src = shift;
	my ($upper, $lower) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new(&Cv::CV_8UC1);
	unshift(@_, $src, $upper, $lower, $dst);
	if (ref $upper eq 'ARRAY') {
		goto &cvInRangeS;
	} else {
		goto &cvInRange;
	}
}


{ *MaxS = \&Max }
sub Max {
	# Max(src1, src2, [dst]);
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2_value, $dst);
	if (!ref $src2_value) {
		goto &cvMaxS;
	} else {
		goto &cvMax;
	}
}


{ *MinS = \&Min }
sub Min {
	# Min(src1, src2, [dst]);
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2_value, $dst);
	if (!ref $src2_value) {
		goto &cvMinS;
	} else {
		goto &cvMin;
	}
}


{ *OrS = \&Or }
sub Or {
	# Or(src1, src2, [dst], [mask])
	# OrS(src, value, [dst], [mask])
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2_value, $dst);
	if (ref $src2_value eq 'ARRAY') {
		goto &cvOrS;
	} else {
		goto &cvOr;
	}
}


{ *SubS = \&Sub }
sub Sub {
	# Sub(src1, src2, [dst], [mask])
	# SubS(src, value, [dst], [mask])
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2_value, $dst);
	if (ref $src2_value eq 'ARRAY') {
		goto &cvSubS;
	} else {
		goto &cvSub;
	}
}


{ *XorS = \&Xor }
sub Xor {
	# Xor(src1, src2, [dst], [mask])
	# XorS(src, value, [dst], [mask])
	my ($src, $src2_value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2_value, $dst);
	if (ref $src2_value eq 'ARRAY') {
		goto &cvXorS;
		# goto &{*cvXorS{CODE}};
	} else {
		goto &cvXor;
		# goto &{*cvXor{CODE}};
	}
}


{ *Scale = *Convert = *CvtScale = \&ConvertScale }
sub ConvertScale {
	# ConvertScale(src, [dst], [scale], [shift])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvConvertScale;
}


{ *CvtScaleAbs = \&ConvertScaleAbs }
sub ConvertScaleAbs {
	# ConvertScaleAbs(src, [dst], [scale], [shift])
	my $src = shift;
	my $dst = dst(@_) || $src->new(&Cv::CV_8UC($src->channels));
	unshift(@_, $src, $dst);
	goto &cvConvertScaleAbs;
}


sub AddWeighted {
	# AddWeighted(src1, alpha, src2, beta, gamma, [dst])
	my ($src, $alpha, $src2, $beta, $gamma) = splice(@_, 0, 5);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $alpha, $src2, $beta, $gamma, $dst);
	goto &cvAddWeighted;
}


sub CrossProduct {
	# CrossProduct(src1, src2, [dst])
	my ($src, $src2) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2, $dst);
	goto &cvCrossProduct;
}


sub DCT {
	# DCT(src, [dst], flags)
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvDCT;
}


sub DFT {
	# DFT(src, [dst], flags, [nonzeroRows])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvDFT;
}


sub Div {
	# Div(src1, src2, [dst], [scale]);
	my ($src, $src2) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2, $dst);
	goto &cvDiv;
}


sub Exp {
	# Exp(src, [dst]);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvExp;
}


{ *Mirror = \&Flip }
sub Flip {
	# Flip(src, [dst], flipMode)
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvFlip;
}


sub GEMM {
	# GEMM($src, $src2, $alpha, $src3, $beta, [$dst], [$tABC]);
	my ($src, $src2, $alpha, $src3, $beta) = splice(@_, 0, 5);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2, $alpha, $src3, $beta, $dst);
	goto &cvGEMM;
}


sub MatMulAdd {
	# MatMulAdd($src1, $src2, $src3, [$dst]);
	my ($src, $src2, $src3) = splice(@_, 0, 3);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2, 1, $src3, 1, $dst, 0);
	goto &GEMM;
}


sub MatMul {
	# MatMulAdd($src1, $src2, [$dst]);
	my ($src, $src2) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2, \0, $dst);
	goto &MatMulAdd;
}


sub Inv {
	# Inv(src, [dst], [$method]);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvInv;
}


sub Log {
	# Log(src, [dst]);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvLog;
}


sub LUT {
	# LUT(src, [dst], $lut);
	my $src = shift;
	my $lut = pop;
	my $dst = dst(@_);
	if (&Cv::CV_MAT_CN($lut->type) > 1) {
		my @lut = $lut->split;
		$dst ||= $src->new($lut->type);
		my @dsts = $dst->split;
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		cvLUT($src, $dsts[$_], $lut[$_]) for 0 .. $#lut;
		Cv->Merge(\@dsts, $dst);
	} else {
		$dst ||= $src->new(&Cv::CV_MAKETYPE($lut->type, 1));
		unshift(@_, $src, $dst, $lut);
		goto &cvLUT;
	}
}


sub Mul {
	# Mul(src1, src2, [dst], [scale])
	my ($src, $src2) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2, $dst);
	goto &cvMul;
}


sub MulSpectrums {
	# MulSpectrums(src1, src2, [dst], flags);
	my ($src, $src2) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2, $dst);
	goto &cvMulSpectrums;
}


sub MulTransposed {
	# MulTransposed(src1, src2, [dst], order, [delta], [scale]);
	my ($src, $src2) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $src2, $dst);
	goto &cvMulTransposed;
}


sub Normalize {
	# Normalize(src, dst, [a], [b], [norm_type], [mask])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvNormalize;
}


sub Not {
	# Not(src, [dst])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvNot;
}


sub Pow {
	# Pow(src, [dst], power)
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvPow;
}


sub Reduce {
	# Reduce(src, [dst], [dim], [op]);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvReduce;
}


sub Repeat {
	# Repeat(src, dst);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvRepeat;
}


{ *MulAddS = \&ScaleAdd }
sub ScaleAdd {
	# ScaleAdd(src, scale, src2, [dst]);
	my ($src, $scale, $src2) = splice(@_, 0, 3);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $scale, $src2, $dst);
	goto &cvScaleAdd;
}


sub SubRS {
	# SubRS(src, value, [dst], [mask])
	my ($src, $value) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $value, $dst);
	goto &cvSubRS;
}


sub Transpose {
	# Transpose(src, [dst])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvTranspose;
}


=pod

=back

=cut

# ============================================================
#  core. The Core Functionality: Dynamic Structures
# ============================================================

package Cv;

sub is_cvmem { Scalar::Util::blessed $_[0] && $_[0]->isa('Cv::MemStorage') }

our $STORAGE;

sub STORAGE {
	$STORAGE ||= &cvCreateMemStorage(0);
}

sub stor (\@) {
	my $storage;
	for (my $i = 0; $i < @{$_[0]}; $i++) {
		($storage) = splice(@{$_[0]}, $i, 1), last
			if Cv::is_cvmem(${$_[0]}[$i]);
	}
	$storage ||= &STORAGE;
}

package Cv::MemStorage;
{ *new = \&Cv::CreateMemStorage }


# ============================================================
#  core. The Core Functionality: Drawing Functions
# ============================================================

package Cv;

sub CV_RGB { my ($r, $g, $b, $a) = @_; cvScalar($b, $g, $r, $a || 0) }

sub GetTextSize {
	shift if $_[0] eq __PACKAGE__ && @_ == 5;
	usage("textString, font, textSize, baseline") unless @_ == 4;
	if (ref $_[1] eq 'Cv::Font') {
		goto &cvGetTextSize;
	} else {
		Carp::croak "unknown font @{[ ref $_[1] ]} in Cv::GetTextSize";
	}
}

package Cv::Font;
{ *new = \&Cv::InitFont }

sub GetTextSize {
	my ($font, $text) = splice(@_, 0, 2);
	unshift(@_, 'Cv', $text, $font);
	goto &Cv::GetTextSize;
}

package Cv::Arr;

sub PutText {
	goto &cvPutText;
}

sub Ellipse {
	# cvEllipse(img, center, axes, angle, start_angle, end_angle,
	# 		  color, thickness=1, int lineType=8, int shift=0)
	my ($img, $center, $axes, $angle, $start_angle, $end_angle) =
		splice(@_, 0, 6);
	if ($O{boxhappy}) {
		if (&Cv::cvVersion() < 2.002) {
			$_ = -$_ for $angle, $start_angle, $end_angle;
		}
	}
	unshift(@_, $img, $center, $axes, $angle, $start_angle, $end_angle);
	goto &cvEllipse;
}

sub EllipseBox {
	# void cvEllipseBox(img, box, color, thickness=1, lineType=8, shift=0)
	my ($img, $box) = splice(@_, 0, 2);
	if ($O{boxhappy}) {
		if (&Cv::cvVersion() < 2.002) {
			$box = [ $box->[0], $box->[1], 90 - $box->[2] ];
		}
	}
	unshift(@_, $img, $box);
	goto &cvEllipseBox;
}

# ============================================================
#  core. The Core Functionality: XML/YAML Persistence
# ============================================================

package Cv;

our %CLASS = (
	&Cv::CV_TYPE_NAME_GRAPH      => 'Cv::Graph',
	&Cv::CV_TYPE_NAME_HAAR       => 'Cv::HaarClassifierCascade',
	&Cv::CV_TYPE_NAME_IMAGE      => 'Cv::Image',
	&Cv::CV_TYPE_NAME_MAT        => 'Cv::Mat',
	&Cv::CV_TYPE_NAME_MATND      => 'Cv::MatND',
	&Cv::CV_TYPE_NAME_SEQ        => 'Cv::Seq',
	&Cv::CV_TYPE_NAME_SEQ_TREE   => 'Cv::Seq',
	&Cv::CV_TYPE_NAME_SPARSE_MAT => 'Cv::SparseMat',
	);

package Cv::FileStorage;
{ *new = \&Cv::OpenFileStorage }

sub fsbless {
	my ($ptr) = @_;
	if (my $class = $Cv::CLASS{Cv::cvTypeOf($ptr)->type_name}) {
		bless $ptr, $class;
	}
	$ptr;
}


sub Cv::Load {
	ref (my $class = shift) and Carp::croak 'class name needed';
	Cv::FileStorage->Load(@_)
}


sub Load {
	ref (my $class = shift) and Carp::croak 'class name needed';
	my $ref = fsbless Cv::cvLoad(@_);
	Carp::croak "type_name unknown in ", (caller 0)[3]
		unless Scalar::Util::blessed $ref;
	$ref;
}


sub Read {
	my $ref = fsbless cvRead(@_);
	Carp::croak "type_name unknown in ", (caller 0)[3]
		unless Scalar::Util::blessed $ref;
	$ref;
}


sub ReadByName {
	my ($fs, $map, $name) = splice(@_, 0, 3);
	Carp::croak "instance variable needed" unless ref $fs;
	$fs->Read($fs->getFileNodeByName($map, $name), @_);
}


sub Cv::TypeInfo::DESTROY {}
sub Cv::FileNode::DESTROY {}
sub Cv::String::DESTROY {}

# ============================================================
#  core. The Core Functionality: Clustering
# ============================================================

# ============================================================
#  core. The Core Functionality: Utility and System Functions and Macros
# ============================================================

package Cv;

=head2 Error Handling

C<Cv> is now possible to detect errors that occur in the block
protected as eval { ... }. (Cv-0.13)

 my $img = eval { Cv->createImage([-1, -1], 8, 3) };
 if ($@) {
    print STDERR "*** got error ***";
 }

=cut

our %ERROR = (
	handler => undef,
	handler_sample => sub {
		my ($status, $func_name, $err_msg, $file_name, $line) = @_;
		Carp::croak("$func_name: @{[ cvErrorStr($status) ]} ($err_msg)");
	},
	mode => 0,
	status => undef,
	userdata => undef,
	);

our $ERROR = sub {
	my ($status, $func_name, $err_msg, $file_name, $line) = @_;
	cvSetErrStatus($status);
	$func_name ||= 'unknown function';
	my $mode = $ERROR{mode};
	if ($mode == 0 || $mode == 1) {
		if (my $handler = $ERROR{handler}) {
			&{$handler}(
				 $status, $func_name, $err_msg, $file_name, $line,
				 $ERROR{userdata},
			);
		}
	}
	my $long = join(' ', "OpenCV Error:", cvErrorStr($status), "($err_msg)",
					"in $func_name");
	my $short = "$func_name: @{[cvErrorStr($status)]} ($err_msg)";
	Carp::croak $long if $mode == 0;
};

# CV_IMPL void cvError(int code, const char* func_name,
#  const char* err_msg, const char* file_name, int line)
sub cvError {
	goto &$ERROR;
}

# CvErrorCallback cvRedirectError(
#  CvErrorCallback error_handler, void* userdata=NULL, void** prevUserdata=NULL)
sub cvRedirectError {
	my $handler; ($handler, $_[2]) = ($ERROR{handler}, $ERROR{userdata});
	($ERROR{handler}, $ERROR{userdata}) = @_[0..1];
	$handler;
}

sub cvGetErrStatus {
	$ERROR{status};
}

sub cvSetErrStatus {
	my $status = $ERROR{status};
	($ERROR{status}) = @_;
	$status;
}

sub cvGetErrMode {
	$ERROR{mode};
}

sub cvSetErrMode {
	my $mode = $ERROR{mode};
	($ERROR{mode}) = @_;
	$mode;
}


our %SIZEOF;

sub CV_SIZEOF {
	my ($name) = @_;
	my $size = $SIZEOF{$name};
	Carp::croak "unknwon type $name in CV_SIZEOF" unless defined $size;
	$size;
}


# ============================================================
#  imgproc. Image Processing: Image Filtering
# ============================================================

package Cv::Arr;

sub CopyMakeBorder {
	# CopyMakeBorder(src, dst, offset, bordertype, [value]);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvCopyMakeBorder;
}


sub Dilate {
	# Dilate(src, dst, [element], [iterations])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvDilate;
}


sub Erode {
	# Erode(src, dst, [element], [iterations])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvErode;
}


sub Filter2D {
	# Filter2D(src, dst, [kernel], [anchor])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvFilter2D;
}


sub Laplace {
	# Laplace(src, dst, [apertureSize])
	my $src = shift;
	my $dst = dst(@_) || $src->new(&Cv::CV_16SC($src->channels));
	unshift(@_, $src, $dst);
	goto &cvLaplace;
}


sub MorphologyEx {
	# MorphologyEx(src, dst, temp, element, operation, [iterations])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	if (@_) {
		my $temp = dst(@_);
		unless ($temp) {
			if ($_[1] == &Cv::CV_MOP_TOPHAT ||
				$_[1] == &Cv::CV_MOP_BLACKHAT) {
				$temp ||= $src->new;
			}
		}
		unshift(@_, $temp);
	}
	unshift(@_, $src, $dst);
	goto &cvMorphologyEx;
}


sub PyrDown {
	# PyrDown(src, dst, [filter]);
	my $src = shift;
	my $dst = dst(@_) || $src->new([map { int(($_ + 1) / 2) } @{$src->sizes}]);
	unshift(@_, $src, $dst);
	goto &cvPyrDown;
}


sub PyrUp {
	# PyrUp(src, dst, [filter]);
	my $src = shift;
	my $dst = dst(@_) || $src->new([map { int($_ * 2) } @{$src->sizes}]);
	unshift(@_, $src, $dst);
	goto &cvPyrUp;
}


sub Smooth {
	# Smooth(src, dst, [smoothtype], [param1], [param2], [param3], [param4])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvSmooth;
}


sub Sobel {
	# Sobel(src, dst, xorder, yorder, [apertureSize])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvSobel;
}


package Cv::ConvKernel;
{ *new = \&Cv::CreateStructuringElementEx }


# ============================================================
#  imgproc. Image Processing: Geometric Image Transformations
# ============================================================

package Cv;

sub GetRotationMatrix2D {
	# Cv->GetRotationMatrix2D($center, $angle, $scale, my $mapMatrix)
	my $class = shift;
	$_[3] ||= Cv::Mat->new([2, 3], &Cv::CV_32FC1) if @_ >= 3;
	goto &cvGetRotationMatrix2D;
}


sub GetAffineTransform {
	# Cv->GetAffineTransform($src, $dst, my $mapMatrix)
	my $class = shift;
	$_[2] ||= Cv::Mat->new([2, 3], &Cv::CV_32FC1) if @_ >= 2;
	goto &cvGetAffineTransform;
}


sub GetPerspectiveTransform {
	# Cv->GetPerspectiveTransform($src, $dst, my $mapMatrix)
	my $class = shift;
	$_[2] ||= Cv::Mat->new([3, 3], &Cv::CV_32FC1) if @_ >= 2;
	goto &cvGetPerspectiveTransform;
}


package Cv::Arr;

sub GetQuadrangleSubPix {
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvGetQuadrangleSubPix;
}

sub LinearPolar {
	# LinearPolar(src, dst, center, maxRadius, [flags]);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvLinearPolar;
}


sub LogPolar {
	# LogPolar(src, dst, center, M, [flags]);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvLogPolar;
}


sub Remap {
	# Remap(src, dst, mapx, mapy, [flags], [fillval])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvRemap;
}


sub Resize {
	# Resize(src, dst, [interpolation])
	my $src = shift;
	my $dst;
	if (@_ && ref $_[0] eq 'ARRAY') {
		my $sizes = shift;
		$dst = $src->new($sizes);
	} else {
		$dst = dst(@_) || $src->new;
	}
	unshift(@_, $src, $dst);
	goto &cvResize;
}


sub WarpAffine {
	# WarpAffine(src, dst, mapMatrix, [flags], [fillval])
	if (ref $_[1] && !ref $_[2]) {
		my $src = shift;
		unshift(@_, $src, $src->new);
	}
	goto &cvWarpAffine;
}


sub WarpPerspective {
	# WarpPerspective(src, dst, mapMatrix, [flags], [fillval])
	if (ref $_[1] && !ref $_[2]) {
		my $src = shift;
		unshift(@_, $src, $src->new);
	}
	goto &cvWarpPerspective;
}

# ============================================================
#  imgproc. Image Processing: Miscellaneous Image Transformations
# ============================================================

package Cv::Arr;

sub AdaptiveThreshold {
	# AdaptiveThreshold(src, dst, maxValue, [adaptive_method], [thresholdType], [blockSize], [param1])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvAdaptiveThreshold;
}

sub CvtColor {
	# cvtColor(src, [dst], code)
	# cvtColor(src, code, [dst])
	my $src = shift;
	my $dst = dst(@_);
	my $code = shift;
	Cv::usage("src, dst, code") unless defined $code;
	unless ($dst) {
		if ($code == &Cv::CV_BGR2RGB   || $code == &Cv::CV_RGB2BGR) {
			$dst = $src->new;
		} elsif ($code == &Cv::CV_BGR2GRAY  || $code == &Cv::CV_RGB2GRAY) {
			$dst = $src->new(&Cv::CV_MAKETYPE($src->type, 1));
		} elsif ($code == &Cv::CV_GRAY2BGR  || $code == &Cv::CV_GRAY2RGB  ||
				 $code == &Cv::CV_BGR2HSV   || $code == &Cv::CV_RGB2HSV   ||
				 $code == &Cv::CV_BGR2YCrCb || $code == &Cv::CV_RGB2YCrCb ||
				 $code == &Cv::CV_YCrCb2BGR || $code == &Cv::CV_YCrCb2RGB) {
			$dst = $src->new(&Cv::CV_MAKETYPE($src->type, 3));
		}
	}
	unshift(@_, $src, $dst, $code);
	goto &cvCvtColor;
}


sub DistTransform {
	# DistTransform(src, dst, [distance_type], [mask_size], [mask], [labels]);
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvDistTransform;
}


sub EqualizeHist {
	# EqualizeHist(src, dst)
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvEqualizeHist;
}


sub Inpaint {
	# Inpaint(src, mask, dst, inpaintRadius, flags)
	my ($src, $mask) = splice(@_, 0, 2);
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $mask, $dst);
	goto &cvInpaint;
}


sub Integral {
	# Integral(image, sum, [sqsum], [tiltedSum])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvIntegral;
}


sub PyrMeanShiftFiltering {
	# PyrMeanShiftFiltering(src, dst, sp, sr, [max_level], [termcrit])
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvPyrMeanShiftFiltering;
}


sub PyrSegmentation {
	# PyrSegmentation(src, dst, storage, comp, level, threshold1, threshold2)
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvPyrSegmentation;
}


sub Threshold {
	# Threshold(src, dst, threshold, maxValue, thresholdType)
	my $src = shift;
	my $dst = dst(@_) || $src->new(&Cv::CV_MAKETYPE($src->type, 1));
	unshift(@_, $src, $dst);
	goto &cvThreshold;
}

# ============================================================
#  imgproc. Image Processing: Structural Analysis and Shape Descriptors
# ============================================================

package Cv;

sub BoxPoints {
	ref (my $class = shift) and Carp::croak 'class name needed';
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my $box = $_[0];
	if ($O{boxhappy}) {
		if (&Cv::cvVersion() < 2.002) {
			$box = [ $box->[0], $box->[1], 90 - $box->[2] ];
		}
	}
	cvBoxPoints($box, my $pts);
	$_[1] = [] unless defined $_[1];
	@{ $_[1] } = @$pts if @_ >= 2;
	wantarray? @$pts : $pts;
}

# ============================================================
#  imgproc. Image Processing: Motion Analysis and Object Tracking
# ============================================================

# ============================================================
#  imgproc. Image Processing: Feature Detection
# ============================================================

package Cv::Arr;

sub Canny {
	# Canny(image, edges, threshold1, threshold2, aperture_size=3)
	my $src = shift;
	my $dst = dst(@_) || $src->new;
	unshift(@_, $src, $dst);
	goto &cvCanny;
}


sub CornerEigenValsAndVecs {
	# CornerEigenValsAndVecs(image, eigenvv, blockSize, aperture_size=3)
	my $src = shift;
	my $dst = dst(@_);
	$dst ||= $src->new([$src->rows, $src->cols * 6], &Cv::CV_32FC1);
	unshift(@_, $src, $dst);
	goto &cvCornerEigenValsAndVecs;
}


sub CornerHarris {
	# CornerHarris(image, harris_dst, blockSize, aperture_size=3, k=0.04)
	my $src = shift;
	my $dst = dst(@_) || $src->new(&Cv::CV_32FC1);
	unshift(@_, $src, $dst);
	goto &cvCornerHarris;
}


sub CornerMinEigenVal {
	# CornerMinEigenVal(image, eigenval, blockSize, aperture_size=3)
	my $src = shift;
	my $dst = dst(@_) || $src->new(&Cv::CV_32FC1);
	unshift(@_, $src, $dst);
	goto &cvCornerMinEigenVal;
}


# ============================================================
#  imgproc. Image Processing: Object Detection
# ============================================================

package Cv::Arr;

sub MatchTemplate {
	# MatchTemplate(image, templ, result, method)
	my $image = shift;
	my $templ = shift;
	my $result = dst(@_) || $templ && $templ->new(
		[ $image->rows - $templ->rows + 1,
		  $image->cols - $templ->cols + 1 ],
		&Cv::CV_32FC1);
	unshift(@_, $image, $templ, $result);
	goto &cvMatchTemplate;
}


# ============================================================
#  features2d. Feature Detection and Descriptor Extraction
# ============================================================

# ============================================================
#  flann. Clustering and Search in Multi-Dimensional Spaces
# ============================================================

# ============================================================
#  objdetect. Object Detection
# ============================================================

package Cv::HaarClassifierCascade;
{ *new = \&Cv::LoadHaarClassifierCascade }


# ============================================================
#  video. Video Analysis: Motion Analysis and Object Tracking
# ============================================================

package Cv::Kalman;
{ *new = \&Cv::CreateKalman }
{ *Correct = \&KalmanCorrect }
{ *Predict = \&KalmanPredict }


# ============================================================
#  highgui. High-level GUI and Media I/O: User Interface
# ============================================================

package Cv;

our %MOUSE = ( );
our %TRACKBAR = ( );

sub InitSystem {
	ref (my $class = shift) and Carp::croak 'class name needed';
	goto &cvInitSystem if cvHasQt();
	return undef;
}

package Cv::Arr;

{ *Show = \&ShowImage }
sub ShowImage {
	Cv::usage("image, name, flags=CV_WINDOW_AUTOSIZE")
		unless @_ >= 1 && @_ <= 3;
	my $image = shift;
	my $name = shift;
	$name = 'Cv' unless defined $name;
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	unless (Cv::cvGetWindowHandle($name)) {
		my @name_flags = ($name, splice(@_));
		Cv::cvNamedWindow(@name_flags);
	}
	Cv::cvShowImage($name, $image);
	$image;
}


# ============================================================
#  highgui. High-level GUI and Media I/O: Reading and Writing Images and Video
# ============================================================

package Cv::Arr;

sub EncodeImage {
	$_[2] = my $params = \0 unless defined $_[2];
	goto &cvEncodeImage;
}

package Cv::Image;
{ *Load = \&Cv::LoadImage }

package Cv::Mat;
{ *Load = \&Cv::LoadImageM }

package Cv::Arr;

{ *Save = \&SaveImage }
sub SaveImage {
	Cv::usage("image, filename, params=0")
		unless @_ >= 2 && @_ <= 3;
	my ($image, $filename) = splice(@_, 0, 2);
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my $r = &Cv::cvSaveImage($filename, $image, @_);
	$r > 0 ? $image : undef;
}

package Cv::Capture;
{ *FromCAM = \&Cv::CaptureFromCAM }
{ *FromFile = *FromAVI = \&Cv::CaptureFromFile }
{ *GetProperty = \&GetCaptureProperty }
{ *Grab = \&GrabFrame }
{ *Query = \&QueryFrame }
{ *Retrieve = \&RetrieveFrame }
{ *SetProperty = \&SetCaptureProperty }

package Cv::VideoWriter;
{ *new = \&Cv::CreateVideoWriter }


package Cv;

use Scalar::Util qw(looks_like_number);

sub CreateVideoWriter {
	ref (my $class = shift) and Carp::croak 'class name needed';
	my $filename = shift;
	my $fourcc = shift;
	$fourcc = CV_FOURCC($fourcc) unless looks_like_number($fourcc);
	unshift(@_, $filename, $fourcc);
	goto &cvCreateVideoWriter;
}


# ============================================================
#  calib3d. Camera Calibration, Pose Estimation and Stereo: Camera
#   Calibration and 3d Reconstruction
# ============================================================

package Cv::Arr;

{ *Cv::GetOptimalNewCameraMatrix = \&GetOptimalNewCameraMatrix }
sub GetOptimalNewCameraMatrix {
	$_[5] = my $newImageSize = [0, 0]    unless defined $_[5];
	$_[6] = my $validROI = \0            unless defined $_[6];
	$_[7] = my $centerPrincipalPoint = 0 unless defined $_[7];
	goto &cvGetOptimalNewCameraMatrix;
}

{ *Cv::StereoRectify = \&StereoRectify }
sub StereoRectify {
	$_[15] = my $roi1 = \0 unless defined $_[15];
	$_[16] = my $roi2 = \0 unless defined $_[16];
	goto &cvStereoRectify;
}

sub ProjectPoints2 {
	# ProjectPoints2($pts3d, $rvec, $tvec, $cmat, $dist, $pts2d);
	$_[5] ||= $_[0]->new(&Cv::CV_MAKETYPE($_[0]->type, 2));
	goto &cvProjectPoints2;
}


package Cv::StereoBMState;

{ *new = \&Cv::CreateStereoBMState }
{ *FindStereoCorrespondence = *FindCorrespondence = \&FindStereoCorrespondenceBM }

package Cv::StereoGCState;

if (Cv->can('cvCreateStereoGCState')) {
	*new = \&Cv::CreateStereoGCState;
	*FindStereoCorrespondence = *FindCorrespondence =
		\&FindStereoCorrespondenceGC;
}

package Cv::StereoSGBM;

if (__PACKAGE__->can('new')) {
	*Cv::CreateStereoSGBM = sub {
		ref (my $class = shift) and Carp::croak 'class name needed';
		unshift(@_, __PACKAGE__);
		goto &{__PACKAGE__ . '::new'};
	};
	*FindStereoCorrespondence = *FindCorrespondence =
		\&FindStereoCorrespondenceSGBM;
}


# ============================================================
#  ml. Machine Learning
# ============================================================


# ============================================================
#  misc.
# ============================================================

package Cv;

sub cvHasGUI {
	if (fork) {
		wait;
		$? == 0;
	} else {
		if (Cv->can('cvNamedWindow')) {
			open(STDERR, ">/dev/null");
			cvNamedWindow("Cv");
			cvDestroyWindow("Cv");
			exit(0);
		} 
		exit(1);
	}
}

sub GetBuildInformation {
	ref (my $class = shift) and Carp::croak 'class name needed';
	our $BuildInformation;
	if (Cv->version >= 2.004) {
		$BuildInformation = cvGetBuildInformation()
			unless defined $BuildInformation;
	}
	$BuildInformation ||= '';
	our %BuildInformation = ();
	unless (%BuildInformation) {
		for ($BuildInformation) {
			my $g = '';
			for (split(/\n/)) {
				s/^\s+//;
				s/\s+$//;
				if (s/([^\:]+):\s*//) {
					my $k = $1;
					if (/^$/) {
						$g = $k;
					} elsif ($g) {
						$BuildInformation{$g}{$k} = $_;
					} else {
						$BuildInformation{$k} = $_;
					}
				} else {
					$g = undef;
				}
			}
		}
	}
	wantarray? %BuildInformation : $BuildInformation;
}

sub HasModule {
	ref (my $class = shift) and Carp::croak 'class name needed';
	our %OpenCV_modules;
	unless (%OpenCV_modules) {
		my %x = Cv->GetBuildInformation();
		if (my $m = $x{q(OpenCV modules)}) {
			$OpenCV_modules{$_}++ for split(/\s+/, $m->{'To be built'});
			delete $OpenCV_modules{$_} for split(/\s+/, $m->{Disabled});
			delete $OpenCV_modules{$_} for split(/\s+/, $m->{Unavailable});
		}
	}
	grep { $OpenCV_modules{$_} } @_ ? @_ : keys %OpenCV_modules;
}

sub cvHasQt {
	my $hasQt;
	my %x = Cv->GetBuildInformation;
	while (my ($k, $v) = each %{$x{GUI}}) {
		$hasQt = $k if ($k =~ /^QT \d\.\w+$/i && $v =~ /^YES\.*/i)
	}
	unless ($hasQt) {
		$hasQt = 1 if Cv->can('cvFontQt');
	}
	$hasQt;
}

1;
__END__

=head2 EXPORT

You put names after use Cv, constants, functions ... to be
imported. (Cv-0.14)

=over 4

=item *

For example, the following two lines to import functions such as
cvScalar() and the constants starting with C<IPL> and C<CV>.

 use Cv qw(:std);
 use Cv;			# considering :std

=item *

For example, the following two lines to import all variables and
functions of Cv.

 use Cv qw(:all);
 use Cv qw(/^(CV|IPL|cv)/);

=item *

If you do not want to import anything, put an empty list.

 use Cv ( );

=back


=head2 TIPS

We'll show you the tips about using C<Cv> that we studied from users.

=over 4

=item *

You can use EncodeImage() and Ptr() when you want to output images in
your CGI without saving to the files.

 use Cv;
 my $img = Cv::Image->new([240, 320], CV_8UC3);
 $img->zero->circle([ 100, 100 ], 100, CV_RGB(255, 100, 100));
 print "Content-type: image/jpg\n\n";
 print $img->encodeImage(".jpg")->ptr;

You can use that to convert for Imager.

 use Imager;
 my $imager = Imager->new(data => $img->encodeImage(".ppm")->ptr);

=item *

We have a configuration to use C<Inline C>.  This makes it easy to
test and extend a variety. How easy is as follows.

 use Cv::Config;
 use Inline C => Config => %Cv::Config::C;

=back

=head1 SAMPLES

We rewrote some OpenCV samples in C<Cv>, and put them in sample/.

 bgfg_codebook.pl calibration.pl camshiftdemo.pl capture.pl
 contours.pl convexhull.pl delaunay.pl demhist.pl dft.pl distrans.pl
 drawing.pl edge.pl facedetect.pl fback_c.pl ffilldemo.pl find_obj.pl
 fitellipse.pl houghlines.pl image.pl inpaint.pl kalman.pl kmeans.pl
 laplace.pl lkdemo.pl minarea.pl morphology.pl motempl.pl
 mser_sample.pl polar_transforms.pl pyramid_segmentation.pl squares.pl
 stereo_calib.pl stereo_match.pl tiehash.pl video.pl watershed.pl

=head1 BUGS

=over 4

=item *

Threshold() updates the parameter threshold if threshold-type is
CV_THRESH_OTSU.  It looks like perl magic.  So, you can use
Threshold() is as follows:

 my $bin = $gray->threshold(my $thresh, 255, CV_THRESH_OTSU);

=item *

Constants used in the Perl world is converted into lib/Cv/Constant.pm
from the header file using h2ph.  If it failed, the version of the
installed OpenCV is checked, and copied from the fallback/.

=cut


=item *

In the version 0.07, we decided to remove keyword parameter.  Because
of that has large overhead. In this version, we decided to remove
C<Cv::TieHash> and C<Cv::TieArr>, too.  See C<sample/tiehash.pl>.

=item *

On cygwin, it is necessary to compile OpenCV. 

=item *

The following names that are the kind of alias are obsolete.  Use the
original names C<CV_SOMETHING> because they are shorter.  (Cv-0.13)

 Cv::MAKETYPE, Cv::MAT_DEPTH, Cv::MAT_CN, Cv::MAT_TYPE, Cv::ELEM_SIZE,
 Cv::NODE_TYPE, Cv::IS_SET_ELEM, Cv::SIZEOF

=item *

Usage of the CV_SIZEOF has changed.  Write the name of structure of
OpenCV that you want to know the size as follows. (Cv-0.13)

 CV_SIZEOF('CvContour')

=item *

When you don't like use Cv::More, you can put qw(:nomore) as use
Cv option, and you could also put -more between 0.20 and 0.23.
However, it was confusing to us, we have to change -nomore. (0.24)

=back

=head1 SEE ALSO

http://github.com/obuk/Cv-Olive


=head1 AUTHOR

MASUDA Yuta E<lt>yuta.cpan@gmail.comE<gt>

=head1 LICENCE

Copyright (c) 2010, 2011, 2012, 2013 by MASUDA Yuta.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
