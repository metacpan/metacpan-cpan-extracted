# mamgal - a program for creating static image galleries
# Copyright 2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# A base class for the image info library wrappers.
package App::MaMGal::ImageInfo::Base;
use strict;
use warnings;
use base 'App::MaMGal::Base';
use Carp;

sub init
{
	my $self = shift;
	my $file = shift or croak 'filename not provided';
	$self->{info} = $self->get_info($file);
	$self->{file_name} = $file;
}

sub get_info { croak "Missing implementation" }

my %methods_to_tags = (
	datetime_original_string  => '0x9003',
	datetime_digitized_string => '0x9004',
	datetime_string           => '0x0132',
);

sub creation_time
{
	my $self = shift;
	foreach my $type (qw(_original_ _digitized_ _)) {
		my $method = "datetime${type}string";
		my $string = $self->$method;
		next unless $string;
		my $value = eval { $self->{parser}->parse($string); };
		my $e = $@;
		return $value if $value;
		if ($e) {
			chomp $e;
			$self->{logger}->log_message(sprintf('EXIF tag %s: %s', $methods_to_tags{$method}, $e), $self->{file_name});
		}
	}
	return undef;
}

# EXIF v2.2 tag 0x9003 DateTimeOriginal
# "when the original image data was generated"
#
# aka. Date/Time Original (exiftool output)
# aka. DateTimeOriginal (Image::ExifTool::Exif)
# aka. DateTimeOriginal (Image::Info, Image::TIFF)
sub datetime_original_string { croak "Missing implementation" }

# EXIF v2.2 tag 0x9004 DateTimeDigitized
# "when the image was stored as digital data"
#
# aka. Create Date (exiftool output)
# aka. CreateDate (Image::ExifTool::Exif)
# aka. DateTimeDigitized (Image::Info, Image::TIFF)
sub datetime_digitized_string { croak "Missing implementation" }

# EXIF v2.2 tag 0x0132 DateTime
# "of image creation"
#
# aka. Modify Date (exiftool output)
# aka. ModifyDate (Image::ExifTool::Exif)
# aka. DateTime (Image::Info, Image::TIFF)
sub datetime_string { croak "Missing implementation" }

sub description { croak "Missing implementation" }

1;
