package DTL::Fast::Filter::SafeSeq;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'safeseq'} = __PACKAGE__;

#@Override
sub filter
{
    shift;

    shift->{'safeseq'} = 1;
    
    return shift;
}

1;