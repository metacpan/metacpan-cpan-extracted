use utf8;
use strict;
use warnings;

use Test::More 1.302 tests => 6;
use Path::Tiny;
use YAML::XS;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDERR,                   ":utf8";

use lib './lib';

use Data::Pokemon::Go::Pokemon;
my $pg = Data::Pokemon::Go::Pokemon->new();

use_ok 'Data::Pokemon::Go::IV';                                         # 1
my $IV = new_ok 'Data::Pokemon::Go::IV';                                # 2

subtest 'Kanto' => sub{ IVs('Kanto') };                                 # 3
subtest 'Johto' => sub{ IVs('Johto') };                                 # 4
subtest 'Hoenn' => sub{ IVs('Hoenn') };                                 # 5
subtest 'Alola' => sub{ IVs('Alola') };                                 # 6

done_testing();

exit;

sub IVs {
    my $region = shift;
    my $in_file = path( 'data', "$region.yaml" );
    my $data = YAML::XS::LoadFile($in_file);
    map{ $data->{$_}{'name'} = $_ } keys %$data;
    my @pokemons = map{ $_->{'name'} } sort{ $a->{'ID'} cmp $b->{'ID'} } values %$data;
    plan tests => scalar @pokemons * 2;
    foreach my $name (@pokemons) {
        next unless $pg->exists($name);
        $pg->name($name);
        SKIP: {
            skip "is Not Available", 2 if $pg->isNotAvailable();
            my $id = $pg->id;
            note $pg->name . "($id)は" . join( '／', @{$pg->types()} ) . "タイプ";
            note '種族値は';
            note 'HPが' . $pg->stamina();
            note '攻撃が' . $pg->attack();
            note '防御が' . $pg->defense();
            my $CP = $IV->_calculate_CP( name => $name, LV => 20, ST => 15, AT => 15, DF => 15 );
            note "孵化時の個体値完璧の時のCPは$CP";
            is $CP, $pg->hatchedMAX(), "calculate CP for $name is ok";
            SKIP: {
                skip "isNotWild", 1 if $pg->isNotWild();
                $CP = $IV->_calculate_CP( name => $name, LV => 25, ST => 15, AT => 15, DF => 15 );
                note "ブースト時の個体値完璧の時のCPは$CP";
                is $CP, $pg->boostedMAX(), "calculate CP for $name is ok";
            }
        }
    }
};
