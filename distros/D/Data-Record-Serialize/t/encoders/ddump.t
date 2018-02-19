#!perl

use Test2::V0;

use lib 't/lib';

use Data::Record::Serialize;

use Data::Dumper;

my ( $s, $buf );

ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode => 'ddump',
            output => \$buf,
          ),
          ;
    },
    "constructor"
) or diag $@;

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );
$s->send( { a => 1, b => 2 } );


my @VAR1;

ok( lives { @VAR1 = eval $buf }, 'deserialize record', ) or diag $@;

is(
    \@VAR1,
    [ {
            a => '1',
            b => '2',
            c => 'nyuck nyuck',
        },
        {
            a => '1',
            b => '2',
        },
    ],
    'properly formatted'
);

done_testing;
