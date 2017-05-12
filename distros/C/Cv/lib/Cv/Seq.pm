# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

package Cv::Seq;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.29';

use Cv::Seq::Point;
use Cv::Seq::Point2;
use Cv::Seq::Circle;
use Cv::Seq::Rect;
use Cv::Seq::SURFPoint;
use Cv::Seq::SURFDescriptor;

package Cv::Seq::Seq;

# our @ISA = qw(Cv::Seq);

{ *Get = \&GetSeqElem }
{ *Push = \&SeqPush }

package Cv::Seq;

for (
	"Cv::Seq",
	"Cv::Seq::Circle",
	"Cv::Seq::Point",
	"Cv::Seq::Point2",
	"Cv::Seq::Rect",
	"Cv::Seq::SURFPoint",
	"Cv::Seq::Seq",
	"Cv::SeqReader",
	"Cv::SeqWriter",
	) {
	{ no strict 'refs'; *{$_ . '::AUTOLOAD'} = \&Cv::autoload }
}


our %TEMPLATE;

sub template {
	my $self = CORE::shift;
	unless (defined $TEMPLATE{&Cv::CV_32SC2}) {
		foreach my $cn (1 .. 4) {
			$TEMPLATE{&Cv::CV_8SC(  $cn )} = [ "c$cn", $cn ];
			$TEMPLATE{&Cv::CV_8UC(  $cn )} = [ "C$cn", $cn ];
			$TEMPLATE{&Cv::CV_16SC( $cn )} = [ "s$cn", $cn ];
			$TEMPLATE{&Cv::CV_16UC( $cn )} = [ "S$cn", $cn ];
			$TEMPLATE{&Cv::CV_32SC( $cn )} = [ "i$cn", $cn ];
			$TEMPLATE{&Cv::CV_32FC( $cn )} = [ "f$cn", $cn ];
			$TEMPLATE{&Cv::CV_64FC( $cn )} = [ "d$cn", $cn ];

		}
	}
	return undef unless ref $self && $self->UNIVERSAL::can('mat_type');
	wantarray ? @{$TEMPLATE{$self->mat_type}} : $TEMPLATE{$self->mat_type}[0];
}


our $FLAGS = &Cv::CV_32SC2;
our @SIZES = (0, 0);

sub new {
	my $self = CORE::shift;
	my $stor = Cv::stor(@_);
	my $sizes = @_ && ref $_[0] eq 'ARRAY' ? CORE::shift : undef;
	my ($hSize, $eSize) = $sizes ? @$sizes : @SIZES;
	my $flags = @_ ? CORE::shift : ref $self ? $self->type : undef;
	my $class = $self->isa('Cv::Seq') && $self || __PACKAGE__;
	$class = ref $class if ref $class;
	$class->CreateSeq($flags, $hSize, $eSize, $stor);
}


{ *Cv::CreateSeq = \&CreateSeq }
sub CreateSeq {
	# CvSeq* cvCreateSeq(
	#	int seqType, int headerSize, int elemSize,
	#	CvMemStorage* storage)
	ref (my $class = CORE::shift) and Carp::croak 'class name needed';
	my $stor = Cv::stor(@_);
	my $flags = CORE::shift;
	$flags = $FLAGS unless defined $flags;
	my $hSize = CORE::shift || $SIZES[0] || &Cv::CV_SIZEOF('CvSeq');
	my $eSize = CORE::shift || $SIZES[1] || &Cv::CV_ELEM_SIZE($flags);
	bless Cv::cvCreateSeq($flags, $hSize, $eSize, $stor), $class;
}


sub MakeSeqHeaderForArray {
	# CvSeq* cvMakeSeqHeaderForArray(
	# 	int seqType, int headerSize, int elemSize,
	#	void* elements, int total, CvSeq* seq, CvSeqBlock* block)
	ref (my $class = CORE::shift) and Carp::croak 'class name needed';
	my $flags = CORE::shift;
	$flags = $FLAGS unless defined $flags;
	my $hSize = CORE::shift || $SIZES[0] || &Cv::CV_SIZEOF('CvSeq');
	my $eSize = CORE::shift || $SIZES[1] || &Cv::CV_ELEM_SIZE($flags);
	bless Cv::cvMakeSeqHeaderForArray($flags, $hSize, $eSize, @_), $class;
}


sub Pop {
	my $self = CORE::shift;
	$self->cvSeqPop;
}


sub Push {
	my $self = CORE::shift;
	$self->cvSeqPush($_) for @_;
	$self;
}


sub Shift {
	my $self = CORE::shift;
	$self->cvSeqPopFront;
}


sub Unshift {
	my $self = CORE::shift;
	$self->cvSeqPushFront($_) for @_;
	$self;
}


sub Splice {
	# splice($array, $offset, $length, @list)
	# splice($array, $offset, $length)
	# splice($array, $offset)
	my $array = CORE::shift;
	my $offset = CORE::shift;
	my $length = @_? CORE::shift : $array->total - $offset;
	my @le = ();
	foreach (0 .. $offset - 1) {
		CORE::push(@le, scalar $array->Shift);
	}
	my @ce = ();
	foreach (0 .. $length - 1) {
		CORE::push(@ce, scalar $array->Shift);
	}
	$array->Unshift(@le, @_);
	wantarray? @ce : \@ce;
}

{ *cvCvtSeqToArray = \&Cv::Arr::cvCvtSeqToArray }
{ *cvGetSeqElem = \&Cv::Arr::cvGetSeqElem }
{ *cvSetSeqElem = \&Cv::Arr::cvSetSeqElem }
{ *cvSeqInvert = \&Cv::Arr::cvSeqInvert }
# { *ToArray = \&CvtSeqToArray }
{ *Get = \&GetSeqElem }
{ *Set = *set = \&SetSeqElem }
{ *Invert = *Reverse = *SeqInvert = \&SeqInvert }

1;
__END__
