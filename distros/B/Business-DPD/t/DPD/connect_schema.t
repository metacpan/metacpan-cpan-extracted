use 5.010;
use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use Business::DPD;

my $dpd = Business::DPD->new;
$dpd->connect_schema;

my $schema = $dpd->schema;

isa_ok($schema,'DBIx::Class');
can_ok($schema,'resultset');

ok($schema->resultset('DpdCountry')->search->count,'can search & count on resultset');

