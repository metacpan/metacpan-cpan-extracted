package DTL::Fast::Filter::Iriencode;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter::Urlencode';

$DTL::Fast::FILTER_HANDLERS{'iriencode'} = __PACKAGE__;

1;