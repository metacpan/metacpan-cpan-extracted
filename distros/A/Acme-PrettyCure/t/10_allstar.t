use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my @girls = Acme::PrettyCure->girls('AllStar');

is scalar(@girls), 28, 'pretty cure allstar';

my @dx1 = Acme::PrettyCure->girls('AllStarDX1');

is scalar(@dx1), 14, 'pretty cure allstar_dx1';

my @dx2 = Acme::PrettyCure->girls('AllStarDX2');

is scalar(@dx2), 17, 'pretty cure allstar_dx2';

my @dx3 = Acme::PrettyCure->girls('AllStarDX3');

is scalar(@dx3), 21, 'pretty cure allstar_dx3';

my @ns = Acme::PrettyCure->girls('AllStarNewStage');

is scalar(@ns), 29, 'pretty cure allstar_ns';

done_testing;

