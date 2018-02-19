#!perl

use Test2::V0;
use Test2::Plugin::NoWarnings;

use lib 't/lib';

use Data::Record::Serialize;

use File::Slurper qw[ read_text ];
use File::Spec::Functions qw[ catfile ];
my ( $s, $buf );

ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode => 'rdb',
            output => \$buf,
            fields => [qw[ a b c ]],
          ),
          ;
    },
    "constructor"
) or diag $@;

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );
$s->send( { a => 1, b => 2 } );

is(
    $buf,
    read_text( catfile( qw[ t data encoders data.rdb ] ) ),
    'properly formatted'
);

done_testing;
