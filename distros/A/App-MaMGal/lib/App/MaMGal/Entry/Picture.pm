# mamgal - a program for creating static image galleries
# Copyright 2007-2010 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# The picture encapsulating class
package App::MaMGal::Entry::Picture;
use strict;
use warnings;
use base 'App::MaMGal::Entry';
use Carp;
use App::MaMGal::Exceptions;

sub make
{
	my $self = shift;
	my %opts = @_;
	my $force_slide = $opts{force_slide} || 0;
	return ($self->refresh_scaled_pictures, $self->refresh_slide($force_slide));
}

sub refresh_slide
{
	my $self = shift;
	my $force = shift;
	my $tools = $self->tools or croak "Tools were not injected";
	my $formatter = $tools->{formatter} or croak "Formatter required";
	ref $formatter and $formatter->isa('App::MaMGal::Formatter') or croak "Arg is not a formatter";

	$self->container->ensure_subdir_exists($self->slides_dir);
	my $name = $self->{dir_name}.'/'.$self->page_path;
	$self->container->_write_contents_to(sub { $formatter->format_slide($self) }, $self->page_path) unless ($self->fresher_than_me($name) and not $force);
	return $self->page_path;
}

sub refresh_miniatures
{
	my $self = shift;
	my @miniatures = @_ or croak "Need args: miniature specifications";
	my $i = undef;
	my $r;
	my @ret;
	foreach my $miniature (@miniatures) {
		my ($subdir, $x, $y, $suffix) = @$miniature;
		my $relative_name = $subdir.'/'.$self->{base_name}.($suffix ? $suffix : '');
		push @ret, $relative_name;
		my $name = $self->{dir_name}.'/'.$relative_name;
		next if $self->fresher_than_me($name);
		# loading image data deferred until it's necessary
		$i = $self->read_image unless defined $i;
		$r = $self->scale_into($i, $x, $y) and App::MaMGal::SystemException->throw(message => '%s: scaling failed: %s', objects => [$name, $r]);
		$self->container->ensure_subdir_exists($subdir);
		$r = $i->Write($name)              and App::MaMGal::SystemException->throw(message => '%s: writing failed: %s', objects => [$name, $r]);
	}
	return @ret;
}

sub is_interesting { 1; }
sub page_path { $_[0]->slides_dir.'/'.$_[0]->{base_name}.'.html' }
sub thumbnail_path { $_[0]->thumbnails_dir.'/'.$_[0]->{base_name} }
sub tile_path { $_[0]->{dir_name}.'/'.$_[0]->thumbnail_path }

# This method does not operate on App::MaMGal::Entry::Picture, but this was the most
# appropriate place to put it into.  At least until we grow a "utils" class.
sub scale_into
{
	my $that = shift;
	my $img = shift;
	ref($img) and $img->isa('Image::Magick') or croak "Need arg: an image";
	my ($x, $y) = @_;

	my $r;
	my ($x_pic, $y_pic) = $img->Get('width', 'height');
	my ($x_ratio, $y_ratio) = ($x_pic / $x, $y_pic / $y);
	if ($x_ratio <= 1 and $y_ratio <= 1) {
		return; # no need to scale
	} elsif ($x_ratio > $y_ratio) {
		return $img->Scale(width => $x, height => $y_pic / $x_ratio);
	} else {
		return $img->Scale(height => $y, width => $x_pic / $y_ratio);
	}
}

1;
