package BalanceOfPower::World;
$BalanceOfPower::World::VERSION = '0.400115';
use strict;
use v5.10;

use Moo;
use Data::Dumper;
use Cwd 'abs_path';
use File::Path 'make_path';

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_turn next_turn);
use BalanceOfPower::Nation;
use BalanceOfPower::Dice;
use BalanceOfPower::Commands;

has name => (
    is => 'ro',
    default => 'WORLD'
);
has silent => (
    is => 'rw',
    default => 0
);
has first_year => (
    is => 'ro'
);
has current_year => (
    is => 'rw'
);
has nations => (
    is => 'rw',
    default => sub { [] }
);
has nation_names => (
    is => 'rw',
    default => sub { [] }
);
has nation_codes => (
    is => 'rw',
    default => sub { {} }
);
has order => (
    is => 'rw',
    default => ""
);
has ia_orders => (
    is => 'rw',
    default => sub { [] }
);
has autoplay => (
    is => 'rw',
    default => 0
);
has data_directory => (
    is => 'rw',
    default => sub {
        my $module_file_path = __FILE__;
        my $root_path = abs_path($module_file_path);
        $root_path =~ s/World\.pm//;
        my $data_directory = $root_path . "data";

    }
);
has dice => (
    is => 'ro',
    default => sub { BalanceOfPower::Dice->new( log_name => "bop-dice.log" ) },
    handles => { random => 'random',
                 random10 => 'random10',
                 random_around_zero => 'random_around_zero',
                 shuffle => 'shuffle_array',
                 tricks => 'tricks',
                 forced_advisor => 'forced_advisor',
                 only_one_nation_acting => 'only_one_nation_acting',
                 dice_log => 'log_active'
               }
);
has savefile => (
    is => 'rw',
    default => ""
);



with 'BalanceOfPower::Role::GameMaster';
with 'BalanceOfPower::Role::Historian';
with 'BalanceOfPower::Role::Herald';
with 'BalanceOfPower::Role::Ruler';
with 'BalanceOfPower::Role::Mapmaker';
with 'BalanceOfPower::Role::Supporter';
with 'BalanceOfPower::Role::Diplomat';
with 'BalanceOfPower::Role::Merchant';
with 'BalanceOfPower::Role::Broker';
with 'BalanceOfPower::Role::Warlord';
with 'BalanceOfPower::Role::Rebel';
with 'BalanceOfPower::Role::CrisisManager';
with 'BalanceOfPower::Role::Analyst';
with 'BalanceOfPower::Role::Recorder';
with 'BalanceOfPower::Role::Shopper';
with 'BalanceOfPower::Role::WebMaster';

sub get_nation
{
    my $self = shift;
    my $nation = shift;
    if(! $nation)
    {
        say "Nation is undef";
        return undef;
    }
    my @nations = grep { $_->name eq $nation } @{$self->nations};
    if(@nations > 0)
    {
        return $nations[0];
    }
    else
    {
        say "Cannot find $nation";
        return undef;
    }
}
sub correct_nation_name
{
    my $self = shift;
    my $nation = shift;
    return undef if(! $nation);
    $nation = $self->nation_codes->{uc $nation} if(exists $self->nation_codes->{uc $nation});
    for(@{$self->nation_names})
    {
        return $_ if(uc $_ eq uc $nation);
    }
    return undef;
}
sub check_nation_name
{
    my $self = shift;
    my $name = shift;
    return grep {$_ eq $name} @{$self->nation_names};
}
sub get_prev_year
{
    my $self = shift;
    return prev_turn($self->current_year);
}

