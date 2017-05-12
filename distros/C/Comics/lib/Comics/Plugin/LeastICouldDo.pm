#! perl

use strict;
use warnings;

package Comics::Plugin::LeastICouldDo;

use parent qw(Comics::Fetcher::Cascade);

our $VERSION = "1.00";

# Current image is date formatted.
# Unfortunately, this is not reliable (e.g., on nov 1 the image
# was 2016/10/20161101.jpg)

our $name    = "Least I Could Do";
our $url     = "http://www.leasticoulddo.com/";
our @patterns =
  ( qr{ <a \s+
	 href="(?<url>http://www.leasticoulddo.com/comic/\d+/)" \s+
	 id="feature-comic">
      }six,
    qr{ <meta \s+
         property="og:image" \s+
         content="(?<url>http://www.leasticoulddo.com/wp-content/uploads/
                   \d+/\d+/(?<image>.*?\.\w+))" \s*
        />
      }six,
  );

# Important: Return the package name!
__PACKAGE__;
