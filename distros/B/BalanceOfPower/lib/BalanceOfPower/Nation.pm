package BalanceOfPower::Nation;
$BalanceOfPower::Nation::VERSION = '0.400115';
use strict;
use v5.10;

use Moo;

use BalanceOfPower::Utils qw( prev_turn );
use BalanceOfPower::Constants ':all';

with 'BalanceOfPower::Role::Reporter';
with 'BalanceOfPower::Nation::Role::IA';
with 'BalanceOfPower::Nation::Role::Shareholder';

has name => (
    is => 'ro',
    default => 'Dummyland'
);
has code => (
    is => 'ro',
    default => 'DUM'
);
has area => (
    is => 'ro',
    default => 'Neverwhere'
);


has export_quote => (
    is => 'ro',
    default => 50
);
has government => (
    is => 'ro',
    default => 'democracy'
);
has government_strength => (
    is => 'rw',
    default => 70
);
has government_id => (
    is => 'rw',
    default => 0
);
has size => (
    is => 'ro',
    default => 1
);

has internal_disorder => (
    is => 'rw',
    default => 0
);
has production_for_domestic => (
    is => 'rw',
    default => 0
);
has production_for_export => (
    is => 'rw',
    default => 0
);
has prestige => (
    is => 'rw',
    default => 0
);
has wealth => (
    is => 'rw',
    default => 0
);
has debt => (
    is => 'rw',
    default => 0
);
has current_year => (
    is => 'rw'
);

has army => (
    default => 0,
    is => 'rw'
);

has progress => (
    default => 0,
    is => 'rw'
);

has frozen_disorder => (
    default => 0,
    is => 'rw'
);

sub production
{
    my $self = shift;
    my $prod = shift;
    if($prod)
    {
        if($prod <= DEBT_TO_RAISE_LIMIT && $self->debt < MAX_DEBT && DEBT_ALLOWED)
        {
            $prod += PRODUCTION_THROUGH_DEBT;
            $self->debt($self->debt + 1);
            $self->register_event("DEBT RISE");
        }
        if($self->government eq 'dictatorship')
        {
            $prod -= DICTATORSHIP_PRODUCTION_MALUS;
        }
        my $internal = $prod - (($self->export_quote * $prod) / 100);
        my $export = $prod - $internal;
        $self->production_for_domestic($internal);
        $self->production_for_export($export);
        $self->register_event("PRODUCTION INT: $internal EXP: $export");
    }
    return $self->production_for_domestic + $self->production_for_export;
}

sub calculate_internal_wealth
{
    my $self = shift;
    my $internal_production = $self->production_for_domestic();
    $self->add_wealth($internal_production * INTERNAL_PRODUCTION_GAIN);
    $self->production_for_domestic(0);
    $self->register_event("INTERNAL " . $internal_production);
}

sub calculate_trading
{
    my $self = shift;
    my $world = shift;
    my @routes = $world->routes_for_node($self->name);
    my %diplomacy = $world->diplomacy_for_node($self->name);
    @routes = sort { $b->factor_for_node($self->name) * 1000 + $diplomacy{$b->destination($self->name)}
                     <=>
                     $a->factor_for_node($self->name) * 1000 + $diplomacy{$a->destination($self->name)}
                   } @routes;
    if(@routes > 0)
    {
        foreach my $r (@routes)
        {
           if($self->production_for_export >= TRADING_QUOTE)
           {
                my $treaty_bonus = 0;
                if($world->exists_treaty_by_type($self->name, $r->destination($self->name), 'commercial'))
                {
                    $treaty_bonus = TREATY_TRADE_FACTOR;
                }
                $self->trade(TRADING_QUOTE, $r->factor_for_node($self->name) + $treaty_bonus);
                my $event = "TRADE OK " . $r->destination($self->name) . " [x" . $r->factor_for_node($self->name);
                if($treaty_bonus > 0)
                {
                    $event .= " +$treaty_bonus";
                }
                $event .= "]";
                $self->register_event($event);
           }
           else
           {
                $self->trade(0, $r->factor_for_node($self->name));
                $self->register_event("TRADE KO " . $r->destination($self->name));
           }     
        }
    }
}

