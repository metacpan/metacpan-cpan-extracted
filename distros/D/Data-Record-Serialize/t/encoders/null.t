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

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );

ok( ! $s->has_types, "no types were derived" );

done_testing;
