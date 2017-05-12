use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use DBICTest;
use Test::More 'no_plan';

my $schema = DBICTest->init_schema( connect => 1 );
$schema->preview_active(1);
ok($schema->resultset('Artist')->create({ name => 'fuckmunch' }), 'create with connect worked');

1;
