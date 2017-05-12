package DTL::Fast::Filter::Safe;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'safe'} = __PACKAGE__;

#@Override
sub filter
{
    shift;

    shift->{'safe'} = 1;
    
    return shift;
}

1;