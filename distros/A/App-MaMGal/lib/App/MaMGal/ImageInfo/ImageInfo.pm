# mamgal - a program for creating static image galleries
# Copyright 2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# A wrapper class for the Image::Info library.
package App::MaMGal::ImageInfo::ImageInfo;
use strict;
use warnings;
use base 'App::MaMGal::ImageInfo::Base';
use Carp;

use Image::Info;

sub get_info
{
	my $self = shift;
	my $file = shift;
	my $info = Image::Info::image_info($file);
	croak $info->{error} if exists $info->{error};
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
	$self->{info}->{DateTimeDigitized};
}

sub datetime_string
{
	my $self = shift;
	$self->{info}->{DateTime};
}

sub description
{
	my $self = shift;
	$self->{info}->{Comment};
}

1;
