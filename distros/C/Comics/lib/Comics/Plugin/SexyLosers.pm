#! perl

use strict;
use warnings;

package Comics::Plugin::SexyLosers;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Sexy Losers";
our $url     = "http://www.sexylosers.com/";
our $pattern =
	    qr{ <div \s+ class="entry-content" \s+ itemprop="text"> \s*
		<p> \s*
		<a \s+
		 href="(?<url>https?://.*?\.wp\.com/www\.sexylosers\.com/
		              wp-content/uploads/\d+/\d+/
			      (?<image>.*?\.\w+))"
	      }six;

our $ondemand = 1;		# NSFW

# Important: Return the package name!
__PACKAGE__;
