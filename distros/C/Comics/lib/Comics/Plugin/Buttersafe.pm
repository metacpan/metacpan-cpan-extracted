#! perl

use strict;
use warnings;

package Comics::Plugin::Buttersafe;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Buttersafe";

our $url     = "https://www.buttersafe.com/";
our $pattern =
  qr{ <img \s+
      src="(?<url>https?://(?:www.)?buttersafe.com/comics/
	  (?<image>\d+-\d+-\d+-[^./]+\.\w+))" \s+
      alt="(?<alt>.*?)" \s+
      />
    }x;

# Important: Return the package name!
__PACKAGE__;
