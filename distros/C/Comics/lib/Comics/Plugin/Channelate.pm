#! perl

use strict;
use warnings;

package Comics::Plugin::Channelate;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.03";

our $name    = "Channelate";
our $url     = "http://channelate.com/";

our $pattern =
  qr{ <div \s+ class="comic-table" > \s*
      <div \s+ id="comic" > \s*
      <span \s+ class="comic-(?: tall | wide )" > \s*
      <img \s+
       src="(?<url>https?://www.channelate.com/wp-content/uploads/\d+/\d+/
             (?<image>.+?\.\w+))" \s+
       alt="(?<alt>.*?)" \s+
       title="(?<title>.*?)"
    }sx;

# Important: Return the package name!
__PACKAGE__;
