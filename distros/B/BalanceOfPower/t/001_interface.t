use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use BalanceOfPower::Relations::Alliance;
use BalanceOfPower::Relations::Crisis;
use BalanceOfPower::Relations::War;
use Test::More;

#Initialization of test scenario
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random('nations-test1.txt', 'borders-test1.txt');
#Stubbed data

$world->get_nation("Germany")->army(15);
$world->get_nation("France")->army(15);
$world->add_alliance('Italy', 'Russia');
$world->add_crisis('Germany', 'France' );
my $war1 = BalanceOfPower::Relations::War->new(node1 => 'Luksoberg', 
                                                    node2 => 'Reditrout',
                                                    attack_leader => 'Luksoberg',
                                                    war_id => 1000000,
                                                    node1_faction => 0,
                                                    node2_faction => 1,
                                                    start_date => "1965/1",
                                                    log_active => 0);
$world->add_war($war1);
$war1->register_event("Starting army for Luksoberg: 12");                                            
$war1->register_event("Starting army for Reditrout: 7");                                            
$world->current_year("1968/2");
$world->delete_war('Luksoberg', 'Reditrout', "Fake war");

$world->add_war(BalanceOfPower::Relations::War->new(node1 => 'Germany', 
                                                    node2 => 'France',
                                                    attack_leader => 'Germany',
                                                    war_id => 0000000,
                                                    node1_faction => 0,
                                                    node2_faction => 1,
                                                    start_date => "1970/1",
                                                    log_active => 0));
$world->start_military_support($world->get_nation("Germany"), $world->get_nation("Russia"));

$world->autoplay(1);
$world->elaborate_turn("1970/1");
$world->autoplay(0);

#Initialization of commands
my $commands = $world->build_commands();
my $result;


#Generic commands
foreach my $c ( ("years", "commands", "wars", "crises", "alliances", "situation", "war history", "influences", "treaties") )
{
    $commands->query($c);
    $result = $commands->report_commands();
    is($result->{status}, 1, "Command elaborated: $c");
}

#Bad command
$commands->query("wrong");
$result = $commands->report_commands();
is($result->{status}, 0, "Bad command returns 0");

#Nation configured
$commands->query('Germany');
$result = $commands->report_commands();
is($result->{status}, 1, "Command elaborated: Germany");

#Commands for nation
foreach my $c ( ("borders", "relations", "events", "status", "history", "plot internal disorder") )
{
    $commands->query($c);
    $result = $commands->report_commands();
    is($result->{status}, 1, "Command elaborated: $c");
}

foreach my $c ( ("Germany borders", "Germany relations", "Germany events", "Germany status", "Germany history", "Germany plot internal disorder") )
{
    $commands->query($c);
    $result = $commands->report_commands();
    is($result->{status}, 1, "Command elaborated: $c");
}

#Distance
$commands->query("distance Italy-United Kingdom");
$result = $commands->report_commands();
is($result->{status}, 1, "Command elaborated: distance Italy-United Kingdom");


#Year command
$commands->query("1970/1");
$result = $commands->report_commands();
is($result->{status}, 1, "Command elaborated: 1970/1");

$commands->query('clear');
$result = $commands->report_commands();
is($result->{status}, 1, "Command elaborated: clear");

$commands->query("1970/1");
$result = $commands->report_commands();
is($result->{status}, 1, "Command elaborated: 1970/1");

$commands->query("turn");
$result = $commands->turn_command();
is($result->{status}, 1, "Command elaborated: turn");

done_testing;

