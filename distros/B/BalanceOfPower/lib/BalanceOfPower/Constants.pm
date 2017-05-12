package BalanceOfPower::Constants;
$BalanceOfPower::Constants::VERSION = '0.400115';
use strict;
use warnings;

use base 'Exporter';

#Random init parameters 
use constant MIN_EXPORT_QUOTE => 30;
use constant MAX_EXPORT_QUOTE => 60;
use constant MIN_STARTING_TRADEROUTES => 1;
use constant MAX_STARTING_TRADEROUTES => 3;
use constant MIN_STARTING_PRODUCTION => 20;
use constant MAX_STARTING_PRODUCTION => 40;
use constant MIN_GOVERNMENT_STRENGTH => 50;
use constant MAX_GOVERNMENT_STRENGTH => 100;
use constant STARTING_ALLIANCES => 7;

#Random parameters 
#use constant MIN_DELTA_PRODUCTION => -10;
use constant MIN_DELTA_PRODUCTION => -3;
#use constant MAX_DELTA_PRODUCTION => 10;
use constant MAX_DELTA_PRODUCTION => 3;
use constant MAX_PRODUCTION => 50;
use constant MIN_ADDED_DISORDER => -2;
use constant MAX_ADDED_DISORDER => 2;
use constant CRISIS_GENERATION_TRIES => 5;
use constant CRISIS_GENERATOR_NOACTION_TOKENS => 6;

#export costs
use constant ADDING_TRADEROUTE_COST => 30;
use constant TRADEROUTE_COST => 10;
use constant TRADING_QUOTE => 15;
use constant AID_INSURGENTS_COST => 25;
use constant ECONOMIC_AID_COST => 30;
use constant MILITARY_AID_COST => 20;

#domestic costs
use constant RESOURCES_FOR_DISORDER => 20;
use constant ARMY_COST => 20;
use constant PROGRESS_COST => 30;

#prestige
use constant INFLUENCE_PRESTIGE_BONUS => 3;
use constant DIPLOMATIC_PRESSURE_PRESTIGE_COST => 6;
use constant TREATY_PRESTIGE_COST => 7;
use constant WAR_PRESTIGE_BONUS => 10;
use constant BEST_WEALTH_FOR_PRESTIGE_BONUS => 5;
use constant BEST_PROGRESS_FOR_PRESTIGE_BONUS => 3;

#IA Thresholds
use constant WORRYING_LIMIT => 30;
use constant DOMESTIC_BUDGET => 50;
use constant MINIMUM_ARMY_LIMIT => 5;
use constant MEDIUM_ARMY_LIMIT => 10;
use constant MEDIUM_ARMY_BUDGET => 40;
use constant MAX_ARMY_BUDGET => 60;
use constant MIN_ARMY_FOR_WAR => 5;
use constant MIN_INFERIOR_ARMY_RATIO_FOR_WAR => 1.2;
use constant MIN_ARMY_TO_EXPORT => 12;
use constant ARMY_TO_ACCEPT_MILITARY_SUPPORT => 10;
use constant ARMY_TO_GIVE_MILITARY_SUPPORT => 7;
use constant ARMY_TO_RECALL_SUPPORT => 2;
use constant ALLY_CONFLICT_LEVEL_FOR_INVOLVEMENT => 2;
use constant MINIMUM_ARMY_FOR_AID => 4;

#Civil war
use constant STARTING_REBEL_PROVINCES => [1, 1, 2];
use constant CIVIL_WAR_WIN => 3;
use constant AFTER_CIVIL_WAR_INTERNAL_DISORDER => 35;
use constant ARMY_UNIT_FOR_CIVIL_WAR => 2;
use constant ARMY_HELP_FOR_CIVIL_WAR => 10;
use constant DICTATORSHIP_BONUS_FOR_CIVIL_WAR => 10;
use constant REBEL_ARMY_FOR_SUPPORT => 4;
use constant SUPPORT_HELP_FOR_CIVIL_WAR => 7; 
use constant REBEL_SUPPORT_HELP_FOR_CIVIL_WAR => 7; 
use constant REBEL_SUPPORTER_WINNER_FRIENDSHIP => 90;
use constant CIVIL_WAR_WEALTH_MALUS => 20;

#War & domination
use constant ARMY_FOR_BATTLE => 3;
use constant WAR_WEALTH_MALUS => 20;
use constant ATTACK_FAILED_PRODUCTION_MALUS => 10;
use constant AFTER_CONQUERED_INTERNAL_DISORDER => 30;
use constant OCCUPATION_LOOT_BY_TYPE => 20;
use constant DOMINATION_LOOT_BY_TYPE => 20;
use constant CONTROL_LOOT_BY_TYPE => 0;
use constant DOMINATION_CLOCK_LIMIT => 5;
use constant OCCUPATION_CLOCK_LIMIT => 1;
use constant PROGRESS_BATTLE_FACTOR => 10;

