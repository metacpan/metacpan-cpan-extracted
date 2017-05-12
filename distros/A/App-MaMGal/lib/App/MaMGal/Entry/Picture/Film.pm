# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# The picture encapsulating class
package App::MaMGal::Entry::Picture::Film;
use strict;
use warnings;
use base 'App::MaMGal::Entry::Picture';
use App::MaMGal::VideoIcon;
use Carp;
use Scalar::Util 'blessed';

my $thumbnail_extension = '.png';

sub refresh_scaled_pictures
{
	my $self = shift;
	return $self->refresh_miniatures([$self->thumbnails_dir, 200, 150, $thumbnail_extension]);
}

sub _new_video_icon
{
	my $self = shift;
	my $s = Image::Magick->new(magick => 'png');
	$s->BlobToImage(App::MaMGal::VideoIcon->img);
	$s;
}

sub read_image
{
	my $self = shift;
	my $tools = $self->tools or croak "Tools were not injected.";
	my $w = $tools->{mplayer_wrapper} or croak "MplayerWrapper required.";
	my $s;
	eval { $s = $w->snapshot($self->{path_name}); };
	if ($@) {
		if (blessed($@) and (
			$@->isa('App::MaMGal::MplayerWrapper::NotAvailableException')
			or
			$@->isa('App::MaMGal::MplayerWrapper::ExecutionFailureException')
		)) {
			$self->logger->log_exception($@, $self->{path_name});
			$s = $self->_new_video_icon;
		} else {
			die $@;
		}
	}
	return $s;
}

sub thumbnail_path { $_[0]->SUPER::thumbnail_path.$thumbnail_extension }

1;
