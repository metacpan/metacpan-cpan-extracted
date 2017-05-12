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
#   * ECONOMIC AID
#   * TREATY COM
#   * AID INSURGENTS IN
#   * MILITARY AID FOR
#   * PROGRESS 


my $first_year = 1970;


my $world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->tricks( { "Export quote Italy" => [50],
                  "Export quote Germany" => [50],
              });
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });


my @internal_event;
my @remain_event;
my @disorder_event;

$world->pre_decisions_elaborations('1970/1');
$world->set_diplomacy("Italy", "Germany", 60);
$world->get_nation("Italy")->production(200);
$world->get_nation("Germany")->production(100);
$world->ia_orders( [ "Italy: ECONOMIC AID FOR Germany" ] );
$world->post_decisions_elaborations();
@remain_event = $world->get_nation("Italy")->get_events("REMAIN", "1970/1");
is($remain_event[0], "REMAIN 70", "ECONOMIC AID: Italy paid for economic aid");
@internal_event = $world->get_nation("Germany")->get_events("INTERNAL", "1970/1");
@remain_event = $world->get_nation("Germany")->get_events("REMAIN", "1970/1");
is($internal_event[0], "INTERNAL 78", "ECONOMIC AID: Domestic production incremented by italian economic aid");
is($remain_event[0], "REMAIN 78", "ECONOMIC AID: Export production incremented by italian economic aid");
is($world->diplomacy_exists("Italy", "Germany")->factor, 69, "ECONOMIC AID: Italy<->Germany diplomacy: 69");

$world->generate_traderoute("Italy", "Germany", 0);
$world->pre_decisions_elaborations('1970/2');
$world->set_diplomacy("Italy", "Germany", 60);
$world->get_nation("Italy")->prestige(20);
$world->ia_orders( [ "Italy: TREATY COM WITH Germany" ] );
$world->post_decisions_elaborations();
my $treaty = $world->exists_treaty_by_type("Italy", "Germany", "commercial");
ok($treaty, "TREATY COM WITH: Italy and Germany have a com treaty");
$world->delete_treaty("Italy", "Germany");
$world->delete_traderoute("Italy", "Germany");

$world->pre_decisions_elaborations('1970/3');
$world->set_diplomacy("Italy", "France", 50);
$world->get_nation("Italy")->production(200);
$world->get_nation("France")->internal_disorder(30);
$world->get_nation("France")->frozen_disorder(1);
$world->ia_orders( [ "Italy: AID INSURGENTS IN France" ] );
$world->post_decisions_elaborations();
@remain_event = $world->get_nation("Italy")->get_events("REMAIN", "1970/3");
is($remain_event[0], "REMAIN 75", "AID INSURGENTS: Italy paid the cost to aid insurgents");
is($world->get_nation("France")->internal_disorder, 45, "AID INSURGENTS: internal disorder raised in France");
$world->get_nation("France")->frozen_disorder(0);

$world->pre_decisions_elaborations('1970/4');
$world->set_diplomacy("Italy", "Germany", 80);
$world->get_nation("Italy")->production(200);
$world->get_nation("Germany")->army(2);
$world->ia_orders( [ "Italy: MILITARY AID FOR Germany" ] );
$world->post_decisions_elaborations();
@remain_event = $world->get_nation("Italy")->get_events("REMAIN", "1970/4");
is($remain_event[0], "REMAIN 80", "MILITARY AID: Italy paid the cost to military aid Germany");
is($world->get_nation("Germany")->army, 3, "MILITARY AID: Germany has new soldiers");
is($world->diplomacy_exists("Italy", "Germany")->factor, 87, "MILITARY AID: Italy<->Germany diplomacy: 87");


$world->pre_decisions_elaborations('1971/1');
$world->get_nation("Italy")->production(200);
$world->get_nation("Italy")->progress(0);
$world->ia_orders( [ "Italy: PROGRESS" ] );
$world->post_decisions_elaborations();
@remain_event = $world->get_nation("Italy")->get_events("INTERNAL", "1971/1");
is($remain_event[0], "INTERNAL 70", "PROGRESS: Italy paid the cost for progress");
is($world->get_nation("Italy")->progress, 0.1, "PROGRESS: Italy progress is now 0.1");



done_testing();

