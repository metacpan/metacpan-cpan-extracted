use v5.10;
use lib "lib";
use BalanceOfPower::World;
use Test::More;

use Data::Dumper;

#Initialization of test scenario
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );

$world->init_random("nations-test3.txt", "borders-test3.txt", 
                    { alliances => 0,
                      trades => 0 });
$world->pre_decisions_elaborations("1970/1");

my $commands = $world->build_commands();
$commands->set_player("Tester");
my %plan;
my $player = $world->get_player("Tester");
$player->position('Italy');

%plan = $world->make_travel_plan($player->position); 
is_deeply(\%plan, 
          { ground => { 'France' => { status => 'OK', 'cost' => 2 },
                        'Germany' => { status => 'OK', 'cost' => 2 } },  
            air => {} },
          "Good travel plan - minimal situation");

$world->generate_traderoute("Italy", "Russia", 0);
$world->generate_traderoute("Italy", "United Kingdom", 0);
%plan = $world->make_travel_plan($player->position); 
is_deeply(\%plan, 
          { ground => { 'France' =>  { status => 'OK', 'cost' => 2 },
                        'Germany' =>  { status => 'OK', 'cost' => 2 } },  
            air => { 'Russia' =>  { status => 'OK', 'cost' => 4 },
                     'United Kingdom' =>  { status => 'OK', 'cost' => 2 }} },
            "Good travel plan - traderoutes present");

$world->get_nation('Germany')->army(7);
$world->get_nation('United Kingdom')->army(7);
$world->ia_orders([ "Germany: DECLARE WAR TO United Kingdom" ]);
$world->post_decisions_elaborations();
$world->pre_decisions_elaborations();
%plan = $world->make_travel_plan($player->position); 
is_deeply(\%plan, 
          { ground => { 'France' =>  { status => 'OK', 'cost' => 2 },
                        'Germany' =>  { status => 'OK', 'cost' => 2 } },  
            air => { 'Russia' =>  { status => 'OK', 'cost' => 4 },
                     'United Kingdom' =>  { status => 'KO' }} },
            "Good travel plan - war blocks air routes");

$world->generate_traderoute("Italy", "France", 0);
%plan = $world->make_travel_plan($player->position); 
is_deeply(\%plan, 
          { ground => { 'Germany' =>  { status => 'OK', 'cost' => 2 } },  
            air => { 'France' =>  { status => 'OK', 'cost' => 1 },
                     'Russia' =>  { status => 'OK', 'cost' => 4 },
                     'United Kingdom' =>  { status => 'KO' }} },
            "Good travel plan - Air has priority on ground");

$world->get_nation("Italy")->add_internal_disorder(90, $world);
$world->post_decisions_elaborations();
$world->pre_decisions_elaborations();
%plan = $world->make_travel_plan($player->position); 
is_deeply(\%plan, 
          { ground => { 'France' =>  { status => 'OK', 'cost' => 2 },
                        'Germany' =>  { status => 'OK', 'cost' => 2 } },  
            air => { 'Russia' =>  { status => 'KO' },
                     'United Kingdom' => { status => 'KO' },
                     'France' => { status => 'KO' } } },
            "Good travel plan - civil war in italy block all the air routes");

done_testing();



