# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );
isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );

my $text = <<'eot';
hash = {
    a=b;
    %warnings param off;
    a= {
	a=c
    }
}
eot

my $expected = { '_GLOBAL' => { 'hash' => { 'a' => { 'a' => 'c' } } } };

is_deeply( $p->parse( text => $text ), $expected, 'hash tests' );