sub convert_remains
{
    my $self = shift;
    $self->add_wealth($self->production);
    $self->register_event("REMAIN " . $self->production);
    $self->production_for_domestic(0);
    $self->production_for_export(0);
}

sub war_cost
{
    my $self = shift;
    $self->add_wealth(-1 * WAR_WEALTH_MALUS);
    $self->register_event("WAR COST PAYED: " . WAR_WEALTH_MALUS);
}
sub civil_war_cost
{
    my $self = shift;
    $self->add_wealth(-1 * CIVIL_WAR_WEALTH_MALUS);
    $self->register_event("CIVIL WAR COST PAYED: " . CIVIL_WAR_WEALTH_MALUS);
}

sub boost_production
{
    my $self = shift;
    my $boost = BOOST_PRODUCTION_QUOTE * PRODUCTION_UNITS->[$self->size];
    $self->subtract_production('export', -1 * $boost);
    $self->subtract_production('domestic', -1 * $boost);
    $self->register_event("BOOST OF PRODUCTION");
}
sub receive_aid
{
    my $self = shift;
    my $from = shift;
    my $boost = ECONOMIC_AID_QUOTE * PRODUCTION_UNITS->[$self->size];
    $self->subtract_production('export', -1 * $boost);
    $self->subtract_production('domestic', -1 * $boost);
}

sub trade
{
    my $self = shift;
    my $production = shift;
    my $gain = shift;
    $self->subtract_production('export', $production);
    $self->add_wealth($production * $gain);
    $self->add_wealth(-1 * TRADEROUTE_COST);
}

sub calculate_disorder
{
    my $self = shift;
    my $world = shift;
    return if($self->internal_disorder_status eq 'Civil war');
    return if($self->frozen_disorder);

    my @ordered_best = $world->order_statistics(prev_turn($self->current_year), 'progress');
    
    #Variables
    my $wd = $self->wealth / PRODUCTION_UNITS->[$self->size];
    my $d = $self->internal_disorder;
    my $g = $self->government_strength;
    my $prg = $ordered_best[0] ? $ordered_best[0]->{'value'} - $self->progress : 0;

    #Constants
    my $wd_middle = 30;
    my $wd_divider = 10;
    my $disorder_divider = 70;
    my $government_strength_minimum = 60;
    my $government_strength_divider = 40;
    my $random_factor_max = 15;
    
    my $disorder = ( ($wd_middle - $wd) / $wd_divider ) +
                   ( $d / $disorder_divider           ) +
                   ( ($government_strength_minimum - $g) / $government_strength_divider ) +
                   $world->random_around_zero($random_factor_max, 100, "Internal disorder random factor for " . $self->name) +
                   $prg;

    $disorder = int ($disorder * 100) / 100;
    $self->register_event("DISORDER CHANGE: " . $disorder);
    $self->add_internal_disorder($disorder, $world);
}

sub subtract_production
{
    my $self = shift;
    my $which = shift;
    my $production = shift;
    if($which eq 'export')
    {
        $self->production_for_export($self->production_for_export - $production);
    }
    elsif($which eq 'domestic')
    {
        $self->production_for_domestic($self->production_for_domestic - $production);
    }
    
}

sub add_wealth
{
    my $self = shift;
    my $wealth = shift;
    $self->wealth($self->wealth + $wealth);
    $self->wealth(0) if($self->wealth < 0);
}

sub lower_disorder
{
    my $self = shift;
    my $world = shift;
    if($world->at_civil_war($self->name))
    {
        return; 
    }
    if($self->production_for_domestic > RESOURCES_FOR_DISORDER)
    {
        $self->subtract_production('domestic', RESOURCES_FOR_DISORDER);
        $self->add_internal_disorder(-1 * DISORDER_REDUCTION, $world);
        $world->broadcast_event({ code => 'lowerdisorder',
                                  text => "DISORDER LOWERED TO " . $self->internal_disorder. " IN " . $self->name,
                                  involved => [$self->name] }, $self->name);
    }
}

