#! perl

use strict;
use warnings;

package Comics::Plugin::Lectrr;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Lectrr";
our $url     = "http://www.lectrr.be/nl/";
our $pattern =
	    qr{ <div \s+  class="daily-cartoon-slide" .*?> \s*
		<div \s+ class="slide-v-allign"> \s*
		<a \s+ .*? class="image"> \s*
		<img \s+
		 src="(?<url>/files/attachments/.*?/(?<image>.*?\.\w+))" \s+
		 title="(?<title>.*?)"
	      }six;

# Important: Return the package name!
__PACKAGE__;
