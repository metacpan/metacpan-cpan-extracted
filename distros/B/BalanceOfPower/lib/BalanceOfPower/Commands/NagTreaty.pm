package BalanceOfPower::Commands::NagTreaty;
$BalanceOfPower::Commands::NagTreaty::VERSION = '0.400115';
use Moo;
use Array::Utils qw(intersect);

extends 'BalanceOfPower::Commands::TargetNation';
with 'BalanceOfPower::Commands::Role::TreatiesUnderLimit';

sub get_available_targets
{
    my $self = shift;
    my @targets = $self->SUPER::get_available_targets();
    my $nation = $self->actor;
    @targets = grep {! $self->world->exists_treaty($nation, $_) } @targets;
    @targets = grep { $self->world->diplomacy_status($nation, $_) ne 'HATE' } @targets;
    return $self->nations_under_treaty_limit(@targets);
}

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    my @available_targets = $self->get_available_targets();
    return undef if @available_targets == 0;
    my @near = $self->world->near_nations($actor->name, 1);

    my @friendly_neighbors = $self->world->shuffle("Mixing neighbors to choose about NAG treaty", intersect(@near, @available_targets));
    my @ordered_friendly_neighbors = ();
    my $dangerous_neighbor = 0;
    for(@friendly_neighbors)
    {
        my $n = $_;
        if(! $self->world->exists_treaty($self->name, $n))
        {
            my $supporter = $self->world->supported($n);
            if($supporter)
            {
                my $supporter_nation = $supporter->node1;
                if($supporter_nation eq $actor->name)
                {
                    #I'm the supporter of this nation!
                    push @ordered_friendly_neighbors, { nation => $n,
                                                            interest => 0 };
                }
                else
                {
                    if($self->world->crisis_exists($actor->name, $supporter_nation))
                    {
                        push @ordered_friendly_neighbors, { nation => $n,
                                                            interest => 100 };
                        $dangerous_neighbor = 1;
                    }
                    elsif($self->world->diplomacy_status($actor->name, $supporter_nation) eq 'HATE')
                    {
                        push @ordered_friendly_neighbors, { nation => $n,
                                                            interest => 10 };
                    }
                    else
                    {
                        push @ordered_friendly_neighbors, { nation => $n,
                                                                interest => 2 };
                    }
                }
            }
            else
            {
                push @ordered_friendly_neighbors, { nation => $n,
                                                    interest => 1 };
            }
        }
    }
    if(@ordered_friendly_neighbors > 0 && $dangerous_neighbor)
    {
        @ordered_friendly_neighbors = sort { $b->{interest} <=> $a->{interest} } @ordered_friendly_neighbors;
        return "TREATY NAG WITH " . $ordered_friendly_neighbors[0]->{nation};
    }
    else
    {
        #Scanning crises
        my @crises = $self->world->get_crises($actor->name);
        if(@crises > 0)
        {
            foreach my $c ($self->world->shuffle("Mixing crisis for war for " . $actor->name, @crises))
            {
                #NAG with enemy supporter
                my $enemy = $c->destination($actor->name);
                my $supporter = $self->world->supported($enemy);
                if($supporter)
                {
                    my $supporter_nation = $supporter->node1;
                    if($supporter_nation ne $actor->name &&
                       $self->world->diplomacy_status($actor->name, $supporter_nation) ne 'HATE' &&
                       ! $self->world->exists_treaty($actor->name, $supporter_nation))
                    {
                       return "TREATY NAG WITH " . $supporter_nation;
                    } 
                }
                #NAG with enemy ally
                my @allies = $self->world->get_allies($enemy);
                for($self->world->shuffle("Mixing allies of enemy for a NAG", @allies))
                {
                    my $all = $_->destination($enemy);
                    if($all ne $actor->name &&
                       $self->world->diplomacy_status($actor->name, $all) ne 'HATE' &&
                       ! $self->world->exists_treaty($actor->name, $all))
                    {
                        return "TREATY NAG WITH " . $all;
                    } 
                }
            }
        }
        if(@ordered_friendly_neighbors > 0)
        {
            @ordered_friendly_neighbors = sort { $b->{interest} <=> $a->{interest} } @ordered_friendly_neighbors;
            return "TREATY NAG WITH " . $ordered_friendly_neighbors[0]->{nation};
        }
        return undef;
    }
}

1;
