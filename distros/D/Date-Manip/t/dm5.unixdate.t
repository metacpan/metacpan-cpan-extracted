#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DM5 :: UnixDate';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;
if ($] < 5.010  ||  $ENV{'DATE_MANIP_TEST_DM5'}) {
   $t->feature("TEST_DM5",1);
}

$t->skip_all('Date::Manip 5.xx tests ignored (set DATE_MANIP_TEST_DM5 to test)',
             'TEST_DM5');

Date_Init("TZ=EST");

$tests="

'Wed Jan 3, 1996  at 8:11:12'
'%y %Y %m %f %b %h %B %U %W %j %d %e %v %a %A %w %E'
=>
'96 1996 01  1 Jan Jan January 01 01 003 03  3  W Wed Wednesday 3 3rd'

'Wed Jan 3, 1996  at 8:11:12'
'%H %k %i %I %p %M %S %s %o %z %Z'
=>
'08  8  8 08 AM 11 12 820674672 820656672 -0500 EST'

";

$t->tests(func  => \&UnixDate,
          tests => $tests);
$t->done_testing();

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
