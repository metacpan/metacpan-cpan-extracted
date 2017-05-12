use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catmandu::Exporter::Table'; }
require_ok 'Catmandu::Exporter::Table';

my ($got, $expect);

sub export_table(@) {
    my ($data, %config) = @_;
    $got = "";
    my $exporter = Catmandu::Exporter::Table->new(%config, file => \$got);
    isa_ok $exporter, 'Catmandu::Exporter::Table';
    $exporter->add($_) for @$data;
    $exporter->commit;
    is($exporter->count, scalar @$data, "Count ok");
}

export_table [{'a' => 'moose', b => '1'}, 
              {'a' => "p\nony", b => '2'}, 
              {'a' => 'shr|mp', b => '3'}];

$expect = <<TABLE;
| a      | b |
|--------|---|
| moose  | 1 |
| p ony  | 2 |
| shr mp | 3 |
TABLE

is($got, $expect, "MultiMarkdown format ok");
 

export_table [ { a => 'Hello', b => 'World' } ],
             fields => { a => 'Longname', x => 'X' };
$expect = <<TABLE;
| Longname | X |
|----------|---|
| Hello    |   |
TABLE
is $got, $expect, 'custom column names as HASH';


export_table [ { a => 'Hi', b => 'World', c => 'long value' } ],
             widths => '5,3,6';
$expect = <<TABLE;
| a     | b   | c      |
|-------|-----|--------|
| Hi    | Wor | lon... |
TABLE

is $got, $expect, 'custom column width / truncation';

done_testing;