#Diplomacy
use constant HATE_LIMIT => 30;
use constant LOVE_LIMIT => 70;
use constant TRADEROUTE_DIPLOMACY_FACTOR => 6;
use constant ALLIANCE_FRIENDSHIP_FACTOR => 200;
use constant PERMANENT_CRISIS_HATE_LIMIT => 10;
use constant DIPLOMATIC_PRESSURE_FACTOR => -6;
use constant DIPLOMACY_MALUS_FOR_CROSSED_CIVIL_WAR_SUPPORT => 3;
use constant DIPLOMACY_MALUS_FOR_REBEL_CIVIL_WAR_SUPPORT => 4;
use constant DIPLOMACY_MALUS_FOR_SUPPORT => 2;
use constant DIPLOMACY_FACTOR_BREAKING_SUPPORT => 12;
use constant DIPLOMACY_FACTOR_STARTING_SUPPORT => 10;
use constant DIPLOMACY_FACTOR_INCREASING_SUPPORT => 2;
use constant DIPLOMACY_FACTOR_STARTING_REBEL_SUPPORT => -10;
use constant DIPLOMACY_FACTOR_INCREASING_REBEL_SUPPORT => -2;
use constant DIPLOMACY_AFTER_OCCUPATION => 90;
use constant DOMINION_DIPLOMACY => 110;
use constant ECONOMIC_AID_DIPLOMACY_FACTOR => 9;
use constant MILITARY_AID_DIPLOMACY_FACTOR => 7;

#Stock exchange
use constant STOCK_INFLUENCE_FACTOR => .5;
use constant START_STOCKS => [ 8, 10, 12 ];
use constant START_PLAYER_MONEY => 1000;
use constant WAR_BOND_COST => 50;
use constant WAR_BOND_GAIN => 90;
use constant INFLUENCE_COST => 1;
use constant MAX_BUY_STOCK => 4;

#Travel
use constant GROUND_TRAVEL_COST => 2;
use constant AIR_TRAVEL_COST_FOR_DISTANCE => 1;
use constant AIR_TRAVEL_CAP_COST => 4;
use constant PLAYER_MOVEMENTS => 8;

#Shop
use constant SHOP_PRICE_FACTOR => 10;
use constant PRICE_RANGES => { 'goods' => [1, 3],
                               'luxury' => [5, 9],
                               'arms' => [10, 15],
                               'tech' => [3, 5],
                               'culture' => [4, 7] };
use constant CARGO_TOTAL_SPACE => 500;
use constant BLACK_MARKET_PERCENT_SELLING_BONUS => 10;
use constant LOWERED_PRICE_PERCENT_SELLING_MALUS => 15;
use constant BLACK_MARKET_FRIENDSHIP_MALUS => -5;
use constant LOWERED_PRICE_FRIENDSHIP_BONUS => 3;
use constant NOT_LOWERED_PRICE_FRIENDSHIP_MALUS => -2;
use constant FRIENDSHIP_LIMIT_TO_SHOP => 30;
use constant LOWER_MY_PRICE_FACTOR => 0.4;

#Missions
use constant FRIENDSHIP_RANGE_FOR_MISSION => { 'parcel' => [-7, +7] };
use constant MONEY_RANGE_FOR_MISSION => { 'parcel' => [100, 500] };
use constant BONUS_FACTOR_FOR_BAD_FRIENSHIP => 15;
use constant MISSIONS_TO_GENERATE_PER_TURN => 40;
use constant MAX_MISSIONS_FOR_USER => 1;
use constant PENALTY_FACTOR_FOR_DROP_MISSION => .5;

#Mercenary
use constant MAX_HEALTH => 5;

#Others
use constant TRADEROUTE_SIZE_BONUS => .5;
use constant PRODUCTION_UNITS => [ 2, 3, 4 ];
use constant INTERNAL_PRODUCTION_GAIN => 1;
use constant INTERNAL_DISORDER_TERRORISM_LIMIT => 10;
use constant INTERNAL_DISORDER_INSURGENCE_LIMIT => 40;
use constant INTERNAL_DISORDER_CIVIL_WAR_LIMIT => 80;
use constant DISORDER_REDUCTION => 10;
use constant DEBT_ALLOWED => 0;
use constant DEBT_TO_RAISE_LIMIT => 50;
use constant PRODUCTION_THROUGH_DEBT => 40;
use constant MAX_DEBT => 3;
use constant TURNS_FOR_YEAR => 4;
use constant MAX_ARMY_FOR_SIZE => [ 9, 12, 15];
use constant ARMY_UNIT => 1;
use constant CRISIS_MAX_FACTOR => 3;
use constant EMERGENCY_PRODUCTION_LIMIT => 55;
use constant BOOST_PRODUCTION_QUOTE => 5;
use constant ARMY_FOR_SUPPORT => 4;
use constant DICTATORSHIP_PRODUCTION_MALUS => 15;
use constant DICTATORSHIP_BONUS_FOR_ARMY_CONSTRUCTION => 5;
use constant INSURGENTS_AID => 15;
use constant BEST_WEALTH_FOR_PRESTIGE => 5;
use constant BEST_PROGRESS_FOR_PRESTIGE => 5;
use constant TREATY_TRADE_FACTOR => .5;
use constant ECONOMIC_AID_QUOTE => 7;
use constant PROGRESS_INCREMENT => .1;
use constant TREATY_LIMIT_PROGRESS_STEP => 0.4;
use constant TREATIES_FOR_PROGRESS_STEP => 5;
use constant MAX_AFFORDABLE_PROGRESS => 0.8;
use constant TIME_FOR_TARGET => 16;
use constant EVENT_TURNS_TO_DUMP => 40;