sub load_nations_data
{
    my $self = shift;
    my $datafile = shift;
    my $file = $self->data_directory . "/" . $datafile;
    open(my $nations_file, "<", $file) || die $!;
    my $area;
    my %nations_data;
    for(<$nations_file>)
    {
        my $n = $_;
        chomp $n;
        if(! ($n =~ /^#/))
        {
            my ($name, $code, $size, $government) = split(',', $n);
            if($government eq 'd')
            {
                $government = 'democracy';
            }
            elsif($government eq 'D')
            {
                $government = 'dictatorship';
            }
            $nations_data{$name} = { code => $code,
                                     area => $area,
                                     size => $size,
                                     government => $government ,
                                   }

        }
        else
        {
            $n =~ /^# (.*)$/;
            $area = $1;
        }
    }
    return %nations_data;
}

#Initial values, randomly generated
sub init_random
{
    my $self = shift;
    my $datafile = shift;
    my $bordersfile = shift;
    my %nations_data = $self->load_nations_data($datafile);
    my $flags = shift;

    my $trades = 1;
    my $diplomacy = 1;
    my $alliances = 1;
    if($flags)
    {
        $trades = $flags->{'trades'}
            if(exists $flags->{'trades'});
        $diplomacy = $flags->{'diplomacy'}
            if(exists $flags->{'diplomacy'});
        $alliances = $flags->{'alliances'}
            if(exists $flags->{'alliances'});

    }

    $self->delete_log();
    $self->dice->delete_log();
    my @nation_names = ();
    foreach my $n (keys %nations_data)
    {
        push @nation_names, $n;
        say "Working on $n" if ! $self->silent;
        my $export_quote = $self->random10(MIN_EXPORT_QUOTE, MAX_EXPORT_QUOTE, "Export quote $n");
        say "  export quote: $export_quote" if ! $self->silent;
        my $government_strength = $self->random10(MIN_GOVERNMENT_STRENGTH, MAX_GOVERNMENT_STRENGTH, "Government strenght $n");
        say "  government strength: $government_strength" if ! $self->silent;

        my $executive = BalanceOfPower::Executive->new( actor => $n );
        $executive->init($self);
        push @{$self->nations}, BalanceOfPower::Nation->new( 
            name => $n, 
            code => $nations_data{$n}->{code},
            executive => $executive,
            area => $nations_data{$n}->{area}, 
            size => $nations_data{$n}->{size},
            government => $nations_data{$n}->{government},
            export_quote => $export_quote, 
            government_strength => $government_strength,
            available_stocks => START_STOCKS->[$nations_data{$n}->{size}],
            log_dir => $self->log_dir,
            log_name => $self->log_name,
            log_on_stdout => $self->log_on_stdout);
        $self->nation_codes->{$nations_data{$n}->{code}} = $n;
    }
    $self->nation_names(\@nation_names);
    $self->load_borders($bordersfile);
    if($trades)
    {
        say "Trades generation..." if ! $self->silent;
        $self->init_trades();
    }
    else
    {
        say "Trades generation skipped" if ! $self->silent;
    }
    if($diplomacy)
    {
        say "Diplomacy generation..." if ! $self->silent;
        $self->init_diplomacy();
    }
    else
    {
        say "Diplomacy generation skipped" if ! $self->silent;
    }
    if($alliances)
    {
        say "Alliances generation..." if ! $self->silent;
        $self->init_random_alliances();
    }
    else
    {
        say "Alliances generation skipped" if ! $self->silent;
    }
}

#Group function for all the steps involved in a turn
sub pre_decisions_elaborations
{
    my $self = shift;
    my $t = shift;
    $self->init_year($t);
    $self->war_current_year();
    $self->player_start_turn();
    $self->civil_war_current_year();
    $self->war_debts();
    $self->crisis_generator();
}
sub post_decisions_elaborations
{
    my $self = shift;
    $self->execute_stock_orders();
    $self->execute_decisions();
    $self->economy();
    $self->civil_warfare();
    $self->warfare();
    $self->internal_conflict();
    $self->player_targets();
    $self->register_global_data();
    $self->collect_events();
}



sub elaborate_turn
{
    my $self = shift;
    my $t = shift;
    $self->pre_decisions_elaborations($t);
    $self->decisions();
    $self->post_decisions_elaborations();
}



#To automatically generate turns
sub autopilot
{
    my $self = shift;
    my $start = shift;
    my $stop = shift;
    $self->autoplay(1);
    for($start..$stop)
    {
        my $y = $_;
        foreach my $t (get_year_turns($y))
        {
            $self->elaborate_turn($t);
        }
    }
    $self->autoplay(0);
}


# Configure current year
# Give production to countries. Countries split it between export and domestic and, if allowed, raise the debt in case of necessity
# Wealth reset
# Production and debt recorded
sub init_year
{
    my $self = shift;
    my $turn = shift;
    if(! $turn)
    {
        $turn = next_turn($self->current_year);
    }
    #$self->log("--- $turn ---");
    say $turn if $self->autoplay();
    $self->current_year($turn);
    foreach my $n (@{$self->nations})
    {
        $n->current_year($turn);
        $n->wealth(0);
        my $prod = $self->calculate_production($n);
        $n->production($prod);
        my $prestige = $self->calculate_prestige($n);
        $n->prestige($prestige);
        my $pu = PRODUCTION_UNITS->[$n->size];
        $self->set_statistics_value($n, 'production', $prod);
        $self->set_statistics_value($n, 'p/d', int(($prod / $pu) * 100) / 100);
        $self->set_statistics_value($n, 'debt', $n->debt);
        $self->set_statistics_value($n, 'prestige', $prestige);
    }
}



# PRODUCTION MANAGEMENT ###############################

#Say the value of starting production used to calculate production for a turn.
#Usually is just the value of production the turn before, but if rebels won a civil war it has to be undef to allow a totally random generation of production.
sub get_base_production
{
    my $self = shift;
    my $nation = shift;

    my @newgov = $nation->get_events("NEW GOVERNMENT CREATED", prev_turn($nation->current_year));
    my $previous_production = $self->get_statistics_value(prev_turn($nation->current_year), $nation->name, 'production'); 
    
    return () if(@newgov > 0);
    return () if(! $previous_production);
    
    my @prods = ();
    for(my $i = 0; $i < PRODUCTION_UNITS->[$nation->size]; $i++)
    {
        push @prods, $self->get_statistics_value(prev_turn($nation->current_year), $nation->name, 'production' . $i); 
    }
    return @prods;
}
sub calculate_production
{
    my $self = shift;
    my $n = shift;
    my @prev_prods = $self->get_base_production($n);
    my @next_prods = ();
    my $cost_for_retreat = 0;
    my @retreats = $n->get_events("RETREAT FROM", prev_turn($n->current_year));
    my $global_production = 0;
    for(my $i = 0; $i < PRODUCTION_UNITS->[$n->size]; $i++)
    {
        if(@prev_prods > 0)
        {
            $next_prods[$i] = $prev_prods[$i] + $self->random10(MIN_DELTA_PRODUCTION, MAX_DELTA_PRODUCTION, "Delta production" . $i . " " . $n->name);
        }
        else
        {
            $next_prods[$i] = $self->random10(MIN_STARTING_PRODUCTION, MAX_STARTING_PRODUCTION, "Starting production" . $i . " " . $n->name);
        }

        #DEFEAT COST MANAGEMENT
        if(@retreats)
        {
            $next_prods[$i] -= ATTACK_FAILED_PRODUCTION_MALUS;
            $cost_for_retreat += ATTACK_FAILED_PRODUCTION_MALUS;
        }
        $next_prods[$i] = 0 if($next_prods[$i] < 0);
        $next_prods[$i] = MAX_PRODUCTION if($next_prods[$i] > MAX_PRODUCTION);

        $self->set_statistics_value($n, 'production' . $i, $next_prods[$i]);
        $global_production += $next_prods[$i];
    }
    if($cost_for_retreat)
    {
        $self->send_event("COST FOR DEFEAT ON PRODUCTION: " . $cost_for_retreat);
    }
    return $global_production;
}


#Conquered nations give to the conqueror a quote of their production at start of the turn
sub war_debts
{
    my $self = shift;
    for($self->influences->all())
    {
        $self->loot($_);
    }
    $self->situation_clock();
}

sub loot
{
    my $self = shift;
    my $influence = shift;
    my $n2 = $influence->node2;
    my $n1 = $influence->node1;
    my $quote = $influence->get_loot_quote();
    return if(! $quote || $quote == 0);
    my $nation = $self->get_nation($n2);
    my $receiver = $self->get_nation($n1);
    my $amount_domestic = $nation->production_for_domestic >= $quote ? $quote : $nation->production_for_domestic;
    my $amount_export = $nation->production_for_export >= $quote ? $quote : $nation->production_for_export;
    $nation->subtract_production('domestic', $amount_domestic);
    $nation->subtract_production('export', $amount_export);
    $nation->register_event("PAY LOOT TO " . $receiver->name . ": $amount_domestic + $amount_export");
    $receiver->subtract_production('domestic', -1 * $amount_domestic);
    $receiver->subtract_production('export', -1 * $amount_export);
    $receiver->register_event("ACQUIRE LOOT FROM " . $nation->name . ": $amount_domestic + $amount_export");
}



# PRODUCTION MANAGEMENT END ###############################################

# PRESTIGE MANAGEMENT #####################################################

sub calculate_prestige
{
    my $self = shift;
    my $nation = shift;
    my $nation_name = $nation->name;
    my $prestige = 0;
    my @routes = $self->routes_for_node($nation_name);
    $prestige += @routes;
    my @supported = $self->supporter($nation_name);
    $prestige += @supported;
    my @influenced = $self->has_influence($nation_name);
    $prestige += @influenced * INFLUENCE_PRESTIGE_BONUS;
    my $bonus = 0;
    my @ordered_best_w = $self->order_statistics(prev_turn($nation->current_year), 'w/d');
    if(@ordered_best_w >= BEST_WEALTH_FOR_PRESTIGE)
    {
        for(my $i = 0; $i < BEST_WEALTH_FOR_PRESTIGE; $i++)
        {
            if($ordered_best_w[$i]->{nation} eq $nation_name)
            {
                $bonus += BEST_WEALTH_FOR_PRESTIGE_BONUS;
                $self->broadcast_event({ code => 'bestwealth',
                                         text => "ONE OF THE FIRST " . BEST_WEALTH_FOR_PRESTIGE . " NATIONS FOR WEALTH WAS " . $nation_name, 
                                         involved => [ $nation_name ],
                                         values => [] },
                                        $nation_name);
            }
        }
    }
    my @ordered_best_p = $self->order_statistics(prev_turn($nation->current_year), 'progress');
    if(@ordered_best_p >= BEST_PROGRESS_FOR_PRESTIGE)
    {
        for(my $i = 0; $i < BEST_PROGRESS_FOR_PRESTIGE; $i++)
        {
            if($ordered_best_p[$i]->{nation} eq $nation_name)
            {
                $bonus += BEST_PROGRESS_FOR_PRESTIGE_BONUS;
                $self->broadcast_event({ code => 'bestprogress',
                                         text => "ONE OF THE FIRST " . BEST_PROGRESS_FOR_PRESTIGE . " NATIONS FOR PROGRESS WAS " . $nation_name, 
                                         involved => [$nation_name],
                                         values => [] },
                                        $nation_name);
            }
        }
    }
   
    $prestige += $bonus;
    my @wins = $nation->get_events("WAR BETWEEN .* AND .* WON BY ". $nation_name, prev_turn($nation->current_year));
    if(@wins > 0)
    {
        $prestige += WAR_PRESTIGE_BONUS;
    }
    return $prestige;
}

# PRESTIGE MANAGEMENT END #####################################################

# DECISIONS ###############################################################

# Decisions are collected and executed
sub execute_decisions
{   
    my $self = shift;
    my @decisions = @{$self->ia_orders};
    my @route_adders = ();
    #foreach my $d (@decisions)
    foreach my $n (@{$self->nation_names})
    {
        my $command = $self->control($n);
        if(! $command)
        {
            my @nation_orders = grep { $_ =~ /^$n: / } @decisions;           if(@nation_orders > 0)
            {
                $nation_orders[0] =~ /^(.*): (.*)$/;
                $command = $2;
            }
            else
            {
                next;
            }
        }
        my $nation = $self->get_nation($n);
        if($command =~ /^DELETE TRADEROUTE (.*)->(.*)$/)
        {
            $self->delete_route($1, $2);
        }
        elsif($command =~ /^ADD ROUTE$/)
        {
            push @route_adders, $nation->name;
        }
        elsif($command =~ /^LOWER DISORDER$/)
        {
           $nation->lower_disorder($self);
        }
        elsif($command =~ /^BUILD TROOPS$/)
        {
           $nation->build_troops();
        }
        elsif($command =~ /^BOOST PRODUCTION$/)
        {
           $nation->boost_production();
        }
        elsif($command =~ /DECLARE WAR TO (.*)$/)
        {
            my $attacker = $nation;
            my $defender = $self->get_nation($1);
            if(! $self->war_busy($attacker->name) && ! $self->war_busy($defender->name))
            {
                $self->create_war($attacker, $defender);
            }
        }
        elsif($command =~ /^MILITARY SUPPORT (.*)$/)
        {
            my $supporter = $nation;
            my $supported = $self->get_nation($1);
            if($supported->accept_military_support($supporter->name, $self))
            {
                $self->start_military_support($supporter, $supported);
            }
            else
            {
                $self->broadcast_event({ code => 'suprefused',
                                         text => $supported->name . " REFUSED MILITARY SUPPORT FROM " . $supporter->name,
                                         involved => [$supporter->name, $supported->name] }, $supporter->name, $supported->name);
            }
        }
        elsif($command =~ /^RECALL MILITARY SUPPORT (.*)$/)
        {
           my $supporter = $nation;
           my $supported = $self->get_nation($1);
           $self->stop_military_support($supporter, $supported);
        }
        elsif($command =~ /^AID INSURGENTS IN (.*)$/)
        {
            my $victim = $self->get_nation($1);
            $self->aid_insurgents($nation, $victim);
        }
        elsif($command =~ /^TREATY (.*) WITH (.*)$/)
        {
            my $nation2 = $self->get_nation($2);
            $self->stipulate_treaty($nation, $nation2, $1);
        }
        elsif($command =~ /^ECONOMIC AID FOR (.*)$/)
        {
            my $nation2 = $self->get_nation($1);
            $self->economic_aid($nation, $nation2);
        }
        elsif($command =~ /^REBEL MILITARY SUPPORT (.*)$/)
        {
            my $nation2 = $self->get_nation($1);
            my $rebsup = $self->rebel_supported($nation2->name);
            if($self->at_civil_war($nation2->name))
            {
                $self->start_rebel_military_support($nation, $nation2);
            }
            else
            {
                say "ERROR: NO CIVIL WAR " . $nation2->name;
            }
        }
        elsif($command =~ /^DIPLOMATIC PRESSURE ON (.*)$/)
        {
            my $n2 = $1;
            if($nation->prestige >= DIPLOMATIC_PRESSURE_PRESTIGE_COST)
            {
                my $under_infl = $self->is_under_influence($n2); 
                $under_infl ||= "";
                if($under_infl ne $nation->name)
                {
                    $self->diplomatic_pressure($nation->name, $n2);
                }
                else
                {
                    $self->broadcast_event("DIPLOMATIC PRESSURE ON $n2 BY " . $nation->name . " IMPOSSIBLE! $n2 IS UNDER INFLUENCE OF " . $nation->name, $nation->name, $n2);
                }
            }
        }
        elsif($command =~ /^RECALL REBEL MILITARY SUPPORT (.*)$/)
        {
           my $supported = $self->get_nation($1);
           $self->stop_rebel_military_support($nation, $supported);
        }
        elsif($command =~ /^MILITARY AID FOR (.*)$/)
        {
            my $nation2 = $self->get_nation($1);
            $self->military_aid($nation, $nation2);
        }
        elsif($command =~ /^PROGRESS$/)
        {
            $nation->grow();
            $self->broadcast_event({ code => 'progress',
                                     text => "INVESTMENT IN PROGRESS FOR " . $nation->name, 
                                     involved => [$nation->name] }, $nation->name);
        }
        $self->set_statistics_value($nation, 'order', $command);
    }
    $self->empty_control_orders();
    $self->manage_route_adding(@route_adders);
}
sub empty_control_orders
{
    my $self = shift;
    foreach my $p (@{$self->players})
    {
       $p->empty_control_orders(); 
    }
}

sub manage_route_adding
{
    my $self = shift;
    my @route_adders = @_;
    if(@route_adders > 1)
    {
       @route_adders = $self->shuffle("Route adders", @route_adders); 
       my $done = 0;
       while(! $done)
       {
            my $node1 = shift @route_adders;
            if($self->suitable_route_creator($node1))
            {
                if(@route_adders == 0)
                {
                    $self->broadcast_event( { code => "tradelack",
                                              text => "TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS FOR $node1", 
                                              involved => [$node1] }, $node1);
                    $done = 1;
                } 
                else
                {
                    my $complete = 0;
                    foreach my $second (@route_adders)
                    {
                        if($self->suitable_new_route($node1, $second))
                        {
                            @route_adders = grep { $_ ne $second } @route_adders;
                            $self->generate_traderoute($node1, $second, 1);
                            $complete = 1;
                        }
                        last if $complete;
                    }     
                    if($complete == 0)
                    {
                        $self->broadcast_event( { code => "tradelack",
                                                  text => "TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS FOR $node1", 
                                                  involved => [$node1] }, $node1);
                    }
                }
            }
            else
            {
                $self->broadcast_event("TRADEROUTE CREATION NOT POSSIBLE FOR $node1", $node1);
            }
            $done = 1 if(@route_adders == 0);
       }
    }
}
sub decisions
{
    my $self = shift;
    my @decisions = ();
    foreach my $nation (@{$self->nations})
    {
        my $decision;
        $decision = $nation->decision($self);
        if($decision)
        {
            push @decisions, $decision;
        }
    }
    $self->ia_orders(\@decisions);
}
sub control
{
    my $self =  shift;
    my $nation = shift;
    my $quote = -1;
    my $winner = undef;
    my @losers = ();
    my $winner_command;
    foreach my $player (@{$self->players})
    {
        my $player_command = $player->get_control_order($nation);
        if($player_command)
        {
            if($player->stocks($nation) > $quote)
            {
                if($winner)
                {
                    push @losers, $winner;
                }
                $winner = $player;
                $quote = $player->stocks($nation);
                $winner_command = $player_command;
            }
            else
            {
                push @losers, $player;
            }
        }
    }
    if($winner)
    {
        $winner->add_influence(-1 * INFLUENCE_COST, $nation);
        $winner->register_event("ORDER FOR $nation IS EXECUTED: $winner_command");
        for(@losers)
        {
            $_->register_event("ORDER FOR $nation NOT EXECUTED! " . $winner->name . " MORE POWERFUL");
        }
        return $winner_command;
    }
    else
    {
        return undef;
    }
}

# DECISIONS END ###########################################################

# ECONOMY #################################################################

# Calculate internal wealth converting domestic production to wealth
# Active trade routes one by one trying to generate wealth from each of them
# Convert remain as generating internal wealth
sub economy
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        $n->calculate_internal_wealth();
        $n->calculate_trading($self);
        $n->convert_remains();
        if($self->at_war($n->name))
        {
            $n->war_cost();
        }
        if($self->at_civil_war($n->name))
        {
            $n->civil_war_cost();
        }

        my $wealth = $n->wealth;
        my $pu = PRODUCTION_UNITS->[$n->size];
        my $prod = $self->get_statistics_value($self->current_year, $n->name, 'production');

        $self->set_statistics_value($n, 'wealth', $n->wealth);
        $self->set_statistics_value($n, 'w/d', int(($wealth / $pu) * 100) / 100);
        if($prod != 0)
        {
            $self->set_statistics_value($n, 'growth', int(($wealth / $prod) * 100) / 100 );
        }
        else
        {
            $self->set_statistics_value($n, 'growth', 'X' );
        }
    }
}
sub economic_aid
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    $nation1->subtract_production('export', ECONOMIC_AID_COST);
    $nation2->receive_aid($nation1->name);
    $self->broadcast_event({ code => 'economicaid' , 
                             text => "ECONOMIC AID FROM " . $nation1->name . " TO " . $nation2->name, 
                             involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
    $self->change_diplomacy($nation1->name, $nation2->name, ECONOMIC_AID_DIPLOMACY_FACTOR, "ECONOMIC AID FROM " . $nation1->name);

}

# ECONOMY END #############################################################

# INTERNAL DISORDER #######################################################

sub internal_conflict
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        if(! $self->get_civil_war($n->name))
        {
            $n->calculate_disorder($self);
            if($n->internal_disorder_status eq 'Civil war')
            {
                $self->start_civil_war($n);
            }
        }
        $self->set_statistics_value($n, 'internal disorder', $n->internal_disorder);
    }
}

