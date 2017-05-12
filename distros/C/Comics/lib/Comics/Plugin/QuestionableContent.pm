#! perl

use strict;
use warnings;

package Comics::Plugin::QuestionableContent;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Questionable Content",
	  url     => "http://www.questionablecontent.net/",
	  pat	  =>
	    qr{ <img \s+
		src="(?<url>http://www.questionablecontent.net/comics/
		      (?<image>\d+\.\w+))" \s*
		>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
