package DTL::Fast::Filter::Rjust;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter::Center';

$DTL::Fast::FILTER_HANDLERS{'rjust'} = __PACKAGE__;

#@Override
sub adjust
{
    my $self = shift;
    my $value = shift;
    my $adjustment = shift;
    return (' 'x $adjustment).$value;
}

1;