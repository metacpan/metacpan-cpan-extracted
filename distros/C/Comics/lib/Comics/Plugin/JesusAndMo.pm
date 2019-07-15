#! perl

use strict;
use warnings;

package Comics::Plugin::JesusAndMo;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Jesus and Mo";
our $url     = "https://www.jesusandmo.net/";
our $pattern =
  qr{ <img \s+
      src="(?<url>https?://www.jesusandmo.net/wp-content/uploads/
	  (?<image>[^./]+\.\w+))" \s+
      alt="(?<alt>.*?)" \s+
      title="(?<title>.*?)" \s+
      />
  }x;

# Important: Return the package name!
__PACKAGE__;
