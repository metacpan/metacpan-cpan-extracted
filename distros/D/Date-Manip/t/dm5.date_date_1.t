#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");

my $tests="
'Wed Jan 10 1996 noon' 'Wed Jan 7 1998 noon' 1 => +1:11:4:0:0:0:0

'Wed Jan 7 1998 noon' 'Wed Jan 10 1996 noon' 1 => -1:11:4:0:0:0:0

'Wed Jan 10 1996 noon' 'Wed Jan 8 1997 noon' 1 => +0:11:4:1:0:0:0

'Wed Jan 8 1997 noon' 'Wed Jan 10 1996 noon' 1 => -0:11:4:1:0:0:0

'Wed May 8 1996 noon' 'Wed Apr 9 1997 noon' 1 => +0:11:0:1:0:0:0

'Wed Apr 9 1997 noon' 'Wed May 8 1996 noon' 1 => -0:11:0:1:0:0:0

'Wed Apr 10 1996 noon' 'Wed May 14 1997 noon' 1 => +1:1:0:4:0:0:0

'Wed May 14 1997 noon' 'Wed Apr 10 1996 noon' 1 => -1:1:0:4:0:0:0

'Wed Jan 10 1996 noon' 'Wed Feb 7 1996 noon' 1 => +0:0:4:0:0:0:0

'Wed Feb 7 1996 noon' 'Wed Jan 10 1996 noon' 1 => -0:0:4:0:0:0:0

'Mon Jan 8 1996 noon' 'Fri Feb 9 1996 noon' 1 => +0:1:0:1:0:0:0

'Fri Feb 9 1996 noon' 'Mon Jan 8 1996 noon' 1 => -0:1:0:1:0:0:0

'Jan 1 1996 12:00:00' 'Jan 1 1996 14:30:30' 1 => +0:0:0:0:2:30:30

'Jan 1 1996 14:30:30' 'Jan 1 1996 12:00:00' 1 => -0:0:0:0:2:30:30

'Jan 1 1996 12:00:00' 'Jan 2 1996 14:30:30' 1 => +0:0:0:1:2:30:30

'Jan 2 1996 14:30:30' 'Jan 1 1996 12:00:00' 1 => -0:0:0:1:2:30:30

'Jan 1 1996 12:00:00' 'Jan 2 1996 10:30:30' 1 => +0:0:0:0:22:30:30

'Jan 2 1996 10:30:30' 'Jan 1 1996 12:00:00' 1 => -0:0:0:0:22:30:30

'Jan 1 1996 12:00:00' 'Jan 2 1997 10:30:30' 1 => +1:0:0:0:22:30:30

'Jan 2 1997 10:30:30' 'Jan 1 1996 12:00:00' 1 => -1:0:0:0:22:30:30

'Jan 31 1996 12:00:00' 'Feb 28 1997 10:30:30' 1 => +1:0:3:6:22:30:30

'Feb 28 1997 10:30:30' 'Jan 31 1996 12:00:00' 1 => -1:0:3:6:22:30:30

'Jan 1st 1997 00:00:01' 'Feb 1st 1997 00:00:00' 1 => +0:0:4:2:23:59:59

'Jan 1st 1997 00:00:01' 'Mar 1st 1997 00:00:00' 1 => +0:1:3:6:23:59:59

'Jan 1st 1997 00:00:01' 'Mar 1st 1998 00:00:00' 1 => +1:1:3:6:23:59:59

";

$::ti->tests(func  => \&DateCalc,
             tests => $tests);
$::ti->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:
