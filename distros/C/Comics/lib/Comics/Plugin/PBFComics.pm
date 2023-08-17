#! perl

use strict;
use warnings;

package Comics::Plugin::PBFComics;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "The Perry Bible Fellowship";
our $url     = "https://pbfcomics.com/";

# <div id="comic"><img src='http://pbfcomics.com/wp-content/uploads/2017/09/PBF280-Technorgy.png' width='750' height='1070' alt='' title='Technorgy' /></div>

our $pattern =
  qr{ <div \s+ id="comic">
      <img \s+
       width  = '\d+' \s+
       height = '\d+' \s+
       alt    = '(?<alt>.*?)' \s+
       title  = '(?<title>.*?)' \s+
       data-src= ['"](?<url>https?://pbfcomics.com/wp-content/uploads/
	         \d+ / \d+ /
	         (?<image>.+?\.\w+))['"]
    }x;

# Important: Return the package name!
__PACKAGE__;
