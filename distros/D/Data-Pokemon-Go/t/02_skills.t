use utf8;
use strict;
use warnings;

use Test::More 1.302 tests => 3;
use Test::More::UTF8;

use lib './lib';

BEGIN{
    use_ok( 'Data::Pokemon::Go::Skill', qw( @ALL ) );                   # 1
}

my $pg = new_ok 'Data::Pokemon::Go::Skill';                             # 2

subtest 'Kanto' => sub {
    plan tests => 166;
    my @skills = @Data::Pokemon::Go::Skill::All;
    foreach my $name (@skills) {
        next unless $pg->exists($name);
        $pg->name($name);
        note "${\$name}は", join( '／', $pg->types() ), "タイプ";
        note '威力は' . $pg->strength();
        note '回復量は', $pg->energy() unless $pg->gauges();
        note 'ゲージ数は', $pg->gauges() if $pg->gauges();
        note 'モーションは', $pg->motion();
        note 'DPSは' . $pg->DPS();
        note 'EPSは', $pg->EPS() if $pg->EPS();
        note '総合評価は', $pg->point() if $pg->point();
        like $pg->point(), qr/^(:?\s?\d{1,2}\.\d{2})$/, "difining the points for $name is ok";
    }
};

done_testing();
