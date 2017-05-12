# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );

my $text = <<'eot';
foo { sec = eval{ 3600 * 24 }};
bar { min = perl_code{ 60 * 24 }};
eot

my $expected = {
    'foo' => { 'sec' => 86400 },
    'bar' => { 'min' => 1440 },
};

isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );
is_deeply( $p->parse( text => $text ), $expected, 'eval test' );


$text = <<'eot';
foo { list = eval{ [1..9] }};
bar { hash = perl_code{ {red => '#FF0000', green => '#00FF00', blue => '#0000FF'}}};
eot

$expected = {
    'foo' => { 'list' => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] },
    'bar' => {
        'hash' => {
            'red'   => '#FF0000',
            'green' => '#00FF00',
            'blue'  => '#0000FF',
        }
    },
};

$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'eval test' );

$text = <<'eot';
%macro IF_LIST 'eth1,eth2,eth3';
if {
    list = eval { [IF_LIST] };
}
eot

$expected = { 'if' => { 'list' => [ 'eth1', 'eth2', 'eth3' ] } };


$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'macro exp. in eval' );
