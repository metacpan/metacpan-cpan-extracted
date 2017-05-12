package BalanceOfPower::Commands::Role::Command;
$BalanceOfPower::Commands::Role::Command::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

has name => (
    is => 'ro',
    default => 'DO NOTHING'
);
has actor => (
    is => 'rw',
);

has world => (
    is => 'ro'
);
has synonyms => (
    is => 'rw',
    default => sub { [] }
);
has export_cost => (
    is => 'ro',
    default => 0
);
has domestic_cost => (
    is => 'ro',
    default => 0
);
has prestige_cost => (
    is => 'ro',
    default => 0
);

has allowed_at_war => (
    is => 'ro',
    default => 0
);
has production_limit => (
    is => 'ro',
    default => sub { {} }
);
has army_limit => (
    is => 'ro',
    default => sub { {} }
);
has treaty_limit => (
    is => 'ro',
    default => 0
);

sub has_argument
{
    return 1;
}

sub get_nation
{
    my $self = shift;
    return $self->world->get_nation($self->actor);
}

sub allowed
{
    my $self = shift;
    my $nation = $self->get_nation();
    return 0
        if($nation->internal_disorder_status() eq 'Civil war');
    if(! $self->allowed_at_war)
    {
        if($self->world->at_war($self->actor))
        {
            return 0;
        }
    }
    if(exists $self->production_limit->{'<'})
    {
        return $nation->production() <= $self->production_limit->{'<'};
    }
    elsif(exists $self->production_limit->{'>'})
    {
        return $nation->production() >= $self->production_limit->{'>'};
    }
    if(exists $self->army_limit->{'<'})
    {
        return $nation->army() <= $self->army_limit->{'<'};
    }
    elsif(exists $self->army_limit->{'>'})
    {
        return $nation->army() >= $self->army_limit->{'>'};
    }
    if($nation->production_for_domestic < $self->domestic_cost)
    {
        return 0;
    }
    if($nation->production_for_export < $self->export_cost)
    {
        return 0;
    }
    if($nation->prestige < $self->prestige_cost)
    {
        return 0;
    }
    if($self->treaty_limit == 1)
    {
       if($self->world->get_treaties_for_nation($nation->name) >= $nation->treaty_limit)
       {
           return 0;
       }
    }
    return 1;
}

sub extract_argument
{
    my $self = shift;
    my $query = shift;
    my $extract = shift;
    $query = uc $query; #Commands are always all caps
    $extract = 1 if(! defined $extract);
    my $name = $self->name;
    if($query =~ /^$name( (.*))?$/)
    {
        if($extract)
        {
            return $2;
        }
        else
        {
            return 1;
        }
    }
    foreach my $syn (@{$self->synonyms})
    {
        if($query =~ /^$syn( (.*))?/)
        {
            if($extract)
            {
                return $2;
            }
            else
            {
                return 1;
            }
        }
    }
    return undef;
}

sub recognize
{
    my $self = shift;
    my $query = shift;
    if($self->extract_argument($query, 0))
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub execute
{
    my $self = shift;
    my $query = shift;
    return { status => 1, command => uc $query };
}

sub print
{
    my $self = shift;
    return $self->name;
}

sub IA
{
    my $self = shift;
    return $self->name;
}


1;
