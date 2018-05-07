package Test::Const::Exporter::Enums;

use Const::Exporter

  default => [

    [qw/ a1 a2 a3 /] => 0,

    [ '$b1', '$b2', undef, '$b3' ] => [ 1, sub { $_[0] << 1 } ],

    [qw/ $c1 $c2 $c3 /] => [qw/ 8 4 20 /],

    [qw/ $d1 $d2 $d3 /] => [ 10, 12 ],

  ];

1;
