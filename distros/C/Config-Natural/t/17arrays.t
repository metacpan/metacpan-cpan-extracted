use strict;
use Test;
BEGIN { plan tests => 32 }
use Config::Natural;
use File::Spec;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

my $weapons;
my @expected_weapons = (
        'progressive knife', 'sonic glaive', 'smash hook', 
        'palet riffle', 'rocket launcher', 'positron gun', 
        'N2 bomb'
);

$obj->read_source(File::Spec->catfile('t', 'eva', 'weapons.txt'));

$weapons = -1;
$weapons = $obj->param('weapons');
ok( ref $weapons, 'ARRAY'                      );  #01
ok( scalar @$weapons, scalar @expected_weapons );  #02

$weapons = -1;
$weapons = $obj->value_of('weapons');
ok( ref $weapons, 'ARRAY'                      );  #03
ok( scalar @$weapons, scalar @expected_weapons );  #04
for my $i (0..$#expected_weapons) {                #05-11
    ok( $weapons->[$i], $expected_weapons[$i] )
}

$weapons = -1;
$weapons = $obj->value_of('/weapons[*]');
ok( ref $weapons, 'ARRAY'                      );  #12
ok( scalar @$weapons, scalar @expected_weapons );  #13
for my $i (0..$#expected_weapons) {                #14-20
    ok( $weapons->[$i], $expected_weapons[$i] )
}


# Now reading t/nerv.txt
undef $obj;
$obj = new Config::Natural File::Spec->catfile('t', 'nerv.txt');

my @expected_operators = ('Ibuki Maya', 'Hyuga Makoto', 'Aoba Shigeru');
my $operators = $obj->value_of('/nerv/operators[*]');
ok( ref $operators, 'ARRAY'                        );  #21
ok( scalar @$operators, scalar @expected_operators );  #22
for my $i (0..$#expected_operators) {                  #23-25
    ok( $operators->[$i], $expected_operators[$i] )
}

my @expected_pilots = (
    'Ayanami Rei', 'Soryu Asuka Langley', 'Ikari Shinji',
    'Suzuhara Toji', 'Nagisa Kaoru'
);
my $pilots = $obj->value_of('/nerv/pilots[*]');
ok( ref $pilots, 'ARRAY'              );  #26
ok( scalar @$pilots, @expected_pilots );  #27
for my $i (0..$#expected_pilots) {        #28-32
    ok( $pilots->[0], $expected_pilots[0] )
}

