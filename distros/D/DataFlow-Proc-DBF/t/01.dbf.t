use strict;
use warnings;
use Test::More;
use DataFlow::Proc::DBF;

new_ok 'DataFlow::Proc::DBF' => [ direction => 'CONVERT_FROM' ];
new_ok 'DataFlow::Proc::DBF' => [ direction => 'CONVERT_TO'   ];


my $structure = [
    [ 'JOSE', 'DA SILVA', 1234 ],
    [ 'JOHN', 'DOE',      4321 ],
];

ok my $to_dbf = DataFlow::Proc::DBF->new( direction => 'CONVERT_TO' ), 'spawning our target object';
ok my @dbf_data = $to_dbf->process($structure), 'got back some dbf data (I hope)';

ok my $from_dbf = DataFlow::Proc::DBF->new( direction => 'CONVERT_FROM' ), 'spawning our source object';
ok my @raw_data = $from_dbf->process( $dbf_data[0] ), 'got back some raw data (I hope)';

is_deeply $structure, $raw_data[0], "...and we've come full circle! perl -> dbf -> perl";

my $headers = [ 'NOME', 'SOBRENOME', 'CODIGO' ];
ok $to_dbf = DataFlow::Proc::DBF->new(
    direction => 'CONVERT_TO',
    headers   => $headers,
), 'spawning target with headers';
ok @dbf_data = $to_dbf->process($structure), 'got back some dbf data with headers (I hope)';

ok $from_dbf = DataFlow::Proc::DBF->new( direction => 'CONVERT_FROM', header_wanted => 1 ), 'spawning other source object';
ok @raw_data = $from_dbf->process( $dbf_data[0] ), 'got back more raw data (I hope)';

is_deeply $raw_data[0], $structure,  '...full circle even after call requesting headers';
is_deeply $from_dbf->header, $headers, '...and how the actual header';

done_testing;