sub aid_insurgents
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    if($nation1->production_for_export >= AID_INSURGENTS_COST && $nation2->internal_disorder_status ne 'Civil war')
    {
        $self->broadcast_event({ code => 'insurgentsaid' ,
                                 text => "AIDS FOR INSURGENTS OF " . $nation2->name . " FROM " . $nation1->name, 
                                 involved => [$nation1->name, $nation2->name] },
                                $nation1->name, $nation2->name);
        $nation1->subtract_production('export', AID_INSURGENTS_COST);
        $nation2->add_internal_disorder(INSURGENTS_AID, $self);
    }
}


# INTERNAL DISORDER END ######################################################

# WAR ######################################################################

sub war_busy
{
    my $self = shift;
    my $n = shift;
    return $self->at_civil_war($n) || $self->at_war($n);
}

sub warfare
{
    my $self = shift;
    $self->fight_wars();
    foreach my $n (@{$self->nations})
    {
        $self->set_statistics_value($n, 'army', $n->army);    
    }    
}

sub civil_warfare
{
    my $self = shift;
    foreach my $cw (@{$self->civil_wars})
    {
        my $winner = $cw->fight($self);
        if($winner)
        {
            $cw->win($winner, $self);
            $self->delete_civil_war($cw->nation_name);
        }
    }
}

