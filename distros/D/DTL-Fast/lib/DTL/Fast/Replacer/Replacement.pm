package DTL::Fast::Replacer::Replacement;
use strict;
use utf8;
use warnings FATAL => 'all';

sub new
{
    my $proto = shift;
    my $expression = shift;

    my $blocksep = '';
    my $block_num = 0;
    while( not $blocksep or $expression =~ /$blocksep/ )
    {
        $blocksep = sprintf '_BL_%s_', $block_num++;
    }

    my $self = bless {
            block_counter => 0
            , block_ph    => $blocksep.'%s_'
            , blocks      => { }
        }, $proto;

    return $self;
}

sub add_replacement
{
    my $self = shift;
    my $value = shift;

    my $key = sprintf $self->{block_ph}, $self->{block_counter}++;
    $self->{blocks}->{$key} = $value;

    return $key;
}

sub get_replacement
{
    my $self = shift;
    my $key = shift;
    my $value = undef;

    if (exists $self->{blocks}->{$key})
    {
        $value = $self->{blocks}->{$key};
        delete $self->{blocks}->{$key};
    }

    return $value;
}



1;