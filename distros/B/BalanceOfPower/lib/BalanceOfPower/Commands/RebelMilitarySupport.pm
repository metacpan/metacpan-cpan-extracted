package BalanceOfPower::Commands::RebelMilitarySupport;
$BalanceOfPower::Commands::RebelMilitarySupport::VERSION = '0.400115';
use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my $player = $self->actor;
    my @ns = grep { $self->world->at_civil_war($_) }  @{$self->world->nation_names};
    my @out = ();
    for(@ns)
    {
       my $rebsup = $self->world->rebel_supported($_);
       if($rebsup)
       {
            if($rebsup->node1 eq $player)
            {
                push @out, $_;
            }
       }
       else
       {
            push @out, $_;
       }
    }
    return @out;
}

sub IA
{
    my $self = shift;
    my $player = $self->actor;
    my @enemies = $self->world->get_hates($self->actor);
    @enemies = $self->world->shuffle("Choosing enemy for rebel support for " . $self->actor, @enemies); 
    foreach my $e (@enemies)
    {
        my $target = $e->destination($self->actor);
        if($self->good_target($target))
        {
            return "REBEL MILITARY SUPPORT " . $e->destination($self->actor);
        }
    }
}

1;
