package BalanceOfPower::Commands::MilitarySupport;
$BalanceOfPower::Commands::MilitarySupport::VERSION = '0.400115';
use BalanceOfPower::Constants ":all";
use Moo;
use Array::Utils qw(intersect);

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my $player = $self->actor;
    return grep { $self->world->get_nation($_)->accept_military_support($player, $self->world) } $self->world->get_friends($player);
}

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    return undef if($actor->army < ARMY_TO_GIVE_MILITARY_SUPPORT);

    my @crises = $self->world->get_crises($actor->name);
    my @friends = $self->world->shuffle("Choosing friend to support for " . $actor->name, $self->world->get_friends($actor->name));
    my @targets = $self->get_available_targets();
    @friends = $self->world->shuffle("Mixing friends for military support for " . $actor->name, intersect(@friends, @targets));
    if(@crises > 0)
    {
        foreach my $c ($self->world->shuffle("Mixing crisis for war for " . $actor->name, @crises))
        {
            my $enemy = $self->world->get_nation($c->destination($actor->name));
            next if $self->world->war_busy($enemy->name);
            for(@friends)
            {
                if($self->world->border_exists($_, $enemy->name))
                {
                    return "MILITARY SUPPORT " . $_;
                }
            }
        }
    }
    if(@friends)
    {
        my $f = $friends[0];
        return "MILITARY SUPPORT " . $f;
    }
    return undef;
}

1;
