# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );
isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );

my $text = <<'eot';
# global scope
b=1

# new scope
# b gets redefined within scope
{
    %warnings parameter off

    foo {
	b=2
    }
}

# collect global scope parameters
bar {}
eot

my $expected = {
    'foo' => { 'b' => '2' },
    'bar' => { 'b' => '1' },
};

is_deeply( $p->parse( text => $text ), $expected, 'scoping tests, parameter' );

$text = <<'eot';
%macro _M1 m1
{
    %warnings macro off
    %macro _M1 m2
    a = "_M1"
}

foo {
    a = "_M1"
}
eot

$expected = { 'foo' => { 'a' => 'm1' } };

$p = Config::Scoped->new();
is_deeply( $p->parse( text => $text ), $expected, 'scoping tests, macro' );

$text = <<'eot';
foo bar baz { global = 1}
{
    %warnings declaration off
    foo bar baz { scope = 1 }
}
eot

$expected = {
  'foo' => {
    'bar' => {
      'baz' => {
        'scope' => '1'
      }
    }
  }
};

$p = Config::Scoped->new();
is_deeply( $p->parse( text => $text ), $expected, 'scoping tests, declaration' );
