use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

#Initialization of test scenario
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );

$world->tricks( { "Export quote Italy" => [30],
                  "Export quote France" => [30],
                  "Export quote Russia" => [30],
                  "Export quote Germany" => [30],
                  "Starting production0 Italy" => [30],
                  "Starting production1 Italy" => [30],
                  "Starting production2 Italy" => [30],
                  "Starting production3 Italy" => [30],
                  "Starting production0 France" => [30],
                  "Starting production1 France" => [30],
                  "Starting production2 France" => [30],
                  "Starting production3 France" => [30],
                  "Starting production0 United Kingdom" => [30],
                  "Starting production1 United Kingdom" => [30],
                  "Starting production2 United Kingdom" => [30],
                  "Starting production3 United Kingdom" => [30],
                  "Starting production0 Germany" => [30],
                  "Starting production1 Germany" => [30],
                  "Starting production2 Germany" => [30],
                  "Starting production3 Germany" => [30],
                  "Side for friendship between France and Italy" => [0],
                  "Random factor for friendship between France and Italy [floor: 35]" =>  [5],
                  "Side for friendship between Italy and France" => [0],
                  "Random factor for friendship between Italy and France [floor: 35]" =>  [5],
                  "Side for friendship between Germany and Italy" => [1],
                  "Random factor for friendship between Germany and Italy [floor: 35]" =>  [35],
                  "Side for friendship between Italy and Germany" => [1],
                  "Random factor for friendship between Italy and Germany [floor: 35]" =>  [35],
                  "Side for friendship between Italy and United Kingdom" => [0],
                  "Random factor for friendship between Italy and United Kingdom [floor: 30]" =>  [30],
                  "Side for friendship between United Kingdom and Italy" => [0],
                  "Random factor for friendship between United Kingdom and Italy [floor: 30]" =>  [30],
                  "Delta production Italy" => [(0) x 20],
                  "Delta production France" => [(0) x 20],
                  "Delta production United Kingdom" => [(0) x 20],
                  "Delta production Germany" => [(0) x 20],
                  "Crisis action choose" => [(5) x 200],
              });  
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });

$world->forced_advisor("military");
$world->autoplay(1);
$world->add_crisis('Italy', 'United Kingdom' );
$world->get_nation("Italy")->army(15);
$world->get_nation("United Kingdom")->army(3);
$world->elaborate_turn("1970/1");
is($world->get_events("MILITARY SUPPORT TO Germany STARTED BY Italy", "1970/1"), 1, "Italy moved to Germany");
$world->elaborate_turn("1970/2");
is($world->get_events("WAR BETWEEN Italy AND United Kingdom STARTED", "1970/2"), 1, "Italy attacked UK");

done_testing();

