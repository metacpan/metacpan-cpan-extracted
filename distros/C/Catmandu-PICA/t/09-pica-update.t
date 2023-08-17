use v5.14;
use Test::More;
use Test::Exception;

use Catmandu::Fix::pica_update as => 'pica_update';
use Catmandu::Importer::PICA;

my $record = { record => [
  ['021A', '', 'a', 'title'],
  ['021A', '', 'a', 'nother'],
] };

note "update/add full field";
 
pica_update($record, '021A','$abook$hto read', all => 0);
is_deeply $record->{record}, [
  ['021A', '', 'a', 'book', 'h', 'to read'],
  ['021A', '', 'a', 'nother'],
], 'update full field (all: 0)';

pica_update($record, '021A','$aX');
is_deeply $record->{record}, [
  ['021A', '', 'a', 'X'],
  ['021A', '', 'a', 'X'],
], 'update full field (all)';

pica_update($record, '003@', '$099');
is scalar @{$record->{record}}, 2, "don't add missing field by default";

pica_update($record, '003@', '$099', add => 1);
is scalar @{$record->{record}}, 3, "add missing field";

note "update/add subfield(s)";

my $record = { record => [] };

pica_update($record, '003@$0', '123');
is scalar @{$record->{record}}, 0, "update subfield (don't add field)";

pica_update($record, '003@$0', '123', add => 1);
is_deeply $record->{record}, [['003@', '', '0', '123']], "update subfield (add field)";

pica_update($record, '003@$*', '99');
is_deeply $record->{record}, [['003@', '', '0', '99']], "update subfield (existing)";

$record->{record} = [
  ['021A', '', 'a', 'A'],
  ['021A', '', 'a', 'B', 'h', 'C', 'h', 'D']];
pica_update($record, '021A$h', 'Z', add => 1, all => 0);

is_deeply $record->{record}, [
  ['021A', '', 'a', 'A', 'h', 'Z'],
  ['021A', '', 'a', 'B', 'h', 'Z', 'h', 'D'],
], 'add subfields (only first)';

pica_update($record, '021A$ah', 'Q', all => 1);
is_deeply $record->{record}, [
  ['021A', '', 'a', 'Q', 'h', 'Q'],
  ['021A', '', 'a', 'Q', 'h', 'Q', 'h', 'Q'],
], 'update subfields (all)';

note "exceptions";

throws_ok { pica_update($record, '021A', '$' ) } qr/invalid/, 'invalid PICA field value';
throws_ok { pica_update($record, '021A', 'a' ) } qr/invalid/, 'invalid PICA field value';
throws_ok { pica_update($record, '021A', '' ) } qr/invalid/, 'missing PICA field value';

done_testing;
