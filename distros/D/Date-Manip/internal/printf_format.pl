#!/usr/bin/perl

# This takes 1-3 argument.
#
# If the first argument is 'posix', then it uses the POSIX printf
# directives rather than the native Date::Manip ones.
#
# The next argument is required and is a format string.
#
# The optional last argument is a time (in seconds since the epoch).  If
# omitted, it defaults to now.

use Date::Manip::Date;
my $date = new Date::Manip::Date;

my $posix  = 0;
if (lc($ARGV[0]) eq 'posix') {
   $posix  = 1;
   shift(@ARGV);
}
my $format = $ARGV[0];
my $time   = $ARGV[1];

if ($posix) {
   $date->config('use_posix_printf',1);
}

if ($time) {
   $date->parse("epoch $time");
} else {
   $date->parse('now');
}

print $date->printf($format),"\n";

