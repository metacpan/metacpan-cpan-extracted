package BalanceOfPower::Commands::InMilitaryRange;
$BalanceOfPower::Commands::InMilitaryRange::VERSION = '0.400115';
use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

has crisis_needed => (
    is => 'ro',
    default => 0
);

sub get_available_targets
{
    my $self = shift;
    my $player = $self->actor;
    my @out = ();
    for($self->SUPER::get_available_targets())
    {
        my $n = $_;
        my $push = 0;
        if($self->world->in_military_range($player, $n))
        {
            if($self->crisis_needed)
            {
                if($self->world->crisis_exists($player, $n))
                {
                    $push = 1;
                }
            }
            else
            {
                $push = 1;
            }
        }
        if($push)
        {
            push @out, $n;
        }
    }
    return @out;
}

1;
