# mamgal - a program for creating static image galleries
# Copyright 2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# A wrapper class for the Image::ExifTool library.
package App::MaMGal::ImageInfo::ExifTool;
use strict;
use warnings;
use base 'App::MaMGal::ImageInfo::Base';
use Carp;

use Image::ExifTool 'ImageInfo';

sub get_info
{
	my $self = shift;
	my $file = shift;
	my $tool = Image::ExifTool->new;
	my $ret = $tool->ExtractInfo($file, [qw(Comment exif:CreateDate exif:ModifyDate exif:DateTimeOriginal)]);
	my $info = $tool->GetInfo;
	croak $info->{Error} unless $ret;
	return $info;
}

sub datetime_original_string
{
	my $self = shift;
	$self->{info}->{DateTimeOriginal};
}

sub datetime_digitized_string
{
	my $self = shift;
	$self->{info}->{CreateDate};
}

sub datetime_string
{
	my $self = shift;
	$self->{info}->{ModifyDate};
}

sub description
{
	my $self = shift;
	$self->{info}->{Comment};
}

1;
