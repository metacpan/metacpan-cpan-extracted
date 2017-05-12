#!/usr/bin/perl -w

use Test::More tests => 7;
use Test::Warn;

use_ok 'Archive::Any';

isa_ok( Archive::Any->new( 't/naughty.tar', 'tar' ), 'Archive::Any' );

# Recognizes tar files with weird extensions
isa_ok( Archive::Any->new( 't/naughty.hominawoof' ), 'Archive::Any' );

warning_like {
    ok( !Archive::Any->new( 't/naughty.tar', 'hominawoof' ) );
}
qr{No mime type found for type 'hominawoof'}, "right warning, unknown type";

warning_like {
    ok( !Archive::Any->new( 't/garbage.foo' ) );
}
qr{No handler available for type 'text/plain'}, "right warning, no type";
