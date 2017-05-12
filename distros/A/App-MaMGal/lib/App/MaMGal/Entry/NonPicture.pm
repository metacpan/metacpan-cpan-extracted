# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# A class for any non-directory which is not a picture, either
package App::MaMGal::Entry::NonPicture;
use strict;
use warnings;
use base 'App::MaMGal::Entry';
use Carp;

sub make {}
sub page_path { shift->{base_name} }
sub thumbnail_path { }

1;
