#!/usr/bin/perl

# Example blosxom script. This script mimics the behaviour of the original 
# blosxom.cgi, but uses Blog::Blosxom to do it.

# Please note this script uses FindBin so if you move it into a cgi-bin
# directory you will probably have to change the code where it is used.
use strict;
use warnings;

use FindBin;
use File::Spec;
use CGI qw(:standard);

use lib "$FindBin::Bin/../lib";

use Blog::Blosxom;

# Note that in your own script you should know exactly where the datadir is.
# See Blog::Blosxom docs for all the available params to new.
my $blog = Blog::Blosxom->new(
    datadir => File::Spec->catdir($FindBin::Bin, "..", "blog"),
    blog_title => "My Blog",
    blog_description => "A blog for blogging with",
);

# Find the path yourself for this version of Blosxom.
my $path = path_info() || param('path');

# Look for e.g. /\.html$/ or use the param. If we don't get a result, we fall
# back on the default flavour, which is itself defaulted to html in new().
my ($flavour) = $path =~ s/(\.\w+)$// || param('flav');

print header,
      $blog->run($path, $flavour);


__END__

This script is licenced under the same licence as the version of Blog::Blosxom
with which it was shipped, or the latest version if it becomes orphaned.
