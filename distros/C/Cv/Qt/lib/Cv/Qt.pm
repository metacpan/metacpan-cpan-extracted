# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

=encoding utf8

=head1 NAME

Cv::Qt - Cv extension for Qt

=head1 SYNOPSIS

  use Cv::Qt;

=cut

package Cv::Qt;

use 5.008008;
use strict;
use warnings;
use Cv ();

our $VERSION = '0.29';

require XSLoader;
XSLoader::load('Cv::Qt', $VERSION);

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = grep /^(IPL|CV|cv)/, (keys %Cv::Qt::);

our %EXPORT_TAGS = (
	'all' => \@EXPORT_OK,
	);

our @EXPORT = ( );

# ============================================================
#  highgui. High-level GUI and Media I/O: Qt new functions
# ============================================================

=head1 DESCRIPTION

=head2 METHOD

=over

=item cvAddText

 cvAddText($arr, $text, $location, $font)
 $arr->addText($text, $location, $font)

L<cvAddText()|http://docs.opencv.org/search.html?q=cvAddText>

=cut

sub Cv::Arr::cvAddText { goto &cvAddText }
sub Cv::cvAddText { goto &cvAddText }
push(@Cv::EXPORT_OK, 'cvAddText');


=item cvDisplayOverlay

 cvDisplayOverlay($name, $text, $delay)
 Cv->displayOverlay($name, $text, $delay)

L<cvDisplayOverlay()|http://docs.opencv.org/search.html?q=cvDisplayOverlay>

=cut

sub Cv::cvDisplayOverlay { goto &cvDisplayOverlay }
push(@Cv::EXPORT_OK, 'cvDisplayOverlay');


=item cvDisplayStatusBar

 cvDisplayStatusBar($name, $text, $delayms)
 Cv->displayStatusBar($name, $text, $delayms)

L<cvDisplayStatusBar()|http://docs.opencv.org/search.html?q=cvDisplayStatusBar>

=cut

sub Cv::cvDisplayStatusBar { goto &cvDisplayStatusBar }
push(@Cv::EXPORT_OK, 'cvDisplayStatusBar');


=item cvFontQt

 cvFontQt($nameFont, $pointSize, $color, $weight, $style, $spacing)
 Cv->fontQt($nameFont, $pointSize, $color, $weight, $style, $spacing)

L<cvFontQt()|http://docs.opencv.org/search.html?q=cvFontQt>

=cut

sub Cv::cvFontQt { goto &cvFontQt }
push(@Cv::EXPORT_OK, 'cvFontQt');


=item cvGetWindowProperty

 cvGetWindowProperty($name, $prop_id)
 Cv->getWindowProperty($name, $prop_id)

L<cvGetWindowProperty()|http://docs.opencv.org/search.html?q=cvGetWindowProperty>

=cut

sub Cv::cvGetWindowProperty { goto &cvGetWindowProperty }
push(@Cv::EXPORT_OK, 'cvGetWindowProperty');


=item cvSetWindowProperty

 cvSetWindowProperty($name, $prop_id, $prop_value)
 Cv->setWindowProperty($name, $prop_id, $prop_value)

L<cvSetWindowProperty()|http://docs.opencv.org/search.html?q=cvSetWindowProperty>

=cut

sub Cv::cvSetWindowProperty { goto &cvSetWindowProperty }
push(@Cv::EXPORT_OK, 'cvSetWindowProperty');


=item cvLoadWindowParameters

 cvLoadWindowParameters($name)
 Cv->loadWindowParameters($name)

L<cvLoadWindowParameters()|http://docs.opencv.org/search.html?q=cvLoadWindowParameters>

=cut

sub Cv::cvLoadWindowParameters { goto &cvLoadWindowParameters }
push(@Cv::EXPORT_OK, 'cvLoadWindowParameters');


=item cvSaveWindowParameters

 cvSaveWindowParameters($name)
 Cv->saveWindowParameters($name)

L<cvSaveWindowParameters()|http://docs.opencv.org/search.html?q=cvSaveWindowParameters>

=cut

sub Cv::cvSaveWindowParameters { goto &cvSaveWindowParameters }
push(@Cv::EXPORT_OK, 'cvSaveWindowParameters');


=item cvCreateOpenGLCallback

TBD

=item cvCreateButton

TBD

=cut

{ package Cv; our @BUTTON; }

sub Cv::cvCreateButton { goto &cvCreateButton }
push(@Cv::EXPORT_OK, 'cvCreateButton');

=back

=cut

1;
__END__

=head2 EXPORT

None by default.


=head1 SEE ALSO

http://github.com/obuk/Cv-Olive

=head1 AUTHOR

MASUDA Yuta E<lt>yuta.cpan@gmail.comE<gt>


=head1 LICENCE

Copyright (c) 2013 by MASUDA Yuta.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