sub add_internal_disorder
{
    my $self = shift;
    my $disorder = shift;
    my $world = shift;
    my $actual_disorder = $self->internal_disorder_status;
    my $new_disorder_data = $self->internal_disorder + $disorder;
    $new_disorder_data = int($new_disorder_data * 100) / 100;
    $self->internal_disorder($new_disorder_data);
    if($self->internal_disorder > 100)
    {
        $self->internal_disorder(100);
    }
    if($self->internal_disorder < 0)
    {
        $self->internal_disorder(0);
    }
    my $new_disorder = $self->internal_disorder_status;
    if($actual_disorder ne $new_disorder)
    {
        $world->broadcast_event({ code => 'disorderchange',
                                  text => "INTERNAL DISORDER LEVEL FROM $actual_disorder TO $new_disorder IN " . $self->name,
                                  involved => [$self->name] }, $self->name);
        if($new_disorder eq "Civil war")
        {
            $world->start_civil_war($self);
        }
    }
}

sub internal_disorder_status
{
    my $self = shift;
    my $disorder = $self->internal_disorder;
    if($disorder < INTERNAL_DISORDER_TERRORISM_LIMIT)
    {
        return "Peace";
    }
    elsif($disorder < INTERNAL_DISORDER_INSURGENCE_LIMIT)
    {
        return "Terrorism";
    }
    elsif($disorder < INTERNAL_DISORDER_CIVIL_WAR_LIMIT)
    {
        return "Insurgence";
    }
    else
    {
        return "Civil war";
    }
}




sub new_government
{
    my $self = shift;
    my $world = shift;
    $self->government_strength($world->random10(MIN_GOVERNMENT_STRENGTH, MAX_GOVERNMENT_STRENGTH, "Reroll government strength for " . $self->name));
    $self->government_id($self->government_id + 1);
    $world->reroll_diplomacy($self->name);
    $world->reset_treaties($self->name);
    $world->reset_influences($self->name);
    $world->reset_supports($self->name);
    $world->reset_crises($self->name);
    $world->broadcast_event({ code => "newgov",
                              text => "NEW GOVERNMENT CREATED IN " . $self->name,
                              involved => [$self->name] }, $self->name);
}

sub occupation
{
    my $self = shift;
    my $world = shift;
    $self->government_id($self->government_id + 1);
    $world->reset_treaties($self->name);
    $world->reset_influences($self->name);
    $world->reset_supports($self->name);
    $world->reset_crises($self->name);
}

sub build_troops
{
    my $self = shift;
    my $army_cost = $self->build_troops_cost();
  
    if($self->production_for_domestic > $army_cost && $self->army < MAX_ARMY_FOR_SIZE->[ $self->size ])
    {
        $self->subtract_production('domestic', $army_cost);
        $self->add_army(ARMY_UNIT);
        $self->register_event("NEW TROOPS FOR THE ARMY");
    } 
}

sub build_troops_cost
{
    my $self = shift;
    my $army_cost = ARMY_COST;
    if($self->government eq 'dictatorship')
    {
        $army_cost -= DICTATORSHIP_BONUS_FOR_ARMY_CONSTRUCTION;
    }
    return $army_cost;
}

sub add_army
{
    my $self = shift;
    my $army = shift;
    $self->army($self->army + $army);
    if($self->army > MAX_ARMY_FOR_SIZE->[ $self->size ])
    {
        $self->army(MAX_ARMY_FOR_SIZE->[ $self->size ]);
    }
    if($self->army < 0)
    {
        $self->army(0);
    }

}

sub grow
{
    my $self = shift;
    return if($self->production_for_domestic < PROGRESS_COST);
    my $new_progress = $self->progress + PROGRESS_INCREMENT;
    $self->progress($new_progress);
    $self->subtract_production('domestic', PROGRESS_COST);
    $self->register_event("GROW. NEW PROGRESS: $new_progress");
}

