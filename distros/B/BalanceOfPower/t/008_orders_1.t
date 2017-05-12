use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

#Initialization of test scenario
# Italy
# France
# United Kingdom
# Russia
# Germany
#
# Orders tested here:
#    * DIPLOMATIC PRESSURE
#    * BUILD TROOPS
#    * BOOST PRODUCTION
#    * LOWER DISORDER
#    * ADD ROUTE
#    * DELETE TRADEROUTE


my $first_year = 1970;

#Scenario: a neighbor has military support from an enemy nation
my $world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->tricks( { "Export quote Italy" => [50],
              });
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });

my @diplomacies = (
    ['Italy', 'Germany', 80],
    ['Italy', 'France', 50], #We'll do pressure on this
    ['Italy', 'United Kingdom', 76],
    ['Italy', 'Russia', 22],
    ['France', 'Germany', 50],
    ['France', 'United Kingdom', 50],
    ['France', 'Russia', 50],
);


for(@diplomacies)
{
    $world->set_diplomacy($_->[0], $_->[1], $_->[2]);
}
my @internal_event;
my @remain_event;
my @disorder_event;

$world->pre_decisions_elaborations('1970/1');
$world->get_nation("Italy")->prestige(15);
$world->ia_orders( [ "Italy: DIPLOMATIC PRESSURE ON France" ]);
$world->post_decisions_elaborations();
is($world->diplomacy_exists("France", "Italy")->factor, 44, "DIPLOMATIC PRESSURE: France<->Italy: 44");
is($world->diplomacy_exists("France", "Germany")->factor, 44, "DIPLOMATIC PRESSURE: France<->Germany: 44");
is($world->diplomacy_exists("France", "United Kingdom")->factor, 44, "DIPLOMATIC PRESSURE: France<->United Kingdom: 44");
is($world->diplomacy_exists("France", "Russia")->factor, 50, "DIPLOMATIC PRESSURE: France<->Russia: 50");


$world->pre_decisions_elaborations('1970/2');
$world->get_nation("Italy")->army(5);
$world->get_nation("Italy")->production(200);
$world->ia_orders( [ "Italy: BUILD TROOPS" ]);
$world->post_decisions_elaborations();
is($world->get_nation("Italy")->army, 6, "BUILD TROOPS: Italy created new troops");
@internal_event = $world->get_nation("Italy")->get_events("INTERNAL", "1970/2");
is($internal_event[0], "INTERNAL 80", "BUILD TROOPS: Cost for new army payed");


$world->pre_decisions_elaborations('1970/3');
$world->get_nation("Italy")->production(200);
$world->ia_orders( [ "Italy: BOOST PRODUCTION" ]);
$world->post_decisions_elaborations();
@internal_event = $world->get_nation("Italy")->get_events("INTERNAL", "1970/3");
@remain_event = $world->get_nation("Italy")->get_events("REMAIN", "1970/3");
is($internal_event[0], "INTERNAL 120", "BOOST PRODUCTION: Domestic production boosted");
is($remain_event[0], "REMAIN 120", "BOOST PRODUCTION: Export production boosted");


$world->pre_decisions_elaborations('1970/4');
$world->get_nation("Italy")->production(200);
$world->get_nation("Italy")->internal_disorder(50);
$world->get_nation("Italy")->frozen_disorder(1);
$world->ia_orders( [ "Italy: LOWER DISORDER" ]);
$world->post_decisions_elaborations();
is($world->get_nation("Italy")->internal_disorder, 40, "LOWER DISORDER: Disorder lowered");
@internal_event = $world->get_nation("Italy")->get_events("INTERNAL", "1970/4");
is($internal_event[0], "INTERNAL 80", "LOWER DISORDER: Cost for lowering disorder payer");
$world->get_nation("Italy")->frozen_disorder(0);


$world->pre_decisions_elaborations('1971/1');
$world->get_nation("Italy")->production(200);
$world->get_nation("Germany")->production(200);
$world->set_diplomacy("Italy", "Germany", 80);
$world->ia_orders( [ "Italy: ADD ROUTE", "Germany: ADD ROUTE" ] );
$world->post_decisions_elaborations();
my $route = $world->route_exists("Italy", "Germany");
ok($route, "ADD ROUTE: Trade route Italy<->Germany created");
is($world->diplomacy_exists("Italy", "Germany")->factor, 86, "ADD ROUTE: Italy<->Germany diplomacy: 86");

$world->pre_decisions_elaborations('1971/2');
$world->get_nation("Italy")->production(200);
$world->get_nation("Germany")->production(200);
$world->set_diplomacy("Italy", "Germany", 80);
$world->ia_orders( [ "Italy: DELETE TRADEROUTE Italy->Germany" ] );
$world->post_decisions_elaborations();
$route = $world->route_exists("Italy", "Germany");
ok(! $route, "DELETE TRADEROUTE: Trade route Italy<->Germany deleted");
is($world->diplomacy_exists("Italy", "Germany")->factor, 74, "DELETE TRADEROUTE: Italy<->Germany diplomacy: 74");


done_testing();
