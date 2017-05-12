#!perl

use Test::More;
use Test::Fatal;

use lib 't/lib';

use Data::Record::Serialize;

use lib 't/lib';

use Data::Record::Serialize::Utils qw[ load_json ];

my $class = eval { load_json }
  or plan skip_all => 'Some sort of JSON module is required for this test';

my $decode_json = load_json . "::decode_json";

my ( $s, $buf );

is(
    exception {
        $s = Data::Record::Serialize->new(
            encode => 'json',
            output => \$buf,
          ),
          ;
    },
    undef,
    "constructor"
);

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );

my $VAR1;

is( exception { $VAR1 = &$decode_json( $buf ) },
    undef,
    'deserialize record' );

is_deeply(
    $VAR1,
    {
        a => '1',
        b => '2',
        c => 'nyuck nyuck',
    },
    'properly formatted'
);

done_testing;
