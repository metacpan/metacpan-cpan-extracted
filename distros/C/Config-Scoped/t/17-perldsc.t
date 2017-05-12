# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );

my $text = <<'eot';
'a' => [ '1', '2', '3', { 'foo' => 'bar' }, '4', '5', '6' ]
eot

my $expected =
  { '_GLOBAL' =>
      { 'a' => [ '1', '2', '3', { 'foo' => 'bar' }, '4', '5', '6' ] } };

isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );
is_deeply( $p->parse( text => $text ), $expected, 'hol' );

$text = <<'eot';
'bar' => { 'a' => '2' },
'baz' => { 'a' => '1' },
'foo' => { 'a' => '3' }
eot

$expected = {
    '_GLOBAL' => {
        'bar' => { 'a' => '2' },
        'baz' => { 'a' => '1' },
        'foo' => { 'a' => '3' }
    }
};

$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'hoh' );

