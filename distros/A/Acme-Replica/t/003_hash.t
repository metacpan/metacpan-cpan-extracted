use strict;
use warnings;
use Test::More tests => 3;

use Acme::Replica;

my %hash = (
    hoge => 'hoge value',
    fuga => 'fuga value',
);

my %replica = replica_of( \%hash );
is($replica{pack('H2', '1c') . 'hoge'}, 'hoge value');
is($replica{pack('H2', '1c') . 'fuga'}, 'fuga value');
isnt($replica{hoge}, 'fuga value');

