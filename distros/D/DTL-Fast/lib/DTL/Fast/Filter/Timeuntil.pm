package DTL::Fast::Filter::Timeuntil;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter::Timesince';

$DTL::Fast::FILTER_HANDLERS{'timeuntil'} = __PACKAGE__;

#@Override
sub time_diff
{
    my $self = shift;
    my $diff = shift;
    return $self->SUPER::time_diff(-$diff);
}

1;