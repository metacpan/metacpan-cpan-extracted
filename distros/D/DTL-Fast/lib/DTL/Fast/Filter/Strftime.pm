package DTL::Fast::Filter::Strftime;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter::Date';

$DTL::Fast::FILTER_HANDLERS{'strftime'} = __PACKAGE__;

use DTL::Fast::Utils;

#@Override
sub filter
{
    my $self = shift;  # self
    shift;  # filter_manager
    my $value = shift;
    my $context = shift;
    
    my $format = $self->{'format'}->render($context);
    
    return DTL::Fast::Utils::time2str($format, $value);
}

1;