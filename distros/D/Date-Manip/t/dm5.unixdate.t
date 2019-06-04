#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");

my $tests="

'Wed Jan 3, 1996  at 8:11:12'
'%y %Y %m %f %b %h %B %U %W %j %d %e %v %a %A %w %E'
=>
'96 1996 01  1 Jan Jan January 01 01 003 03  3  W Wed Wednesday 3 3rd'

'Wed Jan 3, 1996  at 8:11:12'
'%H %k %i %I %p %M %S %s %o %z %Z'
=>
'08  8  8 08 AM 11 12 820674672 820656672 -0500 EST'

";

$::ti->tests(func  => \&UnixDate,
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
