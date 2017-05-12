package DTL::Fast::Filter::Escape;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'escape'} = __PACKAGE__;
$DTL::Fast::FILTER_HANDLERS{'force_escape'} = __PACKAGE__;

#@Override
sub filter
{
    shift;  # self
    shift->{'safe'} = 1;    # filter_manager
    return DTL::Fast::html_protect(shift);
}

1;