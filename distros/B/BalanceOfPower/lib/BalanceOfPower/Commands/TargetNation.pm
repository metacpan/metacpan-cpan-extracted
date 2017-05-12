package BalanceOfPower::Commands::TargetNation;
$BalanceOfPower::Commands::TargetNation::VERSION = '0.400115';
use Moo;
use v5.10;
use IO::Prompter;
use Data::Dumper;


with "BalanceOfPower::Commands::Role::Command";

has exclude_actor => (
    is => 'rw',
    default => 1
);

sub select_message
{
    return "Select a nation:";
}

sub execute
{
    my $self = shift;
    my $query = shift;
    my $nation = shift;
    my $argument = $self->extract_argument($query);
    $argument = $self->world->correct_nation_name($argument);
    if($argument)
    {
        if($self->good_target($argument))
        {
            return { status => 1, command => $self->name . " " . $argument };
        }
        else
        {
            say "Bad argument provided: $argument";
        }
    }
    else
    {
        if($self->good_target($nation))
        {
            return { status => 1, command => $self->name . " " . $nation };
        }
    }
    my @nations = $self->get_available_targets;
    if(@nations > 0)
    {
        $nation = prompt $self->select_message, -menu=>\@nations;
        return { status => -3} if ! $nation;
        return { status => 1, command => $self->name . " " . $nation };
    }
    else
    {
        return { status => -2 };
    }
}

sub good_target
{
    my $self = shift;
    my $nation = shift;
    return 0 if(! $nation);
    my @nations = $self->get_available_targets();
    my @selected = grep { $_ eq $nation} @nations;
    if(@selected >= 1)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub get_available_targets
{
    my $self = shift;
    my @nations = @{$self->world->nation_names};
    if($self->exclude_actor)
    {
        @nations = grep { $_ ne $self->actor } @nations;
    }
    return @nations
}

1;
