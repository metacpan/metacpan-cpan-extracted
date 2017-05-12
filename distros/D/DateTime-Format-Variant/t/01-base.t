use strict;
use warnings;

use Test::More tests => 2;                      # last test to print
use Test::Harness;
use DateTime::Format::Variant;
use Win32::OLE::Variant;
use DateTime;


my $v = Variant(VT_DATE, "April 1 99 2:23 pm");
my $dt = vt2dt($v);
is($dt->ymd, '1999-04-01', 'dt');
my $vt = dt2vt($dt);
is($vt->Date('yyyy-MM-dd'), '1999-04-01', 'vt');

done_testing();






