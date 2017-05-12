#-*-perl-*-
use strict;
use Test::More tests => 2;

use_ok "Data::Dumper::EasyOO";

do "Data/Dumper/EasyOO.pm";

Data::Dumper::EasyOO->import;
Data::Dumper::EasyOO->import;

ok(1);
