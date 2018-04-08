#! perl

use strict;
use warnings;

package Comics::Plugin::LeastICouldDo;

use parent qw(Comics::Fetcher::Cascade);

our $VERSION = "1.02";

our $name    = "Least I Could Do";
our $url     = "http://www.leasticoulddo.com/";
our @patterns =
  ( qr{ <a \s+
	 href="(?<url>https?://(?:www.)?leasticoulddo.com/comic/\d+/?)" \s+
	 id="latest-comic">
      }six,
    qr{ <meta \s+
         property="og:description" \s+
	 content="(?<title>.*?)" \s*
	/>
	.*?
	<meta \s+
         property="og:image" \s+
         content="(?<url>https?://(?:www.)?leasticoulddo.com/wp-content/uploads/
                   \d+/\d+/(?<image>.*?\.\w+))" \s*
        />
      }six,
  );

# Important: Return the package name!
__PACKAGE__;
