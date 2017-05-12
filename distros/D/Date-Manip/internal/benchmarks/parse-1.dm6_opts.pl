#!/usr/bin/perl

use Date::Manip::Date;
$date = new Date::Manip::Date;

@in = `cat parse-1.in`;
chomp(@in);

foreach $in (@in) {
   $date->parse($in,"noiso8601","nospecial","nodelta","nodow","noother");
}

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
