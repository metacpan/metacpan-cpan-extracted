#! perl

use strict;
use warnings;

package Comics::Plugin::QuestionableContent;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Questionable Content";
our $url     = "http://www.questionablecontent.net/";
our $pattern =
	    qr{ <img \s+
		src="(?<url>https?://www.questionablecontent.net/comics/
		      (?<image>\d+\.\w+))" \s*
		>
	      }x;

# Important: Return the package name!
__PACKAGE__;