our @EXPORT_OK = ('MIN_EXPORT_QUOTE', 
                  'MAX_EXPORT_QUOTE',
                  'MIN_STARTING_TRADEROUTES',
                  'MAX_STARTING_TRADEROUTES',
                  'ADDING_TRADEROUTE_COST',
                  'MIN_DELTA_PRODUCTION',
                  'MAX_DELTA_PRODUCTION',
                  'MAX_PRODUCTION',
                  'MIN_STARTING_PRODUCTION',
                  'MAX_STARTING_PRODUCTION',
                  'PRODUCTION_UNITS',
                  'INTERNAL_PRODUCTION_GAIN',
                  'TRADING_QUOTE',
                  'TRADEROUTE_COST',
                  'INTERNAL_DISORDER_TERRORISM_LIMIT',
                  'INTERNAL_DISORDER_INSURGENCE_LIMIT',
                  'INTERNAL_DISORDER_CIVIL_WAR_LIMIT',
                  'MIN_ADDED_DISORDER',
                  'MAX_ADDED_DISORDER',
                  'WORRYING_LIMIT',
                  'DOMESTIC_BUDGET',
                  'RESOURCES_FOR_DISORDER',
                  'DISORDER_REDUCTION',
                  'MIN_GOVERNMENT_STRENGTH',
                  'MAX_GOVERNMENT_STRENGTH',
                  'DEBT_TO_RAISE_LIMIT',
                  'PRODUCTION_THROUGH_DEBT',
                  'MAX_DEBT',
                  'DEBT_ALLOWED',
                  'CIVIL_WAR_WIN',
                  'STARTING_REBEL_PROVINCES',
                  'AFTER_CIVIL_WAR_INTERNAL_DISORDER',
                  'TURNS_FOR_YEAR',
                  'HATE_LIMIT',
                  'LOVE_LIMIT',
                  'MINIMUM_ARMY_LIMIT',
                  'MEDIUM_ARMY_LIMIT',
                  'MAX_ARMY_FOR_SIZE',
                  'MEDIUM_ARMY_BUDGET',
                  'MAX_ARMY_BUDGET',
                  'ARMY_COST',
                  'ARMY_UNIT',
                  'ARMY_FOR_BATTLE',
                  'TRADEROUTE_DIPLOMACY_FACTOR',
                  'ARMY_UNIT_FOR_CIVIL_WAR',
                  'ARMY_HELP_FOR_CIVIL_WAR',
                  'CRISIS_GENERATOR_NOACTION_TOKENS',
                  'CRISIS_GENERATION_TRIES',
                  'CRISIS_MAX_FACTOR',
                  'MIN_ARMY_FOR_WAR',
                  'MIN_INFERIOR_ARMY_RATIO_FOR_WAR',
                  'WAR_WEALTH_MALUS',
                  'ATTACK_FAILED_PRODUCTION_MALUS',
                  'AFTER_CONQUERED_INTERNAL_DISORDER',
                  'OCCUPATION_LOOT_BY_TYPE',
                  'DOMINATION_LOOT_BY_TYPE',
                  'CONTROL_LOOT_BY_TYPE',
                  'OCCUPATION_CLOCK_LIMIT',
                  'DOMINATION_CLOCK_LIMIT',
                  'ALLIANCE_FRIENDSHIP_FACTOR',
                  'ALLY_CONFLICT_LEVEL_FOR_INVOLVEMENT',
                  'STARTING_ALLIANCES',
                  'EMERGENCY_PRODUCTION_LIMIT',
                  'BOOST_PRODUCTION_QUOTE',
                  'MIN_ARMY_TO_EXPORT',
                  'ARMY_TO_ACCEPT_MILITARY_SUPPORT',
                  'ARMY_FOR_SUPPORT',
                  'DIPLOMACY_FACTOR_BREAKING_SUPPORT',
                  'DIPLOMACY_FACTOR_STARTING_SUPPORT',
                  'DIPLOMACY_MALUS_FOR_SUPPORT',
                  'ARMY_TO_RECALL_SUPPORT',
                  'TRADEROUTE_SIZE_BONUS',
                  'DICTATORSHIP_PRODUCTION_MALUS',
                  'DICTATORSHIP_BONUS_FOR_CIVIL_WAR',
                  'DICTATORSHIP_BONUS_FOR_ARMY_CONSTRUCTION',
                  'AID_INSURGENTS_COST',
                  'INSURGENTS_AID',
                  'INFLUENCE_PRESTIGE_BONUS',
                  'BEST_WEALTH_FOR_PRESTIGE',
                  'BEST_WEALTH_FOR_PRESTIGE_BONUS',
                  'WAR_PRESTIGE_BONUS',
                  'TREATY_PRESTIGE_COST',
                  'TREATY_TRADE_FACTOR',
                  'ECONOMIC_AID_COST',
                  'ECONOMIC_AID_QUOTE',
                  'ECONOMIC_AID_DIPLOMACY_FACTOR',
                  'REBEL_ARMY_FOR_SUPPORT',
                  'DIPLOMACY_FACTOR_STARTING_REBEL_SUPPORT',
                  'SUPPORT_HELP_FOR_CIVIL_WAR', 
                  'REBEL_SUPPORT_HELP_FOR_CIVIL_WAR',
                  'DIPLOMACY_MALUS_FOR_CROSSED_CIVIL_WAR_SUPPORT',
                  'DIPLOMACY_MALUS_FOR_REBEL_CIVIL_WAR_SUPPORT',
                  'REBEL_SUPPORTER_WINNER_FRIENDSHIP',
                  'PERMANENT_CRISIS_HATE_LIMIT', 
                  'DIPLOMATIC_PRESSURE_FACTOR',
                  'DIPLOMATIC_PRESSURE_PRESTIGE_COST',
                  'DIPLOMACY_AFTER_OCCUPATION',
                  'DOMINION_DIPLOMACY', 
                  'DIPLOMACY_FACTOR_INCREASING_SUPPORT',
                  'DIPLOMACY_FACTOR_INCREASING_REBEL_SUPPORT',
                  'MINIMUM_ARMY_FOR_AID',
                  'MILITARY_AID_COST',
                  'MILITARY_AID_DIPLOMACY_FACTOR',
                  'ARMY_TO_GIVE_MILITARY_SUPPORT',
                  'PROGRESS_INCREMENT',
                  'PROGRESS_COST',
                  'BEST_PROGRESS_FOR_PRESTIGE',
                  'BEST_PROGRESS_FOR_PRESTIGE_BONUS',
                  'PROGRESS_BATTLE_FACTOR',
                  'TREATY_LIMIT_PROGRESS_STEP',
                  'TREATIES_FOR_PROGRESS_STEP',
                  'MAX_AFFORDABLE_PROGRESS',
                  'STOCK_INFLUENCE_FACTOR',
                  'START_STOCKS',
                  'START_PLAYER_MONEY',
                  'WAR_BOND_COST',
                  'WAR_BOND_GAIN',
                  'CIVIL_WAR_WEALTH_MALUS',
                  'INFLUENCE_COST',
                  'MAX_BUY_STOCK',
                  'TIME_FOR_TARGET',
                  'GROUND_TRAVEL_COST',
                  'AIR_TRAVEL_COST_FOR_DISTANCE',
                  'AIR_TRAVEL_CAP_COST',
                  'PLAYER_MOVEMENTS',
                  'SHOP_PRICE_FACTOR',
                  'CARGO_TOTAL_SPACE',
                  'PRICE_RANGES',
                  'BLACK_MARKET_PERCENT_SELLING_BONUS',
                  'BLACK_MARKET_FRIENDSHIP_MALUS',
                  'FRIENDSHIP_LIMIT_TO_SHOP',
                  'LOWER_MY_PRICE_FACTOR',
                  'LOWERED_PRICE_PERCENT_SELLING_MALUS',
                  'LOWERED_PRICE_FRIENDSHIP_BONUS',
                  'NOT_LOWERED_PRICE_FRIENDSHIP_MALUS',
                  'EVENT_TURNS_TO_DUMP',
                  'FRIENDSHIP_RANGE_FOR_MISSION',
                  'MONEY_RANGE_FOR_MISSION',
                  'BONUS_FACTOR_FOR_BAD_FRIENSHIP',
                  'MISSIONS_TO_GENERATE_PER_TURN',
                  'MAX_MISSIONS_FOR_USER',
                  'PENALTY_FACTOR_FOR_DROP_MISSION',
                  'MAX_HEALTH',
                );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
