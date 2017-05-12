package DTL::Fast::Filter::Upper;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

use locale;

$DTL::Fast::FILTER_HANDLERS{'upper'} = __PACKAGE__;

#@Override
sub filter
{
    shift;  # self
    shift;  # filter_manager
    return uc(shift // '');
}

1;