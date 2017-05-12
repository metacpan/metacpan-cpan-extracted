package Asterisk::LCR::Dialer::MinCost;
use base qw /Asterisk::LCR::Dialer/;
use warnings;
use strict;


sub _process
{
    my $self   = shift;
    my $prefix = shift || return;
    my @rates  = $self->rates ($prefix);
    @rates || return [];
        
    my $local_prefix = $self->locale() ? $self->locale()->global_to_local ($prefix) : $prefix;
    my $exten_remove = length ($local_prefix);
    
    $prefix = "$prefix\${EXTEN:$exten_remove}";
    my $res ||= [];
    foreach my $rate (@rates)
    {
        my $str = $self->dial_string ($prefix, $rate) || next;
        push @{$res}, $str;
    }
    
    return $res;
}


1;
