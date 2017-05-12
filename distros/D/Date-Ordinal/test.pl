#!/usr/bin/perl

use lib '/usr/end70/mnt/admin/perl';
use Date::Ordinal;

print ord2month(5),$/;
print month2ord('May'),$/;
print join ':', @{&Date::Ordinal::all_month_ordinations}, $\;

