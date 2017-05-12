# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# The picture encapsulating class
package App::MaMGal::Entry::Picture::Static;
use strict;
use warnings;
use base 'App::MaMGal::Entry::Picture';
use Carp;
use Image::Magick;
use POSIX;

sub init
{
	my $self = shift;
	$self->SUPER::init(@_);
}

sub refresh_scaled_pictures
{
	my $self = shift;
	return $self->refresh_miniatures([$self->medium_dir, 800, 600], [$self->thumbnails_dir, 200, 150]);
}

sub image_info
{
	my $self = shift;
	return $self->{image_info} if exists $self->{image_info};
	croak 'image info factory not injected' unless defined $self->tools->{image_info_factory};
	$self->{image_info} = eval { $self->tools->{image_info_factory}->read($self->{path_name}); };
	$self->logger->log_message("Cannot retrieve image info: ".$@, $self->{path_name}) if $@;
	return $self->{image_info};
}

sub description
{
	my $self = shift;
	my $i = $self->image_info or return;
	return $i->description;
}

sub read_image
{
	my $self = shift;
	my $i = Image::Magick->new;
	my $r;
	$r = $i->Read($self->{path_name}) and App::MaMGal::SystemException->throw(message => '%s: reading failed: %s', objects => [$self->{path_name}, $r]);
	return $i;
}

sub creation_time
{
	my $self = shift;
	my $info = $self->image_info or return $self->SUPER::creation_time(@_);
	return $info->creation_time || $self->SUPER::creation_time(@_);
}

1;
