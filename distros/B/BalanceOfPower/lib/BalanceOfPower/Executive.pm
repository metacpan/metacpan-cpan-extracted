package BalanceOfPower::Executive;
$BalanceOfPower::Executive::VERSION = '0.400115';
use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Role::Logger';

use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw(as_active as_title);
use BalanceOfPower::Commands::BuildTroops;
use BalanceOfPower::Commands::InMilitaryRange;
use BalanceOfPower::Commands::DeleteRoute;
use BalanceOfPower::Commands::MilitarySupport;
use BalanceOfPower::Commands::RebelMilitarySupport;
use BalanceOfPower::Commands::RecallRebelMilitarySupport;
use BalanceOfPower::Commands::RecallMilitarySupport;
use BalanceOfPower::Commands::ComTreaty;
use BalanceOfPower::Commands::NagTreaty;
use BalanceOfPower::Commands::LowerDisorder;
use BalanceOfPower::Commands::BoostProduction;
use BalanceOfPower::Commands::AddRoute;
use BalanceOfPower::Commands::EconomicAid;
use BalanceOfPower::Commands::DeclareWar;
use BalanceOfPower::Commands::AidInsurgents;
use BalanceOfPower::Commands::DiplomaticPressure;
use BalanceOfPower::Commands::MilitaryAid;
use BalanceOfPower::Commands::Progress;

has actor => (
    is => 'rw',
    default => sub { undef }
);

has commands => (
    is => 'ro',
    default => sub { {} }
);

sub init
{
    my $self = shift;
    $self->log_name("bop-IA.log");
    $self->delete_log();
    $self->log_active(1);
    my $world = shift;
    my $command = 
        BalanceOfPower::Commands::BuildTroops->new( name => "BUILD TROOPS",
                                                    domestic_cost => ARMY_COST,
                                                    world => $world,
                                                    allowed_at_war => 1, );
    $self->commands->{"BUILD TROOPS"} = $command; 
    $command = 
        BalanceOfPower::Commands::LowerDisorder->new( name => "LOWER DISORDER",
                                              world => $world,
                                              domestic_cost => RESOURCES_FOR_DISORDER );
    $self->commands->{"LOWER DISORDER"} = $command; 
    $command = 
        BalanceOfPower::Commands::AddRoute->new( name => "ADD ROUTE",
                                              world => $world,
                                              export_cost => ADDING_TRADEROUTE_COST );
    $self->commands->{"ADD ROUTE"} = $command; 
    $command =
        BalanceOfPower::Commands::DeclareWar->new( name => "DECLARE WAR TO",
                                                   synonyms => ["DECLARE WAR"],
                                                   world => $world,
                                                   crisis_needed => 1 );
    $self->commands->{"DECLARE WAR TO"} = $command; 
    $command =
        BalanceOfPower::Commands::DeleteRoute->new( name => "DELETE TRADEROUTE",
                                                    synonyms => ["DELETE ROUTE"],
                                                    world => $world );
    $self->commands->{"DELETE TRADEROUTE"} = $command; 
    $command =
        BalanceOfPower::Commands::BoostProduction->new( name => "BOOST PRODUCTION",
                                                        world => $world,
                                                      );
    $self->commands->{"BOOST PRODUCTION"} = $command; 
    $command =
        BalanceOfPower::Commands::MilitarySupport->new( name => "MILITARY SUPPORT",
                                                        world => $world,
                                                        army_limit => { '>' => ARMY_FOR_SUPPORT }
                                                      );
    $self->commands->{"MILITARY SUPPORT"} = $command; 
    $command =
        BalanceOfPower::Commands::RecallMilitarySupport->new( name => "RECALL MILITARY SUPPORT",
                                                        synonyms => ["RECALL SUPPORT"],
                                                        world => $world,
                                                        allowed_at_war => 1,
                                                    );
    $self->commands->{"RECALL MILITARY SUPPORT"} = $command; 
    $command =
        BalanceOfPower::Commands::AidInsurgents->new( name => "AID INSURGENTS IN",
                                                             synonyms => ["AID INSURGENTS", "AID INSURGENCE"],
                                                             world => $world,
                                                             export_cost => AID_INSURGENTS_COST );
    $self->commands->{"AID INSURGENTS IN"} = $command; 
    $command =
        BalanceOfPower::Commands::ComTreaty->new( name => "TREATY COM WITH",
                                                             synonyms => ["COM TREATY",
                                                                          "COM TREATY WITH",
                                                                          "TREATY COM",
                                                             ],
                                                             world => $world,
                                                             prestige_cost => TREATY_PRESTIGE_COST,
                                                             treaty_limit => 1,
                                                            );
    $self->commands->{"TREATY COM WITH"} = $command; 
    $command =
        BalanceOfPower::Commands::NagTreaty->new( name => "TREATY NAG WITH",
                                                             synonyms => ["NAG TREATY",
                                                                          "NAG TREATY WITH",
                                                                          "TREATY NAG"
                                                                         ],
                                                             world => $world,
                                                             prestige_cost => TREATY_PRESTIGE_COST,
                                                             treaty_limit => 1,
                                                            );
    $self->commands->{"TREATY NAG WITH"} = $command; 
    $command =
        BalanceOfPower::Commands::EconomicAid->new( name => "ECONOMIC AID FOR",
                                                             synonyms => ["ECONOMIC AID"],
                                                             world => $world,
                                                             export_cost => ECONOMIC_AID_COST,
                                                            );
    $self->commands->{"ECONOMIC AID FOR"} = $command; 
    $command =
        BalanceOfPower::Commands::RebelMilitarySupport->new( name => "REBEL MILITARY SUPPORT",
                                                             world => $world,
                                                             army_limit => { '>' => ARMY_FOR_SUPPORT }
                                                    );
    $self->commands->{"REBEL MILITARY SUPPORT"} = $command; 
    $command =
        BalanceOfPower::Commands::DiplomaticPressure->new( name => "DIPLOMATIC PRESSURE ON",
                                                             world => $world,
                                                             prestige_cost => DIPLOMATIC_PRESSURE_PRESTIGE_COST
                                                    );
    $self->commands->{"DIPLOMATIC PRESSURE ON"} = $command; 
    $command =
        BalanceOfPower::Commands::RecallRebelMilitarySupport->new( name => "RECALL REBEL MILITARY SUPPORT",
                                                                   world => $world,
                                                                 );
    $self->commands->{"RECALL REBEL MILITARY SUPPORT"} = $command; 
    $command =
        BalanceOfPower::Commands::MilitaryAid->new( name => "MILITARY AID FOR",
                                                    synonyms => ["MILITARY AID"],
                                                    world => $world,
                                                    export_cost => MILITARY_AID_COST,
                                                  );
    $self->commands->{"MILITARY AID FOR"} = $command;
    $command =
        BalanceOfPower::Commands::Progress->new( name => "PROGRESS",
                                                    world => $world,
                                                    domestic_cost => PROGRESS_COST,
                                                  );
    $self->commands->{"PROGRESS"} = $command;
}


