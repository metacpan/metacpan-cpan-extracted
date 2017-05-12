use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

my $first_year = 1970;


#Scenario: a neighbor has military support from an enemy nation
my $world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->tricks( { "Export quote Italy" => [50],
                  "Export quote Germany" => [50],
                  "Civil war in Germany: government fight result" => [ (50) x 10 ],
                  "Civil war in Germany: rebels fight result" => [ (50) x 10 ],
              });
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });

$world->forced_advisor("noone");

$world->pre_decisions_elaborations('1970/1');
$world->get_nation("Germany")->production(100);
$world->post_decisions_elaborations();

$world->get_nation("Germany")->add_internal_disorder(85, $world);
$world->pre_decisions_elaborations('1970/2');
$world->post_decisions_elaborations();
is($world->get_civil_war("Germany")->rebel_provinces, 2, "Stalled civil war with no external intervention");

$world->pre_decisions_elaborations('1970/3');
$world->get_nation("Italy")->army(15);
$world->set_diplomacy("Italy", "Germany", 60);
$world->ia_orders([ "Italy: REBEL MILITARY SUPPORT Germany" ]);
$world->post_decisions_elaborations();
my $reb_sup = $world->exists_rebel_military_support("Italy", "Germany");
is($world->get_nation("Italy")->army, 11, "Italian army went to Germany");
ok($reb_sup, "Italy is supporting german rebels");
is($world->get_civil_war("Germany")->rebel_provinces, 2.5, "Italy intervention makes rebels win");
is($world->diplomacy_exists("Italy", "Germany")->factor, 46, "Friendship lowered to 56 because of civil war");

$world->pre_decisions_elaborations('1970/4');
$world->get_nation("France")->army(15);
$world->set_diplomacy("France", "Germany", 80);
$world->set_diplomacy("France", "Italy", 50);
$world->ia_orders([ "France: MILITARY SUPPORT Germany" ]);
$world->post_decisions_elaborations();
my $sup = $world->exists_military_support("France", "Germany");
is($world->get_nation("France")->army, 11, "French army went to Germany");
ok($sup, "France is supporting Germany");
is($world->get_civil_war("Germany")->rebel_provinces, 2.5, "Support vs rebel support makes civl war stall again");
is($world->diplomacy_exists("Italy", "Germany")->factor, 42, "Friendship Italy-Germany lowered to 52 because of civil war");
is($world->diplomacy_exists("France", "Germany")->factor, 90, "Friendship France-Germany raised to 90 because of support");
is($world->diplomacy_exists("France", "Italy")->factor, 47, "Friendship France-Italy lowered to 47 because of crossed support");

$world->pre_decisions_elaborations('1971/1');
$world->ia_orders([ "Italy: RECALL REBEL MILITARY SUPPORT Germany" ]);
$world->post_decisions_elaborations();
$reb_sup = $world->exists_rebel_military_support("Italy", "Germany");
is($world->get_nation("Italy")->army, 15, "Italian army went back home");
ok(! $reb_sup, "German rebels are not supported");
is($world->get_civil_war("Germany")->rebel_provinces, 2, "Civil war tide is now for the government");

done_testing();

