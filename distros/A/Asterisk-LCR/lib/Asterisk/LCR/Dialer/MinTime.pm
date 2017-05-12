package Asterisk::LCR::Dialer::MinTime;
use base qw /Asterisk::LCR::Dialer::MinCost/;
use warnings;
use strict;


sub _process
{
    my $self  = shift;
    my $dial  = $self->SUPER::_process (@_);
    my $str   = join '&', @{$dial};
    return [ $str ];
}


1;


__END__
