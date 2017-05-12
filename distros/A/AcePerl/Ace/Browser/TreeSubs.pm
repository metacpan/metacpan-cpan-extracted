package Ace::Browser::TreeSubs;

# constants used by the tree program (and its ilk)

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Ace::Browser::AceSubs qw(Configuration);
use CGI 'escape';

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(OPENCOLOR CLOSEDCOLOR MAXEXPAND
	     AceImageHackURL);
@EXPORT_OK = ();
%EXPORT_TAGS = ();

# colors
use constant OPENCOLOR      => '#FF0000'; # color when a tree is expanded
use constant CLOSEDCOLOR    => '#909090'; # color when a tree is collapsed

# auto-expand subtrees when the number of subobjects is
# less than or equal to this number
use constant MAXEXPAND => 4;


# A hack to allow access to external images.
# We use the name of the database as a URL to an external image.
# The URL will look like this:
#     /ace_images/external/database_name/foo.gif
# You must arrange for the URL to return the correct image, either with
# a CGI script, a symbolic link, or a redirection directive.
sub AceImageHackURL {
  my $image_name = shift;
  # correct some bad image file names in the database
  $image_name .= '.jpeg' unless $image_name =~ /\.(gif|jpg|jpeg|png|tiff|ps)$/;
  my $picture_path = Configuration->Pictures->[0];
  return join('/',$picture_path,Configuration->Name,'external',escape("$image_name"));
}


1;
