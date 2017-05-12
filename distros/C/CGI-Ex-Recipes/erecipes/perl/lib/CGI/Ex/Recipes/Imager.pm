package CGI::Ex::Recipes::Imager;

use warnings;
use strict;
our $VERSION = '0.01';
=head1 NAME

CGI::Ex::Recipes::Imager - Implements image mangement!

=head1 SYNOPSIS

Somewhere in the templates. 

   [% Imager.img('./foo/bar.jpg',widtt=300, height=400, class='blah',style='float:right) %]
    ...

        
=head1 DESCRIPTION

NOTE: this is just a draft. Nothing is implemented.

Manages display and recise of images. If an image is already recised and stored in the temp directory,
just creates an img tag with src attribute pointing to the ready for display image.
If the image is displayed for the very first time does everithing needed to resize a copy of the
image and place it in the temp directory. then it creates a tag for it so it can be displayed

=head1 METHODS

=head2 img

=cut

=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Ex::Recipes::Imager
