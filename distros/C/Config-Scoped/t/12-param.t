# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 8;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );

my $text = <<'eot';
{ #1
    { #2
	{ #3
	     a=3
	}
	a=2
    }
    a=1
}
foo{}
eot

my $expected = { foo => {} };


isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );
is_deeply( $p->parse( text => $text ), $expected, 'lexically scoped' );

$text = <<'eot';
{ #1
    { #2
	{ #3
	    a=3
	    foo{}
	}
	a=2
	bar{}
    }
    a=1
    baz{}
}
eot

$expected = {
    'foo' => { 'a' => '3' },
    'bar' => { 'a' => '2' },
    'baz' => { 'a' => '1' },
};

$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'lexically scoped' );

$text = <<'eot';
a = default;
foo { %warnings param off; a = 1 }
bar { }
eot

$expected = {
    'foo' => { 'a' => '1' },
    'bar' => { 'a' => 'default' },
};

$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'parameter redefinition' );

$text = <<'eot';
a = default;
foo { a = 1 }
bar { }
eot

$p = Config::Scoped->new;
eval { $p->parse( text => $text ) };
isa_ok($@, 'Config::Scoped::Error::Validate::Parameter');
like($@, qr/redefinition/i, "$@");

$text = <<'eot';
LowerCase = 'Values dont convert'
eot

$expected = { _GLOBAL => { 'lowercase' => 'Values dont convert', }, };

$p = Config::Scoped->new(lc => 1);
is_deeply( $p->parse( text => $text ), $expected, 'lowercase conversion' );

