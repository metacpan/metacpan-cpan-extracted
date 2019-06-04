#!/usr/bin/perl

use warnings;
use strict;

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $::ti->feature("DM6",1);
}

$::ti->skip_all('Date::Manip 6.xx required','DM6');

$::testdir = $::ti->testdir();
chdir($::testdir);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
