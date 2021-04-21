use strict;
use warnings;
use Test::More;
use Crypto::API;

{package foo;
    use Moo;
    extends 'Crypto::API';

    sub set_baz {}
    sub set_qux {{request=> {}}}
    sub set_quux {{request => {}, response => {}}}
    sub set_quuz {{request => {method => 'get'}, response => {}}}
}

my $foo = foo->new;

is ref $foo, 'foo';
ok UNIVERSAL::isa($foo, 'Crypto::API');

eval '$foo->bar';

like $@, qr/Can't call method 'bar'/;

eval '$foo->baz';

like $@, qr/Missing request/;

eval '$foo->qux';

like $@, qr/Missing response/;

eval '$foo->quux';

like $@, qr/Missing method/;

eval '$foo->quuz';

like $@, qr/Missing path or URL/;

done_testing;
