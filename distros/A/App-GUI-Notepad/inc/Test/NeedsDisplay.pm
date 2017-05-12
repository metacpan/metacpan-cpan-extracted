#line 1 "inc/Test/NeedsDisplay.pm - C:/Perl/site/lib/Test/NeedsDisplay.pm"
package Test::NeedsDisplay;

#line 82

use 5.006;
use strict;
use File::Spec ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub import {
	# Get rid of Win32 and existing DISPLAY cases
	return 1 if $^O eq 'MSWin32';
	return 1 if $ENV{DISPLAY};

	# The quick way is to use the xvfb-run script
	print "# No DISPLAY. Looking for xvfb-run...\n";
	my @PATHS = split /:/, $ENV{PATH};
	foreach my $path ( @PATHS ) {
		my $xvfb_run = File::Spec->catfile( $path, 'xvfb-run' );
		next unless -e $xvfb_run;
		next unless -x $xvfb_run;
		print "# Restarting with xvfb-run...\n";
		exec "$xvfb_run $^X $0";
	}

	print "# Failed to find xvfb-run.\n";
	print "# Running anyway, but will probably fail...\n";
}

1;

#line 143