sub treaty_limit
{
    my $self = shift;
    my $progress_step = int($self->progress / TREATY_LIMIT_PROGRESS_STEP) + 1;
    return $progress_step * TREATIES_FOR_PROGRESS_STEP;
}   

sub print_attributes
{
    my $self = shift;
    my $out = "";
    $out .= "Area: " . $self->area . "\n";
    $out .= "Export quote: " . $self->export_quote . "\n";
    $out .= "Government strength: " . $self->government_strength . "\n";
    $out .= "Internal situation: " . $self->internal_disorder_status . "\n";
    return $out;
}

sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . 
                join(";", $self->name, $self->code, $self->area, $self->export_quote, $self->government, $self->government_strength, $self->size, $self->internal_disorder, $self->production_for_domestic, $self->production_for_export, $self->prestige, $self->wealth, $self->debt, $self->current_year, $self->army, $self->progress, $self->available_stocks, $self->government_id) . "\n";
    $self->dump_events($io, " " . $indent);
}

sub load
{
    my $self = shift;
    my $data = shift;
    my $version = shift;
    my $nation_line = ( split /\n/, $data )[0];
    my %init_params = $self->manage_nation_line($nation_line, $version);
    $data =~ s/^.*?\n//;
    my $events = $self->load_events($data);
    $init_params{'events'} = $events;
    return $self->new(%init_params);
}

sub manage_nation_line
{
    my $self = shift;
    my $nation_line = shift;
    my $version = shift;
    $nation_line =~ s/^\s+//;
    chomp $nation_line;

    my %init_params;
    if($version > 2)
    {
        my ($name, $code, $area, $export_quote, $government, $government_strength, $size, $internal_disorder, $production_for_domestic, $production_for_export, $prestige, $wealth, $debt, $current_year, $army, $progress, $available_stocks, $government_id) = split ";", $nation_line;
        %init_params = (name => $name, code => $code, area => $area, size => $size,
                        government_id => $government_id,
                        export_quote => $export_quote, government => $government, government_strength => $government_strength,
                        internal_disorder => $internal_disorder, 
                        production_for_domestic => $production_for_domestic, production_for_export => $production_for_export,
                        prestige => $prestige, wealth => $wealth, debt => $debt,
                        army => $army,
                        current_year => $current_year,
                        progress => $progress,
                        available_stocks => $available_stocks);
    }    
    elsif($version == 2)
    {
        my ($name, $code, $area, $export_quote, $government, $government_strength, $size, $internal_disorder, $production_for_domestic, $production_for_export, $prestige, $wealth, $debt, $current_year, $army, $progress, $available_stocks) = split ";", $nation_line;
        %init_params = (name => $name, code => $code, area => $area, size => $size,
                        export_quote => $export_quote, government => $government, government_strength => $government_strength,
                        internal_disorder => $internal_disorder, 
                        production_for_domestic => $production_for_domestic, production_for_export => $production_for_export,
                        prestige => $prestige, wealth => $wealth, debt => $debt,
                        army => $army,
                        current_year => $current_year,
                        progress => $progress,
                        available_stocks => $available_stocks);

    }
    else
    {
        my ($name, $code, $area, $export_quote, $government, $government_strength, $size, $internal_disorder, $production_for_domestic, $production_for_export, $prestige, $wealth, $debt, $rebel_provinces, $current_year, $army, $progress, $available_stocks) = split ";", $nation_line;
        %init_params = (name => $name, code => $code, area => $area, size => $size,
                        export_quote => $export_quote, government => $government, government_strength => $government_strength,
                        internal_disorder => $internal_disorder, 
                        production_for_domestic => $production_for_domestic, production_for_export => $production_for_export,
                        prestige => $prestige, wealth => $wealth, debt => $debt,
                        army => $army,
                        current_year => $current_year,
                        progress => $progress,
                        available_stocks => $available_stocks);
    }
    return %init_params;
}

1;
