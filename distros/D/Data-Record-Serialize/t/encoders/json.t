#!perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

use JSON::MaybeXS;

my ( $s, $buf );

ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode  => 'json',
            output  => \$buf,
            nullify => ['c'],
          ),
          ;
    },
    "constructor"
) or diag $@;

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );
$s->send( { a => 1, b => 2 } );
$s->send( { a => 1, b => 2, c => '' } );

my @VAR1;

ok( lives { @VAR1 = JSON->new->incr_parse( $buf ) }, 'deserialize record', )
  or diag $@;

is(
    \@VAR1,
    [
        hash {
            field a => '1';
            field b => '2';
            field c => 'nyuck nyuck';
            end;
        },
        hash {
            field a => '1';
            field b => '2';
            end;
        },
        hash {
            field a => '1';
            field b => '2';
            field c => undef;
           end;
        },
    ],
    'properly formatted'
);

done_testing;
