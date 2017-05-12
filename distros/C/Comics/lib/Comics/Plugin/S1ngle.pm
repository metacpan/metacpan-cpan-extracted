#! perl

use strict;
use warnings;

package Comics::Plugin::S1ngle;

use parent qw(Comics::Fetcher::Direct);

our $VERSION = "0.01";

sub register {

    # S1ngle has strips ma, di, .., za (weekdays).
    # Strips on the site are usually some days behind.

    my @tm = localtime;
    my $wd = $tm[6];
    $wd += 7 if $wd < 0;
    $wd = 6 if $wd == 0;
    $wd = qw( ma di wo do vr za )[$wd-1];

    shift->SUPER::register
      ( { name    => "S1ngle",
	  url     => "http://www.s1ngle.nl/",
	  path	  => "strips/$wd.gif",
	} );
}

# Important: Return the package name!
__PACKAGE__;
