# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );

my $text = <<'eot';
list = [ #comment
    1 2 3, 4 5,  # comment 7 8 9 0 ]
    #############
    6, '7', "8",
    # # # # #
    9
    10
#############]
]
eot

my $expected =
  { '_GLOBAL' =>
      { 'list' => [ '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' ] } };


isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );
is_deeply( $p->parse( text => $text ), $expected, 'list test, comments' );


$text = <<'eot';
list = [ #comment
    [ 1 2 ], {a=b, c = [ d e ]}, foo, bar 
# comment
]
eot

$expected = {
    '_GLOBAL' => {
        'list' => [
            [ '1', '2' ],
            {
                'c' => [ 'd', 'e' ],
                'a' => 'b'
            },
            'foo', 'bar'
        ]
    }
};

$p = Config::Scoped->new();
is_deeply( $p->parse( text => $text ), $expected, 'list test, complex' );

