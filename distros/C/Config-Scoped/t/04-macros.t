# vim: cindent ft=perl

use warnings;
use strict;

use Test::More tests => 8;
use File::Spec;

BEGIN { use_ok('Config::Scoped') }
my $macros_cfg = File::Spec->catfile( 't', 'files', 'macros.cfg' );
my ($p, $cfg);
isa_ok($p = Config::Scoped->new(file => $macros_cfg), 'Config::Scoped');
ok($p->set_warnings(name => 'perm', switch => 'off'), 'permission warnings off');
ok(eval {$cfg = $p->parse}, 'parsing macros');

my $text = <<'eot';
{
    %macro _M1 m1;    # lexically scoped
    {
	%macro _M2 m2;
	foo { _M1 = "_M1"; _M2 = "_M2" }
    }
    bar { _M1 = "_M1"; _M2 = "_M2" }
}
baz { _M1 = "_M1"; _M2 = "_M2" }
eot

my $expected = {
    'foo' => {
        '_M1' => 'm1',
        '_M2' => 'm2',
    },
    'bar' => {
        '_M1' => 'm1',
        '_M2' => '_M2',
    },
    'baz' => {
        '_M1' => '_M1',
        '_M2' => '_M2',
    },
};



$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'macros lexically scoped' );

$text = <<'eot';
{
    %macro _M1 m1;    # lexically scoped
    foo { _M1 = "_M1" }
}
%macro _M1 'no redefinition';
bar { _M1 = "_M1" }
eot

$expected = {
    'foo' => { '_M1' => 'm1' },
    'bar' => { '_M1' => 'no redefinition' },
};


$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'macros lexically scoped' );

# no metacharacters expansion
$text = <<'eot';
%macro _M. 'quote metacharacter .';
bar { _M1 = "_M1" }
eot

$expected = {
    'bar' => { '_M1' => '_M1' },
};

$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'quoting meta-characters' );

$text = <<'eot';
%macro _M. 'quote metacharacter .';
foo { _M1 = "_M." }
eot

$expected = {
    'foo' => { '_M1' => 'quote metacharacter .' },
};

$p = Config::Scoped->new;
is_deeply( $p->parse( text => $text ), $expected, 'quoting meta-characters' );


