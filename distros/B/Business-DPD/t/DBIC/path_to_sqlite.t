use 5.010;
use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use Business::DPD::DBIC;

like(Business::DPD::DBIC->path_to_sqlite,qr{t/dpd_test.sqlite$},'path_to_sqlite');

delete $INC{'Test/More.pm'};

like(Business::DPD::DBIC->path_to_sqlite,qr{Business/DPD/dpd.sqlite$},'path_to_sqlite');


