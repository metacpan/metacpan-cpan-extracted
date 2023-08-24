use v5.14;
use Test::More;
use Test::Exception;

use Catmandu::Fix::pica_append as => 'pica_append';

my $record = {};
pica_append($record, '012X $ab$cd');
is_deeply $record->{record}, [
  ['012X', '', 'a', 'b', 'c', 'd'],
], 'append fields';

throws_ok { pica_append($record) } qr/Missing/;
throws_ok { pica_append($record, 'xy' ) } qr/invalid/;

# FIXME: https://github.com/gbv/PICA-Data/issues/136
#throws_ok { pica_append($record, '021A -$' ) } qr/invalid/;

done_testing;
