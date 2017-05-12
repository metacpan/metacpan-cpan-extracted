package BalanceOfPower::Commands::MilitaryAid;
$BalanceOfPower::Commands::MilitaryAid::VERSION = '0.400115';
use Moo;
use BalanceOfPower::Constants ":all";


extends 'BalanceOfPower::Commands::TargetNation';

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();

    my @friends = $self->world->shuffle("Choosing nation to military aid for " . $actor->name, $self->world->get_friends($actor->name));
    for(@friends)
    {
        my $f = $_;
        if($self->world->get_nation($f)->army < MINIMUM_ARMY_FOR_AID)
        {
            return "MILITARY AID FOR $f";
        }
    }
    return undef;
}

1;
