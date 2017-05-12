use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;
use Spreadsheet::ParseExcel ();

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

MyApp->model('DBIC::User')->create({ name => 'peter', password => 'random'})
    for(1..10);

$mech->add_header( 'Accept' => 'application/json' );
$mech->get_ok( "/users", undef, 'request list of users' );

ok( my $json = JSON::decode_json( $mech->content ),
    'response is JSON response' );

is( $json->{results}, 10, '10 results' );

$mech->get_ok( "/users?content-type=application%2Fvnd.ms-excel", undef, 'request list of users' );

ok(my $excel = Spreadsheet::ParseExcel::Workbook->Parse(\($mech->content)),
    'parsed file');
my $sheet = $excel->{Worksheet}[0];

is_deeply(
    read_sheet($sheet),
    [
      [
        'id',
        'name',
        'password'
      ],
      [
        '1',
        'peter',
        'random'
      ],
      [
        '2',
        'peter',
        'random'
      ],
      [
        '3',
        'peter',
        'random'
      ],
      [
        '4',
        'peter',
        'random'
      ],
      [
        '5',
        'peter',
        'random'
      ],
      [
        '6',
        'peter',
        'random'
      ],
      [
        '7',
        'peter',
        'random'
      ],
      [
        '8',
        'peter',
        'random'
      ],
      [
        '9',
        'peter',
        'random'
      ],
      [
        '10',
        'peter',
        'random'
      ]
    ],
    'data is not numified'
);

sub read_sheet {
    my $sheet = shift;
    my $res;
    $sheet->{MaxRow} ||= $sheet->{MinRow};
    foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
        $sheet->{MaxCol} ||= $sheet->{MinCol};
        foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
            my $cell = $sheet->{Cells}[$row][$col];
            if ($cell) {
                $res->[$row][$col] = $cell->{Val};
            }
        }
    }
    $res
}

done_testing;
