use strict;
use warnings;
use Test::More;
use Catmandu::Exporter::Table;


sub is_table(@) {
    my ($message,$expect,$data) = (pop,pop,shift);
    my $out = "";
    my $exporter = Catmandu::Exporter::Table->new(@_, file => \$out);
    $exporter->add($_) for @$data;
    $exporter->commit;
    is $out, $expect, $message;
}

foreach my $schema (
    { fields => [ { name => "c", title => "C" }, { name => "b" } ] },
    't/schema.json'
) {
    is_table [{a => 1, b => 2, c => 3}], schema => $schema
, <<TABLE, 'set fields and columns via JSON Table schema';
| C | b |
|---|---|
| 3 | 2 |
TABLE
}

done_testing;
