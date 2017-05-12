use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

#Initialization of test scenario
my $first_year = 1970;


#Scenario: a neighbor has military support from an enemy nation
my $world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->add_crisis('Italy', 'United Kingdom' );
$world->change_diplomacy('Italy', 'Germany', 100);
$world->change_diplomacy('Italy', 'France', 100);
$world->change_diplomacy('Italy', 'United Kingdom', -100);
$world->change_diplomacy('Germany', 'United Kingdom', 100);
$world->get_nation('United Kingdom')->army(20);
$world->start_military_support($world->get_nation('United Kingdom'), $world->get_nation('Germany'));
my $italy = $world->get_nation('Italy');
$italy->production(100);
$italy->prestige(20);
$world->forced_advisor("domestic");
is($italy->decision($world), 'Italy: TREATY NAG WITH Germany', "Italy will subscribe a non aggression treaty with Germany (dangerous neighbor)");
ok($world->in_military_range("United Kingdom", "Italy"), "With no treaty Italy is in UK military range");
$world->create_treaty('Italy', 'Germany', "no aggression");
ok(! $world->in_military_range("United Kingdom", "Italy"), "With treaty Italy is NOT in UK military range");


#Scenario: neutralize the supporter of the enemy
$world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->add_crisis('Italy', 'United Kingdom' );
$world->change_diplomacy('Italy', 'Germany', 100);
$world->change_diplomacy('Italy', 'France', 100);
$world->change_diplomacy('Italy', 'United Kingdom', -100);
$world->change_diplomacy('Russia', 'United Kingdom', 100);
$world->change_diplomacy('Russia', 'Italy', 100);
$world->get_nation('Russia')->army(20);
$world->start_military_support($world->get_nation('Russia'), $world->get_nation('United Kingdom'));
$italy = $world->get_nation('Italy');
$italy->production(100);
$italy->prestige(20);
$italy->army(15);
my $uk = $world->get_nation('United Kingdom');
$uk->production(100);
$uk->army(15);
$world->tricks( {"War risiko: throw for attacker Italy" => [ 6, 6, 6 ],
                "War risiko: throw for defender United Kingdom" => [ 0, 0, 0 ]}
              );
$world->forced_advisor("domestic");
is($italy->decision($world), 'Italy: TREATY NAG WITH Russia', "Italy will subscribe a non aggression treaty with Russia (enemy supporter)");
$world->create_treaty('Italy', 'Russia', "no aggression");
my @sups = $world->supported('United Kingdom');
my $before_support = $sups[0]->army;
$world->create_war($world->get_nation('Italy'), $world->get_nation('United Kingdom'));
$world->fight_wars();
@sups = $world->supported('United Kingdom');
my $after_support = $sups[0]->army;
is($before_support, $after_support, "Russian army not involved in war between Italy and United Kingdom");


#Scenario: neutralize the ally of the enemy
$world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->current_year('1970/1');
$world->init_year('1970/1');
$world->add_crisis('Italy', 'United Kingdom' );
$world->change_diplomacy('Italy', 'Germany', 100);
$world->change_diplomacy('Italy', 'France', 100);
$world->change_diplomacy('Italy', 'United Kingdom', -100);
$world->change_diplomacy('Russia', 'United Kingdom', 100);
$world->change_diplomacy('Russia', 'Italy', 100);
$world->add_alliance('Russia', 'United Kingdom');
$italy = $world->get_nation('Italy');
$italy->production(100);
$italy->prestige(20);
my $russia = $world->get_nation('Russia');
$russia->army(10);
$world->forced_advisor("domestic");
is($italy->decision($world), 'Italy: TREATY NAG WITH Russia', "Italy will subscribe a non aggression treaty with Russia (enemy ally)");
$world->create_treaty('Italy', 'Russia', "no aggression");
my $event_to_trace_1 = 'NO POSSIBILITY TO PARTECIPATE TO WAR LINKED TO WAR BETWEEN United Kingdom AND Italy FOR Russia';
my $event_to_trace_2 = 'NO POSSIBILITY TO PARTECIPATE TO WAR LINKED TO WAR BETWEEN Italy AND United Kingdom FOR Russia';
$world->create_war($world->get_nation('United Kingdom'), $world->get_nation('Italy'));
is($world->get_events($event_to_trace_1, "1970/1"), 1, "Russia refused to partecipate to war UK->Italy");
$world->wars->reset();
$world->create_war($world->get_nation('Italy'), $world->get_nation('United Kingdom'));
is($world->get_events($event_to_trace_2, "1970/1"), 1, "Russia refused to partecipate to war Italy->UK");


#Scenario: generic neighbor
$world = BalanceOfPower::World->new( first_year => $first_year, silent => 1  );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->add_crisis('Italy', 'United Kingdom' );
$world->change_diplomacy('Italy', 'Germany', -100);
$world->change_diplomacy('Italy', 'France', 100);
$world->change_diplomacy('Italy', 'United Kingdom', -100);
$world->change_diplomacy('Russia', 'United Kingdom', 100);
$world->change_diplomacy('Russia', 'Italy', 100);
$italy = $world->get_nation('Italy');
$italy->production(100);
$italy->prestige(20);
$world->forced_advisor("domestic");
is($italy->decision($world), 'Italy: TREATY NAG WITH France', "Italy will subscribe a non aggression treaty with France (generic friendly neighbor)");







done_testing();

