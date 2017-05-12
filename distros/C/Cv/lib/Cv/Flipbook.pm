# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

package Cv::Flipbook;

use 5.008008;
use strict;
use warnings;
use Carp;
use File::Basename;
use Cv;

our $VERSION = '0.29';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

sub DESTROY { }

{ no strict 'refs'; *AUTOLOAD = \&Cv::autoload; }

{
	package Cv;
	sub CaptureFromFlipbook {
		my $class = shift;
		Cv::Flipbook->new(@_);
	}
}

{
	package Cv::Capture;
	*FromFlipbook = \&Cv::CaptureFromFlipbook;
}

sub new {
    my $class = shift;
	my $dir = shift || ".";
	my $flags = shift;
	$flags = &Cv::CV_LOAD_IMAGE_COLOR unless defined $flags;
	my $pattern = shift || [
		"*.bmp", "*.BMP", "*.jpg", "*.JPG", "*.png", "*.PNG",
		];
	my $self;
	if (-d $dir) {
		if (my $list = list($dir, $pattern)) {
			$self = bless {
				dir => $dir,
				files => $list,
				flags => $flags,
				pattern => $pattern,
			}, $class;
			$self->{&Cv::CV_CAP_PROP_FRAME_COUNT} = scalar @$list;
			$self->{&Cv::CV_CAP_PROP_FPS} = 0;
			$self->{&Cv::CV_CAP_PROP_POS_FRAMES} = 0;
			$self->{&Cv::CV_CAP_PROP_POS_MSEC} = 0;
		}
	}
	$self;
}

sub list { 
	my $dir = shift;
	my @files = ();
	foreach (@_) {
		if (ref $_) {
			if (my $list = list($dir, @{$_})) {
				push(@files, @$list);
			}
		} else {
			push(@files, map { $_->[0] } sort { $a->[1] <=> $b->[1] } map {
				basename($_) =~ /\d+/; [ $_, $& ];
				 } glob("$dir/$_"));
		}
	}
	return undef unless @files && -f $files[0];
	wantarray ? @files : \@files;
}

{ *Grab = \&GrabFrame }
sub GrabFrame {
	my $self = shift;
	my $i = $self->{&Cv::CV_CAP_PROP_POS_FRAMES};
	if ($i >= 0 && $i < $self->{&Cv::CV_CAP_PROP_FRAME_COUNT}) {
		$self->{file} = ${$self->{files}}[$i];
	} else {
		$self->{file} = undef;
	}
}

sub NextFrame {
	my $self = shift;
	$self->{&Cv::CV_CAP_PROP_POS_FRAMES}++;
}

{ *Retrieve = \&RetrieveFrame }
sub RetrieveFrame {
	my $self = shift;
	if ($self->{file}) {
		if (my $image = Cv->LoadImage($self->{file}, $self->{flags})) {
			if ($self->{&Cv::CV_CAP_PROP_FPS}) {
				$self->{&Cv::CV_CAP_PROP_POS_MSEC} =
					1000 * $self->{&Cv::CV_CAP_PROP_POS_FRAMES} /
					$self->{&Cv::CV_CAP_PROP_FPS};
			}
			$self->{&Cv::CV_CAP_PROP_FRAME_WIDTH} = $image->width;
			$self->{&Cv::CV_CAP_PROP_FRAME_HEIGHT} = $image->height;
			$self->NextFrame;
			return $image;
		}
	}
	undef;
}

{ *Query = \&QueryFrame }
sub QueryFrame {
	my $self = shift;
	$self->GrabFrame && $self->RetrieveFrame;
}

{ *GetProperty = \&GetCaptureProperty }
sub GetCaptureProperty {
	my $self = shift;
	my $property = shift;
	$self->{$property};
}

{ *SetProperty = \&SetCaptureProperty }
sub SetCaptureProperty {
	my $self = shift;
	my $property = shift;
	my $value = shift;
	$self->{$property} = $value;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=encoding utf8

=head1 NAME

Cv::Flipbook - Handle flipbook like a video.

=head1 SYNOPSIS

 use Cv;
 use Cv::Flipbook;
 
 my $capture = Cv->CaptureFromFlipbook("/path/to/flipbook");
 while (my $frame = $capture->QueryFrame) {
   $frame->Flip(\0, 1)->ShowImage;
   my $c = Cv->WaitKey(100);
   last if $c >= 0;
 }

=head1 DESCRIPTION

Read sequential image files in the directory, C<Cv::Flipbook> is
treated as a video input it.

It is important to note the following points.

=over

=item * Align the size of all images.

=item * Include the file name number for ordering.

=back

=head1 SEE ALSO

L<Cv>

=head1 AUTHOR

MASUDA Yuta E<lt>yuta.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by MASUDA Yuta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
