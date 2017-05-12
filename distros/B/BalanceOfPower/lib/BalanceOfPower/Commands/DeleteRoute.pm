package BalanceOfPower::Commands::DeleteRoute;
$BalanceOfPower::Commands::DeleteRoute::VERSION = '0.400115';
use Moo;

use BalanceOfPower::Utils qw( prev_turn );

extends 'BalanceOfPower::Commands::TargetRoute';

sub get_available_targets
{
    my $self = shift;
    my @targets = $self->SUPER::get_available_targets();
    my $nation = $self->actor;
    @targets = grep {! $self->world->exists_treaty_by_type($nation, $_, 'commercial') } @targets;
    return @targets;
}

sub execute
{
    my $self = shift;
    my $query = shift;
    my $nation = shift;
    my $result = $self->SUPER::execute($query, $nation);
    if($result->{status} == 1)
    {
        my $command = $result->{command};
        $command .= "->" . $self->actor;
        return { status => 1, command => $command };
    }
    else
    {
        return $result;
    }
}

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();

    my $prev_year = prev_turn($actor->current_year);
    my @trade_ko = $actor->get_events("TRADE KO", $prev_year);
    if(@trade_ko > 1)
    {
        for(@trade_ko)
        {
            my $to_delete = $_;
            $to_delete =~ s/TRADE KO //;
            if(! $self->world->exists_treaty_by_type($actor->name, $to_delete, 'commercial'))
            {
                return "DELETE TRADEROUTE " . $actor->name . "->" . $to_delete;   
            }
        }
    }
    elsif(@trade_ko == 1)
    {
        my @older_trade_ko = $actor->get_events("TRADE KO", prev_turn($prev_year));
        if(@older_trade_ko > 0)
        {
            my $to_delete = $trade_ko[$#trade_ko];
            $to_delete =~ s/TRADE KO //;
            if(! $self->world->exists_treaty_by_type($actor->name, $to_delete, 'commercial'))
            {
                return "DELETE TRADEROUTE " . $actor->name . "->" . $to_delete;
            }
        }
    }
    return undef;
}
   
 
1;
