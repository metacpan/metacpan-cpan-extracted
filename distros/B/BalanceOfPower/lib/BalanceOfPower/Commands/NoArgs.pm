package BalanceOfPower::Commands::NoArgs;
$BalanceOfPower::Commands::NoArgs::VERSION = '0.400115';
use Moo;

extends 'BalanceOfPower::Commands::Plain';

sub has_argument
{
    return 0;
}

sub extract_argument
{
    my $self = shift;
    my $query = shift;
    my $extract = shift;
    $query = uc $query;
    $extract = 1 if(! defined $extract);
    my $name = $self->name;
    if($query =~ /^$name$/)
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
        if($query =~ /^$syn$/)
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
1;
