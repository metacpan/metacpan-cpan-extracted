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

my %orig_cols = $row->get_columns;
$row->update({name => 7});
$orig_row->discard_changes;
$row->discard_changes;

is($row->name, 7, 'set changed on preview row');
is($orig_row->name, $orig_cols{name}, 'set unchanged on original row');

$row->name(4);
$row->update;

$orig_row->discard_changes;
$row->discard_changes;

is($row->name, 4, 'set changed on preview row');
is($orig_row->name, $orig_cols{name}, 'set unchanged on original row');

#use Data::Dumper; warn Dumper({ $row->get_columns }, { $orig_row->get_columns });

my $new_row = $schema->resultset('Artist')->create({ name => 15 });
$new_row->discard_changes;

my $unpreviewed_new_row = $unpreviewed_schema->resultset('Artist')->find($new_row->id);
is($unpreviewed_new_row, undef, 'new row not present in original table'); 

$schema->publish;

$orig_row->discard_changes;
is($orig_row->name, $row->name, 'set changed on original row');
ok($unpreviewed_schema->resultset('Artist')->find($new_row->id), 'new row copied over');

ok($unpreviewed_schema->source('DBICTest::Schema::Artist'), 'got source using full name');

is($schema->resultset('DBICTest::Schema::Artist')->search({ dirty => 1 })->count, 0, 'dirty rows cleared');
