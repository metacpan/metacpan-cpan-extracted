#!perl -T

use strict;
use warnings;
use Test::More;

#unless ( $ENV{RELEASE_TESTING} ) {
#    plan( skip_all => "Author tests not required for installation" );
#}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest({
	     filter => [
			qr{\.svn},
			qr{~$},
			qr{\/?test},
			qr{html$},
			qr{.old$},
			qr{scatter.*},
			qr{ignore.txt},
		       ]
	    });
