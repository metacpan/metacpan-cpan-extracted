#!perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

my ( $s );

ok(
    lives {
        $s = Data::Record::Serialize->new( encode => 'null', )
    },
    "constructor"
) or diag $@;

ok( lives { $s->send( { a => 1, b => 2, c => 'nyuck nyuck' } ) }, 'send' );

done_testing;
