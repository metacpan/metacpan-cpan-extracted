package BalanceOfPower::Commands::DiplomaticPressure;
$BalanceOfPower::Commands::DiplomaticPressure::VERSION = '0.400115';
use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my @targets = $self->SUPER::get_available_targets();
    my $nation = $self->actor;
    @targets = grep { (! $self->world->is_under_influence($_) 
                      || $self->world->is_under_influence($_) ne $nation) } @targets;
    return @targets;
}


sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    my @hates = $self->world->shuffle("Choosing target for diplomatic pressure for ". $self->actor, $self->world->get_nations_with_status($self->actor, ['HATE']));
    if(@hates)
    {
        return "DIPLOMATIC PRESSURE ON " . $hates[0];
    }
    else
    {
        return undef;
    }
}
1;
