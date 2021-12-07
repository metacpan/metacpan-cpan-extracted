use strict;
use warnings;
use Test::More;
use Crypto::API;

is Crypto::API::_get( {a => 'foo'}, 'a' ), 'foo';

is Crypto::API::_get( { a => { b => { c => 'foo' } } }, 'a.b.c' ), 'foo';

is Crypto::API::_get( { a => { b => [ {}, { c => 'foo' } ] } }, 'a.b.1.c' ),
  'foo';

{
    local $SIG{__WARN__} = sub {
        like $_[0], qr/.a.b.d is not exists/;
    };
    Crypto::API::_get( { a => { b => { c => 'foo' } } }, 'a.b.d' );
}

eval { Crypto::API::_get( { a => { b => { c => 'foo' } } }, 'a.b.c..e' ) };

like $@, qr/Invalid path: a.b.c..e/;

{
    local $SIG{__WARN__} = sub {
        like $_[0], qr/.a.b.1 is not exists/;
    };

    Crypto::API::_get( { a => { b => [{ c => 'foo' }] } }, 'a.b.1' );
}

eval { Crypto::API::_get( { a => { b => { c => 'foo' } } }, 'a.b.c.e' ) };

like $@, qr/Path deadend .a.b.c.e/;

done_testing;