sub military_aid
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    $nation1->subtract_production('export', MILITARY_AID_COST);
    $nation2->add_army(ARMY_UNIT);
    $self->broadcast_event({ code => 'militaryaid',
                             text => "MILITARY AID FROM " . $nation1->name . " TO " . $nation2->name,
                             involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
    $self->change_diplomacy($nation1->name, $nation2->name, MILITARY_AID_DIPLOMACY_FACTOR, "MILITARY AID FROM " . $nation1->name );
}

sub war_report
{
    my $self = shift;
    my $message = shift;
    my $nation = shift;
    my @wars = $self->get_wars($nation);
    for(@wars)
    {
         $_->register_event($message);
    }
}

sub civil_war_report
{
    my $self = shift;
    my $message = shift;
    my $nation = shift;
    my $cw = $self->get_civil_war($nation);
    $cw->register_event($message) if $cw;
}


# WAR END ##################################################################

# TREATIES #################################################################

sub stipulate_treaty
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my $type = shift;
    my $present_treaty = $self->exists_treaty($nation1->name, $nation2->name);
    my $diplomatic_status = $self->diplomacy_status($nation1->name, $nation2->name);
    if($diplomatic_status eq 'HATE')
    {
        $self->broadcast_event({ code => 'hatetreaty',
                                 text => "TREATY BETWEEN " . $nation1->name . " AND " . $nation2->name . " NOT POSSIBLE BECAUSE OF HATE", 
                                 involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
        return;
    }
    if($self->get_treaties_for_nation($nation1->name) >= $nation1->treaty_limit ||
       $self->get_treaties_for_nation($nation2->name) >= $nation2->treaty_limit &&
       ! $present_treaty)
    {
        $self->broadcast_event( { code => 'limittreaty',
                                  text => "TREATY BETWEEN " . $nation1->name . " AND " . $nation2->name . " NOT POSSIBLE BECAUSE ONE NATION HAS ALREADY REACHED MAXIMUM ALLOWED TREATIES", 
                                  involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
        return;
    }
    if($nation1->prestige >= TREATY_PRESTIGE_COST)
    {
        if($present_treaty && $present_treaty->type ne 'alliance')
        {
            $self->create_treaty($nation1->name, $nation2->name, 'alliance');
            $self->broadcast_event({ code => 'alliancetreatynew',
                                     text => "ALLIANCE BETWEEN " . $nation1->name . " AND " . $nation2->name, 
                                     involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
        }
        else
        {
            if($type eq 'COM')
            {
                if(! $present_treaty)
                {
                    if($self->route_exists($nation1->name, $nation2->name))
                    {
                        $self->create_treaty($nation1->name, $nation2->name, 'commercial');
                        $self->broadcast_event({ code => "comtreatynew",
                                                text => "COMMERCIAL TREATY BETWEEN " . $nation1->name . " AND " . $nation2->name, 
                                                involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
                    }
                    else
                    {
                        $self->broadcast_event({ code => "uselesstreaty",
                                                text => "COMMERCIAL TREATY BETWEEN " . $nation1->name . " AND " . $nation2->name . " MADE USELESS BY ROUTE CANCELATION", 
                                                involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
                    }
                }
            }
            elsif($type eq 'NAG')
            {
                $self->create_treaty($nation1->name, $nation2->name, 'no aggression');
                $self->broadcast_event({ code => 'nagtreatynew',
                                         text => "NO AGGRESSION TREATY BETWEEN " . $nation1->name . " AND " . $nation2->name, 
                                         involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
            }
        }
    }
}



# TRATIES END ##############################################################

# TRAVELS ##################################################################

sub make_travel_plan
{
    my $self = shift;
    my $from = shift;
    my @already = ();
    my %plan;
    $plan{'ground'} = {};
    $plan{'air'} = {};
    my @for_commerce = $self->route_destinations_for_node($from);
    
    my @at_borders = $self->near_nations($from, 1);
    foreach my $n(@for_commerce)
    {
        if(! grep { $_ eq $n } @already)
        {
            my $youcan = 'OK';
            $youcan = 'KO' if($self->war_busy($from) || $self->war_busy($n));
            $plan{'air'}->{$n}->{status} = $youcan;
            my $cost = $self->distance($from, $n) * AIR_TRAVEL_COST_FOR_DISTANCE;
            $cost = AIR_TRAVEL_CAP_COST if $cost > AIR_TRAVEL_CAP_COST;
            $plan{'air'}->{$n}->{cost} = $cost if($youcan eq 'OK');
            push @already, $n if $youcan eq 'OK';
        }
    }
    foreach my $n(@at_borders)
    {
        if(! grep { $_ eq $n } @already)
        {
            $plan{'ground'}->{$n}->{status} = 'OK';
            $plan{'ground'}->{$n}->{cost} = GROUND_TRAVEL_COST;
            push @already, $n;
        }
    }
    return %plan;
}

# END TRAVELS ########################################################################

# MISSIONS ###########################################################################

sub generate_mission
{
    my $self = shift;
    my $type = shift;
    my @nations = @{$self->nation_names};
    my %out;
    
    if($type eq 'parcel')
    {
        @nations = $self->shuffle("Nations for mission - assignment", @nations); 
        $out{'assignment'} = $nations[0];
        @nations = $self->shuffle("Nations for mission - from", @nations); 
        $out{'from'} = $nations[0];
        @nations = $self->shuffle("Nations for mission - to", @nations); 
        $out{'to'} = $nations[0] ne $out{'from'} ? $nations[0] : $nations[1];
        my $time = $self->random(0, 2, "Time available for mission");
        $out{'expire'} = next_turn($self->current_year);
        for(my $i = 0; $i < $time; $i++)
        {
            $out{'expire'} = next_turn($out{'expire'});
        }
        $out{'reward'}->{'friendship'}->{'assignment'} =  $self->random(FRIENDSHIP_RANGE_FOR_MISSION->{$type}->[0], 
                                                                        FRIENDSHIP_RANGE_FOR_MISSION->{$type}->[1], 
                                                                        "Friendship for mission - assignment");
        $out{'reward'}->{'friendship'}->{'from'} =  $self->random(FRIENDSHIP_RANGE_FOR_MISSION->{$type}->[0], 
                                                                  FRIENDSHIP_RANGE_FOR_MISSION->{$type}->[1], 
                                                                  "Friendship for mission - from");
        $out{'reward'}->{'friendship'}->{'to'} =  $self->random(FRIENDSHIP_RANGE_FOR_MISSION->{$type}->[0], 
                                                                FRIENDSHIP_RANGE_FOR_MISSION->{$type}->[1], 
                                                                "Friendship for mission - to");
        my $tot_friendship = $out{'reward'}->{'friendship'}->{'assignment'} +  $out{'reward'}->{'friendship'}->{'from'} +  $out{'reward'}->{'friendship'}->{'to'};
        my $money_bonus = $tot_friendship * BONUS_FACTOR_FOR_BAD_FRIENSHIP;
        $out{'reward'}->{'money'} = $self->random(MONEY_RANGE_FOR_MISSION->{$type}->[0] - $money_bonus, MONEY_RANGE_FOR_MISSION->{$type}->[1], "Money for mission");
    }
    else
    {
        die "Wrong type of mission";
    }
    return %out;
}















# END MISSIONS #######################################################################

sub register_global_data
{
    my $self = shift;
    my $crises = $self->get_all_crises();
    my $wars = $self->wars->all();
    $self->set_statistics_value(undef, 'crises', $crises);
    $self->set_statistics_value(undef, 'wars', $wars);
}

sub collect_events
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
       $self->set_statistics_value($n, 'progress', $n->progress);
    }
    foreach my $p (@{$self->players})
    {
        my $status = $self->player_stocks_status($p->name);
        $self->set_statistics_value($p, 'stock value', $status->{'stock_value'}, 'player');     
        $self->set_statistics_value($p, 'money', $status->{'money'}, 'player');     
        $self->set_statistics_value($p, 'total value', $status->{'total_value'}, 'player');     
    }
}

### Commands

sub build_commands
{
    my $self = shift;
    my $commands = BalanceOfPower::Commands->new( world => $self, log_name => 'bop-commands.log', log_active => $self->log_active, log_dir => $self->log_dir );
    return $commands;
}

### Logs

sub set_log_dir
{
    my $self = shift;
    my $log_dir = shift;

    $self->log_dir($log_dir);
    $self->dice->log_dir($log_dir);

    for(@{$self->nations})
    {
        $_->log_dir($log_dir);
    }
    for(@{$self->players})
    {
        $_->log_dir($log_dir);
    }
}


1;
