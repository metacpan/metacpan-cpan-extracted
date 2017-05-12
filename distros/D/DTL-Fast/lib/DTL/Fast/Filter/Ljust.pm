package DTL::Fast::Filter::Ljust;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter::Center';

$DTL::Fast::FILTER_HANDLERS{'ljust'} = __PACKAGE__;

#@Override
sub adjust
{
    my $self = shift;
    my $value = shift;
    my $adjustment = shift;
    return $value.(' 'x $adjustment);
}

1;