package BalanceOfPower::Commands::EconomicAid;
$BalanceOfPower::Commands::EconomicAid::VERSION = '0.400115';
use Moo;


extends 'BalanceOfPower::Commands::TargetNation';

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();

    my @hates = $self->world->get_hates($actor->name);
    if(@hates)
    {
        #Minor hate is used
        @hates = sort { $b->factor <=> $a->factor } @hates;
        my $other = $hates[0]->destination($actor->name);
        return "ECONOMIC AID FOR $other";
    }
    return undef;
}

1;
