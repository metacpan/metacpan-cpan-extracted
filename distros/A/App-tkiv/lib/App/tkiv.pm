#!/usr/bin/perl

package App::tkiv;

use strict;
use warnings;

our $VERSION = "0.132";

1;

__END__

=encoding UTF-8

=head1 NAME

App::tkiv - An image viewer in Perl::Tk based on IrfanView

=head1 SYNOPSIS

 $ iv [-v[#]] [-f] [-1|-s] [option=value ...] [dir]

 $ iv -f imageposition=s thumsorting=size .

=head1 DESCRIPTION

C<iv> is a pure-perl application that was written to mimic the behavior
of the image view and manipulation program C<irfanview>, which is available
as freeware on Windows.

Linux already offers many free image view and manipulation programs, but
none gave me the key-driven approach that I liked in IrfanView, and most
left traces of what was viewed in hidden files (thumbnail previews etc).

C<iv> is not written to be a I<better> image viewer. It is written to
prove such an application can be written in perl and still is fast and
versatile enough to need my (own) needs.

C<iv> is not aiming for a complete rewrite of IrfanView.

=head1 Command Line Arguments

=over 2

=item -v[#]

Set verbose level. Default value is 0. A plain -v without value will set
the level to 1.

=item -f

Start in full-screen mode. Thumbnail view will not be full-screen, but the
displayed images will. This overrules the default option from .ivrc files.

=item -s

Start the slideview on open automatically.

=item -1

After populating the thumbnail view, immediately display the first image
and minimize the thumbnail view.

=back

=head2 Options

Options are case insensitive. They are read from /etc/iv.rc, /etc/.ivrc,
~/iv.rc, ~/.ivrc, ./iv.rc, ./.ivrc, image_dir/iv.rc and image_dir/.ivrc
(in that order if available).

Not (yet) local per dir, so the last one read stays active and overrules
the previous settings.

    thumbSize		=> 80,		# in pixels
	size of the thumbnails in the thumbview. default 80x80

    thumbRows		=> 5,
	number of rows in the thumbview. default 5

    thumbPosition	=> "se",
	position of the thumbview on the screen. default se (bottom right)
	possible values: n, ne, e, se, s, sw, w, nw, c

    thumbRefresh	=> 1,
	when deleting images, the thumb preview is also deleted, and all
	thumbs then have to be re-displayed in order to fill the gap. When
	deleting images out of a long sequence, this will take a long time.
	Disabling the refresh will make the cleanup procedure go faster,
	but will cause errors/warnings when you re-visit the thumb that
	has been deleted

    thumbSorting	=> "default",
	defines the ordering of the thumbnails in the thumbview.

	default	: on the numeric part of the image name, then on the full name
	caseless: on the lower-cased image name
	date	: on mtime
	size	: on (file) size
	random	: random

    thumbSortOrder	=> "ascending",
	ordering of the thumbs. default ascending. possible values ascending
	or descending

    imagePosition	=> "nw",
	position of the image window. default nw (top-left)
	possible values: n, ne, e, se, s, sw, w, nw, c

    imageDir		=> ".",
	default image dir (current folder)

    slideShowDelay	=> 1500,	# in milliseconds
	in slide shows, define the display time for each image. default: 1500 ms

    slidePosition	=> "c",
	position of the full image in slide-show mode. default c (center)
	possible values: n, ne, e, se, s, sw, w, nw, c

    slideFull		=> 0,
	display images auto-fit in slide-show mode. default 0 (off)

    slideCover		=> 0,
	EXPERIMENTAL
	cover the background when in slideshow mode

    titleDirs		=> 0
	The number of dir levels (counted from the end) that should be included
	in the image title

    titleIndex		=> 0
	display the index of the image in the image title. (default off)
	When on, the title of the image window is extended with " n/N", where
	n is the index and N is the total number of images in the current
	thumb-view

    maxX		=> 9999,
	maximum horizontal resolution (some size quests are unreliable)

    maxY		=> 9999,
	maximum vertical resolution (some size quests are unreliable)

    smallFont		=> "{Liberation Mono} 8",",
	define the font for labels

    selectionFont	=> "{Liberation Sans} 5",
	the font used to display information with the selection rectangle

    selectionColor	=> "Yellow",
	the color used when drawing selection rectangles

    confirmDelete	=> 1,
	ask for confirmation when deleting images. default 1 (true)

    removeTarget	=> 0,
	remove target folder when it is empty. default 0 (false)

    imageFull		=> 0,
	show images full-screen. default 0 (off). Full-screen resizes the
	image to automatically fit the screen height or screen-width when
	maintaining aspect ratio. Also sometimes called auto-fit.

    lastFirstNext	=> 0,
	If set will cause keys_nextpic on the last pic to open the first
	pic of the next set as if keys_firstnext was used

    showExifInfo	=> 0,
	show a summary of the exif info of the image on the image

    exifInfoColor	=> "Blue",
	the color if the exif info text on the image for showexifinfo

    decoration		=> 1,
	show the screen control elements. Default 1 (on). Some window
	managers support full control, either by keys or mouse, even when
	the borders and title bar are gone. Some refuse to do scroll bars
	and such when the decoration is disabled. YMMV

    scrollSpeed		=> 3,
	The default scroll increments for Tk::Canvas is a bit too course
	for fine-grained scrolling. A low value enables precise positioning
	with the scroll wheel, high values scroll fast.

    dirTreeStartPos	=> 0.,
	The initial position of the dir tree view relative from the top.
	The default is to show the top of the tree if there is more than
	the current window to be viewed and a scrollbar is shown. Setting
	dirTreeStartPos to 1. will show the bottom of the tree on startup.
	A value of .5 will show the middle.

=head2 Key bindings

Key bindings. Most are the same as the windows program IrfanView, after
which iv was initially modeled

			Thumb view		Image view
  keys_quit

    q ESC		Quit program		Close image,
						return to thumbs

  keys_quit_all

    Q Control-q		Quit program		Quit program

  keys_options

    o			Open option window	-

  keys_firstpic

    0 1 a		Open first pic		id

  keys_prevpic

    Left Up BS		Prev pic (round robin)	id

  keys_nextpic

    Space Right Down	Next pic		id
			 When LastFirstNext is false (default), this
			 will round-robin to the first pic, otherwise
			 it will open the first pic in the next set

  keys_lastpic

    9 z			Open last pic		id

  keys_firstnext

    v			-			Open first pic in next folder

  keys_firstprev

    ^			-			Open first pic in prev folder

  keys_fullscreen

    f F11		-			Toggle auto-fit

  keys_fitwidth

    b			-			Zoom to fit screen-width

  keys_fitheight

    h			-			Zoom to fit screen-height

  keys_origsize

    o			-			Display in original size

  keys_full_toggle

    Alt-f		-			Toggle auto-fit and remember
						for next sets

  keys_full_rc

    F			-			Switch to auto-fit and save
						in ./.ivrc

  keys_rotleft

    l			-			Rotate image left (90°
						anti-clockwise)

  keys_rotexifl

    L			-			Rotate image left (90° anti-
						clockwise) in the EXIF info,
						and store the change in the
						image file

  keys_rotright

    r			-			Rotate image right (90°
						clockwise)

  keys_rotexifr

    R			-			Rotate image right (90°
						clockwise) in the EXIF info,
						and store the change in the
						image file
  keys_zoomin

    plus		-			Zoom in with 20% steps.

  keys_zoomout

    minus		-			Zoom out with 20% steps.

  keys_delete

    Delete		-			Delete image from disk

  keys_slideshow

    w s			Start slideshow		id

  keys_exif

    i			-			Show EXIF info

  keys_exifinfo

    I			-			Show EXIF info summary on image

  keys_decoration

    d			-			Remove decoration. Unreliable,
						you might loose control or key
						bindings.

  keys_focusthumbs

    t			-			Restore and focus thumbnails

  keys_imgpos_nw

    Alt-u		-			Set image position to nw

  keys_imgpos_n

    Alt-i		-			Set image position to n

  keys_imgpos_ne

    Alt-o		-			Set image position to ne

  keys_imgpos_e

    Alt-l		-			Set image position to e

  keys_imgpos_se

    Alt-period		-			Set image position to se

  keys_imgpos_s

    Alt-comma		-			Set image position to s

  keys_imgpos_sw

    Alt-m		-			Set image position to sw

  keys_imgpos_w

    Alt-j		-			Set image position to w

  keys_imgpos_c

    Alt-k		-			Set image position to c


  keys_crop

    Control-y		-			Crop image to selection box

Zoom factors are limited to 1 2 3 4 5 7 9 11 14 17 21 26 32 39 47 57 69 83 100
120 144 172 206 247 296 355 426 511 613 735 882 1058 1269 1522 1826 2191 2629
3154 3784 4540 5448 6537 7844 9412 and 11300

=head1 EXIF INFO

...

=head1 EXAMPLES

...

=head1 DIAGNOSTICS

...

=head1 BUGS and CAVEATS

For manipulation (resizing, rotation, ...) the external command C<convert>
from ImageMagick is used.

=head1 TODO

=over 2

=item save/load from .ivrc buttons on option window

=item Slideshow

 - behavior: location, dir depth, cycling
 - randomness, slide lists, full screen background (no decoration)
 - playlist
 - loop control
 - Auto-sense image load time for slideshows

=item Image manipulation

 - selection less picky
 - selection from zoom other than original
 - Save, Save as ...

=item Titles and decoration behavior

 - adjust height/width of screen-fit images to decoration
   (I just cannot get $iv->overrideredirect (1) to work as I want)

=item Tree view

 - Hide dirs above dt root
 - Allow a set of dirs from the command line
 - Make pirstnext and firstprev look in the original folder if the
   image folder actually been viewed is a symlink in the parent folder

=item Animation

 - use Tk::Animation for animated gif's

=item Menu's

=item Documentation

=item Portability

 - make image format's optional (TIFF, NEF, ...)

=back

=head1 SEE ALSO

L<perl>, L<Tk>, L<Tk::JPEG>, L<Tk::PNG>, L<Tk::TIFF>, L<Tk::Bitmap>,
L<Tk::Pixmap>, L<Tk::Animation>, L<Image::ExifTool>, L<Image::Size>,
L<Image::Info> and ImageMagick.

=head1 WARRANTY

The fact that I use it on my own picture sets is by no means a guarantee
that the software is without bugs. Use with care, and make backups of all
pictures you care about before experimenting.

=head1 AUTHOR

H.Merijn Brand F<E<lt>h.m.brand@xs4all.nlE<gt>> wrote this for his own
personal use, but was asked to make it publicly available as application.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2022 H.Merijn Brand

This software is free; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
