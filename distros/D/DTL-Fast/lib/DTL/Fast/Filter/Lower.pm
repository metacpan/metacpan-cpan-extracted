package DTL::Fast::Filter::Lower;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

use locale;

$DTL::Fast::FILTER_HANDLERS{'lower'} = __PACKAGE__;

#@Override
sub filter
{
    shift;  # self
    shift;  # filter_manager
    
    return lc(shift // '');
}

1;