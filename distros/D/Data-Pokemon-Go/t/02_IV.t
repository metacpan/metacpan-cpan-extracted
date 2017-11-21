use utf8;
use strict;
use warnings;

use Test::More 1.302 tests => 3;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDERR,                   ":utf8";

use lib './lib';

use Data::Pokemon::Go::Pokemon;
my @pokemon = @Data::Pokemon::Go::Pokemon::All;
my $pg = Data::Pokemon::Go::Pokemon->new();

use_ok 'Data::Pokemon::Go::IV';                                               # 1
my $IV = new_ok 'Data::Pokemon::Go::IV';                                      # 2

subtest 'Kanto' => sub {
    plan tests => 151;
    foreach my $name (@pokemon) {
        next unless $pg->exists($name);
        $pg->name($name);
        my $id = $pg->id;
        note $pg->name . "($id)は" . join( '／', @{$pg->types()} ) . "タイプ";
        note '種族値は';
        note 'HPが' . $pg->stamina();
        note '攻撃が' . $pg->attack();
        note '防御が' . $pg->defense();
        my $CP = $IV->_calculate_CP( name => $name, LV => 20, ST => 15, AT => 15, DF => 15 );
        note "個体値完璧の時のCPは$CP";
        is $CP, $pg->hatchedMAX(), "calculate CP for $name is ok";
    }
};

done_testing();