sub recognize_command
{
    my $self = shift;
    my $nation = shift;
    my $query = shift;
    my $actor = $self->actor;
    for(keys %{$self->commands})
    {
        my $c = $self->commands->{$_};
        $c->actor($actor);
        if($c->recognize($query))
        {
            if($c->allowed())
            {
                return $c->execute($query, $nation);
            }
            else
            {
                return { status => -1 };
            }
        
        }
    }
    return { status => 0 };
}

sub decide
{
    my $self = shift;
    my $order = shift;
    if(! exists $self->commands->{$order})
    {
        $self->log($self->actor . ": $order doesn't exists!");
        return undef;
    }
    my $c = $self->commands->{$order};
    $c->actor($self->actor);
    if($c->allowed())
    {
        my $command = $c->IA();
        my $exit_log = $command ? $command : "KO";
        $self->log($self->actor . ": executing $order: $exit_log");
        return $command;  
    }
    else
    {
        $self->log($self->actor . ": $order not allowed");
        return undef;
    }
}

sub allowed_orders
{
    my $self = shift;
    my @out;
    for(keys %{$self->commands})
    {
        my $c = $self->commands->{$_};
        $c->actor($self->actor);
        if( $c->allowed() )
        {
            push @out, $c->print;
        }
    }
    return @out;
}

sub print_orders
{
    my $self = shift;
    my $out = as_title("ORDERS FOR " . $self->actor);
    $out .= "\n\n";
    for(keys %{$self->commands})
    {
        my $c = $self->commands->{$_};
        $c->actor($self->actor);
        if( $c->allowed() )
        {
            $out .= as_active($c->print) . "\n";
        }
        else
        {
            $out .= $c->print . "\n";
        }
    }
    return $out;
}

1;
