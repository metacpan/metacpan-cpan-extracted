use strict;
use Test::More 0.98 tests => 10;

use lib 'lib';

use Business::Tax::Withholding::JP;
my $calc = Business::Tax::Withholding::JP->new( no_wh => 1, price => 10000 );

note "before consumption tax";
$calc->date('1979-04-01');
is $calc->tax(), 0, "since " . $calc->date();                       # 1
$calc->date('1989-03-31');
is $calc->tax(), 0, "until " . $calc->date();                       # 2

note "after consumption tax 3%";
$calc->date('1989-04-01');
is $calc->tax(), 300, "since " . $calc->date();                     # 3
$calc->date('1997-03-31');
is $calc->tax(), 300, "until " . $calc->date();                     # 4

note "after consumption tax 5%";
$calc->date('1997-04-01');
is $calc->tax(), 500, "since " . $calc->date();                     # 5
$calc->date('2014-03-31');
is $calc->tax(), 500, "until " . $calc->date();                     # 6

note "after consumption tax 8%";
$calc->date('2014-04-01');
is $calc->tax(), 800, "since " . $calc->date();                     # 7
$calc->date('2019-09-30');
is $calc->tax(), 800, "until " . $calc->date();                     # 8

note "after consumption tax 10%";
$calc->date('2019-10-01');
is $calc->tax(), 1000, "tax";                                       # 9
is $calc->full(), 11000, "full";                                    #10

done_testing;
