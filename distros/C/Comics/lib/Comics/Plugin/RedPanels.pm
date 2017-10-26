#! perl

use strict;
use warnings;

package Comics::Plugin::RedPanels;

our $disabled = 1;

=begin disabled

2017-02-27
Dear Readers,

After 18 wonderful months as the creator of RedPanels, I am announcing
my retirement. Knowing and interacting with you has made all the labor
worthwhile.

=cut

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Red Panels";
our $url     = "http://www.redpanels.com/";

our $pattern =
  qr{ <img \s+
       (?: id='comicImg' \s+ )?
       src='(?<url>http://redpanels.com/comics/(?<image>.*?\.\w+))' \s+
       alt='(?<alt>.*?)' \s*
      >
    }six;

# Important: Return the package name!
__PACKAGE__;
