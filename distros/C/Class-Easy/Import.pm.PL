#!/usr/bin/env perl

open STDOUT, ">$ARGV[0]~"
   or die "$ARGV[0]~: $!";

our $WARN;
our $H;

BEGIN {
	$H    = $^H;
}

use utf8;
use strict qw(subs vars);

no warnings;
use warnings qw(
	FATAL closed threads internal debugging pack malloc portable prototype
	inplace io pipe unpack deprecated glob digit printf
	layer reserved taint closure semicolon
);
no warnings qw(exec newline unopened);

BEGIN {
	$H    = $^H              & ~$H;
	$WARN = ${^WARNING_BITS};
}

print "package Class::Easy::Import;

";

printf "our \$H = 0x%x;\n", $H;
printf "our \$WARN = \"%s\";\n\n", join "", map "\\x$_", unpack "(H2)*", $WARN;

print "sub import {
	# use warnings
	\${^WARNING_BITS} = \$WARN;
	
	# use strict, use utf8;
	\$^H |= \$H;
	
	# use feature
	\$^H{feature_switch} = \$^H{feature_say} = \$^H{feature_state} = 1;

}
";

print "1;";

close STDOUT;

rename "$ARGV[0]~", $ARGV[0];