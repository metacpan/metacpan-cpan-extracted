use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use DBICTest;
use Test::More 'no_plan';

my $schema = DBICTest->init_schema;
$schema->preview_active(1);
my $unpreviewed_schema = $schema->unpreviewed;
my $row = $schema->resultset('Artist')->first;
ok($row, 'got an artist row');
my $orig_row = $unpreviewed_schema->resultset('Artist')->find($row->id);

$row->delete;

my $result = $schema->resultset('Artist')->search({});
ok(!$schema->resultset('Artist')->find($row->id), 'artist no longer visible in previewed table');
ok($unpreviewed_schema->resultset('Artist')->find($row->id), 'artist still visible in unpreviewed table');

$schema->publish;

ok(!$schema->resultset('Artist')->find($row->id), 'artist still not visible in previewed table');
ok(!$unpreviewed_schema->resultset('Artist')->find($row->id), 'artist now not visible in unpreviewed table');
